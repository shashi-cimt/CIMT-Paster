



import 'package:canimage/Screens/Rework/rework_display_page.dart';
import 'package:canimage/Screens/Rework/rework_see_plans.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import '../../Hive_Database/rework_db.dart';
import '../../Repository/Rework_completed_upload_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../utils/textStyle.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/can_image_loader.dart';
import '../landing/landing_screen.dart';

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
  String? serverId;
  String? address;
  String? artworkId;

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
    this.serverId,
    this.address,
    this.artworkId,
  });
}

class ReworkMap extends StatefulWidget {
  final List<ReworkModel> groupedPlans;
  final Function(String) changeLanguage;

  ReworkMap({required this.groupedPlans, required this.changeLanguage});

  @override
  _ReworkMapState createState() => _ReworkMapState();
}

class _ReworkMapState extends State<ReworkMap> {
  GoogleMapController? mapController;
  List<Marker> markers = [];
  Map<String, MarkerData> markerDataMap = {};
  MarkerData? selectedMarker;
  List<ReworkModel>? savedPlans;
  LatLng? currentLocation;
  bool _isLocationFetched = false;
  Set<Circle> _circles = Set<Circle>();
  TextEditingController searchController = TextEditingController();
  String? searchQuery;
  String? highlightedMarkerId;

  List<String> uploadedPrintIds = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUploadedPrintIds();
  }

  // ============ LOCATION METHODS ============

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

  // ============ UPLOAD MANAGEMENT ============

  Future<void> _loadUploadedPrintIds() async {
    try {
      final completedRepo = ReworkCompletedUploadRepository();
      final completedIds = await completedRepo.getCompletedPrintIds();

      setState(() {
        uploadedPrintIds = completedIds;
      });

      print(' Loaded ${uploadedPrintIds.length} completed upload IDs');

      if (uploadedPrintIds.isNotEmpty) {
        final sampleIds = uploadedPrintIds.take(5).join(', ');
        print(' Sample IDs: $sampleIds${uploadedPrintIds.length > 5 ? '...' : ''}');
      }

    } catch (e) {
      print(' Error loading completed uploads: $e');
      setState(() {
        uploadedPrintIds = [];
      });
    }
  }

  //  FIXED: Complete refresh after upload
  Future<void> refreshMarkersAfterUpload() async {
    print(' Refreshing markers after upload...');

    // Clear existing markers immediately
    setState(() {
      markers.clear();
      markerDataMap.clear();
    });

    // Reload uploaded print IDs from SharedPreferences
    await _loadUploadedPrintIds();
    print(' Uploaded print IDs count: ${uploadedPrintIds.length}');

    // Regenerate markers (this will exclude uploaded ones)
    _generateMarkersFromGroup();

    // Update map with remaining markers
    if (markers.isNotEmpty) {
      _fitMarkersToMap();
      print(' ${markers.length} markers remaining');
    } else {
      print('ℹ No markers remaining - all plans uploaded');
      Fluttertoast.showToast(
        msg: " All plans have been uploaded!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    }
  }

  // ============ MARKER GENERATION ============

  void _generateMarkersFromGroup() {
    print(' Starting marker generation...');
    print(' Uploaded print IDs count: ${uploadedPrintIds.length}');

    if (currentLocation == null) {
      print('Current location is not available');
      return;
    }

    // Clear existing markers
    markers.clear();
    markerDataMap.clear();

    int hiddenCount = 0;
    int totalProcessed = 0;

    for (int i = 0; i < widget.groupedPlans.length; i++) {
      final p = widget.groupedPlans[i];
      totalProcessed++;

      // Check if this print should be hidden (already uploaded)
      bool shouldHide = _shouldHideMarker(p);

      if (shouldHide) {
        hiddenCount++;
        print(' HIDING marker for printId: ${p.printId} - printNo: ${p.printNo}');
        continue;
      }

      if (!_isValidCoordinate(p.latitude, p.longitude)) {
        print(' Invalid coordinates for printId: ${p.printId}');
        continue;
      }

      final lat = double.tryParse(p.latitude) ?? 0.0;
      final lng = double.tryParse(p.longitude) ?? 0.0;
      final position = LatLng(lat, lng);

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
        tensil: p.tehsil,
        serverId: p.planServerId?.toString(),
        address: p.address?.toString(),
        artworkId: p.artworkId?.toString(),
        lat: lat,
        long: lng,
        projectName: p.projectName,
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
            onTap: () => _onInfoWindowTap(markerData),
          ),
          onTap: () => _onMarkerTap(markerData),
        ),
      );
      markerDataMap[uniqueId] = markerData;

      // Log each visible marker
      print(' VISIBLE marker: printNo=${p.printNo}, printId=${p.printId}');
    }

    if (mounted) {
      setState(() {});
      print(' Generated ${markers.length} visible markers');
      print(' Hidden ${hiddenCount} markers (already uploaded)');
      print(' Total processed: ${totalProcessed}');
    }
  }

  bool _shouldHideMarker(ReworkModel plan) {
    // Check if printId is in completed uploads list
    bool isUploaded = uploadedPrintIds
        .map((e) => e.trim())
        .contains(plan.printId.toString().trim());

    if (isUploaded) {
      print(' Hiding marker: printId=${plan.printId} is in completed list');
      return true;
    }

    // Secondary check with Hive metadata
    return _isMarkerInHiveMetadata(plan);
  }

  bool _isMarkerInHiveMetadata(ReworkModel plan) {
    // You can implement additional matching logic here
    return false;
  }

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
      ) / 1000;
    } catch (e) {
      print('Error calculating distance: $e');
      return 0.0;
    }
  }

  // ============ MARKER INTERACTIONS ============

  void _onMarkerTap(MarkerData markerData) {
    setState(() {
      selectedMarker = markerData;
    });
    _showMarkerBottomSheet(markerData);
  }

  //  FIXED: Handle result from display page and refresh
  void _onInfoWindowTap(MarkerData markerData) async {
    print(' Marker tapped: ${markerData.printNo}');

    // Navigate and wait for result from display page
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReworkDisplayPage(
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
          planCode: markerData.planCode,
          tensil: markerData.tensil,
          changeLanguage: widget.changeLanguage,
          serverId: markerData.serverId,
          address: markerData.address,
          artworkId: markerData.artworkId,
          markerLatitude: markerData.lat.toString(),
          markerLongitude: markerData.long.toString(),
        ),
      ),
    );

    // If upload successful, refresh and remove marker
    if (result == true) {
      print(' Upload completed, refreshing markers...');

      // Show loading indicator
      Fluttertoast.showToast(
        msg: " Removing marker...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      // Immediately refresh markers
      await refreshMarkersAfterUpload();

      // Show confirmation that marker was removed
      Fluttertoast.showToast(
        msg: " Marker removed successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    }
  }

  // ============ MAP NAVIGATION ============

  Future<void> _zoomToNearbyMarkers() async {
    if (currentLocation == null || markers.isEmpty) {
      _moveCameraToCurrentLocation();
      return;
    }

    double searchRadius = 5.0;
    List<Marker> nearbyMarkers = [];

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

    if (nearbyMarkers.isEmpty) {
      searchRadius = 10.0;
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
      _fitMarkersToMap();
      return;
    }

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

    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
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

  void _moveCameraToSelectedMarker(MarkerData markerData) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: markerData.position,
          zoom: 18.0,
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
      mapController?.showMarkerInfoWindow(markerId);
      setState(() {
        selectedMarker = markerData;
      });
    }
  }

  // ============ BOTTOM SHEET ============

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
                  Navigator.pop(context);
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
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  // ============ SEARCH FUNCTIONALITY ============

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

    for (var entry in markerDataMap.entries) {
      final markerData = entry.value;
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
        highlightedMarkerId = foundMarkerId;
      });

      _updateMarkersWithHighlight();

      Future.delayed(Duration(milliseconds: 300), () {
        _moveCameraToSelectedMarker(foundMarker!);
      });

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
            onTap: () => _onInfoWindowTap(markerData),
          ),
          onTap: () => _onMarkerTap(markerData),
        ),
      );
    }

    setState(() {});
  }

  void _clearHighlight() {
    setState(() {
      highlightedMarkerId = null;
      searchController.clear();
      searchQuery = null;
    });
    _updateMarkersWithHighlight();
  }

  // ============ NAVIGATION ============

  Future<bool> _onWillPop() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, false);
      return false;
    }
    return true;
  }

  // ============ BUILD ============

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
            onBackPressed: () => Navigator.pop(context, false),
            actions: const [CommonHomeButton()],
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

              // Search Bar
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

              // My Location Button
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
                          mapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: currentLocation!,
                                zoom: 15.0,
                              ),
                            ),
                          );
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
