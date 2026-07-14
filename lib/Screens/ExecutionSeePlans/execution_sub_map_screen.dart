import 'dart:async';
import 'dart:math' as math;
import 'package:canimage/Screens/ExecutionSeePlans/execution_see_plans.dart';
import 'package:canimage/Screens/ExecutionSeePlans/execution_upload_see_plan.dart';
import 'package:canimage/Screens/ExecutionSeePlans/execution_detailed_list_see_plan.dart';
import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../Hive_Database/execution_seeplan_db.dart';
import '../../Repository/execution_balance_count_change_repository.dart';

class SubMapScreen extends StatefulWidget {
  String? planCode;
  String? VillageCode;
  String? ServerID;
  var width;
  var height;
  var villageName;
  var brand;
  var tensil;
  var artworkId;
  final Function(String) changeLanguage;

  SubMapScreen({
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
    required this.artworkId
  });

  @override
  _SubMapScreenState createState() => _SubMapScreenState();
}

class _SubMapScreenState extends State<SubMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Position? _bestPosition;
  bool _isLocationFetched = false;
  Set<Marker> _markers = Set<Marker>();
  Set<Circle> _circles = Set<Circle>();
  bool _showNextButton = false;
  String currentAddress = "";
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isGettingAccurateLocation = false;
  double _currentAccuracy = 0.0;
  int _locationUpdatesCount = 0;
  bool _isManualSelectionMode = false;
  List<Position> _recentPositions = [];
  bool _isUserSelectedLocation = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  // Search related variables
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<PlanItem> _searchResults = [];
  List<PlanItem> _allPlans = [];
  bool _showSearchResults = false;

  // Store marker data for navigation
  Map<MarkerId, Map<String, dynamic>> _markerDataMap = {};

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _listenToConnectivityChanges();
    _getCurrentLocationWithHighAccuracy();
    _startNextButtonDelay();
    _loadPlansFromHive();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _checkInitialConnectivity() async {
    final List<ConnectivityResult> connectivityResult =
    await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);

    // Show alert if offline
    if (!_isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOfflineAlert();
      });
    }
  }

  // Listen to connectivity changes
  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (List<ConnectivityResult> result) {
        _updateConnectionStatus(result);

        // Show toast when connection changes
        if (!_isOnline) {
          _showOfflineAlert();
        } else {
          Fluttertoast.showToast(
            msg: "Internet connection restored",
            backgroundColor: Colors.green,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      },
    );
  }

  // Update connection status
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    setState(() {
      _isOnline = !result.contains(ConnectivityResult.none);
    });
  }

  // Show offline alert dialog
  void _showOfflineAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Roboto",
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This map feature requires an active internet connection to function properly.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: "Roboto",
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please check your connection and try again.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          fontFamily: "Roboto",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LandingScreen(
                      changeLanguage: widget.changeLanguage,
                    ),
                  ),
                );
              },
              child: Text(
                'Go Back',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _checkInitialConnectivity();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Font.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Load plans from Hive database for search
  Future<void> _loadPlansFromHive() async {
    try {
      Box<PlanItem>? box = await Hive.openBox<PlanItem>('plans');
      setState(() {
        _allPlans = box.values.toList();
      });
      // print('Loaded ${_allPlans.length} plans from Hive');
    } catch (e) {
      print('Error loading plans from Hive: $e');
    }
  }

  // Search villages WITH BALANCE CHECK
  Future<void> _searchVillages(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    if (!_isOnline) {
      Fluttertoast.showToast(
        msg: "Search requires internet connection",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Filter plans by search query
    List<PlanItem> filteredPlans = _allPlans.where((plan) {
      String lowerQuery = query.toLowerCase();
      return plan.villageCode.toLowerCase().contains(lowerQuery) ||
          plan.villageName.toLowerCase().contains(lowerQuery);
    }).toList();

    // Group by village code + plan code and check balance
    Map<String, PlanItem> uniqueVillagesWithBalance = {};

    for (var plan in filteredPlans) {
      String villageKey = '${plan.villageCode}_${plan.planCode}';

      if (!uniqueVillagesWithBalance.containsKey(villageKey)) {
        // Get all plans for this village+planCode combination
        List<PlanItem> samePlans = _allPlans.where((p) =>
        p.villageCode == plan.villageCode && p.planCode == plan.planCode
        ).toList();

        // Calculate total balance
        int totalBalance = samePlans.fold(0, (sum, p) => sum + (p.noOfBalance ?? 0));

        // Get offline count
        int offlineCount = await PlanCountChangeHiveRepository().getOfflineCountForGroup(
          plan.planCode,
          plan.villageCode,
          plan.villageName,
          plan.tehsil,
        );

        // Calculate display balance
        int displayBalance = totalBalance - offlineCount;

        // Only add if display balance > 0
        if (displayBalance > 0) {
          uniqueVillagesWithBalance[villageKey] = plan;
        }
      }
    }

    setState(() {
      _searchResults = uniqueVillagesWithBalance.values.toList();
      _showSearchResults = true;
      _isSearching = false;
    });
  }

  // Clean village name for better geocoding
  String _cleanVillageName(String villageName) {
    String cleaned = villageName.replaceAll(RegExp(r'\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\bWARD NO\.?.*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\bRural MDDS CODE.*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\bMDDS CODE.*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(OG\)', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(CT\)', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  // Navigate to selected village and show markers with balance > 0
  Future<void> _navigateToVillage(PlanItem plan) async {
    try {
      Fluttertoast.showToast(
        msg: "${S.of(context).searchingForLocation}...",
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
      );

      // Find all plans with the same village code
      List<PlanItem> samePlans = _allPlans.where((p) =>
      p.villageCode == plan.villageCode
      ).toList();

      // Group by plan code and filter by balance
      Map<String, List<PlanItem>> planGroups = {};
      for (var p in samePlans) {
        String key = '${p.villageCode}_${p.planCode}';
        if (!planGroups.containsKey(key)) {
          planGroups[key] = [];
        }
        planGroups[key]!.add(p);
      }

      // Filter groups with balance > 0
      List<Map<String, dynamic>> validPlanGroups = [];
      for (var entry in planGroups.entries) {
        List<PlanItem> groupPlans = entry.value;
        int totalBalance = groupPlans.fold(0, (sum, p) => sum + (p.noOfBalance ?? 0));

        PlanItem firstPlan = groupPlans[0];
        int offlineCount = await PlanCountChangeHiveRepository().getOfflineCountForGroup(
          firstPlan.planCode,
          firstPlan.villageCode,
          firstPlan.villageName,
          firstPlan.tehsil,
        );

        int displayBalance = totalBalance - offlineCount;

        if (displayBalance > 0) {
          validPlanGroups.add({
            'plans': groupPlans,
            'totalBalance': totalBalance,
            'displayBalance': displayBalance,
          });
        }
      }

      if (validPlanGroups.isEmpty) {
        Fluttertoast.showToast(
          msg: S.of(context).noPlansWithBalance,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      String cleanedVillageName = _cleanVillageName(plan.villageName);

      List<String> searchQueries = [
        "$cleanedVillageName, ${plan.tehsil}, ${plan.stateName}, India",
        "$cleanedVillageName, ${plan.districtName}, ${plan.stateName}, India",
        "$cleanedVillageName, ${plan.stateName}, India",
        "${plan.villageName}, ${plan.stateName}, India",
      ];

      Location? foundLocation;

      for (String query in searchQueries) {
        try {
          // print("Trying geocoding with: $query");
          List<Location> locations = await locationFromAddress(query);

          if (locations.isNotEmpty) {
            foundLocation = locations[0];
            // print("Success with query: $query");
            break;
          }
        } catch (e) {
          // print("Failed with query: $query - Error: $e");
          continue;
        }
      }

      if (foundLocation != null) {
        double baseLat = foundLocation.latitude;
        double baseLng = foundLocation.longitude;

        // Create positions for all valid plan groups with offset
        List<Map<String, dynamic>> markerData = [];

        for (int i = 0; i < validPlanGroups.length; i++) {
          double lat = baseLat;
          double lng = baseLng;

          if (validPlanGroups.length > 1) {
            double offsetMeters = 12.0;
            double angleRadians = (2 * math.pi * i) / validPlanGroups.length;

            double latOffset = (offsetMeters / 111000) * (i == 0 ? 0 : 1);
            double lngOffset = (offsetMeters / (111000 * 0.9)) * (i == 0 ? 0 : 1);

            lat = baseLat + (latOffset * math.cos(angleRadians));
            lng = baseLng + (lngOffset * math.sin(angleRadians));
          }

          markerData.add({
            'plans': validPlanGroups[i]['plans'],
            'totalBalance': validPlanGroups[i]['totalBalance'],
            'displayBalance': validPlanGroups[i]['displayBalance'],
            'lat': lat,
            'lng': lng,
          });
        }

        Position villagePosition = Position(
          latitude: baseLat,
          longitude: baseLng,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        setState(() {
          _currentPosition = villagePosition;
          _bestPosition = villagePosition;
          _isLocationFetched = true;
          _showSearchResults = false;
          _searchController.clear();
          _isUserSelectedLocation = true;
        });

        _addMultipleVillageMarkers(markerData);
        _moveCameraToLocation(baseLat, baseLng, animate: true);
        _getAddressFromLatLng(baseLat, baseLng, showToast: true);

        Fluttertoast.showToast(
          msg: "${S.of(context).located}: $cleanedVillageName (${validPlanGroups.length} plan${validPlanGroups.length > 1 ? 's' : ''})",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        Fluttertoast.showToast(
          msg: S.of(context).locationNotFoundSelection,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      // print('Error navigating to village: $e');
      Fluttertoast.showToast(
        msg: S.of(context).unableToFindSelection,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  // Add multiple markers with navigation capability
  void _addMultipleVillageMarkers(List<Map<String, dynamic>> markerData) {
    _markers.clear();
    _circles.clear();
    _markerDataMap.clear();

    for (int i = 0; i < markerData.length; i++) {
      List<PlanItem> plans = markerData[i]['plans'];
      double lat = markerData[i]['lat'];
      double lng = markerData[i]['lng'];
      int displayBalance = markerData[i]['displayBalance'];
      int totalBalance = markerData[i]['totalBalance'];

      PlanItem firstPlan = plans[0];

      final markerId = MarkerId('village_${firstPlan.villageCode}_${firstPlan.planCode}_$i');

      // Store data for navigation
      _markerDataMap[markerId] = {
        'plans': plans,
        'totalBalance': totalBalance,
        'displayBalance': displayBalance,
      };

      Color markerColor = Colors.green;

      final marker = Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: '${firstPlan.villageName}',
          snippet: '${S.of(context).planTab}: ${firstPlan.planCode} • ${S.of(context).balance}: $displayBalance',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: () {
          // print('Marker tapped: $markerId'); // Debug log
          // print('Marker data exists: ${_markerDataMap.containsKey(markerId)}'); // Debug log
          _onMarkerTapped(markerId);
        }
      );

      final circle = Circle(
        circleId: CircleId('circle_${firstPlan.villageCode}_${firstPlan.planCode}_$i'),
        center: LatLng(lat, lng),
        radius: 25,
        fillColor: markerColor.withOpacity(0.15),
        strokeWidth: 1,
        strokeColor: markerColor,
      );

      _markers.add(marker);
      _circles.add(circle);
    }

    // print('Total markers created: ${_markers.length}'); // Debug log
    // print('Total marker data stored: ${_markerDataMap.length}'); // Debug log

    setState(() {});
  }

  Future<void> _onMarkerTapped(MarkerId markerId) async {
    if (!_markerDataMap.containsKey(markerId)) return;

    Map<String, dynamic> markerInfo = _markerDataMap[markerId]!;
    List<PlanItem> groupPlans = markerInfo['plans'];
    int displayBalance = markerInfo['displayBalance'];

    PlanItem firstPlan = groupPlans[0];

    // Show bottom sheet with marker details
    _showMarkerBottomSheet(
      projectName: firstPlan.projectName ?? 'N/A',
      villageName: firstPlan.villageName,
      villageCode: firstPlan.villageCode,
      cdBlockName: firstPlan.tehsil,
      balance: displayBalance,
      markerId: markerId,
    );
  }

// New method to show bottom sheet
  void _showMarkerBottomSheet({
    required String projectName,
    required String villageName,
    required String villageCode,
    required String cdBlockName,
    required int balance,
    required MarkerId markerId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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

            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    S.of(context).planDetails,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Font.neutralDarkColor,
                      fontFamily: "Roboto",
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

            SizedBox(height: 16),

            // Project Name
            _buildDetailRow(
              label: S.of(context).projectName,
              value: projectName,
            ),

            SizedBox(height: 12),

            // Village Name with Code
            _buildDetailRow(
              label: S.of(context).villageNameMap,
              value: '$villageName ($villageCode)',
            ),

            SizedBox(height: 12),

            // CD Block Name
            _buildDetailRow(
              label: S.of(context).cdBlockName,
              value: cdBlockName,
            ),

            SizedBox(height: 12),

            // Balance
            _buildDetailRow(
              label: S.of(context).balancePrints,
              value: balance.toString(),
              // valueColor: balance > 0 ? Colors.green : Colors.red,
            ),

            SizedBox(height: 20),

            // See Plan Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close bottom sheet first

                  // Navigate to detailed list screen
                  Map<String, dynamic> markerInfo = _markerDataMap[markerId]!;
                  List<PlanItem> groupPlans = markerInfo['plans'];
                  int totalBalance = markerInfo['totalBalance'];

                  // Create artwork list from plans
                  List<ArtworkData> artworkList = groupPlans.map((plan) => ArtworkData(
                    artworkId: plan.artworkId,
                    artworkName: plan.artworkName,
                    height: int.tryParse(plan.height) ?? 0,
                    width: int.tryParse(plan.width) ?? 0,
                    sqft: int.tryParse(plan.sqft) ?? 0,
                    artworkUrl: plan.artworkUrl,
                    planServerId: plan.planServerId,
                    planCode: plan.planCode,
                    villageCode: plan.villageCode,
                    balance: plan.noOfBalance,
                  )).toList();

                  // Remove duplicates based on artworkId
                  Map<int, ArtworkData> uniqueArtworks = {};
                  for (var artwork in artworkList) {
                   //error uniqueArtworks[artwork.artworkId] = artwork;
                    uniqueArtworks[artwork.planServerId] = artwork;
                  }

                  final filteredArtworks = uniqueArtworks.values.toList();
                  final firstPlan = groupPlans[0];
                  int totalPrints = groupPlans.fold(0, (sum, plan) => sum + (plan.noOfPrints ?? 0));

                  // Calculate display balance
                  int offlineCount = await PlanCountChangeHiveRepository().getOfflineCountForGroup(
                    firstPlan.planCode,
                    firstPlan.villageCode,
                    firstPlan.villageName,
                    firstPlan.tehsil,
                  );

                  int displayBalance = totalBalance - offlineCount;

                  // Navigate to DetailedListSeePlansScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailedListSeePlansScreen(
                        artworkList: filteredArtworks,
                        villageName: firstPlan.villageName,
                        districtName: firstPlan.districtName,
                        cdBlockName: firstPlan.tehsil,
                        totalPrints: totalPrints,
                        balancePrints: displayBalance,
                        planCode: firstPlan.planCode,
                        VillageCode: firstPlan.villageCode,
                        ServerID: firstPlan.planServerId.toString(),
                        changeLanguage: widget.changeLanguage,
                        flag: '7',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Font.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
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

// Helper method to build detail rows
  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label + ':',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Font.neutralDarkColor,
              fontFamily: "Roboto",
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Font.primaryColor,
              fontFamily: "Roboto",
            ),
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _moveCameraToLocation(double lat, double lng, {bool animate = true}) {
    if (_mapController == null) return;

    if (animate) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 18.0),
        ),
      );
    } else {
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 18.0),
        ),
      );
    }
  }

  void _startNextButtonDelay() {
    Future.delayed(Duration(seconds: 4), () {
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
          msg: "Location permission denied",
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

          setState(() {});

          _updateMarkerAndCircleSmoothly();
          _getAddressFromLatLng(smoothedPosition.latitude, smoothedPosition.longitude, showToast: false);
        }
      }

      if (smoothedPosition.accuracy <= 5.0 || _locationUpdatesCount >= 25) {
        _positionStreamSubscription?.cancel();
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
    if (_mapController == null) return;

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

  Future<void> _getAddressFromLatLng(double latitude, double longitude, {bool showToast = false}) async {
    try {
      List<Placemark> placemarks = await GeocodingPlatform.instance!.placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      String address = "${place.name}, ${place.subLocality}, ${place.locality}, ${place.country}";

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
      print("Error getting address: $e");
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
      MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
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
            title: Row(
              children: [
                Text(
                  S.of(context).geoLoc,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      letterSpacing: 1,
                      fontFamily: "Roboto"
                  ),
                ),

                SizedBox(width: 8),
                // Online/Offline indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOnline ? Icons.wifi : Icons.wifi_off,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),

            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
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
              if (!_isOnline)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Container(
                        margin: EdgeInsets.all(20),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off, size: 60, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Map Unavailable',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Roboto",
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Internet connection required',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: "Roboto",
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _checkInitialConnectivity,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Font.primaryColor,
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              GoogleMap(
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: _onMapTapped,
                mapType: MapType.hybrid,
                initialCameraPosition: CameraPosition(
                  target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  zoom: 18.0,
                ),
                markers: _markers,
                circles: _circles,
              ),

              // Search Bar
              Positioned(
                top: 10,
                left: 10,
                right: 70,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: S.of(context).searchVillageCode,
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Font.primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults = [];
                            _showSearchResults = false;
                          });
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: _searchVillages,
                  ),
                ),
              ),

              // Search Results Dropdown
              if (_showSearchResults && _searchResults.isNotEmpty)
                Positioned(
                  top: 65,
                  left: 10,
                  right: 70,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final plan = _searchResults[index];
                        return ListTile(
                          leading: Icon(Icons.location_on, color: Font.primaryColor),
                          title: Text(
                            plan.villageName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${plan.villageCode} • ${plan.stateName}',
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () => _navigateToVillage(plan),
                        );
                      },
                    ),
                  ),
                ),

              // No Results Found
              if (_showSearchResults && _searchResults.isEmpty && _searchController.text.isNotEmpty)
                Positioned(
                  top: 65,
                  left: 10,
                  right: 70,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          S.of(context).noBalanceFound,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          S.of(context).tryDifferentSearch,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Current Location Button
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "location",
                      onPressed: _onCurrentLocationPressed,
                      child: Icon(
                        _isUserSelectedLocation ? Icons.location_searching : Icons.my_location,
                        color: Colors.white,
                      ),
                      backgroundColor: _isUserSelectedLocation
                          ? Colors.orange.withOpacity(0.8)
                          : Colors.black54.withOpacity(0.4),
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
                          'Reset',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(S.of(context).getingLocation),
              ],
            ),
          ),

        ),
      ),
    );
  }

  void _proceedToNextScreen() {
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
          )
      ),
    );
  }
}