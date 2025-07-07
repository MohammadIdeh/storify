// lib/customer/widgets/location_popup.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

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
    // Use post frame callback to avoid initState issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _center = _defaultCenter;
      _selectedLocation = _defaultCenter; // Set a default selection
      _updateMarker(_defaultCenter);
    });
  }

  void _updateMarker(LatLng position) {
    if (mounted) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: position,
            draggable: true,
            onDragEnd: (LatLng newPosition) {
              if (mounted) {
                setState(() {
                  _selectedLocation = newPosition;
                  _useCurrentLocation = false;
                });
              }
            },
          ),
        };
      });
    }
  }

  // Get the current location
  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final l10n =
          Localizations.of<AppLocalizations>(context, AppLocalizations)!;
      final isArabic = LocalizationHelper.isArabic(context);

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.locationPopupServicesDisabled,
                style:
                    isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
              ),
            ),
          );
          setState(() {
            _isLoading = false;
            _useCurrentLocation = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.locationPopupPermissionsDenied,
                  style: isArabic
                      ? GoogleFonts.cairo()
                      : GoogleFonts.spaceGrotesk(),
                ),
              ),
            );
            setState(() {
              _isLoading = false;
              _useCurrentLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.locationPopupPermissionsPermanentlyDenied,
                style:
                    isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
              ),
            ),
          );
          setState(() {
            _isLoading = false;
            _useCurrentLocation = false;
          });
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (mounted) {
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
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        final l10n =
            Localizations.of<AppLocalizations>(context, AppLocalizations)!;
        final isArabic = LocalizationHelper.isArabic(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.locationPopupErrorGettingLocation(e.toString()),
              style:
                  isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
          _useCurrentLocation = false;
        });
      }
    }
  }

  // Save the selected location to the API
  Future<void> _saveLocation() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.locationPopupSelectLocationFirst,
            style: isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
          ),
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSavingLocation = true;
      });
    }

    try {
      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.locationPopupAuthError,
                style:
                    isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
              ),
            ),
          );
          setState(() {
            _isSavingLocation = false;
          });
        }
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

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.locationPopupSavedSuccessfully,
                style:
                    isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
              ),
            ),
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
              content: Text(
                l10n.locationPopupErrorSaving(response.statusCode.toString()),
                style:
                    isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final isArabic = LocalizationHelper.isArabic(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.locationPopupErrorSavingLocation(e.toString()),
              style:
                  isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Calculate dialog size - not full screen, but proportional
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final dialogWidth = screenWidth < 600 ? screenWidth * 0.8 : 500.0;
    final dialogHeight = screenHeight < 800 ? screenHeight * 0.7 : 500.0;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          padding: EdgeInsetsDirectional.all(20),
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
                    l10n.locationPopupTitle,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
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
                l10n.locationPopupSubtitle,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey[400],
                      )
                    : GoogleFonts.spaceGrotesk(
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
                            if (mounted) {
                              setState(() {
                                _isMapLoading = false;
                              });
                            }
                          },
                          initialCameraPosition: CameraPosition(
                            target: _center,
                            zoom: 12,
                          ),
                          markers: _markers,
                          onTap: (LatLng position) {
                            if (mounted) {
                              setState(() {
                                _selectedLocation = position;
                                _useCurrentLocation = false;
                              });
                              _updateMarker(position);
                            }
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
                    PositionedDirectional(
                      top: 10,
                      end: 10,
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
                          icon: const Icon(Icons.my_location,
                              color: Colors.white),
                          onPressed: _getCurrentLocation,
                          tooltip: l10n.locationPopupUseCurrentLocationTooltip,
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
                              if (mounted) {
                                setState(() {
                                  _useCurrentLocation = value!;
                                  if (_useCurrentLocation) {
                                    _getCurrentLocation();
                                  }
                                });
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.locationPopupUseCurrentLocation,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.white,
                            )
                          : GoogleFonts.spaceGrotesk(
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
                          l10n.locationPopupSaveButton,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )
                              : GoogleFonts.spaceGrotesk(
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
