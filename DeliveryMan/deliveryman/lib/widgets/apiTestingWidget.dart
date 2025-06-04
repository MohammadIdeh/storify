import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _addDebugLine(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toIso8601String()}: $message\n';
    });
    print(message);
  }

  void _clearDebug() {
    setState(() {
      _debugOutput = '';
    });
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
    });

    _addDebugLine('=== API Connection Test Started ===');

    final authService = Provider.of<AuthService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);

    // Check authentication
    _addDebugLine('Checking authentication...');
    _addDebugLine('Is logged in: ${authService.isLoggedIn}');
    _addDebugLine('Token available: ${authService.token != null}');

    if (authService.token != null) {
      _addDebugLine(
          'Token (first 20 chars): ${authService.token!.substring(0, math.min(20, authService.token!.length))}...');
    }

    if (!authService.isLoggedIn || authService.token == null) {
      _addDebugLine('ERROR: Not authenticated. Please login first.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Test order fetching
    _addDebugLine('Testing order API...');
    try {
      await orderService.fetchAssignedOrders();

      if (orderService.lastError != null) {
        _addDebugLine('API Error: ${orderService.lastError}');
      } else {
        _addDebugLine('SUCCESS: Orders fetched successfully');
        _addDebugLine(
            'Number of assigned orders: ${orderService.assignedOrders.length}');

        for (int i = 0; i < orderService.assignedOrders.length; i++) {
          final order = orderService.assignedOrders[i];
          _addDebugLine('Order ${i + 1}:');
          _addDebugLine('  ID: ${order.id}');
          _addDebugLine('  Customer: ${order.customerName}');
          _addDebugLine('  Status: ${order.status}');
          _addDebugLine('  Can Start: ${order.canStart}');
          _addDebugLine('  Is In Progress: ${order.isInProgress}');
          _addDebugLine('  Total Cost: \$${order.totalCost}');
          _addDebugLine('  Address: ${order.address}');
          _addDebugLine('  Items: ${order.items.length}');
        }

        if (orderService.currentOrder != null) {
          _addDebugLine('Current Order ID: ${orderService.currentOrder!.id}');
        } else {
          _addDebugLine('No current order set');
        }
      }
    } catch (e) {
      _addDebugLine('EXCEPTION during API call: $e');
    }

    _addDebugLine('=== API Connection Test Completed ===');

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D2939),
      appBar: AppBar(
        backgroundColor: const Color(0xFF304050),
        title: const Text(
          'API Testing',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: _clearDebug,
            tooltip: 'Clear Debug Output',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testApiConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6941C6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Test API Connection'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF304050),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6941C6).withOpacity(0.3),
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _debugOutput.isEmpty
                      ? 'Tap "Test API Connection" to start debugging...'
                      : _debugOutput,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Consumer<OrderService>(
            builder: (context, orderService, child) {
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF304050),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Order Service Status:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Is Loading: ${orderService.isLoading}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Assigned Orders: ${orderService.assignedOrders.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Current Order: ${orderService.currentOrder?.id ?? 'None'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (orderService.lastError != null)
                      Text(
                        'Last Error: ${orderService.lastError}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
