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

  DeliveryPerson? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (_token != null && userJson != null) {
      _currentUser = DeliveryPerson.fromJson(json.decode(userJson));
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final roleName = responseData['user']['roleName'];

        // Ensure the user is a delivery person
        if (roleName != 'DeliveryMan') {
          notifyListeners();
          return false;
        }

        _token = responseData['token'];
        _currentUser = DeliveryPerson.fromJson(responseData['user']);

        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(responseData['user']));
        await prefs.setString('roleName', roleName);

        notifyListeners();
        return true;
      } else {
        notifyListeners();
        return false;
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
