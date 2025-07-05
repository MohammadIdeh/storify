// lib/customer/widgets/location_popup.dart - Alternative version using standard GoogleMap widget

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationSelectionPopup extends StatefulWidget {
  final Function? onLocationSaved;

  const LocationSelectionPopup({Key? key, this.onLocationSaved})
      : super(key: key);

  @override
  State<LocationSelectionPopup> createState() => _LocationSelectionPopupState();
}

class _LocationSelectionPopupState extends State<LocationSelectionPopup> {
  bool _useCurrentLocation = false;
  bool _isLoading = false;
  bool _isMapLoading = true;
  bool _isSavingLocation = false;

  // Default center (Ramallah, Palestine)
  final LatLng _defaultCenter = const LatLng(31.9038, 35.2034);
  late LatLng _center;
  LatLng? _selectedLocation;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _center = _defaultCenter;
    _selectedLocation = _defaultCenter; // Set a default selection
    _updateMarker(_defaultCenter);
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          draggable: true,
          onDragEnd: (LatLng newPosition) {
            setState(() {
              _selectedLocation = newPosition;
              _useCurrentLocation = false;
            });
          },
        ),
      };
    });
  }

  // Get the current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        setState(() {
          _isLoading = false;
          _useCurrentLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          setState(() {
            _isLoading = false;
            _useCurrentLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location permissions are permanently denied')),
        );
        setState(() {
          _isLoading = false;
          _useCurrentLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _selectedLocation = _center;
        _isLoading = false;
      });

      // Update map camera and marker
      _updateMarker(_center);
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_center),
        );
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      setState(() {
        _isLoading = false;
        _useCurrentLocation = false;
      });
    }
  }

  // Save the selected location to the API
  Future<void> _saveLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    setState(() {
      _isSavingLocation = true;
    });

    try {
      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error. Please login again.')),
        );
        setState(() {
          _isSavingLocation = false;
        });
        return;
      }

      // Prepare data for API
      final Map<String, dynamic> locationData = {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      };

      // Send location to API
      final response = await http.put(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/customer-details/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(locationData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location saved successfully')),
        );

        // Call the callback if provided
        if (widget.onLocationSaved != null) {
          widget.onLocationSaved!();
        }

        // Close the popup
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving location: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: $e')),
      );
    } finally {
      setState(() {
        _isSavingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dialog size - not full screen, but proportional
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final dialogWidth = screenWidth < 600 ? screenWidth * 0.8 : 500.0;
    final dialogHeight = screenHeight < 800 ? screenHeight * 0.7 : 500.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 29, 41, 57),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Set Your Location",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              "Select your location on the map or use your current location",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
                  // Map container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFF283548),
                          width: 1,
                        ),
                      ),
                      child: GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          setState(() {
                            _isMapLoading = false;
                          });
                        },
                        initialCameraPosition: CameraPosition(
                          target: _center,
                          zoom: 12,
                        ),
                        markers: _markers,
                        onTap: (LatLng position) {
                          setState(() {
                            _selectedLocation = position;
                            _useCurrentLocation = false;
                          });
                          _updateMarker(position);
                        },
                        style: _mapDarkStyle,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                      ),
                    ),
                  ),

                  if (_isMapLoading)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: SpinKitRing(
                          color: Color.fromARGB(255, 105, 65, 198),
                          size: 50.0,
                        ),
                      ),
                    ),

                  // Recenter button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 48, 60, 80),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.my_location, color: Colors.white),
                        onPressed: _getCurrentLocation,
                        tooltip: "Use current location",
                        iconSize: 20,
                        constraints:
                            BoxConstraints.tightFor(width: 36, height: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _useCurrentLocation,
                    activeColor: const Color.fromARGB(255, 105, 65, 198),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _useCurrentLocation = value!;
                              if (_useCurrentLocation) {
                                _getCurrentLocation();
                              }
                            });
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Use my current location",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SpinKitThreeBounce(
                    color: Color.fromARGB(255, 105, 65, 198),
                    size: 18.0,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSavingLocation ? null : _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSavingLocation
                    ? const SpinKitThreeBounce(
                        color: Colors.white,
                        size: 20.0,
                      )
                    : Text(
                        "Save Location",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dark mode style for Google Maps
  final String _mapDarkStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  }
]
''';
}
