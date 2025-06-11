// lib/services/user_profile_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';

class UserProfileService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  // Get user profile from API
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
      );

      print('Profile API Response Status: ${response.statusCode}');
      print('Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['user'] != null) {
          // Store profile data locally
          await _storeProfileDataLocally(data['user']);
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Store profile data in SharedPreferences
  static Future<void> _storeProfileDataLocally(
      Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name', userData['name'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('phoneNumber', userData['phoneNumber'] ?? '');
    await prefs.setString('profilePicture', userData['profilePicture'] ?? '');
    await prefs.setString('currentRole', userData['roleName'] ?? '');
    await prefs.setString('userId', userData['userId']?.toString() ?? '');
    await prefs.setString('isActive', userData['isActive'] ?? '');
    await prefs.setString(
        'registrationDate', userData['registrationDate'] ?? '');

    print('✅ Profile data stored locally');
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

      print('Change Password Request Body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/user/change-password'),
        headers: headers,
        body: body,
      );

      print('Change Password API Response Status: ${response.statusCode}');
      print('Change Password API Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'Unknown error occurred',
        'data': responseData,
      };
    } catch (e) {
      print('Error changing password: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  // Update profile without image (using JSON)
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

      print('Update Profile Request Body: ${json.encode(body)}');

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
        body: json.encode(body),
      );

      print('Update Profile API Response Status: ${response.statusCode}');
      print('Update Profile API Response Body: ${response.body}');

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
      print('Error updating profile: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  // Upload profile picture using multipart form data
  static Future<Map<String, dynamic>> uploadProfilePicture(
      Uint8List imageBytes, String fileName) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      // Remove Content-Type from headers since it will be set automatically for multipart
      final multipartHeaders = Map<String, String>.from(headers);
      multipartHeaders.remove('Content-Type');

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile'),
      );

      // Add headers (except Content-Type)
      request.headers.addAll(multipartHeaders);

      // Add the image file
      var multipartFile = http.MultipartFile.fromBytes(
        'profilePicture', // This should match your API's expected field name
        imageBytes,
        filename: fileName,
      );

      request.files.add(multipartFile);

      print(
          'Upload Profile Picture Request - File: $fileName, Size: ${imageBytes.length} bytes');
      print('Request headers: ${request.headers}');

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(
          'Upload Profile Picture API Response Status: ${response.statusCode}');
      print('Upload Profile Picture API Response Body: ${response.body}');

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
      print('Error uploading profile picture: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  // Remove profile picture by sending empty value
  static Future<Map<String, dynamic>> removeProfilePicture() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      // Create multipart request for consistency
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile'),
      );

      // Remove Content-Type from headers
      final multipartHeaders = Map<String, String>.from(headers);
      multipartHeaders.remove('Content-Type');
      request.headers.addAll(multipartHeaders);

      // Add empty field to remove the profile picture
      request.fields['profilePicture'] = '';

      print('Remove Profile Picture Request');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(
          'Remove Profile Picture API Response Status: ${response.statusCode}');
      print('Remove Profile Picture API Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['user'] != null) {
        // Update local storage with the updated profile data
        await _storeProfileDataLocally(responseData['user']);
      }

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message':
            responseData['message'] ?? 'Profile picture removed successfully',
        'data': responseData,
      };
    } catch (e) {
      print('Error removing profile picture: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  // Update profile with image using multipart form data
  static Future<Map<String, dynamic>> updateProfileWithImage({
    String? name,
    String? email,
    String? phoneNumber,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      // Remove Content-Type from headers since it will be set automatically for multipart
      final multipartHeaders = Map<String, String>.from(headers);
      multipartHeaders.remove('Content-Type');

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile'),
      );

      // Add headers (except Content-Type)
      request.headers.addAll(multipartHeaders);

      // Add text fields
      if (name != null) request.fields['name'] = name;
      if (email != null) request.fields['email'] = email;
      if (phoneNumber != null) request.fields['phoneNumber'] = phoneNumber;

      // Add the image file if provided
      if (imageBytes != null && fileName != null) {
        var multipartFile = http.MultipartFile.fromBytes(
          'profilePicture',
          imageBytes,
          filename: fileName,
        );
        request.files.add(multipartFile);
      }

      print('Update Profile with Image Request');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.map((f) => f.filename).toList()}');

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(
          'Update Profile with Image API Response Status: ${response.statusCode}');
      print('Update Profile with Image API Response Body: ${response.body}');

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
      print('Error updating profile with image: $e');
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

  // Check image file size (in bytes)
  static bool isValidImageSize(Uint8List imageBytes, {int maxSizeInMB = 5}) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024; // Convert MB to bytes
    return imageBytes.length <= maxSizeInBytes;
  }

  // Get locally stored profile data
  static Future<Map<String, String>> getLocalProfileData() async {
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

  // Load fresh profile data and update local storage
  static Future<bool> refreshProfile() async {
    final profileData = await getUserProfile();
    return profileData != null;
  }

  // Helper method to get MIME type from file extension
  static String _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default to jpeg
    }
  }
}
