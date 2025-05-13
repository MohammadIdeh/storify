import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  int _currentIndex = 0;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isMapInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchData();
    }
  }

  void _initializeServices() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    // Set token for services
    orderService.updateToken(authService.token);
    locationService.updateToken(authService.token);

    // Initialize location
    locationService.getCurrentLocation();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final orderService = Provider.of<OrderService>(context, listen: false);
    await orderService.fetchAssignedOrders();

    if (_currentIndex == 1) {
      await orderService.fetchCompletedOrders();
    }

    setState(() {
      _isLoading = false;
    });

    _updateMap();
  }

  void _updateMap() {
    if (!_isMapInitialized) return;

    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final currentOrder = orderService.currentOrder;
    final currentPosition = locationService.currentPosition;

    setState(() {
      _markers = {};
      _polylines = {};

      // Add marker for delivery person's current location
      if (currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position:
                LatLng(currentPosition.latitude, currentPosition.longitude),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );

        // Move camera to current location if no active order
        if (currentOrder == null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(currentPosition.latitude, currentPosition.longitude),
              15,
            ),
          );
        }
      }

      // Add marker for current order's destination
      if (currentOrder != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('order_${currentOrder.id}'),
            position: LatLng(currentOrder.latitude, currentOrder.longitude),
            infoWindow: InfoWindow(
              title: 'Delivery to ${currentOrder.customerName}',
              snippet: currentOrder.address,
            ),
          ),
        );

        // If we have both current location and destination, show both on map
        if (currentPosition != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  math.min(currentPosition.latitude, currentOrder.latitude) -
                      0.01,
                  math.min(currentPosition.longitude, currentOrder.longitude) -
                      0.01,
                ),
                northeast: LatLng(
                  math.max(currentPosition.latitude, currentOrder.latitude) +
                      0.01,
                  math.max(currentPosition.longitude, currentOrder.longitude) +
                      0.01,
                ),
              ),
              100, // padding
            ),
          );

          // In a real app, you'd draw polylines for the route here
          // For this example, we'll just draw a straight line
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route_${currentOrder.id}'),
              color: AppColors.primary,
              width: 5,
              points: [
                LatLng(currentPosition.latitude, currentPosition.longitude),
                LatLng(currentOrder.latitude, currentOrder.longitude),
              ],
            ),
          );
        } else {
          // If we only have destination, center on that
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(currentOrder.latitude, currentOrder.longitude),
              15,
            ),
          );
        }
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapInitialized = true;
    _updateMap();
  }

  void _startDelivery(Order order) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    final success =
        await orderService.updateOrderStatus(order.id, OrderStatus.inProgress);

    if (success) {
      // Start location tracking
      locationService.startTracking(order.id);

      // Refresh data
      _fetchData();
    }
  }

  void _markAsDelivered(Order order) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    final success =
        await orderService.updateOrderStatus(order.id, OrderStatus.delivered);

    if (success) {
      // Stop location tracking
      locationService.stopTracking();

      // Refresh data
      _fetchData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as delivered'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _viewOrderDetails(Order order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        )
        .then((_) => _fetchData());
  }

  Widget _buildActiveOrdersTab() {
    final orderService = Provider.of<OrderService>(context);
    final orders = orderService.assignedOrders;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delivery_dining,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No active deliveries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have any active deliveries at the moment.',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Refresh',
              onPressed: _fetchData,
              width: 150,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            onViewDetails: () => _viewOrderDetails(order),
            onStartDelivery: order.status == OrderStatus.accepted
                ? () => _startDelivery(order)
                : null,
            onMarkAsDelivered: order.status == OrderStatus.inProgress
                ? () => _markAsDelivered(order)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    final orderService = Provider.of<OrderService>(context);
    final orders = orderService.completedOrders;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No delivery history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your completed deliveries will appear here.',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await orderService.fetchCompletedOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            onViewDetails: () => _viewOrderDetails(order),
          );
        },
      ),
    );
  }

  Widget _buildMapView() {
    final locationService = Provider.of<LocationService>(context);
    final orderService = Provider.of<OrderService>(context);
    final currentOrder = orderService.currentOrder;

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: locationService.currentPosition != null
                ? LatLng(
                    locationService.currentPosition!.latitude,
                    locationService.currentPosition!.longitude,
                  )
                : const LatLng(31.9539, 35.9106), // Default to Amman, Jordan
            zoom: 14,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: _markers,
          polylines: _polylines,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
        ),

        // Current order info overlay at the bottom
        if (currentOrder != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.delivery_dining,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Delivery to ${currentOrder.customerName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentOrder.address,
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'View Details',
                            onPressed: () => _viewOrderDetails(currentOrder),
                            backgroundColor: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomButton(
                            text: currentOrder.status == OrderStatus.accepted
                                ? 'Start Delivery'
                                : 'Mark as Delivered',
                            onPressed:
                                currentOrder.status == OrderStatus.accepted
                                    ? () => _startDelivery(currentOrder)
                                    : () => _markAsDelivered(currentOrder),
                            backgroundColor:
                                currentOrder.status == OrderStatus.accepted
                                    ? AppColors.primary
                                    : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        authService.logout();
                        Navigator.of(context).pushReplacementNamed('/');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMapView(),
          _buildActiveOrdersTab(),
          _buildHistoryTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 1) {
            // Active Orders tab
            Provider.of<OrderService>(context, listen: false)
                .fetchAssignedOrders();
          } else if (index == 2) {
            // History tab
            Provider.of<OrderService>(context, listen: false)
                .fetchCompletedOrders();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
