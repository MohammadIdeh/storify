import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/location.dart';

class LocationService with ChangeNotifier {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;
  bool _isTracking = false;
  bool _isPeriodicUpdatesActive = false;
  String? _token;
  int? _activeOrderId;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  bool get isPeriodicUpdatesActive => _isPeriodicUpdatesActive;

  void updateToken(String? token) {
    _token = token;
    
    // Start periodic updates when token is available
    if (_token != null && !_isPeriodicUpdatesActive) {
      _startPeriodicLocationUpdates();
    } else if (_token == null) {
      _stopPeriodicLocationUpdates();
    }
  }

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();

      if (!hasPermission) {
        return null;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  // Start periodic location updates every 10 seconds
  void _startPeriodicLocationUpdates() async {
    if (_isPeriodicUpdatesActive || _token == null) return;

    print("🌍 Starting periodic location updates every 10 seconds");
    
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      print("❌ Location permission denied - cannot start periodic updates");
      return;
    }

    _isPeriodicUpdatesActive = true;
    
    // Initial location update
    await _updateCurrentLocationAndSend();
    
    // Start timer for periodic updates
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _updateCurrentLocationAndSend();
    });
  }

  void _stopPeriodicLocationUpdates() {
    if (!_isPeriodicUpdatesActive) return;
    
    print("🛑 Stopping periodic location updates");
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isPeriodicUpdatesActive = false;
  }

  Future<void> _updateCurrentLocationAndSend() async {
    try {
      final position = await getCurrentLocation();
      if (position != null && _token != null) {
        await _sendLocationToServer(position);
      }
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  // Send location to the new general endpoint
  Future<void> _sendLocationToServer(Position position) async {
    if (_token == null) return;

    try {
      final location = DeliveryLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      print("📍 Sending location update: ${position.latitude}, ${position.longitude}");

      final response = await http.put(
        Uri.parse('$baseUrl/delivery/location'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
        body: json.encode(location.toJson()),
      );

      if (response.statusCode == 200) {
        print("✅ Location updated successfully");
      } else {
        print("❌ Failed to update location: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending location to server: $e");
    }
  }

  void startTracking(int orderId) async {
    if (_isTracking) return;

    final hasPermission = await requestPermission();
    if (!hasPermission || _token == null) return;

    print("🚚 Starting delivery tracking for order $orderId");
    _isTracking = true;
    _activeOrderId = orderId;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      _currentPosition = position;
      notifyListeners();

      // Send to both endpoints when actively tracking
      await _sendLocationToServer(position);
 
    });
  }

  void stopTracking() {
    if (_positionStream != null) {
      print("🛑 Stopping delivery tracking");
      _positionStream!.cancel();
      _positionStream = null;
    }
    _isTracking = false;
    _activeOrderId = null;
    notifyListeners();
  }



  // Method to manually force location update (useful for testing)
  Future<void> forceLocationUpdate() async {
    if (_token == null) {
      print("❌ No token available for location update");
      return;
    }
    
    print("🔄 Forcing location update...");
    await _updateCurrentLocationAndSend();
  }

  @override
  void dispose() {
    stopTracking();
    _stopPeriodicLocationUpdates();
    super.dispose();
  }
}