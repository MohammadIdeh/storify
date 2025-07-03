// lib/services/user_profile_service.dart
// Fixed version with role-specific profile data storage
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';

class UserProfileService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  // Get user profile from API for current role
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final currentRole = await AuthService.getCurrentRole();
      if (currentRole == null) {
        debugPrint('❌ No current role found');
        return null;
      }

      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
      );

      debugPrint('Profile API Response Status: ${response.statusCode}');
      debugPrint('Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['user'] != null) {
          // Store profile data locally with role-specific keys
          await _storeRoleSpecificProfileData(data['user'], currentRole);
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // Get role-specific profile data
  static Future<Map<String, dynamic>?> getRoleSpecificProfile(
      String role) async {
    try {
      // First try to get fresh data from API
      if (await AuthService.isLoggedInAsRole(role)) {
        final currentRole = await AuthService.getCurrentRole();
        if (currentRole == role) {
          final freshData = await getUserProfile();
          if (freshData != null) return freshData;
        }
      }

      // Fallback to local data
      final localData = await _getRoleSpecificLocalData(role);
      return localData.isNotEmpty ? localData : null;
    } catch (e) {
      debugPrint('Error getting role-specific profile: $e');
      return null;
    }
  }

  // Store profile data with role-specific keys
  static Future<void> _storeRoleSpecificProfileData(
      Map<String, dynamic> userData, String role) async {
    final prefs = await SharedPreferences.getInstance();

    // Store with role-specific keys
    await prefs.setString('${role}_name', userData['name'] ?? '');
    await prefs.setString('${role}_email', userData['email'] ?? '');
    await prefs.setString('${role}_phoneNumber', userData['phoneNumber'] ?? '');
    await prefs.setString(
        '${role}_profilePicture', userData['profilePicture'] ?? '');
    await prefs.setString(
        '${role}_userId', userData['userId']?.toString() ?? '');
    await prefs.setString('${role}_isActive', userData['isActive'] ?? '');
    await prefs.setString(
        '${role}_registrationDate', userData['registrationDate'] ?? '');

    // Also store generic keys for backward compatibility
    await prefs.setString('name', userData['name'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('phoneNumber', userData['phoneNumber'] ?? '');
    await prefs.setString('profilePicture', userData['profilePicture'] ?? '');
    await prefs.setString('currentRole', role);
    await prefs.setString('userId', userData['userId']?.toString() ?? '');

    debugPrint('✅ Role-specific profile data stored for $role');
  }

  // Get role-specific local data
  static Future<Map<String, dynamic>> _getRoleSpecificLocalData(
      String role) async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'name': prefs.getString('${role}_name') ?? '',
      'email': prefs.getString('${role}_email') ?? '',
      'phoneNumber': prefs.getString('${role}_phoneNumber') ?? '',
      'profilePicture': prefs.getString('${role}_profilePicture') ?? '',
      'userId': prefs.getString('${role}_userId') ?? '',
      'isActive': prefs.getString('${role}_isActive') ?? '',
      'registrationDate': prefs.getString('${role}_registrationDate') ?? '',
      'roleName': role,
    };
  }

  // Store profile data locally (legacy method for compatibility)
  static Future<void> _storeProfileDataLocally(
      Map<String, dynamic> userData) async {
    final currentRole = await AuthService.getCurrentRole();
    if (currentRole != null) {
      await _storeRoleSpecificProfileData(userData, currentRole);
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final body = json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });

      debugPrint('Change Password Request Body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/user/change-password'),
        headers: headers,
        body: body,
      );

      debugPrint('Change Password API Response Status: ${response.statusCode}');
      debugPrint('Change Password API Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'Unknown error occurred',
        'data': responseData,
      };
    } catch (e) {
      debugPrint('Error changing password: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  // Update profile without image
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

      debugPrint('Update Profile Request Body: ${json.encode(body)}');

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
        body: json.encode(body),
      );

      debugPrint('Update Profile API Response Status: ${response.statusCode}');
      debugPrint('Update Profile API Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['user'] != null) {
        // Update local storage with the updated profile data
        await _storeProfileDataLocally(responseData['user']);
      }

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'Unknown error occurred',
        'data': responseData,
      };
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  // Upload profile picture (role-specific)
  static Future<Map<String, dynamic>> uploadProfilePicture(
      Uint8List imageBytes, String fileName) async {
    debugPrint('🌐 === ROLE-SPECIFIC IMAGE UPLOAD START ===');

    try {
      final currentRole = await AuthService.getCurrentRole();
      if (currentRole == null) {
        return {
          'success': false,
          'message': 'No current role found',
        };
      }

      debugPrint('📋 Uploading for role: $currentRole');

      final headers = await AuthService.getAuthHeaders();
      debugPrint('🔑 Auth headers available: ${headers.keys.toList()}');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile'),
      );

      // Add authorization header
      if (headers['Authorization'] != null) {
        request.headers['Authorization'] = headers['Authorization']!;
        debugPrint('✅ Authorization header added to request');
      }

      // Add other headers except Content-Type
      headers.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers[key] = value;
        }
      });

      // Create the multipart file
      var multipartFile = http.MultipartFile.fromBytes(
        'profilePicture',
        imageBytes,
        filename: fileName,
        contentType: _getMediaType(fileName),
      );

      request.files.add(multipartFile);

    

      var streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout after 30 seconds');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

    

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
       
      } catch (e) {
        debugPrint('❌ Failed to parse response as JSON: $e');
        responseData = {
          'message':
              response.body.isNotEmpty ? response.body : 'Empty response',
        };
      }

      bool isSuccess = response.statusCode == 200 || response.statusCode == 201;
      debugPrint('🎯 Upload Success Status: $isSuccess');

      if (isSuccess) {
        debugPrint('🎉 Upload successful for role: $currentRole');

        if (responseData['user'] != null) {
          // Store updated profile data with role-specific keys
          await _storeRoleSpecificProfileData(
              responseData['user'], currentRole);
          debugPrint('💾 Role-specific profile data updated');
        }
      }

      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'message': responseData['message'] ??
            (isSuccess
                ? 'Profile picture updated successfully'
                : 'Upload failed'),
        'data': responseData,
        'hasUserData': responseData['user'] != null,
        'profilePictureUrl': responseData['user']?['profilePicture'],
      };
    } catch (e, stackTrace) {
      debugPrint('💥 === UPLOAD EXCEPTION ===');
      debugPrint('   Error: $e');

      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error: $e',
        'data': null,
        'error': e.toString(),
      };
    }
  }

  // Remove profile picture (role-specific)
  static Future<Map<String, dynamic>> removeProfilePicture() async {
    try {
      final currentRole = await AuthService.getCurrentRole();
      if (currentRole == null) {
        return {
          'success': false,
          'message': 'No current role found',
        };
      }

      final headers = await AuthService.getAuthHeaders();

      // Try DELETE endpoint first
      debugPrint('🗑️ Trying DELETE endpoint for role: $currentRole');
      try {
        final deleteResponse = await http.delete(
          Uri.parse('$baseUrl/user/profile/picture'),
          headers: headers,
        );

        if (deleteResponse.statusCode != 404 &&
            deleteResponse.statusCode != 405) {
          final responseData = json.decode(deleteResponse.body);
          bool isSuccess = deleteResponse.statusCode == 200 ||
              deleteResponse.statusCode == 204;

          if (isSuccess && responseData['user'] != null) {
            await _storeRoleSpecificProfileData(
                responseData['user'], currentRole);
          }

          return {
            'success': isSuccess,
            'statusCode': deleteResponse.statusCode,
            'message': responseData['message'] ?? 'Profile picture removed',
            'data': responseData,
          };
        }
      } catch (e) {
        debugPrint('⚠️ DELETE endpoint not available: $e');
      }

      // Fallback to multipart approach
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile'),
      );

      if (headers['Authorization'] != null) {
        request.headers['Authorization'] = headers['Authorization']!;
      }
      headers.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers[key] = value;
        }
      });

      request.fields['removeProfilePicture'] = 'true';
      request.fields['profilePicture'] = '';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        responseData = {'message': response.body};
      }

      bool isSuccess = response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess && responseData['user'] != null) {
        await _storeRoleSpecificProfileData(responseData['user'], currentRole);
      }

      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'message': responseData['message'] ??
            (isSuccess ? 'Profile picture removed' : 'Failed to remove'),
        'data': responseData,
      };
    } catch (e) {
      debugPrint('Error removing profile picture: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  // Validate image file
  static bool isValidImageFile(String fileName) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = fileName.toLowerCase().split('.').last;
    return allowedExtensions.contains(extension);
  }

  // Check image file size
  static bool isValidImageSize(Uint8List imageBytes, {int maxSizeInMB = 5}) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return imageBytes.length <= maxSizeInBytes;
  }

  // Get locally stored profile data (role-specific)
  static Future<Map<String, String>> getLocalProfileData() async {
    final currentRole = await AuthService.getCurrentRole();
    if (currentRole != null) {
      final roleData = await _getRoleSpecificLocalData(currentRole);
      return roleData.map((key, value) => MapEntry(key, value.toString()));
    }

    // Fallback to generic data
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('name') ?? '',
      'email': prefs.getString('email') ?? '',
      'phoneNumber': prefs.getString('phoneNumber') ?? '',
      'profilePicture': prefs.getString('profilePicture') ?? '',
      'currentRole': prefs.getString('currentRole') ?? '',
      'userId': prefs.getString('userId') ?? '',
      'isActive': prefs.getString('isActive') ?? '',
      'registrationDate': prefs.getString('registrationDate') ?? '',
    };
  }

  // Refresh profile data
  static Future<bool> refreshProfile() async {
    final profileData = await getUserProfile();
    return profileData != null;
  }

  // Helper method to get proper MediaType
  static http_parser.MediaType _getMediaType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return http_parser.MediaType('image', 'jpeg');
      case 'png':
        return http_parser.MediaType('image', 'png');
      case 'gif':
        return http_parser.MediaType('image', 'gif');
      case 'webp':
        return http_parser.MediaType('image', 'webp');
      case 'svg':
        return http_parser.MediaType('image', 'svg+xml');
      default:
        return http_parser.MediaType('image', 'jpeg');
    }
  }

  // Clear role-specific data when switching roles or logging out
  static Future<void> clearRoleData(String role) async {
    final prefs = await SharedPreferences.getInstance();

    final keysToRemove = [
      '${role}_name',
      '${role}_email',
      '${role}_phoneNumber',
      '${role}_profilePicture',
      '${role}_userId',
      '${role}_isActive',
      '${role}_registrationDate',
    ];

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    debugPrint('✅ Cleared data for role: $role');
  }

  // Clear all role data
  static Future<void> clearAllRoleData() async {
    final roles = [
      'Admin',
      'Supplier',
      'Customer',
      'WareHouseEmployee',
      'DeliveryEmployee'
    ];

    for (final role in roles) {
      await clearRoleData(role);
    }

    // Also clear generic data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('phoneNumber');
    await prefs.remove('profilePicture');
    await prefs.remove('userId');
    await prefs.remove('isActive');
    await prefs.remove('registrationDate');

    debugPrint('✅ Cleared all role data');
  }
}

// Helper function
int min(int a, int b) => a < b ? a : b;
