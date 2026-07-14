import 'dart:async';
import 'package:canimage/Screens/ExecutionSeePlans/execution_see_plans.dart';
import 'package:canimage/Screens/ExecutionSeePlans/execution_upload_see_plan.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../landing/landing_screen.dart';

class MapScreen extends StatefulWidget {
  String? planCode;
  String? VillageCode;
  String? ServerID;
  var width;
  var height;
  var villageName;
  var brand;
  var tensil;
  var artworkId;
  final String? locateId;
  final Function(String) changeLanguage;

  MapScreen({
    super.key,
    required this.planCode,
    required this.VillageCode,
    required this.ServerID,
    required this.changeLanguage,
    required this.height,
    required this.width,
    required this.villageName,
    required this.brand,
    required this.tensil,
    required this.artworkId,
     this.locateId,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Position? _bestPosition;
  bool _isLocationFetched = false;
  Set<Marker> _markers = Set<Marker>();
  Set<Circle> _circles = Set<Circle>();
  bool _showNextButton = false;
  String currentAddress = "Getting address...";
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isGettingAccurateLocation = false;
  double _currentAccuracy = 0.0;
  int _locationUpdatesCount = 0;
  bool _isManualSelectionMode = false;
  List<Position> _recentPositions = [];
  bool _isUserSelectedLocation = false;

  // Timer for periodic refresh
  Timer? _periodicRefreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    _getCurrentLocationWithHighAccuracy();
    _startNextButtonDelay();
    _startPeriodicLocationRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    _positionStreamSubscription?.cancel();
    _periodicRefreshTimer?.cancel();
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, check if location is now available
      if (!_isLocationFetched && !_isGettingAccurateLocation) {
        _checkAndRetryLocation();
      }
    }
  }

  // Check permission and retry getting location
  Future<void> _checkAndRetryLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Permission is now granted, retry getting location
      // print("Permission granted after resume, retrying location...");
      _getCurrentLocationWithHighAccuracy();
    }
  }

  // Start periodic location refresh every 5 seconds
  void _startPeriodicLocationRefresh() {
    _periodicRefreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isUserSelectedLocation && _isLocationFetched) {
        _refreshCurrentLocation();
      }
    });
  }

  // Refresh current location without camera movement
  Future<void> _refreshCurrentLocation() async {
    try {
      Position newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 4),
      );

      if (_shouldUpdatePosition(newPosition)) {
        _recentPositions.add(newPosition);
        if (_recentPositions.length > 5) {
          _recentPositions.removeAt(0);
        }

        Position smoothedPosition = _calculateWeightedAveragePosition(_recentPositions);

        setState(() {
          _currentPosition = smoothedPosition;
          _bestPosition = smoothedPosition;
          _currentAccuracy = smoothedPosition.accuracy;
          _lastRefreshTime = DateTime.now();
        });

        _updateMarkerAndCircleOnly();
        _getAddressFromLatLng(smoothedPosition.latitude, smoothedPosition.longitude, showToast: false);
      }
    } catch (e) {
      print("Error refreshing location: $e");
    }
  }

  // Update marker and circle WITHOUT camera movement
  void _updateMarkerAndCircleOnly() {
    _markers.clear();
    _circles.clear();

    final marker = Marker(
      markerId: MarkerId('current_location'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      infoWindow: InfoWindow(
        title: S.of(context).currentLocation,
        snippet: S.of(context).tapAddress,
      ),
      onTap: () => _getAddressFromLatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          showToast: true
      ),
    );

    final circle = Circle(
      circleId: CircleId('accuracy_circle'),
      center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      radius: _currentAccuracy > 0 ? _currentAccuracy : 10,
      fillColor: Colors.blue.withOpacity(0.2),
      strokeWidth: 2,
      strokeColor: Colors.blue,
    );

    setState(() {
      _markers.add(marker);
      _circles.add(circle);
    });
  }

  // Check if new position should update current position
  bool _shouldUpdatePosition(Position newPosition) {
    if (_currentPosition == null) return true;

    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    double accuracyImprovement = _currentPosition!.accuracy - newPosition.accuracy;

    return accuracyImprovement >= 2.0 ||
        distance >= 3.0 ||
        (newPosition.accuracy <= _currentPosition!.accuracy + 1.0);
  }

  void _startNextButtonDelay() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showNextButton = true;
        });
      }
    });
  }

  Future<void> _getCurrentLocationWithHighAccuracy() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(
          msg: S.of(context).locationPermissionDenied,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
      return;
    }

    setState(() {
      _isGettingAccurateLocation = true;
    });

    await _tryMultipleLocationMethods();
  }

  Future<void> _tryMultipleLocationMethods() async {
    List<Position> positions = [];

    try {
      try {
        Position bestPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        );
        positions.add(bestPosition);
      } catch (e) {
        print("Best position failed: $e");
      }

      try {
        Position highPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        );
        positions.add(highPosition);
      } catch (e) {
        print("High position failed: $e");
      }

      try {
        Position mediumPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        );
        positions.add(mediumPosition);
      } catch (e) {
        print("Medium position failed: $e");
      }

      if (positions.isNotEmpty) {
        Position smoothedPosition = _calculateWeightedAveragePosition(positions);

        _currentPosition = smoothedPosition;
        _bestPosition = smoothedPosition;
        _currentAccuracy = smoothedPosition.accuracy;
        _recentPositions.add(smoothedPosition);
        _lastRefreshTime = DateTime.now();
       if (!mounted) return;
        setState(() {
          _isLocationFetched = true;
        });

        _addMarker();
        _addCircle();
        _moveCameraToCurrentLocation(animate: false);
        _getAddressFromLatLng(_currentPosition!.latitude, _currentPosition!.longitude);

        _startSmoothLocationUpdates();

      } else {
        throw Exception("All location methods failed");
      }

    } catch (e) {
      // print("Error getting location: $e");
      setState(() {
        _isGettingAccurateLocation = false;
      });
      _showLocationFailureDialog();
    }
  }

  Position _calculateWeightedAveragePosition(List<Position> positions) {
    if (positions.isEmpty) throw Exception("No positions to average");
    if (positions.length == 1) return positions[0];

    double totalWeight = 0;
    double weightedLat = 0;
    double weightedLng = 0;
    double bestAccuracy = double.infinity;

    for (var pos in positions) {
      double weight = 1.0 / (pos.accuracy + 1);
      totalWeight += weight;
      weightedLat += pos.latitude * weight;
      weightedLng += pos.longitude * weight;
      if (pos.accuracy < bestAccuracy) bestAccuracy = pos.accuracy;
    }

    return Position(
      latitude: weightedLat / totalWeight,
      longitude: weightedLng / totalWeight,
      timestamp: DateTime.now(),
      accuracy: bestAccuracy,
      altitude: positions[0].altitude,
      heading: positions[0].heading,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  void _startSmoothLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 45),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _locationUpdatesCount++;

      _recentPositions.add(position);
      if (_recentPositions.length > 5) {
        _recentPositions.removeAt(0);
      }

      Position smoothedPosition = _calculateWeightedAveragePosition(_recentPositions);

      bool shouldUpdate = false;

      if (_bestPosition == null) {
        shouldUpdate = true;
      } else {
        double accuracyImprovement = _bestPosition!.accuracy - smoothedPosition.accuracy;
        double distance = Geolocator.distanceBetween(
          _bestPosition!.latitude,
          _bestPosition!.longitude,
          smoothedPosition.latitude,
          smoothedPosition.longitude,
        );

        if (accuracyImprovement >= 3.0 || distance >= 2.0) {
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        _bestPosition = smoothedPosition;

        if (!_isUserSelectedLocation) {
          _currentPosition = smoothedPosition;
          _currentAccuracy = smoothedPosition.accuracy;
          _lastRefreshTime = DateTime.now();

          if (!mounted) return;
          setState(() {});

          _updateMarkerAndCircleOnly();
          _getAddressFromLatLng(smoothedPosition.latitude, smoothedPosition.longitude, showToast: false);
        }
      }

      if (smoothedPosition.accuracy <= 5.0 || _locationUpdatesCount >= 25) {
        _positionStreamSubscription?.cancel();
        if(!mounted) return;
        setState(() {
          _isGettingAccurateLocation = false;
        });
      }
    }, onError: (error) {
      // print("Location stream error: $error");
      setState(() {
        _isGettingAccurateLocation = false;
      });
    });

    Timer(Duration(seconds: 45), () {
      _positionStreamSubscription?.cancel();
      if (mounted) {
        setState(() {
          _isGettingAccurateLocation = false;
        });
      }
    });
  }

  void _updateMarkerAndCircleSmoothly() {
    _markers.clear();
    _circles.clear();

    final marker = Marker(
      markerId: MarkerId('current_location'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      infoWindow: InfoWindow(
        title: S.of(context).currentLocation,
        snippet: S.of(context).tapAddress,
      ),
      onTap: () => _getAddressFromLatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          showToast: true
      ),
    );

    final circle = Circle(
      circleId: CircleId('accuracy_circle'),
      center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      radius: _currentAccuracy > 0 ? _currentAccuracy : 10,
      fillColor: Colors.blue.withOpacity(0.2),
      strokeWidth: 2,
      strokeColor: Colors.blue,
    );

    setState(() {
      _markers.add(marker);
      _circles.add(circle);
    });

    _moveCameraToCurrentLocation(animate: true);
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).locationServicesDisabled),
          content: Text(S.of(context).pleaseAccurate),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: Text(S.of(context).openSettings),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).locationRequired),
          content: Text(S.of(context).pleaseAppSettings),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: Text(S.of(context).openSettings),
            ),
          ],
        );
      },
    );
  }

  void _showLocationFailureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).locationDetectionFailed),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(context).unableLocation),
              SizedBox(height: 10),
              Text('• ${S.of(context).moveWindows}'),
              Text('• ${S.of(context).enableWiFi}'),
              Text('• ${S.of(context).useManualSelection}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _enableManualLocationSelection();
              },
              child: Text(S.of(context).manualSelection),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _getCurrentLocationWithHighAccuracy();
              },
              child: Text(S.of(context).retry),
            ),
          ],
        );
      },
    );
  }

  void _enableManualLocationSelection() {
    setState(() {
      _isManualSelectionMode = true;
    });

    Fluttertoast.showToast(
      msg: S.of(context).tapLocation,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  void _onMapTapped(LatLng tappedPoint) {
    if (_isManualSelectionMode) {
      setState(() {
        _currentPosition = Position(
          latitude: tappedPoint.latitude,
          longitude: tappedPoint.longitude,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        _bestPosition = _currentPosition;
        _currentAccuracy = 1.0;
        _isManualSelectionMode = false;
        _isLocationFetched = true;
        _isUserSelectedLocation = true;
      });

      _updateMarkerAndCircleSmoothly();
      _getAddressFromLatLng(tappedPoint.latitude, tappedPoint.longitude, showToast: true);

      Fluttertoast.showToast(
        msg: S.of(context).locationResumeGPS,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _addMarker() {
    final marker = Marker(
      markerId: MarkerId('current_location'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      infoWindow: InfoWindow(
        title: S.of(context).currentLocation,
        snippet: S.of(context).tapAddress,
      ),
      onTap: () => _getAddressFromLatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          showToast: true
      ),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _addCircle() {
    final circle = Circle(
      circleId: CircleId('accuracy_indicator'),
      center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      radius: _currentAccuracy > 0 ? _currentAccuracy : 10,
      fillColor: Colors.blue.withOpacity(0.2),
      strokeWidth: 2,
      strokeColor: Colors.blue,
    );

    setState(() {
      _circles.add(circle);
    });
  }

  void _moveCameraToCurrentLocation({bool animate = true}) {
    if (_mapController == null || _currentPosition == null) return;

    if (animate) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0,
          ),
        ),
      );
    } else {
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0,
          ),
        ),
      );
    }
  }

  // Future<void> _getAddressFromLatLng(double latitude, double longitude, {bool showToast = false}) async {
  //   try {
  //     List<Placemark> placemarks = await GeocodingPlatform.instance!.placemarkFromCoordinates(latitude, longitude);
  //     Placemark place = placemarks[0];
  //     String address = "${place.name}, ${place.subLocality}, ${place.locality}, ${place.country}";
  //
  //     setState(() {
  //       currentAddress = address;
  //     });
  //
  //     if (showToast) {
  //       Fluttertoast.showToast(
  //         msg: "${S.of(context).address}: $address",
  //         toastLength: Toast.LENGTH_SHORT,
  //         gravity: ToastGravity.BOTTOM,
  //         backgroundColor: Colors.black87,
  //         textColor: Colors.white,
  //       );
  //     }
  //   } catch (e) {
  //     // print("Error getting address (may be offline): $e");
  //     String fallbackAddress = "Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}";
  //     setState(() {
  //       currentAddress = fallbackAddress;
  //     });
  //
  //     if (showToast) {
  //       Fluttertoast.showToast(
  //         msg: S.of(context).addressUnavailable,
  //         toastLength: Toast.LENGTH_SHORT,
  //         gravity: ToastGravity.BOTTOM,
  //         backgroundColor: Colors.orange,
  //         textColor: Colors.white,
  //       );
  //     }
  //   }
  // }
  Future<void> _getAddressFromLatLng(double latitude, double longitude, {bool showToast = false}) async {
    try {
      List<Placemark> placemarks =
      await GeocodingPlatform.instance!.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) return;

      Placemark place = placemarks[0];
      String address =
          "${place.name}, ${place.subLocality}, ${place.locality}, ${place.country}";

      if (!mounted) return;

      setState(() {
        currentAddress = address;
      });

      if (showToast) {
        Fluttertoast.showToast(
          msg: "${S.of(context).address}: $address",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
        );
      }
    } catch (e) {

      String fallbackAddress =
          "Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}";

      if (!mounted) return;

      setState(() {
        currentAddress = fallbackAddress;
      });

      if (showToast) {
        Fluttertoast.showToast(
          msg: S.of(context).addressUnavailable,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    }
  }

  void _onCurrentLocationPressed() {
    bool wasUserSelected = _isUserSelectedLocation;

    setState(() {
      _isUserSelectedLocation = false;
    });

    if (wasUserSelected) {
      if (_bestPosition != null) {
        _currentPosition = _bestPosition;
        _currentAccuracy = _bestPosition!.accuracy;
      }

      Fluttertoast.showToast(
        msg: S.of(context).gpsTrackingResumed,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      _updateMarkerAndCircleSmoothly();
    } else {
      if (_currentPosition != null) {
        _moveCameraToCurrentLocation(animate: true);
      } else {
        _getCurrentLocationWithHighAccuracy();
      }
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage)),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Font.primaryColor,
            title: Text(
              S.of(context).geoLoc,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 1,
                  fontFamily: "Roboto"
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage)),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
                  );
                },
              ),
            ],
          ),
          body: _isLocationFetched
              ? Stack(
            children: [
              GoogleMap(
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: _onMapTapped,
                mapType: MapType.hybrid,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentPosition?.latitude ?? 0.0,
                    _currentPosition?.longitude ?? 0.0,
                  ),
                  zoom: 18.0,
                ),
                markers: _markers,
                circles: _circles,
              ),

              Positioned(
                top: 16,
                right: 10,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "location",
                      onPressed: _onCurrentLocationPressed,
                       child:  Icon(
                        _isUserSelectedLocation ? Icons.location_searching : Icons.my_location,
                        color: Colors.white,
                      ),
                      backgroundColor: _isUserSelectedLocation
                          ? Colors.orange.withOpacity(0.8)
                          : Font.primaryColor.withOpacity(0.9),
                    ),
                    if (_isUserSelectedLocation)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Reset GPS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Font.primaryColor),
                ),
                SizedBox(height: 16),
                Text(
                  'Getting your location...',
                  style: TextStyle(fontSize: 16),
                ),
                if (_isGettingAccurateLocation)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '${S.of(context).accuracy}: ${_currentAccuracy.toStringAsFixed(1)}m',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          bottomSheet: _showNextButton
              ? InkWell(
            onTap: () {
              if (_currentPosition != null) {
                if (_currentAccuracy > 100) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(S.of(context).lowAccuracy),
                        content: Text(
                            '${S.of(context).locationAccuracy} (${_currentAccuracy.toStringAsFixed(1)}m). ${S.of(context).continueAnyway}'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _getCurrentLocationWithHighAccuracy();
                            },
                            child: Text(S.of(context).improve),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _proceedToNextScreen();
                            },
                            child: Text(S.of(context).continueBtn),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  _proceedToNextScreen();
                }
              } else {
                Fluttertoast.showToast(
                  msg: S.of(context).pleaseDetection,
                  backgroundColor: Colors.orange,
                  textColor: Colors.white,
                );
              }
            },
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Font.primaryColor,
              ),
              child: Center(
                child: Text(
                  S.of(context).next,
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: "Roboto",
                      fontWeight: FontWeight.w600,
                      color: Colors.white
                  ),
                ),
              ),
            ),
          )
              : SizedBox.shrink(),
        ),
      ),
    );
  }

  void _proceedToNextScreen() {
    print("🔍 MapScreen passing locateId: ${widget.locateId}");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => UploadSeePlanScreen(
            planCode: widget.planCode.toString(),
            VillageCode: widget.VillageCode.toString(),
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            ServerID: widget.ServerID,
            Address: currentAddress,
            changeLanguage: widget.changeLanguage,
            height: widget.height,
            width: widget.width,
            villageName: widget.villageName,
            brand: widget.brand,
            tensil: widget.tensil,
            artworkId: widget.artworkId,
            locateId: widget.locateId,
          )
      ),
    );
  }
}