import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_models.dart';

class DashboardService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  // Get authentication headers using your existing AuthService
  static Future<Map<String, String>> _getHeaders() async {
    // Use the existing AuthService to get headers for Admin role
    return await AuthService.getAuthHeaders(role: 'Admin');
  }

  static Future<DashboardCardsResponse> getDashboardCards() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/cards'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DashboardCardsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception(
            'Unauthorized: Please ensure you are logged in as Admin');
      } else {
        throw Exception(
            'Failed to load dashboard cards: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard cards: $e');
    }
  }

  static Future<TopCustomersResponse> getTopCustomers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/top-customers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TopCustomersResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception(
            'Unauthorized: Please ensure you are logged in as Admin');
      } else {
        throw Exception(
            'Failed to load top customers: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching top customers: $e');
    }
  }

  static Future<OrdersOverviewResponse> getOrdersOverview(
      {String period = 'weekly'}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/orders-overview?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return OrdersOverviewResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception(
            'Unauthorized: Please ensure you are logged in as Admin');
      } else {
        throw Exception(
            'Failed to load orders overview: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching orders overview: $e');
    }
  }

  static Future<TopProductsResponse> getTopProducts(
      {int page = 1, int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/top-products?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TopProductsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception(
            'Unauthorized: Please ensure you are logged in as Admin');
      } else {
        throw Exception(
            'Failed to load top products: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching top products: $e');
    }
  }

  static Future<OrderCountResponse> getOrderCounts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/order-counts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return OrderCountResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception(
            'Unauthorized: Please ensure you are logged in as Admin');
      } else {
        throw Exception(
            'Failed to load order counts: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching order counts: $e');
    }
  }

  // Helper method to check if admin is logged in
  static Future<bool> isAdminLoggedIn() async {
    return await AuthService.isLoggedInAsRole('Admin');
  }

  // Helper method to get current admin token for debugging
  static Future<String?> getCurrentAdminToken() async {
    return await AuthService.getTokenForRole('Admin');
  }

  // Add this method to your existing DashboardService class in dashboard_service.dart

  static Future<OrdersChartResponse> getOrdersChart({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();

      // Build URL with optional query parameters
      String url = '$baseUrl/dashboard/orders-chart';
      List<String> queryParams = [];

      if (startDate != null) {
        queryParams.add('startDate=$startDate');
      }
      if (endDate != null) {
        queryParams.add('endDate=$endDate');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return OrdersChartResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception(
            'Unauthorized: Please ensure you are logged in as Admin');
      } else {
        throw Exception(
            'Failed to load orders chart: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching orders chart: $e');
    }
  } // Add this method to your DashboardService class in dashboard_service.dart:

  static Future<ProfitChartResponse> getProfitChart({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();

      // Build URL with optional query parameters
      String url = '$baseUrl/dashboard/profit-chart';
      List<String> queryParams = [];

      if (startDate != null) {
        queryParams.add('startDate=$startDate');
      }
      if (endDate != null) {
        queryParams.add('endDate=$endDate');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ProfitChartResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception(
            'Unauthorized: Please ensure you are logged in as Admin');
      } else {
        throw Exception(
            'Failed to load profit chart: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching profit chart: $e');
    }
  }
}
