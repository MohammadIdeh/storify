import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class TrackMapSection extends StatefulWidget {
  const TrackMapSection({super.key});

  @override
  State<TrackMapSection> createState() => _TrackMapSectionState();
}

class _TrackMapSectionState extends State<TrackMapSection> {
  late GoogleMapController mapController;
  LatLng? _currentLatLng;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLatLng = loc;
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: loc,
            infoWindow: const InfoWindow(title: 'You Are Here'),
          ),
        );
      });
      // if map already created, animate camera
      if (mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(loc, 14),
        );
      }
    });
  }

  Future<Position> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_currentLatLng != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _currentLatLng ?? const LatLng(31.9000, 35.2000);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 66, 67, 121),
            spreadRadius: 10,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: double.infinity,
          height: 820,
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: initial,
              zoom: 11.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            mapType: MapType.normal,
          ),
        ),
      ),
    );
  }
}
