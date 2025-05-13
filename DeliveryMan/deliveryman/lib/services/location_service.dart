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
  bool _isTracking = false;
  String? _token;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  void updateToken(String? token) {
    _token = token;
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

  void startTracking(int orderId) async {
    if (_isTracking) return;

    final hasPermission = await requestPermission();
    if (!hasPermission || _token == null) return;

    _isTracking = true;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      _currentPosition = position;
      notifyListeners();

      // Send location update to server
      await _updateLocationOnServer(position, orderId);
    });
  }

  void stopTracking() {
    if (_positionStream != null) {
      _positionStream!.cancel();
      _positionStream = null;
    }
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _updateLocationOnServer(Position position, int orderId) async {
    if (_token == null) return;

    try {
      final location = DeliveryLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await http.post(
        Uri.parse('$baseUrl/delivery/update-location/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
        body: json.encode(location.toJson()),
      );
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
