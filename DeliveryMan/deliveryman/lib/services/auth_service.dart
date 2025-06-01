import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delivery_person.dart';

class AuthService with ChangeNotifier {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';
  DeliveryPerson? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _lastError;
  bool _isInitialized = false;

  DeliveryPerson? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _currentUser != null;
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token');
      final userJson = prefs.getString('user');

      if (savedToken != null && userJson != null) {
        try {
          final userData = json.decode(userJson);
          _currentUser = DeliveryPerson.fromJson(userData);
          _token = savedToken;
          print('Successfully restored user session');
        } catch (e) {
          print('Error parsing saved user data: $e');
          // Clear corrupted data
          await _clearStoredData();
        }
      }
    } catch (e) {
      print('Error during initialization: $e');
      await _clearStoredData();
    }

    _isInitialized = true;
    // Only notify listeners after initialization is complete
    notifyListeners();
  }

  Future<void> _clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing stored data: $e');
    }
    _token = null;
    _currentUser = null;
    _lastError = null;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      print('Attempting login for: $email');
      print('Login URL: $baseUrl/auth/login');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      _isLoading = false;

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Validate response structure
        if (responseData['user'] == null) {
          _lastError = 'Invalid response from server - missing user data';
          notifyListeners();
          return false;
        }

        if (responseData['token'] == null) {
          _lastError = 'Invalid response from server - missing token';
          notifyListeners();
          return false;
        }

        final userData = responseData['user'];
        final roleName = userData['roleName'];
        print('User role: $roleName');

        // Ensure the user is a delivery person
        if (roleName != 'DeliveryEmployee') {
          _lastError =
              'Access denied. This app is only for delivery employees.';
          notifyListeners();
          return false;
        }

        // Validate user data structure before parsing
        final requiredFields = ['userId', 'email', 'roleName', 'name'];
        for (String field in requiredFields) {
          if (userData[field] == null) {
            _lastError = 'Invalid user data - missing $field';
            print('Missing required field: $field');
            print('User data: $userData');
            notifyListeners();
            return false;
          }
        }

        // Additional validation for specific field types
        if (userData['userId'] is! int) {
          _lastError = 'Invalid user data - userId must be an integer';
          print('Invalid userId type: ${userData['userId'].runtimeType}');
          notifyListeners();
          return false;
        }

        _token = responseData['token'];

        try {
          // Create user object with validated data
          _currentUser = DeliveryPerson.fromJson(userData);
          print('Successfully created DeliveryPerson object');
          print('User ID: ${_currentUser!.userId}');
          print('User email: ${_currentUser!.email}');
          print('User name: ${_currentUser!.name}');
        } catch (e, stackTrace) {
          print('Error creating DeliveryPerson object: $e');
          print('Stack trace: $stackTrace');
          print('User data that caused error: $userData');
          _lastError = 'Error processing user data: ${e.toString()}';
          notifyListeners();
          return false;
        }

        // Save to shared preferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('user', json.encode(userData));
          await prefs.setString('roleName', roleName);
          print('Successfully saved user data to SharedPreferences');
        } catch (e) {
          print('Error saving to SharedPreferences: $e');
          // Continue anyway since login was successful
        }

        print('Login successful for user: ${_currentUser?.email}');
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _lastError = 'Invalid email or password';
        notifyListeners();
        return false;
      } else if (response.statusCode == 403) {
        _lastError = 'Account access denied';
        notifyListeners();
        return false;
      } else {
        _lastError = 'Server error (${response.statusCode}). Please try again.';
        print('Login failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        notifyListeners();
        return false;
      }
    } catch (error, stackTrace) {
      _isLoading = false;
      print('Login error: $error');
      print('Stack trace: $stackTrace');

      if (error.toString().contains('SocketException') ||
          error.toString().contains('TimeoutException')) {
        _lastError =
            'Network error. Please check your connection and try again.';
      } else if (error.toString().contains('FormatException')) {
        _lastError = 'Invalid response format from server.';
      } else {
        _lastError = 'An unexpected error occurred: ${error.toString()}';
      }

      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _lastError = null;

    await _clearStoredData();

    print('User logged out');
    notifyListeners();
  }
}
