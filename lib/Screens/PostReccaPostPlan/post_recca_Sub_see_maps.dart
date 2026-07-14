import 'package:canimage/Hive_Database/post_recca_seePlan_db.dart';
import 'package:canimage/Screens/PostReccaPostPlan/post_recca_photo_capture.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import '../../Repository/completed_upload_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../utils/textStyle.dart';
import '../landing/landing_screen.dart';
import 'post_recca_see_plans.dart';

class MarkerData {
  final String id;
  final String printNo;
  final LatLng position;
  final String villageName;
  final double distance;
  final String size;
  final String projectID;
  final String width;
  final String height;
  final String frontView;
  final String surroundingView;
  final String artworkName;
  final String printId;
  final String villageCode;
  final String planCode;
  final String tensil;
  final String projectName;
  final double lat;
  final double long;

  MarkerData({
    required this.id,
    required this.printNo,
    required this.position,
    required this.villageName,
    required this.distance,
    required this.size,
    required this.projectID,
    required this.width,
    required this.height,
    required this.frontView,
    required this.surroundingView,
    required this.artworkName,
    required this.printId,
    required this.villageCode,
    required this.planCode,
    required this.tensil,
    required this.projectName,
    required this.lat,
    required this.long,
  });
}

class SUSubMapScreen extends StatefulWidget {
  final List<SUPlanModel> groupedPlans;
  final Function(String) changeLanguage;

  // Constructor to accept grouped data
  SUSubMapScreen({required this.groupedPlans, required this.changeLanguage});
  @override
  _SUSubMapScreenState createState() => _SUSubMapScreenState();
}

class _SUSubMapScreenState extends State<SUSubMapScreen> {
  GoogleMapController? mapController;
  List<Marker> markers = [];
  Map<String, MarkerData> markerDataMap = {}; // Map to hold markerId to MarkerData
  MarkerData? selectedMarker;
  List<SUPlanModel>? savedPlans;
  LatLng? currentLocation;
  bool _isLocationFetched = false;
  Set<Circle> _circles = Set<Circle>();
  TextEditingController searchController = TextEditingController();  // Controller for the search field
  String? searchQuery;

  List<String> uploadedPrintIds = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUploadedPrintIds(); // Load uploaded plans on init
  }



  // Function to get the current location using Geolocator
  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;
  //
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return;
  //   }
  //
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       return;
  //     }
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) {
  //     return;
  //   }
  //
  //   try {
  //     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //     setState(() {
  //       currentLocation = LatLng(position.latitude, position.longitude);
  //       _isLocationFetched = true;
  //     });
  //
  //     _addCircle();
  //     _moveCameraToCurrentLocation();
  //     _getAddressFromLatLng(currentLocation!.latitude, currentLocation!.longitude);
  //     _generateMarkersFromGroup();
  //   } catch (e) {
  //     print('Error fetching current location: $e');
  //   }
  // }
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        _isLocationFetched = true;
      });

      _addCircle();
      _getAddressFromLatLng(currentLocation!.latitude, currentLocation!.longitude);
      _generateMarkersFromGroup();

      // CHANGED: Zoom to nearby markers instead of current location
      _zoomToNearbyMarkers();
    } catch (e) {
      print('Error fetching current location: $e');
    }
  }
  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await GeocodingPlatform.instance!.placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      String address = "${place.name}, ${place.subLocality}, ${place.locality}, ${place.country}";
      Fluttertoast.showToast(
        msg: "${S.of(context).lat}: $latitude, ${S.of(context).lng}: $longitude\n${S.of(context).address}: $address",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  void _moveCameraToCurrentLocation() {
    if (mapController != null && currentLocation != null) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation!,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<void> _zoomToNearbyMarkers() async {
    if (currentLocation == null || markers.isEmpty) {
      _moveCameraToCurrentLocation();
      return;
    }

    // Define radius to search for nearby markers (in kilometers)
    double searchRadius = 5.0; // 5km radius

    List<Marker> nearbyMarkers = [];

    // Find all markers within the search radius
    for (var marker in markers) {
      double distance = Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        marker.position.latitude,
        marker.position.longitude,
      ) / 1000; // Convert to kilometers

      if (distance <= searchRadius) {
        nearbyMarkers.add(marker);
      }
    }

    if (nearbyMarkers.isEmpty) {
      // If no markers nearby, expand search radius
      searchRadius = 10.0; // Try 10km

      for (var marker in markers) {
        double distance = Geolocator.distanceBetween(
          currentLocation!.latitude,
          currentLocation!.longitude,
          marker.position.latitude,
          marker.position.longitude,
        ) / 1000;

        if (distance <= searchRadius) {
          nearbyMarkers.add(marker);
        }
      }
    }

    if (nearbyMarkers.isEmpty) {
      // If still no markers, just show all markers
      _fitMarkersToMap();
      return;
    }

    // Calculate bounds that include current location and nearby markers
    double minLat = currentLocation!.latitude;
    double maxLat = currentLocation!.latitude;
    double minLng = currentLocation!.longitude;
    double maxLng = currentLocation!.longitude;

    for (var marker in nearbyMarkers) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }

    // Add some padding to the bounds
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    // Animate camera to show nearby markers
    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // 50 is padding
    );
  }

  void _addCircle() {
    final circle = Circle(
      circleId: CircleId('current_location_radius'),
      center: LatLng(currentLocation!.latitude, currentLocation!.longitude),
      radius: 300000, // 30km radius
      fillColor: Colors.blue.withOpacity(0.3),
      strokeWidth: 2,
      strokeColor: Font.primaryColor,
    );

    setState(() {
      _circles.add(circle);
    });
  }

  // void _loadSavedPlans() async {
  //   savedPlans = await HiveRepository().loadSUPlans();
  //   if (savedPlans!.isNotEmpty) {
  //     _generateMarkersFromPlan();
  //   } else {
  //     print('No saved plans found.');
  //   }
  // }
  void _generateMarkersFromGroup() async {
    print('🔍 Starting marker generation...');

    // Load uploaded metadata first
    await _loadUploadedPrintIds();
    print('📁 Loaded ${uploadedPrintIds.length} uploaded print IDs');

    // Clear existing markers before regenerating
    markers.clear();
    markerDataMap.clear();

    int hiddenCount = 0;
    int totalProcessed = 0;

    for (int i = 0; i < widget.groupedPlans.length; i++) {
      final p = widget.groupedPlans[i];
      totalProcessed++;

      // Enhanced hiding logic - check multiple conditions
      bool shouldHideMarker = _shouldHideMarker(p);

      if (shouldHideMarker) {
        hiddenCount++;
        print('🚫 Hiding marker for printId: ${p.printId} - printNo: ${p.printNo}');
        continue;
      }

      // Validate coordinates before creating marker
      if (!_isValidCoordinate(p.latitude, p.longitude)) {
        print('⚠️ Invalid coordinates for printId: ${p.printId}');
        continue;
      }

      final position = LatLng(double.parse(p.latitude), double.parse(p.longitude));

      double distance = _calculateDistance(position);

      final markerData = MarkerData(
        id: p.planCode,
        printNo: p.printNo,
        position: position,
        villageName: p.villageName,
        distance: double.parse(distance.toStringAsFixed(2)),
        size: '${p.width}W x${p.height}H',
        projectID: p.projectId,
        width: p.width,
        height: p.height,
        frontView: p.frontView,
        surroundingView: p.surroundingView,
        artworkName: p.artworkName,
        printId: p.printId.toString(),
        villageCode: p.villageCode,
        planCode: p.planCode,
        tensil: p.tehsil, lat: double.parse(p.latitude.toString()), long: double.parse(p.longitude.toString()), projectName: p.projectName,
      );

      final uniqueId = '${p.planCode}_${p.printId}_$i';

      markers.add(
        Marker(
          markerId: MarkerId(uniqueId),
          position: position,
          infoWindow: InfoWindow(
            title: '${S.of(context).printNo}: ${markerData.printNo}',
            onTap: () => _onInfoWindowTap(markerData),
          ),
          onTap: () => _onMarkerTap(markerData),
        ),
      );
      markerDataMap[uniqueId] = markerData;
    }

    if (mounted) {
      setState(() {});
      print('✅ Generated ${markers.length} markers');
      print('🚫 Hidden ${hiddenCount} markers (already uploaded)');
      print('📊 Total processed: ${totalProcessed}');
    }
  }

// Enhanced method to determine if a marker should be hidden
  bool _shouldHideMarker(SUPlanModel plan) {
    // Primary check: Is printId in uploaded list?
    bool isUploaded = uploadedPrintIds.contains(plan.printId.toString());

    if (isUploaded) {
      return true;
    }

    // Secondary check: Cross-reference with Hive metadata
    // This is useful if printId matching isn't sufficient
    return _isMarkerInHiveMetadata(plan);
  }

// Check if marker exists in Hive metadata using multiple criteria
  bool _isMarkerInHiveMetadata(SUPlanModel plan) {
    // You can implement additional matching logic here
    // For example, matching by planCode + villageCode combination
    // if printId matching isn't reliable enough

    return false; // For now, rely on printId matching
  }

// Validate coordinate strings
  bool _isValidCoordinate(String latitude, String longitude) {
    if (latitude.isEmpty || longitude.isEmpty) {
      return false;
    }

    try {
      double lat = double.parse(latitude);
      double lng = double.parse(longitude);

      // Check for reasonable coordinate bounds
      return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
    } catch (e) {
      return false;
    }
  }


  double _calculateDistance(LatLng position) {
    if (currentLocation == null) {
      return 0.0;
    }

    try {
      return Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        position.latitude,
        position.longitude,
      ) / 1000; // Convert meters to kilometers
    } catch (e) {
      print('Error calculating distance: $e');
      return 0.0;
    }
  }

// Enhanced method to load uploaded print IDs with better error handling
//   Future<void> _loadUploadedPrintIds() async {
//     try {
//       final uploadedMetadata = await PostReccaImageUploadHiveRepository().loadSUMetadata();
//
//       // Extract printIds and ensure they're strings
//       final printIds = uploadedMetadata
//           .map((metadata) => metadata.printId.toString())
//           .where((id) => id.isNotEmpty)
//           .toList();
//
//       setState(() {
//         uploadedPrintIds = printIds;
//       });
//
//       print('📁 Successfully loaded ${uploadedPrintIds.length} uploaded print IDs');
//
//       // Debug: Print first few IDs for verification
//       if (uploadedPrintIds.isNotEmpty) {
//         final sampleIds = uploadedPrintIds.take(5).join(', ');
//         print('📋 Sample uploaded IDs: $sampleIds${uploadedPrintIds.length > 5 ? '...' : ''}');
//       }
//
//     } catch (e) {
//       print('❌ Error loading uploaded print IDs: $e');
//       // Set empty list to prevent null errors
//       setState(() {
//         uploadedPrintIds = [];
//       });
//     }
//   }


  Future<void> _loadUploadedPrintIds() async {
    try {
      // Load from completed uploads (not pending)
      final completedIds = await CompletedUploadRepository().getCompletedPrintIds();

      setState(() {
        uploadedPrintIds = completedIds;
      });

      print('Loaded ${uploadedPrintIds.length} completed upload IDs');

      if (uploadedPrintIds.isNotEmpty) {
        final sampleIds = uploadedPrintIds.take(5).join(', ');
        print('Sample completed IDs: $sampleIds${uploadedPrintIds.length > 5 ? '...' : ''}');
      }

    } catch (e) {
      print('Error loading completed uploads: $e');
      setState(() {
        uploadedPrintIds = [];
      });
    }
  }
// Method to manually refresh markers after upload
  Future<void> refreshMarkersAfterUpload() async {
    print('🔄 Refreshing markers after upload...');

    // Clear existing markers
    markers.clear();
    markerDataMap.clear();

    // Reload uploaded print IDs
    await _loadUploadedPrintIds();

    // Regenerate markers (this will automatically exclude newly uploaded plans)
    _generateMarkersFromGroup();

    // Refit map to show remaining markers if any exist
    if (markers.isNotEmpty) {
      _fitMarkersToMap();
    } else {
      print('ℹ️ No markers remaining after refresh');
    }
  }

// Method to get statistics about hidden/visible markers
  Map<String, int> getMarkerStatistics() {
    int totalPlans = widget.groupedPlans.length;
    int visibleMarkers = markers.length;
    int hiddenMarkers = uploadedPrintIds.length;

    return {
      'total': totalPlans,
      'visible': visibleMarkers,
      'hidden': hiddenMarkers,
    };
  }




  void _onMarkerTap(MarkerData markerData) {
    setState(() {
      selectedMarker = markerData;
    });
    _showMarkerBottomSheet(markerData);
  }

  void _onInfoWindowTap(MarkerData markerData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoDisplayScreen(
          projectID: markerData.projectID,
          VillageName: markerData.villageName,
          width: markerData.width,
          height: markerData.height,
          printNo: markerData.printNo,
          frontView: markerData.frontView,
          surroundingView: markerData.surroundingView,
          artworkName: markerData.artworkName,
          printId: markerData.printId,
          villageCode: markerData.villageCode,
          planCode: markerData.planCode, tensil: markerData.tensil, changeLanguage: widget.changeLanguage, markerLatitude: markerData.lat.toString(), markerLongitude: markerData.long.toString(),
        ),
      ),
    );
  }

  void _fitMarkersToMap() {
    if (markers.isNotEmpty && currentLocation != null) {
      double minLat = double.infinity, maxLat = double.negativeInfinity;
      double minLng = double.infinity, maxLng = double.negativeInfinity;

      for (var marker in markers) {
        minLat = min(minLat, marker.position.latitude);
        maxLat = max(maxLat, marker.position.latitude);
        minLng = min(minLng, marker.position.longitude);
        maxLng = max(maxLng, marker.position.longitude);
      }

      // Define the bounds based on the min/max latitude and longitude
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      // Animate the camera to fit the bounds
      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50)); // 50 is padding
    }
  }

  void _searchMarkerByVillageCode() {
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      MarkerData? foundMarker;

      // Search through markerDataMap using the village code
      for (var markerData in markerDataMap.values) {
        if (markerData.villageCode == searchQuery) {
          foundMarker = markerData;
          break;
        }
      }

      if (foundMarker != null) {
        setState(() {
          selectedMarker = foundMarker;
        });
        _moveCameraToSelectedMarker(foundMarker);
        _openMarkerInfoWindow(foundMarker);
      } else {
        Fluttertoast.showToast(
          msg: S.of(context).pleaseCheckVillageCode,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  // Function to move the camera to the selected marker
  void _moveCameraToSelectedMarker(MarkerData markerData) {
    mapController?.animateCamera(CameraUpdate.newLatLng(markerData.position));
  }

  void _openMarkerInfoWindow(MarkerData markerData) {
    // Find the marker that matches this markerData
    String? matchingMarkerId;

    // Search through markerDataMap to find the key that corresponds to this markerData
    for (var entry in markerDataMap.entries) {
      if (entry.value.planCode == markerData.planCode &&
          entry.value.printId == markerData.printId) {
        matchingMarkerId = entry.key;
        break;
      }
    }

    if (matchingMarkerId != null) {
      final markerId = MarkerId(matchingMarkerId);

      // Find the marker in the markers list
      Marker? targetMarker;
      for (var marker in markers) {
        if (marker.markerId.value == matchingMarkerId) {
          targetMarker = marker;
          break;
        }
      }

      if (targetMarker != null) {
        // Show InfoWindow by calling the GoogleMapController's showMarkerInfoWindow method
        mapController?.showMarkerInfoWindow(markerId);

        // Also set the selected marker for the bottom sheet
        setState(() {
          selectedMarker = markerData;
        });
      } else {
        print("Marker with id $matchingMarkerId not found in markers list.");
      }
    } else {
      print("No matching marker found for the given markerData.");
    }
  }

  void _showMarkerBottomSheet(MarkerData markerData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Font.pureWhiteColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 250,
                  child: Text(
                    '${S.of(context).printNo}: ${markerData.printNo}',
                    maxLines: 10,
                    style: TextstyleGlobal.bodyTextStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Font.neutralDarkColor),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "${S.of(context).villageNameMap}:",
                  style: TextstyleGlobal.bodyTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Font.neutralDarkColor,
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 200,
                  child: Text(
                    markerData.villageName,
                    maxLines: 10,
                    style: TextstyleGlobal.bodyTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Font.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "${S.of(context).projectName}:",
                  style: TextstyleGlobal.bodyTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Font.neutralDarkColor,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    markerData.projectName,
                    style: TextstyleGlobal.bodyTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Font.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "${S.of(context).planId}:",
                  style: TextstyleGlobal.bodyTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Font.neutralDarkColor,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    markerData.planCode,
                    style: TextstyleGlobal.bodyTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Font.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${S.of(context).coordinates}:',
                        style: TextstyleGlobal.bodyTextStyle.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${S.of(context).lat}: ${markerData.position.latitude.toStringAsFixed(6)}',
                        style: TextstyleGlobal.bodyTextStyle.copyWith(fontSize: 12),
                      ),
                      Text(
                        '${S.of(context).lng}: ${markerData.position.longitude.toStringAsFixed(6)}',
                        style: TextstyleGlobal.bodyTextStyle.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${S.of(context).details}:',
                        style: TextstyleGlobal.bodyTextStyle.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${S.of(context).size}: ${markerData.size}',
                        style: TextstyleGlobal.bodyTextStyle.copyWith(fontSize: 12),
                      ),
                      Text(
                        '${S.of(context).distance}: ${markerData.distance}km',
                        style: TextstyleGlobal.bodyTextStyle.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet first
                  _onInfoWindowTap(markerData);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Font.accentColor,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  S.of(context).viewDetails,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // Add bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SUSeePlanScreen(changeLanguage: widget.changeLanguage,)),
    );
    return false;
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Font.pureWhiteColor,
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
                fontFamily: "Roboto",
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SUSeePlanScreen(changeLanguage: widget.changeLanguage,)),
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
                onMapCreated: (controller) {
                  mapController = controller;
                  Future.delayed(Duration(milliseconds: 500), () {
                    _zoomToNearbyMarkers();
                  });
                },
                initialCameraPosition: CameraPosition(
                  target: currentLocation ?? LatLng(0.0, 0.0),
                  zoom: 11.0,
                ),
                markers: Set.from(markers),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapType: MapType.hybrid,
              ),

              Positioned(
                top: 16,
                right: 1,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Font.primaryColor,
                  onPressed: () {
                    if (currentLocation != null && mapController != null) {
                      mapController?.animateCamera(CameraUpdate.newLatLng(currentLocation!));
                    }
                  },
                  child: Icon(Icons.my_location, color: Colors.white),
                ),
              ),

            ],
          )
              : Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

