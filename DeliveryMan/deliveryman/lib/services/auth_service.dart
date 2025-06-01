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

  DeliveryPerson? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  String? get lastError => _lastError;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (_token != null && userJson != null) {
      try {
        _currentUser = DeliveryPerson.fromJson(json.decode(userJson));
        notifyListeners();
      } catch (e) {
        print('Error parsing saved user data: $e');
        // Clear corrupted data
        await logout();
      }
    }
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

        if (responseData['user'] == null) {
          _lastError = 'Invalid response from server';
          notifyListeners();
          return false;
        }

        final roleName = responseData['user']['roleName'];
        print('User role: $roleName');

        if (roleName != 'DeliveryEmployee') {
          _lastError =
              'Access denied. This app is only for delivery employees.';
          notifyListeners();
          return false;
        }

        _token = responseData['token'];

        try {
          // Use the corrected DeliveryPerson model
          _currentUser = DeliveryPerson.fromJson(responseData['user']);
        } catch (e) {
          print('Error parsing user data: $e');
          print('User data structure: ${responseData['user']}');
          _lastError = 'Error processing user data: ${e.toString()}';
          notifyListeners();
          return false;
        }

        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(responseData['user']));
        await prefs.setString('roleName', roleName);

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
    } catch (error) {
      _isLoading = false;
      print('Login error: $error');

      if (error.toString().contains('SocketException') ||
          error.toString().contains('TimeoutException')) {
        _lastError =
            'Network error. Please check your connection and try again.';
      } else {
        _lastError = 'An unexpected error occurred. Please try again.';
      }

      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _lastError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    print('User logged out');
    notifyListeners();
  }
}
