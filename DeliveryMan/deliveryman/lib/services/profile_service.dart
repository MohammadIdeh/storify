// lib/services/profile_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) {
        // User cancelled
        return false;
      }

      _isLoading = true;
      _lastError = null;
      notifyListeners();

      print('📤 Starting profile picture upload...');
      print('📄 Image path: ${image.path}');
      print('📏 Image size: ${await image.length()} bytes');

      // Read image as bytes
      final bytes = await image.readAsBytes();
      print('✅ Image read successfully: ${bytes.length} bytes');

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/auth/${_profile!.userId}'),
      );

      // Add headers
      request.headers.addAll({
        'token': _token!,
        'Accept': 'application/json',
      });

      // Create multipart file with proper content type
      var multipartFile = http.MultipartFile.fromBytes(
        'profilePicture', // Make sure this matches your backend field name
        bytes,
        filename:
            'profile_${_profile!.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      print('🌐 Sending request to: $baseUrl/auth/${_profile!.userId}');
      print('📋 Request headers: ${request.headers}');
      print('📎 File field name: profilePicture');
      print('📷 File name: ${multipartFile.filename}');
      print('🏷️ Content type: ${multipartFile.contentType}');

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout after 30 seconds');
        },
      );

      // Convert streamed response to regular response
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Profile picture uploaded successfully');

        // Refresh profile to get updated picture
        final success = await fetchProfile();
        if (success) {
          print('✅ Profile refreshed successfully');
          return true;
        } else {
          _lastError =
              'Profile picture uploaded but failed to refresh profile data';
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = json.decode(response.body);
          _lastError =
              errorData['message'] ?? 'Bad request - invalid image format';
        } catch (e) {
          _lastError = 'Bad request - invalid image format';
        }
        print('❌ Bad request: ${_lastError}');
      } else if (response.statusCode == 401) {
        _lastError = 'Authentication failed. Please login again.';
        print('❌ Unauthorized: ${_lastError}');
      } else if (response.statusCode == 413) {
        _lastError = 'Image file is too large. Please select a smaller image.';
        print('❌ File too large: ${_lastError}');
      } else if (response.statusCode == 500) {
        try {
          final errorData = json.decode(response.body);
          _lastError =
              'Server error: ${errorData['message'] ?? 'Internal server error'}';
        } catch (e) {
          _lastError = 'Server error: Please try again later';
        }
        print('❌ Server error (500): ${response.body}');
      } else {
        _lastError =
            'Failed to update profile picture: HTTP ${response.statusCode}';
        print('❌ HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (error) {
      print('❌ Error updating profile picture: $error');

      if (error is TimeoutException) {
        _lastError = 'Request timeout. Please check your internet connection.';
      } else if (error.toString().contains('SocketException')) {
        _lastError = 'Network error. Please check your internet connection.';
      } else if (error.toString().contains('FormatException')) {
        _lastError = 'Invalid server response. Please try again.';
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
