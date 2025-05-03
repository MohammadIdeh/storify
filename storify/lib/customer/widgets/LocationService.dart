// lib/customer/services/location_service.dart - Comprehensive version

import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';

class LocationService {
  static const String _baseUrl =
      'https://finalproject-a5ls.onrender.com/customer-details';

  // Get the saved location (for reading only)
  static Future<LatLng?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final double? latitude = prefs.getDouble('latitude');
    final double? longitude = prefs.getDouble('longitude');

    if (latitude != null && longitude != null) {
      return LatLng(latitude, longitude);
    }
    return null;
  }

  // Save location to API
  static Future<bool> saveLocation(LatLng location) async {
    try {
      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication error. Please login again.');
      }

      // Prepare data for API
      final Map<String, dynamic> locationData = {
        'latitude': location.latitude,
        'longitude': location.longitude,
      };

      // Send location to API
      final response = await http.put(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(locationData),
      );

      if (response.statusCode == 200) {
        // Save location to shared preferences for future reference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('latitude', location.latitude);
        await prefs.setDouble('longitude', location.longitude);
        return true;
      } else {
        throw Exception('Failed to save location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving location: $e');
      return false;
    }
  }

  // Comprehensive check for location in the API response
  static Future<bool> isLocationSetInDatabase() async {
    try {
      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        print('Authentication error: No token available');
        return false;
      }

      // Get customer profile
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Location check API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseText = response.body;
        print('Raw API response: $responseText');

        // Try to parse the JSON
        try {
          final data = json.decode(responseText);
          print('Parsed API data: $data');

          // Search for latitude/longitude at different levels of the response
          // because we don't know the exact structure

          // Helper function to deeply search the object
          bool hasLocationData(dynamic obj) {
            if (obj is Map) {
              // Check directly in this object
              final hasLatLng =
                  obj['latitude'] != null && obj['longitude'] != null;
              if (hasLatLng) return true;

              // Check in child objects
              for (var value in obj.values) {
                if (value is Map || value is List) {
                  if (hasLocationData(value)) return true;
                }
              }
            } else if (obj is List) {
              // Check each item in the list
              for (var item in obj) {
                if (hasLocationData(item)) return true;
              }
            }
            return false;
          }

          return hasLocationData(data);
        } catch (e) {
          print('Error parsing API response: $e');
          return false;
        }
      } else {
        print('Error getting profile: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking location in database: $e');
      return false;
    }
  }
}
