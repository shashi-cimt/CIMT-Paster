import 'package:canimage/Hive_Database/post_recca_seePlan_db.dart';
import 'package:canimage/Repository/post_recca_post_plan_repository.dart';
import 'package:canimage/Screens/PostReccaPostPlan/post_recca_photo_capture.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

import '../../Repository/completed_upload_repository.dart'; // ADD THIS IMPORT

import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../utils/textStyle.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/can_image_loader.dart';
import '../WCC/wcc_screen.dart' as TextStyleGlobal;
import '../landing/landing_screen.dart';

// Color Palette (matching your existing design)


// Sample data model for markers
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

class SUMapScreen extends StatefulWidget {
  final Function(String) changeLanguage;

  const SUMapScreen({super.key, required this.changeLanguage});
  @override
  _SUMapScreenState createState() => _SUMapScreenState();
}

class _SUMapScreenState extends State<SUMapScreen> {
  GoogleMapController? mapController;
  List<Marker> markers = [];
  Map<String, MarkerData> markerDataMap = {};
  MarkerData? selectedMarker;
  List<SUPlanModel>? savedPlans;
  LatLng? currentLocation;
  bool _isLocationFetched = false;
  Set<Circle> _circles = Set<Circle>();
  TextEditingController searchController = TextEditingController();
  String? searchQuery;
  String? highlightedMarkerId;

  // ADD THIS: Track uploaded print IDs
  List<String> uploadedPrintIds = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUploadedPrintIds(); // ADD THIS
  }

  // ADD THIS METHOD: Load completed upload IDs
  Future<void> _loadUploadedPrintIds() async {
    try {
      final completedIds = await CompletedUploadRepository().getCompletedPrintIds();

      setState(() {
        uploadedPrintIds = completedIds;
      });

    } catch (e) {
      setState(() {
        uploadedPrintIds = [];
      });
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
  // ADD THIS METHOD: Check if marker should be hidden
  bool _shouldHideMarker(SUPlanModel plan) {
    bool isUploaded = uploadedPrintIds.contains(plan.printId.toString());

    if (isUploaded) {
      print(' Hiding marker for printId: ${plan.printId} - printNo: ${plan.printNo}');
      return true;
    }

    return false;
  }

  // ADD THIS METHOD: Validate coordinates
  bool _isValidCoordinate(String latitude, String longitude) {
    if (latitude.isEmpty || longitude.isEmpty) {
      return false;
    }

    try {
      double lat = double.parse(latitude);
      double lng = double.parse(longitude);
      return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
    } catch (e) {
      return false;
    }
  }

  // ADD THIS METHOD: Refresh markers after upload
  Future<void> refreshMarkersAfterUpload() async {
    print(' Refreshing markers after upload...');

    markers.clear();
    markerDataMap.clear();

    await _loadUploadedPrintIds();

    if (savedPlans != null && savedPlans!.isNotEmpty) {
      _generateMarkersFromPlan();
    }

    if (markers.isNotEmpty) {
      _fitMarkersToMap();
    } else {
      print('ℹ No markers remaining after refresh');
    }
  }

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
      _moveCameraToCurrentLocation();
      _getAddressFromLatLng(currentLocation!.latitude, currentLocation!.longitude);
      _loadSavedPlans();

    } catch (e) {
      print('Error fetching current location: $e');
    }
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await GeocodingPlatform.instance!.placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      String address = "${place.name}, ${place.subLocality},${place.locality}, ${place.country}";

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
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLocation!.latitude, currentLocation!.longitude),
          zoom: 15.0,
        ),
      ),
    );
  }

  void _addCircle() {
    final circle = Circle(
      circleId: CircleId('current_location_radius'),
      center: LatLng(currentLocation!.latitude, currentLocation!.longitude),
      radius: 300000,
      fillColor: Colors.blue.withOpacity(0.3),
      strokeWidth: 2,
      strokeColor: Font.primaryColor,
    );

    setState(() {
      _circles.add(circle);
    });
  }

  // void _loadSavedPlans() async {
  //   print(' Loading saved plans...');
  //   savedPlans = await PostReccaPlanHiveRepository().loadSUPlans();
  //   print(' Loaded ${savedPlans!.length} plans from Hive');
  //
  //   if (savedPlans!.isNotEmpty) {
  //     _generateMarkersFromPlan();
  //   } else {
  //     print('ℹ No saved plans found');
  //   }
  // }
  void _loadSavedPlans() async {
    print(' Loading saved plans...');
    savedPlans = await PostReccaPlanHiveRepository().loadSUPlans();
    print(' Loaded ${savedPlans!.length} plans from Hive');

    if (savedPlans!.isNotEmpty) {
      _generateMarkersFromPlan();
      // ADDED: Zoom to nearby markers after generating markers
      Future.delayed(Duration(milliseconds: 500), () {
        _zoomToNearbyMarkers();
      });
    } else {
      print('ℹ No saved plans found');
    }
  }
  void _generateMarkersFromPlan() {
    print(' Starting marker generation...');
    print(' Uploaded print IDs count: ${uploadedPrintIds.length}');

    if (currentLocation == null) {
      print(' Current location is not available');
      return;
    }

    markers.clear();
    markerDataMap.clear();

    int hiddenCount = 0;
    int totalProcessed = 0;

    for (int i = 0; i < savedPlans!.length; i++) {
      final p = savedPlans![i];
      totalProcessed++;

      if (_shouldHideMarker(p)) {
        hiddenCount++;
        continue;
      }

      if (!_isValidCoordinate(p.latitude, p.longitude)) {
        print(' Invalid coordinates for printId: ${p.printId}');
        continue;
      }

      if (p.latitude.isNotEmpty && p.longitude.isNotEmpty) {
        final position = LatLng(double.parse(p.latitude), double.parse(p.longitude));

        double distance = 0.0;
        try {
          distance = Geolocator.distanceBetween(
            currentLocation!.latitude,
            currentLocation!.longitude,
            position.latitude,
            position.longitude,
          ) / 1000;
        } catch (e) {
          print('Error calculating distance: $e');
        }

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
        final isHighlighted = uniqueId == highlightedMarkerId;

        markers.add(
          Marker(
            markerId: MarkerId(uniqueId),
            position: position,
            icon: isHighlighted
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: '${S.of(context).printNo}: ${markerData.printNo}',
              onTap: () => _onInfoWindowTap(
                markerData,
                markerData.projectID,
                markerData.villageName,
                markerData.width,
                markerData.height,
                markerData.printNo,
                markerData.frontView,
                markerData.surroundingView,
                markerData.artworkName,
                markerData.printId,
                markerData.villageCode,
                markerData.planCode,
                markerData.tensil, markerData.lat.toString(), markerData.long.toString()
              ),
            ),
            onTap: () => _onMarkerTap(markerData),
          ),
        );
        markerDataMap[uniqueId] = markerData;
      }
    }

    if (mounted) {
      setState(() {});
      print(' Generated ${markers.length} visible markers');
      print(' Hidden ${hiddenCount} markers (already uploaded)');
      print(' Total processed: ${totalProcessed}');
    }
  }


  void _searchMarkerByVillageCode() {
    if (searchQuery == null || searchQuery!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter a search term",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    MarkerData? foundMarker;
    String? foundMarkerId;

    // Search through markerDataMap using village code OR print number
    for (var entry in markerDataMap.entries) {
      final markerData = entry.value;

      // Case-insensitive search for both village code and print number
      if (markerData.villageCode.toLowerCase() == searchQuery!.toLowerCase() ||
          markerData.printNo.toLowerCase().contains(searchQuery!.toLowerCase())) {
        foundMarker = markerData;
        foundMarkerId = entry.key;
        break;
      }
    }

    if (foundMarker != null && foundMarkerId != null) {
      setState(() {
        selectedMarker = foundMarker;
        highlightedMarkerId = foundMarkerId; // Highlight this marker
      });

      // Regenerate markers with highlight
      _updateMarkersWithHighlight();

      Future.delayed(Duration(milliseconds: 300), () {
        _moveCameraToSelectedMarker(foundMarker!);
      });

      // Open info window after zoom completes
      Future.delayed(Duration(milliseconds: 800), () {
        _openMarkerInfoWindow(foundMarker!);
      });

      Fluttertoast.showToast(
        msg: "Found: ${foundMarker.printNo}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: "No matching marker found!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _updateMarkersWithHighlight() {
    markers.clear();

    for (var entry in markerDataMap.entries) {
      final uniqueId = entry.key;
      final markerData = entry.value;
      final isHighlighted = uniqueId == highlightedMarkerId;

      markers.add(
        Marker(
          markerId: MarkerId(uniqueId),
          position: markerData.position,
          icon: isHighlighted
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: '${S.of(context).printNo}: ${markerData.printNo}',
            onTap: () => _onInfoWindowTap(
              markerData,
              markerData.projectID,
              markerData.villageName,
              markerData.width,
              markerData.height,
              markerData.printNo,
              markerData.frontView,
              markerData.surroundingView,
              markerData.artworkName,
              markerData.printId,
              markerData.villageCode,
              markerData.planCode,
              markerData.tensil, markerData.lat.toString(), markerData.long.toString()
            ),
          ),
          onTap: () => _onMarkerTap(markerData),
        ),
      );
    }

    setState(() {});
  }

  // ADD THIS METHOD to clear highlight
  void _clearHighlight() {
    setState(() {
      highlightedMarkerId = null;
      searchController.clear();
      searchQuery = null;
    });
    _updateMarkersWithHighlight();
  }

  void _moveCameraToSelectedMarker(MarkerData markerData) {
    // Zoom in to the marker with animation
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: markerData.position,
          zoom: 18.0, // Close zoom level (adjust between 15-20)
          // tilt: 45.0, // Optional: 3D tilt effect (0-90 degrees)
          // bearing: 0.0, // Optional: Rotation angle
        ),
      ),
    );
  }

// OPTIONAL: Add this method for custom zoom levels based on user preference
  void _moveCameraWithCustomZoom(MarkerData markerData, double zoomLevel) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: markerData.position,
          zoom: zoomLevel,
          tilt: 45.0,
        ),
      ),
    );
  }

  void _onMarkerTap(MarkerData markerData) {
    setState(() {
      selectedMarker = markerData;
    });
    _showMarkerBottomSheet(markerData);
  }

  // MODIFIED: Add await and result handling
  void _onInfoWindowTap(
      MarkerData markerData,
      String projectID,
      String villageName,
      String width,
      String height,
      String printNo,
      String frontview,
      String surroundingView,
      String artworkName,
      String printId,
      String villageCode,
      String planCode,
      String tensil,
      String lat,
      String long,
      ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoDisplayScreen(
          projectID: projectID,
          VillageName: villageName,
          width: width,
          height: height,
          printNo: printNo,
          frontView: frontview,
          surroundingView: surroundingView,
          artworkName: artworkName,
          printId: printId,
          villageCode: villageCode,
          planCode: planCode,
          tensil: tensil,
          changeLanguage: widget.changeLanguage, markerLatitude: lat, markerLongitude: long,
        ),
      ),
    );

    // ADDED: Refresh markers if upload was successful
    if (result == true) {
      await refreshMarkersAfterUpload();
    }
  }

  // void _onMapCreated(GoogleMapController controller) {
  //   mapController = controller;
  //   _fitMarkersToMap();
  // }
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // CHANGED: Zoom to nearby markers instead of all markers
    Future.delayed(Duration(milliseconds: 500), () {
      _zoomToNearbyMarkers();
    });
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

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  void _openMarkerInfoWindow(MarkerData markerData) {
    String? matchingMarkerId;

    for (var entry in markerDataMap.entries) {
      if (entry.value.planCode == markerData.planCode &&
          entry.value.printId == markerData.printId) {
        matchingMarkerId = entry.key;
        break;
      }
    }

    if (matchingMarkerId != null) {
      final markerId = MarkerId(matchingMarkerId);

      Marker? targetMarker;
      for (var marker in markers) {
        if (marker.markerId.value == matchingMarkerId) {
          targetMarker = marker;
          break;
        }
      }

      if (targetMarker != null) {
        mapController?.showMarkerInfoWindow(markerId);

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
                      fontWeight: FontWeight.w700,
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
                Expanded(
                  child: Text(
                    markerData.villageName,
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
                        style: TextstyleGlobal.bodyTextStyle.copyWith(fontWeight: FontWeight.w600),
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
                        style: TextstyleGlobal.bodyTextStyle.copyWith(fontWeight: FontWeight.w600),
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
                  Navigator.pop(context);
                  _onInfoWindowTap(
                    markerData,
                    markerData.projectID,
                    markerData.villageName,
                    markerData.width,
                    markerData.height,
                    markerData.printNo,
                    markerData.frontView,
                    markerData.surroundingView,
                    markerData.artworkName,
                    markerData.printId,
                    markerData.villageCode,
                    markerData.planCode,
                    markerData.tensil, markerData.lat.toString(), markerData.long.toString()
                  );
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
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Font.pureWhiteColor,
          appBar: CommonAppBar(
            title: S.of(context).geoLoc,
            actions: const [CommonHomeButton()],
          ),
          body: _isLocationFetched
              ? Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
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
                top: 12,
                left: 12,
                right: 74,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: "Roboto",
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      onSubmitted: (_) => _searchMarkerByVillageCode(),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: IconButton(
                          icon: Icon(Icons.search_rounded, color: Font.primaryColor, size: 24),
                          onPressed: _searchMarkerByVillageCode,
                        ),
                        suffixIcon: searchQuery?.isNotEmpty == true
                            ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              searchQuery = '';
                            });
                          },
                        )
                            : null,
                        hintText: S.of(context).searchVillageCode,
                        hintStyle: TextStyle(
                          fontSize: 14.5,
                          fontFamily: "Roboto",
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (currentLocation != null && mapController != null) {
                          mapController?.animateCamera(CameraUpdate.newLatLng(currentLocation!));
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: Icon(Icons.my_location_rounded, color: Font.primaryColor, size: 26),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
              : Center(
                  child: CanImageLoader(
                    spinnerSize: 52,
                    showBrand: true,
                    message: S.of(context).getingLocation,
                  ),
                ),
        ),
      ),
    );
  }
}