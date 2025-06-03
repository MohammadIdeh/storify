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

class _LiveNavigationCardState extends State<LiveNavigationCard> {
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

  @override
  void initState() {
    super.initState();
    _deliveryStartTime =
        widget.currentOrder.deliveryStartTime ?? DateTime.now();
    _startNavigationTracking();
    _calculateInitialETA();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF304050),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6941C6).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with navigation status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getETAColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: _getETAColor(),
                    size: 20,
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
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
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
              ],
            ),

            const SizedBox(height: 16),

            // Real-time navigation stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2939),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getETAColor().withOpacity(0.2),
                ),
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
                            SizedBox(
                              width: 5,
                            ),
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
                  borderRadius: BorderRadius.circular(8),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
}
