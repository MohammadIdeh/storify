import 'dart:async';
import 'dart:math' as math;
import 'package:deliveryman/models/order.dart';
import 'package:deliveryman/services/location_service.dart';
import 'package:deliveryman/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class LiveNavigationCard extends StatefulWidget {
  final Order currentOrder;
  final VoidCallback onViewDetails;
  final VoidCallback onComplete;

  const LiveNavigationCard({
    Key? key,
    required this.currentOrder,
    required this.onViewDetails,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<LiveNavigationCard> createState() => _LiveNavigationCardState();
}

class _LiveNavigationCardState extends State<LiveNavigationCard>
    with TickerProviderStateMixin {
  Timer? _navigationTimer;
  int _elapsedSeconds = 0;
  int _estimatedRemainingMinutes = 0;
  double _remainingDistanceKm = 0.0;
  double _averageSpeedKmh = 0.0;
  bool _isLoadingETA = false;
  DateTime? _deliveryStartTime;

  // Track movement for better ETA calculation
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  List<double> _recentSpeeds = [];

  // Animation and minimization state
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool _isMinimized = false;

  // Batch delivery state
  int _selectedOrderIndex = 0;

  @override
  void initState() {
    super.initState();
    _deliveryStartTime =
        widget.currentOrder.deliveryStartTime ?? DateTime.now();

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation for minimized state
    _pulseController.repeat(reverse: true);

    _startNavigationTracking();
    _calculateInitialETA();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });

    if (_isMinimized) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _startNavigationTracking() {
    _navigationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds =
              DateTime.now().difference(_deliveryStartTime!).inSeconds;
        });

        // Update ETA every 30 seconds
        if (_elapsedSeconds % 30 == 0) {
          _updateETAFromCurrentLocation();
        }
      }
    });
  }

  Future<void> _calculateInitialETA() async {
    if (!mounted) return;

    setState(() {
      _isLoadingETA = true;
      _estimatedRemainingMinutes = widget.currentOrder.estimatedDeliveryTime;
    });

    await _updateETAFromCurrentLocation();

    if (mounted) {
      setState(() {
        _isLoadingETA = false;
      });
    }
  }

  Future<void> _updateETAFromCurrentLocation() async {
    try {
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      final currentPosition = locationService.currentPosition;

      if (currentPosition == null) return;

      // Calculate remaining distance
      final distanceToCustomer = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        widget.currentOrder.latitude,
        widget.currentOrder.longitude,
      );

      setState(() {
        _remainingDistanceKm = distanceToCustomer / 1000;
      });

      // Calculate average speed if we have movement history
      _updateAverageSpeed(currentPosition);

      // Get updated ETA from Google Directions (every 30 seconds)
      final origin =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      final destination =
          LatLng(widget.currentOrder.latitude, widget.currentOrder.longitude);

      final directionsResponse =
          await orderService.getDirectionsFromGoogle(origin, destination);

      if (directionsResponse != null && mounted) {
        setState(() {
          _estimatedRemainingMinutes = directionsResponse.durationMinutes;
          _remainingDistanceKm = directionsResponse.distanceKm;
        });
      } else {
        // Fallback calculation based on average speed
        if (_averageSpeedKmh > 5) {
          // Only if we have reasonable speed data
          final etaMinutes =
              (_remainingDistanceKm / _averageSpeedKmh * 60).round();
          setState(() {
            _estimatedRemainingMinutes = etaMinutes;
          });
        }
      }
    } catch (e) {
      print('Error updating ETA: $e');
    }
  }

  void _updateAverageSpeed(Position currentPosition) {
    final now = DateTime.now();

    if (_lastPosition != null && _lastPositionTime != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      final timeElapsed = now.difference(_lastPositionTime!).inSeconds;

      if (timeElapsed > 0 && distance > 10) {
        // Only calculate if moved > 10 meters
        final speedMps = distance / timeElapsed; // meters per second
        final speedKmh = speedMps * 3.6; // convert to km/h

        // Add to recent speeds (keep last 10 readings)
        _recentSpeeds.add(speedKmh);
        if (_recentSpeeds.length > 10) {
          _recentSpeeds.removeAt(0);
        }

        // Calculate average speed
        if (_recentSpeeds.isNotEmpty) {
          _averageSpeedKmh =
              _recentSpeeds.reduce((a, b) => a + b) / _recentSpeeds.length;
        }
      }
    }

    _lastPosition = currentPosition;
    _lastPositionTime = now;
  }

  String _formatElapsedTime() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatETA() {
    if (_estimatedRemainingMinutes <= 0) return 'Arrived';
    if (_estimatedRemainingMinutes < 60) {
      return '${_estimatedRemainingMinutes}min';
    } else {
      final hours = _estimatedRemainingMinutes ~/ 60;
      final minutes = _estimatedRemainingMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  Color _getETAColor() {
    if (_estimatedRemainingMinutes <= 5)
      return const Color(0xFF4CAF50); // Green - Almost there
    if (_estimatedRemainingMinutes <= 15)
      return const Color(0xFFFF9800); // Orange - Close
    return const Color(0xFF6941C6); // Purple - En route
  }

  Widget _buildMinimizedButton() {
    return Consumer<OrderService>(
      builder: (context, orderService, child) {
        final activeRoutes = orderService.activeRoutes;
        final isBatch = activeRoutes.length > 1;

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTap: _toggleMinimize,
                child: Container(
                  width: isBatch ? 100 : 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getETAColor(),
                        _getETAColor().withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getETAColor().withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background pulse effect
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isBatch ? Icons.route : Icons.navigation,
                              color: Colors.white,
                              size: 20,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            if (isBatch) ...[
                              Text(
                                '${activeRoutes.length} Orders',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatETA(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Text(
                                _formatETA(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Live indicator
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Batch indicator
                      if (isBatch)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${activeRoutes.length}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getETAColor(),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpandedCard() {
    return Consumer<OrderService>(
      builder: (context, orderService, child) {
        final activeRoutes = orderService.activeRoutes;
        final isBatch = activeRoutes.length > 1;

        if (isBatch) {
          return _buildBatchDeliveryCard(activeRoutes);
        } else {
          return _buildSingleDeliveryCard();
        }
      },
    );
  }

  Widget _buildBatchDeliveryCard(List<RouteInfo> activeRoutes) {
    final totalDistance =
        activeRoutes.fold<double>(0, (sum, route) => sum + route.distance);
    final totalTime =
        activeRoutes.fold<int>(0, (sum, route) => sum + route.estimatedTime);
    final currentRouteIndex =
        activeRoutes.indexWhere((route) => route.order.isInProgress);
    final nextRouteIndex = currentRouteIndex + 1 < activeRoutes.length
        ? currentRouteIndex + 1
        : -1;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF304050),
            const Color(0xFF304050).withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6941C6).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF6941C6).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6941C6),
                        const Color(0xFF6941C6).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6941C6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.route,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Delivery Route',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: const Color(0xAAFFFFFF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${activeRoutes.length} Orders • ${totalDistance.toStringAsFixed(1)}km',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Minimize button
                GestureDetector(
                  onTap: _toggleMinimize,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.minimize_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Overall Progress Stats
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1D2939),
                    const Color(0xFF1D2939).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6941C6).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  // Total ETA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: const Color(0xFF6941C6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total ETA',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '~${totalTime}min',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6941C6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: const Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Progress',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentRouteIndex + 1}/${activeRoutes.length}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Elapsed Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: const Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Elapsed',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatElapsedTime(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Current Order Details
            if (currentRouteIndex >= 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${currentRouteIndex + 1}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT DELIVERY',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Order #${activeRoutes[currentRouteIndex].order.id} - ${activeRoutes[currentRouteIndex].order.customerName}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatETA(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activeRoutes[currentRouteIndex].order.address,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: const Color(0xAAFFFFFF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Next Order Preview
            if (nextRouteIndex >= 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6941C6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6941C6).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6941C6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${nextRouteIndex + 1}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXT: Order #${activeRoutes[nextRouteIndex].order.id}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              color: const Color(0xFF6941C6),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            activeRoutes[nextRouteIndex].order.customerName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${activeRoutes[nextRouteIndex].distance.toStringAsFixed(1)}km',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF6941C6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: widget.onViewDetails,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: Text(
                        'Details',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D2939),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFF4CAF50).withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: widget.onComplete,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(
                        'Complete',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleDeliveryCard() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF304050),
            const Color(0xFF304050).withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6941C6).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF6941C6).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with navigation status and close button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getETAColor(),
                        _getETAColor().withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getETAColor().withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navigating to Customer',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: const Color(0xAAFFFFFF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.currentOrder.customerName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Minimize button
                GestureDetector(
                  onTap: _toggleMinimize,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.minimize_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Real-time navigation stats
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1D2939),
                    const Color(0xFF1D2939).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getETAColor().withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ETA Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: _getETAColor(),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ETA',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_isLoadingETA) ...[
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      _getETAColor()),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatETA(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getETAColor(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Distance Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.straighten,
                              size: 16,
                              color: Color(0xFF6941C6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Distance',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_remainingDistanceKm.toStringAsFixed(1)}km',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6941C6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Elapsed Time Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.timer,
                              size: 16,
                              color: Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Elapsed',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatElapsedTime(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Speed info (if available)
            if (_averageSpeedKmh > 5) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6941C6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6941C6).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.speed,
                      size: 16,
                      color: Color(0xFF6941C6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Average Speed: ${_averageSpeedKmh.toStringAsFixed(1)} km/h',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF6941C6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Address
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF6941C6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.currentOrder.address,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: const Color(0xAAFFFFFF),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: widget.onViewDetails,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: Text(
                        'Details',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D2939),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFF4CAF50).withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: widget.onComplete,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(
                        'Complete',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        if (child.key == const ValueKey('minimized')) {
          // Slide in from right for minimized button
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            )),
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        } else {
          // Scale and fade for expanded card
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        }
      },
      child: _isMinimized
          ? Align(
              key: const ValueKey('minimized'),
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildMinimizedButton(),
              ),
            )
          : Container(
              key: const ValueKey('expanded'),
              child: _buildExpandedCard(),
            ),
    );
  }
}
