// lib/customer/widgets/location_popup.dart - Fixed version

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';

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

  // String for the iframe ID
  late String _mapElementId;

  @override
  void initState() {
    super.initState();
    _center = _defaultCenter;
    _selectedLocation = _defaultCenter; // Set a default selection
    _mapElementId = 'map-${DateTime.now().millisecondsSinceEpoch}';
    _registerMapWidget();
  }

  // Register the HTML element in the web page
  void _registerMapWidget() {
    // Register a factory for the HTML element
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
        _mapElementId, (int viewId) => _createMapElement());
  }

  // Create the map element
  html.Element _createMapElement() {
    final mapDiv = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none';

    // We'll initialize the map after this element is connected to the DOM
    Future.delayed(Duration(milliseconds: 500), () {
      _initializeMap(mapDiv);
    });

    return mapDiv;
  }

  // Initialize the Google Map with the element
// Replace the event listener part in _initializeMap method

// Initialize the Google Map with the element
  void _initializeMap(html.Element mapDiv) {
    try {
      // Create map options with dark style
      final mapOptions = js_util.jsify({
        'center': {'lat': _center.latitude, 'lng': _center.longitude},
        'zoom': 12,
        'fullscreenControl': false,
        'mapTypeControl': false,
        'streetViewControl': false,
        'zoomControl': true,
        'styles': _mapDarkStyle,
      });

      // Create the map
      final map = js_util.callConstructor(
          js_util.getProperty(html.window, 'google').maps.Map,
          [mapDiv, mapOptions]);

      // Create a marker
      final markerOptions = js_util.jsify({
        'position': {'lat': _center.latitude, 'lng': _center.longitude},
        'map': map,
        'draggable': true,
        'title': 'Selected Location',
      });

      final marker = js_util.callConstructor(
          js_util.getProperty(html.window, 'google').maps.Marker,
          [markerOptions]);

      // Get the maps event object for proper event handling
      final mapsEvent = js_util.getProperty(
          js_util.getProperty(html.window, 'google').maps, 'event');

      // Add click listener to map (using the correct method)
      js_util.callMethod(mapsEvent, 'addListener', [
        map,
        'click',
        js_util.allowInterop((event) {
          // Get the latLng object from the event
          final latLng = js_util.getProperty(event, 'latLng');
          // Get lat and lng values
          final lat = js_util.callMethod(latLng, 'lat', []);
          final lng = js_util.callMethod(latLng, 'lng', []);

          setState(() {
            _selectedLocation = LatLng(lat, lng);
            _useCurrentLocation = false;
          });

          // Update marker position
          js_util.callMethod(marker, 'setPosition', [
            js_util.jsify({'lat': lat, 'lng': lng})
          ]);
        })
      ]);

      // Add drag end listener to marker (using the correct method)
      js_util.callMethod(mapsEvent, 'addListener', [
        marker,
        'dragend',
        js_util.allowInterop((_) {
          final position = js_util.callMethod(marker, 'getPosition', []);
          final lat = js_util.callMethod(position, 'lat', []);
          final lng = js_util.callMethod(position, 'lng', []);

          setState(() {
            _selectedLocation = LatLng(lat, lng);
            _useCurrentLocation = false;
          });
        })
      ]);

      setState(() {
        _isMapLoading = false;
      });
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _isMapLoading = false;
      });
    }
  }

  // Get the current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use browser geolocation API
      final geolocation = html.window.navigator.geolocation;

      geolocation.getCurrentPosition().then((position) {
        final latitude = position.coords!.latitude;
        final longitude = position.coords!.longitude;

        setState(() {
          _center = LatLng(latitude!.toDouble(), longitude!.toDouble());
          _selectedLocation = _center;
          _isLoading = false;

          // Need to re-register the map with new coordinates
          _mapElementId = 'map-${DateTime.now().millisecondsSinceEpoch}';
          _registerMapWidget();
        });
      }).catchError((error) {
        print("Browser geolocation error: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please enable location services in your browser and try again')),
        );
        setState(() {
          _isLoading = false;
          _useCurrentLocation = false;
        });
      });
    } catch (e) {
      print("Error getting location: $e");
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
// At the bottom of _saveLocation() method in LocationSelectionPopup
      if (response.statusCode == 200) {
        // Save location to shared preferences for future use
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setDouble('latitude', _selectedLocation!.latitude);
        // await prefs.setDouble('longitude', _selectedLocation!.longitude);
        // await prefs.setBool('locationSet', true); // Key flag!

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
                  // Map container - Using ClipRRect to ensure it stays within bounds
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
                      // Use HtmlElementView with the registered factory
                      child: HtmlElementView(viewType: _mapElementId),
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
  final _mapDarkStyle = [
    {
      "elementType": "geometry",
      "stylers": [
        {"color": "#242f3e"}
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#746855"}
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {"color": "#242f3e"}
      ]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#d59563"}
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {"color": "#38414e"}
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [
        {"color": "#212a37"}
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#9ca5b3"}
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {"color": "#17263c"}
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#515c6d"}
      ]
    }
  ];
}
