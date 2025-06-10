class DashboardCard {
  final String title;
  final String value;
  final String growth;
  final bool isPositive;

  DashboardCard({
    required this.title,
    required this.value,
    required this.growth,
    required this.isPositive,
  });

  factory DashboardCard.fromJson(Map<String, dynamic> json) {
    return DashboardCard(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
      growth: json['growth'] ?? '0%',
      isPositive: json['isPositive'] ?? true,
    );
  }
}

class DashboardCardsResponse {
  final List<DashboardCard> cards;

  DashboardCardsResponse({required this.cards});

  factory DashboardCardsResponse.fromJson(Map<String, dynamic> json) {
    return DashboardCardsResponse(
      cards: (json['cards'] as List<dynamic>?)
              ?.map((cardJson) => DashboardCard.fromJson(cardJson))
              .toList() ??
          [],
    );
  }
}

class Customer {
  final int rank;
  final int customerId;
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final double accountBalance;
  final int orderCount;
  final double totalSpent;
  final double avgOrderValue;
  final double orderPercentage;
  final double revenuePercentage;
  final String lastOrderDate;
  final String firstOrderDate;
  final int daysSinceLastOrder;
  final int customerLifetimeDays;
  final String segment;

  Customer({
    required this.rank,
    required this.customerId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.accountBalance,
    required this.orderCount,
    required this.totalSpent,
    required this.avgOrderValue,
    required this.orderPercentage,
    required this.revenuePercentage,
    required this.lastOrderDate,
    required this.firstOrderDate,
    required this.daysSinceLastOrder,
    required this.customerLifetimeDays,
    required this.segment,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      rank: json['rank'] ?? 0,
      customerId: json['customerId'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
      accountBalance: (json['accountBalance'] ?? 0).toDouble(),
      orderCount: json['orderCount'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      avgOrderValue: (json['avgOrderValue'] ?? 0).toDouble(),
      orderPercentage: (json['orderPercentage'] ?? 0).toDouble(),
      revenuePercentage: (json['revenuePercentage'] ?? 0).toDouble(),
      lastOrderDate: json['lastOrderDate'] ?? '',
      firstOrderDate: json['firstOrderDate'] ?? '',
      daysSinceLastOrder: json['daysSinceLastOrder'] ?? 0,
      customerLifetimeDays: json['customerLifetimeDays'] ?? 0,
      segment: json['segment'] ?? '',
    );
  }
}

class CustomersSummary {
  final int totalCustomers;
  final int totalActiveCustomers;
  final int totalOrders;
  final double totalRevenue;
  final double avgOrdersPerCustomer;
  final double avgRevenuePerCustomer;

  CustomersSummary({
    required this.totalCustomers,
    required this.totalActiveCustomers,
    required this.totalOrders,
    required this.totalRevenue,
    required this.avgOrdersPerCustomer,
    required this.avgRevenuePerCustomer,
  });

  factory CustomersSummary.fromJson(Map<String, dynamic> json) {
    return CustomersSummary(
      totalCustomers: json['totalCustomers'] ?? 0,
      totalActiveCustomers: json['totalActiveCustomers'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      avgOrdersPerCustomer: (json['avgOrdersPerCustomer'] ?? 0).toDouble(),
      avgRevenuePerCustomer: (json['avgRevenuePerCustomer'] ?? 0).toDouble(),
    );
  }
}

class TopCustomersResponse {
  final String message;
  final CustomersSummary summary;
  final List<Customer> customers;

  TopCustomersResponse({
    required this.message,
    required this.summary,
    required this.customers,
  });

  factory TopCustomersResponse.fromJson(Map<String, dynamic> json) {
    return TopCustomersResponse(
      message: json['message'] ?? '',
      summary: CustomersSummary.fromJson(json['summary'] ?? {}),
      customers: (json['customers'] as List<dynamic>?)
              ?.map((customerJson) => Customer.fromJson(customerJson))
              .toList() ??
          [],
    );
  }
}

class OrderData {
  final String date;
  final String label;
  final int orderCount;
  final double revenue;
  final double avgOrderValue;
  final double value;

  OrderData({
    required this.date,
    required this.label,
    required this.orderCount,
    required this.revenue,
    required this.avgOrderValue,
    required this.value,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      date: json['date'] ?? '',
      label: json['label'] ?? '',
      orderCount: json['orderCount'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      avgOrderValue: (json['avgOrderValue'] ?? 0).toDouble(),
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class OrdersSummary {
  final Map<String, dynamic> current;
  final Map<String, dynamic> previous;
  final Map<String, dynamic> changes;
  final Map<String, dynamic> peak;
  final Map<String, dynamic> low;

  OrdersSummary({
    required this.current,
    required this.previous,
    required this.changes,
    required this.peak,
    required this.low,
  });

  factory OrdersSummary.fromJson(Map<String, dynamic> json) {
    return OrdersSummary(
      current: json['current'] ?? {},
      previous: json['previous'] ?? {},
      changes: json['changes'] ?? {},
      peak: json['peak'] ?? {},
      low: json['low'] ?? {},
    );
  }
}

class OrdersOverviewResponse {
  final String message;
  final String period;
  final String metric;
  final OrdersSummary summary;
  final List<OrderData> data;
  final List<OrderData> comparison;

  OrdersOverviewResponse({
    required this.message,
    required this.period,
    required this.metric,
    required this.summary,
    required this.data,
    required this.comparison,
  });

  factory OrdersOverviewResponse.fromJson(Map<String, dynamic> json) {
    return OrdersOverviewResponse(
      message: json['message'] ?? '',
      period: json['period'] ?? '',
      metric: json['metric'] ?? '',
      summary: OrdersSummary.fromJson(json['summary'] ?? {}),
      data: (json['data'] as List<dynamic>?)
              ?.map((dataJson) => OrderData.fromJson(dataJson))
              .toList() ??
          [],
      comparison: (json['comparison'] as List<dynamic>?)
              ?.map((dataJson) => OrderData.fromJson(dataJson))
              .toList() ??
          [],
    );
  }
}

class Product {
  final int productId;
  final String name;
  final String vendor;
  final double totalSold;
  final int stock;

  Product({
    required this.productId,
    required this.name,
    required this.vendor,
    required this.totalSold,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] ?? 0,
      name: json['name'] ?? '',
      vendor: json['vendor'] ?? '',
      totalSold: (json['totalSold'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
    );
  }
}

class Pagination {
  final int currentPage;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  Pagination({
    required this.currentPage,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      limit: json['limit'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}

class TopProductsResponse {
  final String message;
  final List<Product> products;
  final Pagination pagination;

  TopProductsResponse({
    required this.message,
    required this.products,
    required this.pagination,
  });

  factory TopProductsResponse.fromJson(Map<String, dynamic> json) {
    return TopProductsResponse(
      message: json['message'] ?? '',
      products: (json['products'] as List<dynamic>?)
              ?.map((productJson) => Product.fromJson(productJson))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class OrderCountData {
  final String day;
  final int count;

  OrderCountData({
    required this.day,
    required this.count,
  });

  factory OrderCountData.fromJson(Map<String, dynamic> json) {
    return OrderCountData(
      day: json['day'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class OrderCountResponse {
  final List<OrderCountData> data;
  final int growth;
  final int total;

  OrderCountResponse({
    required this.data,
    required this.growth,
    required this.total,
  });

  factory OrderCountResponse.fromJson(Map<String, dynamic> json) {
    return OrderCountResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((dataJson) => OrderCountData.fromJson(dataJson))
              .toList() ??
          [],
      growth: json['growth'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}
