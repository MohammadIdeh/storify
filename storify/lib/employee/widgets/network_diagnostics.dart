// lib/employee/widgets/network_diagnostics.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';

class NetworkDiagnosticsWidget extends StatefulWidget {
  const NetworkDiagnosticsWidget({Key? key}) : super(key: key);

  @override
  State<NetworkDiagnosticsWidget> createState() =>
      _NetworkDiagnosticsWidgetState();
}

class _NetworkDiagnosticsWidgetState extends State<NetworkDiagnosticsWidget> {
  Map<String, dynamic> _diagnostics = {};
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _diagnostics = {};
    });

    try {
      // 1. Get public IP
      await _getPublicIP();

      // 2. Check JWT token
      await _checkJWTToken();

      // 3. Test server connectivity
      await _testServerConnectivity();

      // 4. Test API endpoints
      await _testAPIEndpoints();
    } catch (e) {
      debugPrint('Diagnostics error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _getPublicIP() async {
    try {
      final response = await http.get(
        Uri.parse('https://httpbin.org/ip'),
        headers: {'User-Agent': 'StorifyApp/1.0'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _diagnostics['publicIP'] = data['origin'];
          _diagnostics['ipStatus'] = 'Success';
        });
      }
    } catch (e) {
      setState(() {
        _diagnostics['publicIP'] = 'Failed to get IP';
        _diagnostics['ipStatus'] = 'Error: $e';
      });
    }
  }

  Future<void> _checkJWTToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('WareHouseEmployee_token');

      if (token != null && token.isNotEmpty) {
        // Parse JWT payload
        final parts = token.split('.');
        if (parts.length == 3) {
          String payload = parts[1];

          // Add padding if needed
          switch (payload.length % 4) {
            case 2:
              payload += '==';
              break;
            case 3:
              payload += '=';
              break;
          }

          try {
            final decoded = utf8.decode(base64Url.decode(payload));
            final data = json.decode(decoded);

            final exp = data['exp'];
            final expirationTime =
                DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            final now = DateTime.now();

            setState(() {
              _diagnostics['tokenExists'] = true;
              _diagnostics['tokenExpiry'] = expirationTime.toIso8601String();
              _diagnostics['tokenValid'] = expirationTime.isAfter(now);
              _diagnostics['currentTime'] = now.toIso8601String();
              _diagnostics['userRole'] = data['roleName'];
              _diagnostics['userId'] = data['userId'];
            });
          } catch (e) {
            setState(() {
              _diagnostics['tokenExists'] = true;
              _diagnostics['tokenParseError'] = e.toString();
            });
          }
        }
      } else {
        setState(() {
          _diagnostics['tokenExists'] = false;
        });
      }
    } catch (e) {
      setState(() {
        _diagnostics['tokenCheckError'] = e.toString();
      });
    }
  }

  Future<void> _testServerConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('https://finalproject-a5ls.onrender.com'),
        headers: {'User-Agent': 'StorifyApp/1.0'},
      ).timeout(Duration(seconds: 15));

      setState(() {
        _diagnostics['serverConnectivity'] = {
          'status': response.statusCode,
          'accessible': response.statusCode < 500,
          'responseTime': DateTime.now().toIso8601String(),
        };
      });
    } catch (e) {
      setState(() {
        _diagnostics['serverConnectivity'] = {
          'status': 'Error',
          'accessible': false,
          'error': e.toString(),
        };
      });
    }
  }

  Future<void> _testAPIEndpoints() async {
    final endpoints = [
      '/worker/supplier-orders',
      '/worker/customer-orders',
      '/worker/orders-history?page=1&limit=1',
    ];

    for (String endpoint in endpoints) {
      try {
        final headers = await AuthService.getAuthHeaders();
        final response = await http
            .get(
              Uri.parse('https://finalproject-a5ls.onrender.com$endpoint'),
              headers: headers,
            )
            .timeout(Duration(seconds: 15));

        setState(() {
          _diagnostics['endpoint_$endpoint'] = {
            'status': response.statusCode,
            'success': response.statusCode == 200,
            'responseLength': response.body.length,
            'headers': response.headers.toString(),
          };
        });

        // If we get 403, try to extract more info
        if (response.statusCode == 403) {
          try {
            final errorData = jsonDecode(response.body);
            _diagnostics['endpoint_$endpoint']['errorMessage'] =
                errorData['message'] ?? 'No message';
          } catch (e) {
            _diagnostics['endpoint_$endpoint']['rawError'] = response.body;
          }
        }
      } catch (e) {
        setState(() {
          _diagnostics['endpoint_$endpoint'] = {
            'status': 'Error',
            'success': false,
            'error': e.toString(),
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color.fromARGB(255, 47, 71, 82),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.network_check,
                color: Colors.blue,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "Network Diagnostics",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              if (_isRunning)
                SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue, size: 20.sp),
                  onPressed: _runDiagnostics,
                ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_diagnostics.isNotEmpty) ...[
            _buildDiagnosticSection(),
          ] else if (!_isRunning) ...[
            Text(
              "Tap refresh to run diagnostics",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Network Info
        _buildInfoRow(
            "Public IP", _diagnostics['publicIP']?.toString() ?? 'Unknown'),
        _buildInfoRow(
            "IP Check", _diagnostics['ipStatus']?.toString() ?? 'Not checked'),

        SizedBox(height: 8.h),

        // Token Info
        _buildInfoRow("Token Exists",
            _diagnostics['tokenExists']?.toString() ?? 'Unknown'),
        if (_diagnostics['tokenValid'] != null)
          _buildInfoRow("Token Valid", _diagnostics['tokenValid'].toString(),
              color: _diagnostics['tokenValid'] ? Colors.green : Colors.red),
        if (_diagnostics['userRole'] != null)
          _buildInfoRow("User Role", _diagnostics['userRole'].toString()),

        SizedBox(height: 8.h),

        // Server Connectivity
        if (_diagnostics['serverConnectivity'] != null)
          _buildServerConnectivityInfo(),

        SizedBox(height: 8.h),

        // API Endpoints
        Text(
          "API Endpoints:",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 4.h),

        ..._diagnostics.entries
            .where((entry) => entry.key.startsWith('endpoint_'))
            .map((entry) {
          final endpoint = entry.key.replaceFirst('endpoint_', '');
          final info = entry.value;
          final status = info['status'].toString();
          final success = info['success'] ?? false;

          return Container(
            margin: EdgeInsets.only(bottom: 4.h),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: success
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: success
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  endpoint,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  "Status: $status",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.sp,
                    color: Colors.white70,
                  ),
                ),
                if (info['errorMessage'] != null)
                  Text(
                    "Error: ${info['errorMessage']}",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.sp,
                      color: Colors.red.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),

        SizedBox(height: 12.h),

        // Copy diagnostics button
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 105, 65, 198),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              // Copy diagnostics to clipboard
              final diagnosticsText = _diagnostics.entries
                  .map((e) => "${e.key}: ${e.value}")
                  .join('\n');

              // You can add clipboard functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Diagnostics copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Copy Diagnostics',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServerConnectivityInfo() {
    final serverInfo = _diagnostics['serverConnectivity'];
    return _buildInfoRow("Server Status", serverInfo['status'].toString(),
        color: serverInfo['accessible'] ? Colors.green : Colors.red);
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.sp,
              color: Colors.white70,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.sp,
                color: color ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
