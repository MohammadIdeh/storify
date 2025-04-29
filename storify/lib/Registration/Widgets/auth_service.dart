import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Constants for SharedPreferences keys
  static const String _currentRoleKey = 'currentRole';

  /// Save token with role-specific key
  static Future<void> saveToken(String token, String roleName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = token.trim();

    // Store the token with a role-specific key
    final roleKey = 'authToken_$roleName';
    await prefs.setString(roleKey, raw);

    // Save the current active role
    await prefs.setString(_currentRoleKey, roleName);

    print('🗝️ Saved $roleName token: $raw');
  }

  /// Get current active role
  static Future<String?> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentRoleKey);
  }

  /// Retrieve token for a specific role
  static Future<String?> getTokenForRole(String roleName) async {
    final prefs = await SharedPreferences.getInstance();
    final roleKey = 'authToken_$roleName';
    final token = prefs.getString(roleKey)?.trim();

    if (token == null || token.isEmpty) {
      print('⚠️ No token found for role: $roleName');
      return null;
    }

    print('🔍 Retrieved $roleName token: $token');
    return token;
  }

  /// Get token for the current active role
  static Future<String?> getToken() async {
    final currentRole = await getCurrentRole();
    if (currentRole == null) {
      print('⚠️ No current role set.');
      return null;
    }

    return getTokenForRole(currentRole);
  }

  /// Build headers for the current role or a specific role
  static Future<Map<String, String>> getAuthHeaders({String? role}) async {
    final headers = {'Content-Type': 'application/json'};

    String? token;
    if (role != null) {
      token = await getTokenForRole(role);
    } else {
      token = await getToken();
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Check if user is logged in with any role
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Check if user is logged in with a specific role
  static Future<bool> isLoggedInAsRole(String roleName) async {
    final token = await getTokenForRole(roleName);
    return token != null;
  }

  /// Get all roles the user is logged in as
  static Future<List<String>> getLoggedInRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    List<String> roles = [];
    for (var key in allKeys) {
      if (key.startsWith('authToken_')) {
        roles.add(key.replaceFirst('authToken_', ''));
      }
    }

    return roles;
  }

  /// Switch to a different role (if logged in with that role)
  static Future<bool> switchToRole(String roleName) async {
    if (await isLoggedInAsRole(roleName)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentRoleKey, roleName);
      print('🔄 Switched to role: $roleName');
      return true;
    }
    return false;
  }

  static Future<int?> getSupplierId() async {
    final prefs = await SharedPreferences.getInstance();
    final supplierId = prefs.getInt('supplierId');

    if (supplierId == null) {
      print('⚠️ No supplierId found.');
      return null;
    }

    print('🔍 Retrieved supplierId: $supplierId');
    return supplierId;
  }

  /// Clear supplierId when logging out from Supplier role
  static Future<void> logoutFromRole(String roleName) async {
    final prefs = await SharedPreferences.getInstance();
    final roleKey = 'authToken_$roleName';
    await prefs.remove(roleKey);

    // Clear supplierId if logging out from Supplier role
    if (roleName == 'Supplier') {
      await prefs.remove('supplierId');
      print('📦 Removed supplierId from storage');
    }

    // If this was the current role, clear the current role
    final currentRole = await getCurrentRole();
    if (currentRole == roleName) {
      await prefs.remove(_currentRoleKey);
    }

    print('🚪 Logged out from role: $roleName');
  }

  static Future<void> logoutFromAllRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = await getLoggedInRoles();

    for (var role in roles) {
      final roleKey = 'authToken_$role';
      await prefs.remove(roleKey);
    }

    // Clear supplierId as well
    await prefs.remove('supplierId');
    await prefs.remove(_currentRoleKey);
    print('🚪 Logged out from all roles and cleared supplierId');
  }
}
