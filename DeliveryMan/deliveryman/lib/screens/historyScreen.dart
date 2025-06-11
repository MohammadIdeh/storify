// lib/screens/enhanced_history_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/delivery_history.dart';
import '../models/today_stats.dart'; // Import the new model
import '../services/auth_service.dart';

class EnhancedHistoryScreen extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onRefresh;

  const EnhancedHistoryScreen({
    Key? key,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<EnhancedHistoryScreen> createState() => _EnhancedHistoryScreenState();
}

class _EnhancedHistoryScreenState extends State<EnhancedHistoryScreen>
    with SingleTickerProviderStateMixin {
  DeliveryHistoryResponse? _historyData;
  TodayStatsResponse? _todayStats; // Add today stats
  bool _isLoading = false;
  bool _isLoadingStats = false; // Separate loading for stats
  String? _error;
  int _currentPage = 1;
  final int _limit = 10;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, cash, partial, debt
  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch both delivery history and today stats
  Future<void> _fetchData() async {
    await Future.wait([
      _fetchDeliveryHistory(),
      _fetchTodayStats(),
    ]);
  }

  // New method to fetch today's stats
  Future<void> _fetchTodayStats() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.token == null) {
        throw Exception('No authentication token');
      }

      print(
          'Fetching today stats from: https://finalproject-a5ls.onrender.com/delivery/today-stats');

      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/delivery/today-stats'),
        headers: {
          'Content-Type': 'application/json',
          'token': authService.token!,
        },
      );

      print('Today stats response status: ${response.statusCode}');
      print('Today stats response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _todayStats = TodayStatsResponse.fromJson(jsonData);
          _isLoadingStats = false;
        });
        print('Successfully fetched today stats');
      } else {
        throw Exception('Failed to load today stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching today stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _fetchDeliveryHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/delivery/history?page=$_currentPage&limit=$_limit'),
        headers: {
          'Content-Type': 'application/json',
          'token': authService.token!,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _historyData = DeliveryHistoryResponse.fromJson(jsonData);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<DeliveryHistoryItem> get _filteredDeliveries {
    if (_historyData == null) return [];

    var deliveries = _historyData!.deliveries;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      deliveries = deliveries.where((delivery) {
        return delivery.customer.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            delivery.customer.address
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            delivery.orderId.toString().contains(_searchQuery);
      }).toList();
    }

    // Apply payment filter
    if (_selectedFilter != 'all') {
      deliveries = deliveries.where((delivery) {
        return delivery.paymentMethod.toLowerCase() == _selectedFilter;
      }).toList();
    }

    return deliveries;
  }

  Widget _buildStatsCards() {
    // Show loading state if stats are loading
    if (_isLoadingStats || _todayStats == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Performance',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: _isLoadingStats
                  ? Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading today\'s stats...',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: const Color(0xAAFFFFFF),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'No stats available',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: const Color(0xAAFFFFFF),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    final stats = _todayStats!.todayStats;
    final activity = _todayStats!.todayActivity;
    final performance = _todayStats!.performance;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Today\'s Performance',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6941C6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6941C6).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _todayStats!.date,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF6941C6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Deliveries',
                  value: stats.totalDeliveries.toString(),
                  icon: Icons.local_shipping,
                  color: const Color(0xFF6941C6),
                  subtitle: 'Completed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Revenue',
                  value: '\$${stats.totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: const Color(0xFF4CAF50),
                  subtitle: 'Earned',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Avg Delivery Time',
                  value: '${stats.avgDeliveryTime}min',
                  icon: Icons.access_time,
                  color: const Color(0xFFFF9800),
                  subtitle: 'Per delivery',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Avg Revenue',
                  value: '\$${stats.avgRevenuePerDelivery.toStringAsFixed(1)}',
                  icon: Icons.trending_up,
                  color: const Color(0xFF2196F3),
                  subtitle: 'Per delivery',
                ),
              ),
            ],
          ),

          // Performance metrics row
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Completion Rate',
                  value: '${performance.completionRate.toStringAsFixed(1)}%',
                  icon: Icons.check_circle,
                  color: const Color(0xFF4CAF50),
                  subtitle: 'Success rate',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Amount Paid',
                  value: '\$${stats.totalAmountPaid.toStringAsFixed(0)}',
                  icon: Icons.payment,
                  color: const Color(0xFF9C27B0),
                  subtitle: 'Collected',
                ),
              ),
            ],
          ),

          // Activity overview
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF304050),
                  const Color(0xFF304050).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6941C6).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.volunteer_activism_outlined,
                      color: Color(0xFF6941C6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Activity',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActivityItem(
                        'Active',
                        activity.activeOrders.toString(),
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildActivityItem(
                        'Completed',
                        activity.completedDeliveries.toString(),
                        const Color(0xFF4CAF50),
                      ),
                    ),
                    Expanded(
                      child: _buildActivityItem(
                        'Pending',
                        activity.pendingOrders.toString(),
                        const Color(0xFF6941C6),
                      ),
                    ),
                    if (activity.returnedOrders > 0)
                      Expanded(
                        child: _buildActivityItem(
                          'Returned',
                          activity.returnedOrders.toString(),
                          Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: const Color(0xAAFFFFFF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF304050),
            const Color(0xFF304050).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 19,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: const Color(0xAAFFFFFF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF304050),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6941C6).withOpacity(0.3),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by customer, address, or order ID...',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: const Color(0xAAFFFFFF),
                ),
                border: InputBorder.none,
                icon: const Icon(
                  Icons.search,
                  color: Color(0xFF6941C6),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Filter tabs
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF304050),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6941C6).withOpacity(0.3),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF6941C6),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xAAFFFFFF),
              labelStyle: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              onTap: (index) {
                setState(() {
                  switch (index) {
                    case 0:
                      _selectedFilter = 'all';
                      break;
                    case 1:
                      _selectedFilter = 'cash';
                      break;
                    case 2:
                      _selectedFilter = 'partial';
                      break;
                    case 3:
                      _selectedFilter = 'debt';
                      break;
                  }
                });
              },
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Cash'),
                Tab(text: 'Partial'),
                Tab(text: 'Debt'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryHistoryItem delivery) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF304050),
            const Color(0xFF304050).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6941C6).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with order info and performance indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6941C6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${delivery.orderId}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a')
                          .format(delivery.endTime),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xAAFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPerformanceIndicator(delivery),
            ],
          ),

          const SizedBox(height: 16),

          // Customer and payment info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2939),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6941C6).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.person_outline,
                  'Customer',
                  delivery.customer.name,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Address',
                  delivery.customer.address,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.payment,
                        'Payment',
                        _formatPaymentMethod(delivery.paymentMethod),
                        valueColor: _getPaymentColor(delivery.paymentMethod),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.attach_money,
                        'Amount',
                        '\$${delivery.totalAmount.toStringAsFixed(2)}',
                        valueColor: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Performance metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: delivery.wasOnTime
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : const Color(0xFFFF9800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: delivery.wasOnTime
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : const Color(0xFFFF9800).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Estimated',
                    '${delivery.estimatedTime}min',
                    Icons.schedule,
                    const Color(0xFF6941C6),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Actual',
                    '${delivery.actualTime}min',
                    Icons.timer,
                    delivery.wasOnTime
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Efficiency',
                    '${delivery.efficiency.toStringAsFixed(0)}%',
                    Icons.trending_up,
                    delivery.efficiency >= 100
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ),

          // Delivery notes (if any)
          if (delivery.deliveryNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6941C6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6941C6).withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: Color(0xFF6941C6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      delivery.deliveryNotes,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(DeliveryHistoryItem delivery) {
    Color color;
    IconData icon;
    String label;

    if (delivery.efficiency >= 120) {
      color = const Color(0xFF4CAF50);
      icon = Icons.star;
      label = 'Excellent';
    } else if (delivery.efficiency >= 100) {
      color = const Color(0xFF4CAF50);
      icon = Icons.check_circle;
      label = 'On Time';
    } else if (delivery.efficiency >= 80) {
      color = const Color(0xFFFF9800);
      icon = Icons.access_time;
      label = 'Good';
    } else {
      color = const Color(0xFFFF5722);
      icon = Icons.schedule;
      label = 'Delayed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6941C6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: const Color(0xAAFFFFFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            color: const Color(0xAAFFFFFF),
          ),
        ),
      ],
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'partial':
        return 'Partial';
      case 'debt':
        return 'Account';
      default:
        return method;
    }
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return const Color(0xFF4CAF50);
      case 'partial':
        return const Color(0xFFFF9800);
      case 'debt':
        return const Color(0xFF2196F3);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _historyData == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
        ),
      );
    }

    if (_error != null && _historyData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF304050),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading History',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: const Color(0xAAFFFFFF),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _fetchData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6941C6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredDeliveries = _filteredDeliveries;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF6941C6),
      backgroundColor: const Color(0xFF304050),
      child: CustomScrollView(
        slivers: [
          // Stats cards (now using today stats API)
          SliverToBoxAdapter(
            child: _buildStatsCards(),
          ),

          // Search and filter
          SliverToBoxAdapter(
            child: _buildSearchAndFilter(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),

          // Deliveries header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Recent Deliveries',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (_searchQuery.isNotEmpty || _selectedFilter != 'all')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6941C6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filteredDeliveries.length} results',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: const Color(0xFF6941C6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),

          // Delivery list
          if (filteredDeliveries.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildDeliveryCard(filteredDeliveries[index]);
                },
                childCount: filteredDeliveries.length,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF304050),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.history,
                          size: 64,
                          color: Color(0xFF6941C6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Delivery History',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your completed deliveries will appear here.\nStart completing orders to build your history.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          color: const Color(0xAAFFFFFF),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
