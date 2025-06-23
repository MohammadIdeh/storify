// lib/services/user_profile_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
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

  // MAIN UPLOAD METHOD WITH FULL DEBUGGING
  static Future<Map<String, dynamic>> uploadProfilePicture(
      Uint8List imageBytes, String fileName) async {
    print('🌐 === HTTP REQUEST DEBUG START ===');

    try {
      final headers = await AuthService.getAuthHeaders();
      print('🔑 Auth headers available: ${headers.keys.toList()}');
      print(
          '🔑 Authorization present: ${headers.containsKey('Authorization')}');

      // Log token for debugging (first/last 10 chars only for security)
      if (headers['Authorization'] != null) {
        final token = headers['Authorization']!;
        final tokenPreview = token.length > 20
            ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
            : token;
        print('🔑 Token preview: $tokenPreview');
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile'),
      );

      // Add authorization header
      if (headers['Authorization'] != null) {
        request.headers['Authorization'] = headers['Authorization']!;
        print('✅ Authorization header added to request');
      }

      // Add other headers except Content-Type (will be set automatically for multipart)
      headers.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers[key] = value;
        }
      });

      // Create the multipart file with proper content type
      var multipartFile = http.MultipartFile.fromBytes(
        'profilePicture', // Make sure this matches your backend field name
        imageBytes,
        filename: fileName,
        contentType: _getMediaType(fileName),
      );

      request.files.add(multipartFile);

      print('📤 === REQUEST DETAILS ===');
      print('   URL: ${request.url}');
      print('   Method: ${request.method}');
      print('   Headers: ${request.headers}');
      print('   File field name: ${multipartFile.field}');
      print('   File name: ${multipartFile.filename}');
      print('   File size: ${multipartFile.length} bytes');
      print('   File content type: ${multipartFile.contentType}');
      print('   Expected backend field: profilePicture');

      print('⏳ Sending multipart request...');

      // Send the request with timeout
      var streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout after 30 seconds');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      print('📥 === RESPONSE DETAILS ===');
      print('   Status Code: ${response.statusCode}');
      print('   Response Headers: ${response.headers}');
      print('   Response Body: ${response.body}');
      print('   Response Length: ${response.body.length} characters');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
        print('✅ Response successfully parsed as JSON');
        print('📋 Parsed response keys: ${responseData.keys.toList()}');
      } catch (e) {
        print('❌ Failed to parse response as JSON: $e');
        print('📄 Raw response body: ${response.body}');
        responseData = {
          'message':
              response.body.isNotEmpty ? response.body : 'Empty response',
          'rawResponse': response.body,
        };
      }

      bool isSuccess = response.statusCode == 200 || response.statusCode == 201;
      print('🎯 Upload Success Status: $isSuccess');

      // Handle successful response
      if (isSuccess) {
        print('🎉 Upload reported as successful by server');

        if (responseData['user'] != null) {
          print('👤 User data found in response');
          print(
              '🖼️ Profile picture in response: ${responseData['user']['profilePicture']}');

          // Store updated profile data
          await _storeProfileDataLocally(responseData['user']);
          print('💾 Profile data updated in local storage');
        } else {
          print(
              '⚠️ No user data in successful response - this might be the issue!');
          print('📋 Available response keys: ${responseData.keys.toList()}');
        }
      } else {
        print('❌ Upload failed according to server');
        print('📋 Error details: ${responseData}');
      }

      print('🌐 === HTTP REQUEST DEBUG END ===');

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
      print('💥 === UPLOAD EXCEPTION ===');
      print('   Error Type: ${e.runtimeType}');
      print('   Error Message: $e');
      print('   Stack Trace: $stackTrace');

      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error: $e',
        'data': null,
        'error': e.toString(),
      };
    }
  }

  // TEST UPLOAD METHOD - Upload a simple test image
  static Future<Map<String, dynamic>> testUpload() async {
    print('🧪 === STARTING TEST UPLOAD ===');

    // Create a minimal 1x1 pixel PNG
    final testImageBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    final testImageBytes = base64Decode(testImageBase64);
    final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.png';

    print('🧪 Test image details:');
    print('   Size: ${testImageBytes.length} bytes');
    print('   Name: $testFileName');
    print('   Type: PNG');

    final result = await uploadProfilePicture(testImageBytes, testFileName);

    print('🧪 === TEST UPLOAD RESULT ===');
    print('   Success: ${result['success']}');
    print('   Status: ${result['statusCode']}');
    print('   Message: ${result['message']}');
    print('   Has User Data: ${result['hasUserData']}');
    print('   New Profile URL: ${result['profilePictureUrl']}');

    return result;
  }

  // Remove profile picture
  static Future<Map<String, dynamic>> removeProfilePicture() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      // Try different approaches for removing profile picture

      // Approach 1: Try dedicated DELETE endpoint
      print('🗑️ Trying DELETE endpoint first...');
      try {
        final deleteResponse = await http.delete(
          Uri.parse('$baseUrl/user/profile/picture'),
          headers: headers,
        );

        if (deleteResponse.statusCode != 404 &&
            deleteResponse.statusCode != 405) {
          print('✅ DELETE endpoint exists, processing response...');
          final responseData = json.decode(deleteResponse.body);
          bool isSuccess = deleteResponse.statusCode == 200 ||
              deleteResponse.statusCode == 204;

          if (isSuccess && responseData['user'] != null) {
            await _storeProfileDataLocally(responseData['user']);
          }

          return {
            'success': isSuccess,
            'statusCode': deleteResponse.statusCode,
            'message': responseData['message'] ?? 'Profile picture removed',
            'data': responseData,
          };
        }
      } catch (e) {
        print('⚠️ DELETE endpoint not available or failed: $e');
      }

      // Approach 2: Use multipart with removal flag
      print('🗑️ Using multipart with removal flag...');
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile'),
      );

      // Add headers
      if (headers['Authorization'] != null) {
        request.headers['Authorization'] = headers['Authorization']!;
      }
      headers.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers[key] = value;
        }
      });

      // Try multiple approaches for removal
      request.fields['removeProfilePicture'] = 'true';
      request.fields['profilePicture'] = ''; // Empty string

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Remove Profile Picture Response Status: ${response.statusCode}');
      print('Remove Profile Picture Response Body: ${response.body}');

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        responseData = {'message': response.body};
      }

      bool isSuccess = response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess && responseData['user'] != null) {
        await _storeProfileDataLocally(responseData['user']);
      }

      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'message': responseData['message'] ??
            (isSuccess ? 'Profile picture removed' : 'Failed to remove'),
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

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile'),
      );

      // Add headers
      if (headers['Authorization'] != null) {
        request.headers['Authorization'] = headers['Authorization']!;
      }
      headers.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers[key] = value;
        }
      });

      // Add text fields
      if (name != null && name.isNotEmpty) request.fields['name'] = name;
      if (email != null && email.isNotEmpty) request.fields['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        request.fields['phoneNumber'] = phoneNumber;
      }

      // Add image file if provided
      if (imageBytes != null && fileName != null) {
        var multipartFile = http.MultipartFile.fromBytes(
          'profilePicture',
          imageBytes,
          filename: fileName,
          contentType: _getMediaType(fileName),
        );
        request.files.add(multipartFile);
      }

      print('Combined Update Request:');
      print('   Fields: ${request.fields}');
      print(
          '   Files: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Combined Update Response Status: ${response.statusCode}');
      print('Combined Update Response Body: ${response.body}');

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        responseData = {'message': response.body};
      }

      bool isSuccess = response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess && responseData['user'] != null) {
        await _storeProfileDataLocally(responseData['user']);
      }

      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'message': responseData['message'] ??
            (isSuccess ? 'Profile updated successfully' : 'Update failed'),
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
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
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

  // Helper method to get proper MediaType for multipart files
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

  // Debug method to check current authentication status
  static Future<Map<String, dynamic>> debugAuthStatus() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      print('🔍 === AUTH DEBUG ===');
      print('   Available headers: ${headers.keys.toList()}');
      print('   Has Authorization: ${headers.containsKey('Authorization')}');

      if (headers['Authorization'] != null) {
        final token = headers['Authorization']!;
        print('   Token length: ${token.length}');
        print(
            '   Token starts with: ${token.substring(0, min(20, token.length))}...');
      }

      // Test a simple GET request
      final testResponse = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
      );

      print('   Test GET status: ${testResponse.statusCode}');
      print(
          '   Test GET response: ${testResponse.body.substring(0, min(100, testResponse.body.length))}...');

      return {
        'hasAuth': headers.containsKey('Authorization'),
        'testStatus': testResponse.statusCode,
        'testSuccess': testResponse.statusCode == 200,
      };
    } catch (e) {
      print('❌ Auth debug error: $e');
      return {
        'hasAuth': false,
        'testStatus': 0,
        'testSuccess': false,
        'error': e.toString(),
      };
    }
  }
}

// Helper function for min
int min(int a, int b) => a < b ? a : b;
