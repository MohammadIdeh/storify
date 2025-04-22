import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// Save raw JWT (no "Bearer ") into SharedPreferences.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = token.trim();
    await prefs.setString('authToken', raw);
    print('🗝️ Saved token: $raw');
  }

  /// Retrieve raw JWT from SharedPreferences.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken')?.trim();
    if (token == null || token.isEmpty) {
      print('⚠️ No token in storage.');
      return null;
    }
    print('🔍 Retrieved token: $token');
    return token;
  }

  /// Build headers for any authenticated API call.
  /// Always returns JSON content type; if a token exists,
  /// includes the Authorization header WITHOUT "Bearer "
static Future<Map<String, String>> getAuthHeaders() async {
  final token = await getToken();
  final headers = {'Content-Type': 'application/json'};
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}

  /// Convenience: check if a token is present (client‑side).
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
