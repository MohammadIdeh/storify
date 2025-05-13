import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class OrderService with ChangeNotifier {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';
  List<Order> _assignedOrders = [];
  List<Order> _completedOrders = [];
  Order? _currentOrder;
  String? _token;
  bool _isLoading = false;
  Timer? _refreshTimer;

  List<Order> get assignedOrders => [..._assignedOrders];
  List<Order> get completedOrders => [..._completedOrders];
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;

  void updateToken(String? token) {
    _token = token;
    if (_token != null) {
      _startRefreshTimer();
    } else {
      _stopRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchAssignedOrders();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> fetchAssignedOrders() async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/orders/assigned'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body);
        _assignedOrders =
            ordersJson.map((order) => Order.fromJson(order)).toList();

        // Set current order to the first in-progress order, if any
        // Updated code that handles the null case properly
        if (_assignedOrders.isNotEmpty) {
          // First try to find an in-progress order
          try {
            _currentOrder = _assignedOrders.firstWhere(
              (order) => order.status == OrderStatus.inProgress,
            );
          } catch (e) {
            // If no in-progress order, try to find an accepted order
            try {
              _currentOrder = _assignedOrders.firstWhere(
                (order) => order.status == OrderStatus.accepted,
              );
            } catch (e) {
              // If no accepted order either, just use the first one
              _currentOrder = _assignedOrders.first;
            }
          }
        } else {
          // No orders available
          _currentOrder = null;
        }
      }
    } catch (e) {
      print("Error fetching assigned orders: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCompletedOrders() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/orders/completed'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body);
        _completedOrders =
            ordersJson.map((order) => Order.fromJson(order)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching completed orders: $e");
    }
  }

  Future<bool> updateOrderStatus(int orderId, OrderStatus status) async {
    if (_token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/delivery/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
        body: json.encode({
          'status': status.toString().split('.').last,
        }),
      );

      if (response.statusCode == 200) {
        await fetchAssignedOrders();
        if (status == OrderStatus.delivered) {
          await fetchCompletedOrders();
        }
        return true;
      }
      return false;
    } catch (e) {
      print("Error updating order status: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }
}
