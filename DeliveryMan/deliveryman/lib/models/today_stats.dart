// lib/models/today_stats.dart

class TodayStatsResponse {
  final String date;
  final TodayStats todayStats;
  final TodayActivity todayActivity;
  final Performance performance;

  TodayStatsResponse({
    required this.date,
    required this.todayStats,
    required this.todayActivity,
    required this.performance,
  });

  factory TodayStatsResponse.fromJson(Map<String, dynamic> json) {
    return TodayStatsResponse(
      date: json['date'] ?? '',
      todayStats: TodayStats.fromJson(json['todayStats'] ?? {}),
      todayActivity: TodayActivity.fromJson(json['todayActivity'] ?? {}),
      performance: Performance.fromJson(json['performance'] ?? {}),
    );
  }
}

class TodayStats {
  final int totalDeliveries;
  final double totalRevenue;
  final int avgDeliveryTime;
  final double avgRevenuePerDelivery;
  final double totalAmountPaid;

  TodayStats({
    required this.totalDeliveries,
    required this.totalRevenue,
    required this.avgDeliveryTime,
    required this.avgRevenuePerDelivery,
    required this.totalAmountPaid,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      totalDeliveries: (json['totalDeliveries'] ?? 0).toInt(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      avgDeliveryTime: (json['avgDeliveryTime'] ?? 0).toInt(),
      avgRevenuePerDelivery: (json['avgRevenuePerDelivery'] ?? 0).toDouble(),
      totalAmountPaid: (json['totalAmountPaid'] ?? 0).toDouble(),
    );
  }
}

class TodayActivity {
  final int activeOrders;
  final int completedDeliveries;
  final int returnedOrders;
  final int pendingOrders;

  TodayActivity({
    required this.activeOrders,
    required this.completedDeliveries,
    required this.returnedOrders,
    required this.pendingOrders,
  });

  factory TodayActivity.fromJson(Map<String, dynamic> json) {
    return TodayActivity(
      activeOrders: (json['activeOrders'] ?? 0).toInt(),
      completedDeliveries: (json['completedDeliveries'] ?? 0).toInt(),
      returnedOrders: (json['returnedOrders'] ?? 0).toInt(),
      pendingOrders: (json['pendingOrders'] ?? 0).toInt(),
    );
  }
}

class Performance {
  final double completionRate;
  final double returnRate;

  Performance({
    required this.completionRate,
    required this.returnRate,
  });

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      returnRate: (json['returnRate'] ?? 0).toDouble(),
    );
  }
}
