// lib/customer/services/location_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/customer/widgets/mapPopUp.dart';

class LocationController {
  static const String _baseUrl =
      'https://finalproject-a5ls.onrender.com/customer-details';

  // Simple method to check if location popup should be shown
  static Future<void> checkAndShowLocationPopup(BuildContext context) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('Token is null, skipping location check');
        return;
      }

      // Use a flag to force showing the popup (for testing)
      final bool forcePopup = false;

      if (forcePopup) {
        _showLocationPopup(context);
        return;
      }

      // Real check
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool locationIsSet = _hasLocationData(data);

        if (!locationIsSet) {
          print('Location is not set, showing popup');
          _showLocationPopup(context);
        } else {
          print('Location is already set, not showing popup');
        }
      } else {
        print('API call failed, not showing popup');
      }
    } catch (e) {
      print('Error in location check: $e');
    }
  }

  // Helper method to deep search for location data
  static bool _hasLocationData(dynamic data) {
    // Print the full data for debugging
    print('Checking data: $data');

    // Check for direct location data
    if (data is Map) {
      if (data['latitude'] != null && data['longitude'] != null) {
        print('Found location at top level');
        return true;
      }

      // Check for nested values
      if (data.containsKey('Customer')) {
        final customer = data['Customer'];
        if (customer is Map &&
            customer['latitude'] != null &&
            customer['longitude'] != null) {
          print('Found location in customer field');
          return true;
        }
      }

      // Check all fields recursively
      for (final key in data.keys) {
        if (data[key] is Map) {
          final bool hasLocation = _hasLocationData(data[key]);
          if (hasLocation) return true;
        }
      }
    }

    print('No location data found');
    return false;
  }

  // Save location to API
  static Future<bool> saveLocation(LatLng location) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': location.latitude,
          'longitude': location.longitude,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving location: $e');
      return false;
    }
  }

  // Show location popup
  static void _showLocationPopup(BuildContext context) {
    // Add a small delay to ensure the main UI is built
    Future.delayed(Duration(milliseconds: 300), () {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => LocationSelectionPopup(
            onLocationSaved: () {
              // No need to do anything on save - API call is handled in the popup
            },
          ),
        );
      }
    });
  }
}
