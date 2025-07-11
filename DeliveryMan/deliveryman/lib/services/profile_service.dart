// lib/services/profile_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/profile.dart';

class ProfileService with ChangeNotifier {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  DeliveryProfile? _profile;
  bool _isLoading = false;
  String? _lastError;
  String? _token;

  DeliveryProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  void updateToken(String? token) {
    _token = token;
  }

  Future<bool> fetchProfile() async {
    if (_token == null) {
      _lastError = 'No authentication token available';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      print('Fetching profile from: $baseUrl/delivery/profile');

      final response = await http.get(
        Uri.parse('$baseUrl/delivery/profile'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
      );

      print('Profile response status: ${response.statusCode}');
      print('Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final profileResponse = ProfileResponse.fromJson(responseData);

        _profile = profileResponse.profile;
        print('Successfully fetched profile for user: ${_profile!.user.name}');

        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _lastError = 'Authentication failed. Please login again.';
      } else if (response.statusCode == 403) {
        _lastError =
            'Access denied. You do not have permission to view profile.';
      } else {
        _lastError = 'Server error (${response.statusCode}): ${response.body}';
      }
    } catch (error) {
      print('Network error fetching profile: $error');

      if (error.toString().contains('SocketException') ||
          error.toString().contains('TimeoutException')) {
        _lastError =
            'Network error. Please check your connection and try again.';
      } else {
        _lastError = 'An unexpected error occurred: ${error.toString()}';
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfilePicture() async {
    if (_token == null || _profile == null) {
      _lastError = 'No authentication token or profile available';
      notifyListeners();
      return false;
    }

    try {
      // Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        // User cancelled
        return false;
      }

      _isLoading = true;
      _lastError = null;
      notifyListeners();

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/auth/${_profile!.userId}'),
      );

      // Add headers
      request.headers.addAll({
        'token': _token!,
      });

      // Add the image file
      var multipartFile = await http.MultipartFile.fromPath(
        'profilePicture',
        image.path,
      );
      request.files.add(multipartFile);

      print('Uploading profile picture for user: ${_profile!.userId}');

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Profile picture update response: ${response.statusCode}');
      print('Profile picture update body: $responseBody');

      if (response.statusCode == 200) {
        // Refresh profile to get updated picture
        final success = await fetchProfile();
        if (success) {
          print('Profile picture updated successfully');
          return true;
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(responseBody);
        _lastError =
            errorData['message'] ?? 'Bad request - invalid image format';
      } else if (response.statusCode == 401) {
        _lastError = 'Authentication failed. Please login again.';
      } else {
        _lastError =
            'Failed to update profile picture: HTTP ${response.statusCode}';
      }
    } catch (error) {
      print('Error updating profile picture: $error');

      if (error.toString().contains('SocketException')) {
        _lastError = 'Network error. Please check your internet connection.';
      } else {
        _lastError = 'Error updating profile picture: ${error.toString()}';
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    _lastError = null;
    _isLoading = false;
    notifyListeners();
  }
}
