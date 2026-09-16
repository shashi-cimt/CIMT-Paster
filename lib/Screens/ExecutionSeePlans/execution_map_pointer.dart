import 'dart:async';
import 'dart:math';
import 'package:canimage/APIService/auth_service.dart';
import 'package:canimage/Screens/ExecutionSeePlans/execution_map_screen.dart';
import 'package:canimage/Screens/ExecutionSeePlans/execution_see_plans.dart';
import 'package:canimage/Screens/ExecutionSeePlans/execution_upload_see_plan.dart';
import 'package:canimage/generated/l10n.dart' show view360;
import 'package:canimage/main.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../generated/l10n.dart';
import '../../../../utils/crash_manager.dart';
import '../../Hive_Database/execution_seeplan_location_db.dart';
import '../../Repository/Map_pointer_locate_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../widgets/can_image_loader.dart';
import '../../widgets/app_snack_bar.dart';
import '../Rework/Rework_upload_see_plans.dart' as ColorsConst;
import '../Rework/Rework_upload_see_plans.dart' as font;
import '../landing/landing_screen.dart';
import 'execution_display_page.dart';
import '../../widgets/common_app_bar.dart';

class MapPointerData {
  final String planServerId;
  final String locateId;
  final double latitude;
  final double longitude;
  final String? artworkName;

  MapPointerData({
    required this.planServerId,
    required this.locateId,
    required this.latitude,
    required this.longitude,
    this.artworkName,
  });
}

class MapScreenpointer extends StatefulWidget {
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
  final List<MapPointerData>? pointers; // Only use passed pointers
  final String? projectId;

  MapScreenpointer({
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
    this.pointers, // Pointers passed from previous screen
    this.projectId,
  });
  
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreenpointer> with WidgetsBindingObserver {
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

  // Track screen entry time
  DateTime? _screenEntryTime;

  // Store pointer markers separately for zoom functionality
  List<Marker> _pointerMarkers = [];

  @override
  void initState() {
    super.initState();
    _screenEntryTime = DateTime.now();
    _logScreenEntry();
    _logScreenParameters();
    _logLocationOnEntry();
    WidgetsBinding.instance.addObserver(this);
    _getCurrentLocationWithHighAccuracy();
    _startNextButtonDelay();
    _startPeriodicLocationRefresh();

    // Load pointers from passed data only
    _loadPointers();
  }

  // ============ UPDATED: Only use passed pointers ============
  Future<void> _loadPointers() async {
    // Only use pointers passed from previous screen
    if (widget.pointers != null && widget.pointers!.isNotEmpty) {
      print(" Using ${widget.pointers!.length} pointers passed from previous screen");

      final capturedRepo = CapturedLocateRepository();
      List<MapPointerData> filteredPointers = [];
      int capturedCount = 0;

      for (var pointer in widget.pointers!) {
        // Skip if locateId is empty
        if (pointer.locateId.isEmpty) {
          print(" Skipping pointer with empty locateId");
          continue;
        }

        // Check if this locateId has been captured
        bool isCaptured = await capturedRepo.isLocateCaptured(
          pointer.locateId,
          pointer.planServerId,
        );

        if (isCaptured) {
          capturedCount++;
          print(" Skipping captured locateId: ${pointer.locateId}");
        } else {
          filteredPointers.add(pointer);
          print(" Showing pointer: ${pointer.locateId} (${filteredPointers.length})");
        }
      }

      print(" Summary: ${filteredPointers.length} uncaptured, $capturedCount captured");

      if (filteredPointers.isNotEmpty) {
        _showPointersFromData(filteredPointers);
        // REMOVED: _waitForLocationAndZoomToMarkers();
      } else {
        // All pointers captured
        if (mounted) {
          setState(() {
            _showNextButton = true;
          });

          AppSnackBar.showSuccess(
            context,
            "All locations for this artwork have been captured!",
          );
        }
      }
    } else {
      print(" No pointers passed to MapScreenpointer");

      if (mounted) {
        AppSnackBar.showError(
          context,
          "No location data available for this plan",
        );
      }
    }
  }

  // ============ REMOVED: _waitForLocationAndZoomToMarkers() ============
  // ============ REMOVED: _zoomToNearbyMarkers() ============
  // ============ REMOVED: _fitAllMarkersToMap() ============

  void _showPointersFromData(List<MapPointerData> pointers) {
    print(" Displaying ${pointers.length} pointers on map");

    // Clear existing pointer markers
    _pointerMarkers.clear();

    for (var item in pointers) {
      final marker = Marker(
        markerId: MarkerId('pointer_${item.locateId}'),
        position: LatLng(
          item.latitude,
          item.longitude,
        ),
        infoWindow: InfoWindow(
          title: "Location ${item.locateId}",
          snippet: "Plan ID: ${item.planServerId}\n${item.artworkName ?? ''}",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed, // Red markers for pointers
        ),
        onTap: () {
          _showPointerDistanceDialog(
            pointerId: item.locateId.toString(),
            pointerLat: item.latitude,
            pointerLng: item.longitude,
            pointerTitle: "Location ${item.locateId}",
            artworkName: item.artworkName,
          );
        },
      );
      _markers.add(marker);
      _pointerMarkers.add(marker); // Store for potential future use
    }
    setState(() {});
  }

  void _showPointerDistanceDialog({
    required String pointerId,
    required double pointerLat,
    required double pointerLng,
    required String pointerTitle,
    String? artworkName,
  }) async {
    if (_currentPosition == null) {
      Fluttertoast.showToast(
        msg: "Getting your location... Please wait.",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    // Calculate distance between user and pointer
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      pointerLat,
      pointerLng,
    );

    String distanceText = "";
    String distanceUnit = "";

    if (distanceInMeters >= 1000) {
      distanceText = (distanceInMeters / 1000).toStringAsFixed(2);
      distanceUnit = "km";
    } else {
      distanceText = distanceInMeters.toStringAsFixed(0);
      distanceUnit = "meters";
    }

    CrashReportManager.storeLogMessage(
        "event=pointer_tapped | "
            "planCode=${widget.planCode} | "
            "pointerId=$pointerId | "
            "distance=${distanceInMeters.toStringAsFixed(2)}m | "
            "timestamp=${DateTime.now().toIso8601String()}"
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isNear = distanceInMeters <= 100;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // TOP ICON
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isNear
                            ? [Colors.green, Colors.green.shade300]
                            : [
                          ColorsConst.primaryColor,
                          ColorsConst.primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),

                  SizedBox(height: 10),

                  // TITLE
                  Text(
                    pointerTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4),

                  // ARTWORK NAME
                  if (artworkName != null && artworkName.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsConst.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        artworkName,
                        style: TextStyle(
                          color: ColorsConst.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  SizedBox(height: 8),

                  // DISTANCE CARD
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isNear
                          ? Colors.green.withOpacity(0.08)
                          : Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isNear
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [

                        Icon(
                          Icons.social_distance,
                          size: 30,
                          color: isNear
                              ? Colors.green
                              : Colors.orange,
                        ),

                        SizedBox(height: 4),

                        Text(
                          "$distanceText $distanceUnit",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isNear
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          isNear
                              ? S.of(context).withinAllowedRange
                              : S.of(context).moveWithin100mToUnlockNext,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  // LOCATION INFO (Expandable)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            S.of(context).coordinates,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            S.of(context).tapToViewLocationDetails,
                            style: const TextStyle(
                              fontSize: 11,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 28,
                          ),
                          children: [

                            /// Pointer Coordinates
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Pointer Coordinates",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    "Latitude : ${pointerLat.toStringAsFixed(6)}",
                                    style: const TextStyle(fontSize: 12),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    "Longitude : ${pointerLng.toStringAsFixed(6)}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            /// User Coordinates
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.person_pin_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Your Coordinates",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    "Latitude : ${_currentPosition!.latitude.toStringAsFixed(6)}",
                                    style: const TextStyle(fontSize: 12),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    "Longitude : ${_currentPosition!.longitude.toStringAsFixed(6)}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                  // BUTTONS
                  Row(
                    children: [
                      // CANCEL
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(S.of(context).cancel),
                        ),
                      ),

                      SizedBox(width: 10),

                      // 360 VIEW
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);

                            _navigateToExecutionDisplay(
                              pointerLat,
                              pointerLng,
                              pointerTitle,
                            );
                          },
                          icon: Icon(
                            Icons.threesixty,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            S.of(context).view360,
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsConst.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      // NEXT BUTTON ONLY IF NEAR
                      if (isNear) ...[
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapScreen(
                                    planCode: widget.planCode,
                                    VillageCode: widget.VillageCode,
                                    ServerID: widget.ServerID,
                                    changeLanguage: widget.changeLanguage,
                                    height: widget.height,
                                    width: widget.width,
                                    villageName: widget.villageName,
                                    brand: widget.brand,
                                    tensil: widget.tensil,
                                    artworkId: widget.artworkId,
                                    locateId: pointerId,
                                    projectId: widget.projectId,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              S.of(context).next,
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToExecutionDisplay(double lat, double lng, String title) {
    CrashReportManager.storeLogMessage(
        "event=navigate_to_execution_display | "
            "planCode=${widget.planCode} | "
            "lat=$lat | "
            "lng=$lng | "
            "timestamp=${DateTime.now().toIso8601String()}"
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExecutionDisplayPage(
          changeLanguage: widget.changeLanguage,
          pointerLat: lat,
          pointerLng: lng,
          pointerTitle: title,
        ),
      ),
    );
  }

  void _logScreenEntry() {
    final timestamp = _screenEntryTime!.toIso8601String();

    CrashReportManager.storeLogMessage(
        "event=map_screen_entry | "
            "message=User entered Map Screen | "
            "planCode=${widget.planCode} | "
            "villageCode=${widget.VillageCode} | "
            "artworkId=${widget.artworkId} | "
            "artworkName=${widget.brand} | "
            "villageName=${widget.villageName} | "
            "size=${widget.width}x${widget.height} | "
            "pointersCount=${widget.pointers?.length ?? 0} | "
            "entryTime=$timestamp"
    );
  }

  void _logScreenParameters() {
    final timestamp = DateTime.now().toIso8601String();

    CrashReportManager.storeLogMessage(
        "event=map_screen_parameters | "
            "planCode=${widget.planCode} | "
            "villageCode=${widget.VillageCode} | "
            "serverId=${widget.ServerID} | "
            "artworkId=${widget.artworkId} | "
            "artworkName=${widget.brand} | "
            "villageName=${widget.villageName} | "
            "tehsil=${widget.tensil} | "
            "height=${widget.height} | "
            "width=${widget.width} | "
            "timestamp=$timestamp"
    );
  }

  Future<void> _logLocationOnEntry() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      Position? position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        CrashReportManager.storeLogMessage(
            "event=map_screen_entry_location | "
                "message=User location on Map Screen entry | "
                "planCode=${widget.planCode} | "
                "lat=${position.latitude} | "
                "lng=${position.longitude} | "
                "accuracy=${position.accuracy}m | "
                "time=$timestamp"
        );
      } else {
        CrashReportManager.storeLogMessage(
            "event=map_screen_entry_location | "
                "message=No last known location available on entry | "
                "planCode=${widget.planCode} | "
                "time=$timestamp"
        );
      }
    } catch (e) {
      CrashReportManager.storeLogMessage(
          "event=map_screen_entry_location_error | "
              "planCode=${widget.planCode} | "
              "error=$e | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );
    }
  }

  @override
  void dispose() {
    _logScreenExit();
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _periodicRefreshTimer?.cancel();
    super.dispose();
  }

  void _logScreenExit() {
    final duration = _screenEntryTime != null
        ? DateTime.now().difference(_screenEntryTime!).inSeconds
        : null;
    final timestamp = DateTime.now().toIso8601String();

    CrashReportManager.storeLogMessage(
        "event=map_screen_exit | "
            "planCode=${widget.planCode} | "
            "villageCode=${widget.VillageCode} | "
            "durationOnScreen=${duration != null ? "${duration}s" : "unknown"} | "
            "locationFetched=$_isLocationFetched | "
            "userSelectedLocation=$_isUserSelectedLocation | "
            "finalAccuracy=${_currentAccuracy.toStringAsFixed(1)}m | "
            "timestamp=$timestamp"
    );
  }

  Future<void> _logLocation(String eventType, Position position, {String? additionalInfo}) async {
    final timestamp = DateTime.now().toIso8601String();

    CrashReportManager.storeLogMessage(
        "event=$eventType | "
            "planCode=${widget.planCode} | "
            "villageCode=${widget.VillageCode} | "
            "lat=${position.latitude} | "
            "lng=${position.longitude} | "
            "accuracy=${position.accuracy}m | "
            "altitude=${position.altitude}m | "
            "speed=${position.speed}m/s | "
            "additionalInfo=${additionalInfo ?? 'none'} | "
            "time=$timestamp"
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final timestamp = DateTime.now().toIso8601String();

    CrashReportManager.storeLogMessage(
        "event=app_lifecycle_change | "
            "screen=MapScreen | "
            "state=$state | "
            "planCode=${widget.planCode} | "
            "locationFetched=$_isLocationFetched | "
            "timestamp=$timestamp"
    );

    if (state == AppLifecycleState.paused) {
      // Pause GPS refresh in background to prevent OS killing app for background location violations
      _periodicRefreshTimer?.cancel();
      _periodicRefreshTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      if (_periodicRefreshTimer == null) {
        _startPeriodicLocationRefresh();
      }
      CrashReportManager.storeLogMessage(
          "event=app_resumed | "
              "screen=MapScreen | "
              "checkingLocationPermission | "
              "locationFetched=$_isLocationFetched | "
              "timestamp=$timestamp"
      );
      if (!_isLocationFetched && !_isGettingAccurateLocation) {
        _checkAndRetryLocation();
      }
    }
  }

  Future<void> _checkAndRetryLocation() async {
    final timestamp = DateTime.now().toIso8601String();
    CrashReportManager.storeLogMessage(
        "event=checking_retry_location | "
            "planCode=${widget.planCode} | "
            "timestamp=$timestamp"
    );

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      CrashReportManager.storeLogMessage(
          "event=retry_location_permission_granted | "
              "planCode=${widget.planCode} | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );
      _getCurrentLocationWithHighAccuracy();
    } else {
      CrashReportManager.storeLogMessage(
          "event=retry_location_permission_denied | "
              "planCode=${widget.planCode} | "
              "permission=$permission | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );
    }
  }

  void _startPeriodicLocationRefresh() {
    _periodicRefreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isUserSelectedLocation && _isLocationFetched) {
        _refreshCurrentLocation();
      }
    });
  }

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

        await _logLocation("periodic_location_refresh", smoothedPosition);

        // REMOVED: _zoomToNearbyMarkers();
      }
    } catch (e) {
      CrashReportManager.storeLogMessage(
          "event=periodic_refresh_error | "
              "planCode=${widget.planCode} | "
              "error=$e | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );
    }
  }

  void _updateMarkerAndCircleOnly() {
    // Clear existing markers but keep a reference to pointer markers
    Set<Marker> pointerMarkers = Set.from(_markers.where((marker)
    => marker.markerId.value.startsWith('pointer_')
    ));

    _markers.clear();
    _circles.clear();

    final marker = Marker(
      markerId: MarkerId('current_location'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      infoWindow: InfoWindow(
        title: S.of(context).currentLocation,
        snippet: S.of(context).tapAddress,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
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
      _markers.addAll(pointerMarkers); // Restore pointer markers
    });
  }

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
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showNextButton = true;
        });
        final timestamp = DateTime.now().toIso8601String();
        CrashReportManager.storeLogMessage(
            "event=next_button_enabled | "
                "planCode=${widget.planCode} | "
                "delayComplete=4s | "
                "timestamp=$timestamp"
        );
      }
    });
  }

  Future<void> _getCurrentLocationWithHighAccuracy() async {
    final startTime = DateTime.now();
    CrashReportManager.storeLogMessage(
        "event=get_location_started | "
            "planCode=${widget.planCode} | "
            "timestamp=${startTime.toIso8601String()}"
    );

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      CrashReportManager.storeLogMessage(
          "event=location_services_disabled | "
              "planCode=${widget.planCode} | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );
      _showLocationServiceDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      CrashReportManager.storeLogMessage(
          "event=location_permission_denied | "
              "planCode=${widget.planCode} | "
              "requestingPermission | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        CrashReportManager.storeLogMessage(
            "event=location_permission_denied_by_user | "
                "planCode=${widget.planCode} | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
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
      CrashReportManager.storeLogMessage(
          "event=location_permission_denied_forever | "
              "planCode=${widget.planCode} | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );
      _showPermissionDeniedDialog();
      return;
    }

    setState(() {
      _isGettingAccurateLocation = true;
    });

    await _tryMultipleLocationMethods();

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    CrashReportManager.storeLogMessage(
        "event=get_location_completed | "
            "planCode=${widget.planCode} | "
            "duration=${duration}ms | "
            "accuracy=${_currentAccuracy.toStringAsFixed(1)}m | "
            "timestamp=${DateTime.now().toIso8601String()}"
    );
  }

  Future<void> _tryMultipleLocationMethods() async {
    final startTime = DateTime.now();
    CrashReportManager.storeLogMessage(
        "event=multiple_location_methods_started | "
            "planCode=${widget.planCode} | "
            "timestamp=${startTime.toIso8601String()}"
    );

    List<Position> positions = [];

    try {
      try {
        Position bestPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        );
        positions.add(bestPosition);
        await _logLocation("best_accuracy_location", bestPosition);
      } catch (e) {
        CrashReportManager.storeLogMessage(
            "event=best_position_failed | "
                "planCode=${widget.planCode} | "
                "error=$e | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
      }

      try {
        Position highPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        );
        positions.add(highPosition);
        await _logLocation("high_accuracy_location", highPosition);
      } catch (e) {
        CrashReportManager.storeLogMessage(
            "event=high_position_failed | "
                "planCode=${widget.planCode} | "
                "error=$e | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
      }

      try {
        Position mediumPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        );
        positions.add(mediumPosition);
        await _logLocation("medium_accuracy_location", mediumPosition);
      } catch (e) {
        CrashReportManager.storeLogMessage(
            "event=medium_position_failed | "
                "planCode=${widget.planCode} | "
                "error=$e | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
      }

      if (positions.isNotEmpty) {
        Position smoothedPosition = _calculateWeightedAveragePosition(positions);

        CrashReportManager.storeLogMessage(
            "event=location_obtained_successfully | "
                "planCode=${widget.planCode} | "
                "accuracy=${smoothedPosition.accuracy}m | "
                "lat=${smoothedPosition.latitude} | "
                "lng=${smoothedPosition.longitude} | "
                "methodsUsed=${positions.length} | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );

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

        final duration = DateTime.now().difference(startTime).inMilliseconds;
        CrashReportManager.storeLogMessage(
            "event=location_processing_complete | "
                "planCode=${widget.planCode} | "
                "totalDuration=${duration}ms | "
                "finalAccuracy=${_currentAccuracy.toStringAsFixed(1)}m | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );

      } else {
        CrashReportManager.storeLogMessage(
            "event=all_location_methods_failed | "
                "planCode=${widget.planCode} | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
        throw Exception("All location methods failed");
      }

    } catch (e) {
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

          // REMOVED: _zoomToNearbyMarkers();
        }
      }

      if (smoothedPosition.accuracy <= 5.0 || _locationUpdatesCount >= 25) {
        _positionStreamSubscription?.cancel();
        if(!mounted) return;
        setState(() {
          _isGettingAccurateLocation = false;
        });
        CrashReportManager.storeLogMessage(
            "event=smooth_location_updates_stopped | "
                "planCode=${widget.planCode} | "
                "finalAccuracy=${smoothedPosition.accuracy.toStringAsFixed(1)}m | "
                "updatesCount=$_locationUpdatesCount | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
      }
    }, onError: (error) {
      CrashReportManager.storeLogMessage(
          "event=location_stream_error | "
              "planCode=${widget.planCode} | "
              "error=$error | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );
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
      CrashReportManager.storeLogMessage(
          "event=location_stream_timeout | "
              "planCode=${widget.planCode} | "
              "timeout=45s | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );
    });
  }

  void _updateMarkerAndCircleSmoothly() {
    // Clear existing markers but keep a reference to pointer markers
    Set<Marker> pointerMarkers = Set.from(_markers.where((marker)
    => marker.markerId.value.startsWith('pointer_')
    ));

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
      _markers.addAll(pointerMarkers); // Restore pointer markers
    });

    _moveCameraToCurrentLocation(animate: true);
  }

  void _showLocationServiceDialog() {
    final timestamp = DateTime.now().toIso8601String();
    CrashReportManager.storeLogMessage(
        "event=location_service_dialog_shown | "
            "planCode=${widget.planCode} | "
            "timestamp=$timestamp"
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).locationServicesDisabled),
          content: Text(S.of(context).pleaseAccurate),
          actions: [
            TextButton(
              onPressed: () {
                CrashReportManager.storeLogMessage(
                    "event=location_service_dialog_cancelled | "
                        "planCode=${widget.planCode} | "
                        "timestamp=${DateTime.now().toIso8601String()}"
                );
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                CrashReportManager.storeLogMessage(
                    "event=location_settings_opened | "
                        "planCode=${widget.planCode} | "
                        "timestamp=${DateTime.now().toIso8601String()}"
                );
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
    final timestamp = DateTime.now().toIso8601String();
    CrashReportManager.storeLogMessage(
        "event=permission_denied_dialog_shown | "
            "planCode=${widget.planCode} | "
            "timestamp=$timestamp"
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).locationRequired),
          content: Text(S.of(context).pleaseAppSettings),
          actions: [
            TextButton(
              onPressed: () {
                CrashReportManager.storeLogMessage(
                    "event=permission_denied_dialog_cancelled | "
                        "planCode=${widget.planCode} | "
                        "timestamp=${DateTime.now().toIso8601String()}"
                );
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                CrashReportManager.storeLogMessage(
                    "event=app_settings_opened | "
                        "planCode=${widget.planCode} | "
                        "timestamp=${DateTime.now().toIso8601String()}"
                );
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
    final timestamp = DateTime.now().toIso8601String();
    CrashReportManager.storeLogMessage(
        "event=location_failure_dialog_shown | "
            "planCode=${widget.planCode} | "
            "timestamp=$timestamp"
    );

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
              onPressed: () {
                CrashReportManager.storeLogMessage(
                    "event=location_failure_dialog_cancelled | "
                        "planCode=${widget.planCode} | "
                        "timestamp=${DateTime.now().toIso8601String()}"
                );
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                CrashReportManager.storeLogMessage(
                    "event=manual_selection_enabled | "
                        "planCode=${widget.planCode} | "
                        "timestamp=${DateTime.now().toIso8601String()}"
                );
                Navigator.of(context).pop();
                _enableManualLocationSelection();
              },
              child: Text(S.of(context).manualSelection),
            ),
            TextButton(
              onPressed: () {
                CrashReportManager.storeLogMessage(
                    "event=location_retry_from_dialog | "
                        "planCode=${widget.planCode} | "
                        "timestamp=${DateTime.now().toIso8601String()}"
                );
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
    CrashReportManager.storeLogMessage(
        "event=manual_location_selection_enabled | "
            "planCode=${widget.planCode} | "
            "timestamp=${DateTime.now().toIso8601String()}"
    );
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
    final timestamp = DateTime.now().toIso8601String();

    CrashReportManager.storeLogMessage(
        "event=map_tapped | "
            "planCode=${widget.planCode} | "
            "lat=${tappedPoint.latitude} | "
            "lng=${tappedPoint.longitude} | "
            "isManualSelectionMode=$_isManualSelectionMode | "
            "timestamp=$timestamp"
    );

    if (_isManualSelectionMode) {
      CrashReportManager.storeLogMessage(
          "event=manual_location_selected | "
              "planCode=${widget.planCode} | "
              "lat=${tappedPoint.latitude} | "
              "lng=${tappedPoint.longitude} | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );

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

      // REMOVED: _zoomToNearbyMarkers();

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

  Future<void> _getAddressFromLatLng(double latitude, double longitude, {bool showToast = false}) async {
    final startTime = DateTime.now();
    CrashReportManager.storeLogMessage(
        "event=get_address_started | "
            "planCode=${widget.planCode} | "
            "lat=$latitude | "
            "lng=$longitude | "
            "timestamp=${startTime.toIso8601String()}"
    );

    try {
      List<Placemark> placemarks =
      await GeocodingPlatform.instance!.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        CrashReportManager.storeLogMessage(
            "event=get_address_no_results | "
                "planCode=${widget.planCode} | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
        return;
      }

      Placemark place = placemarks[0];
      String address =
          "${place.name}, ${place.subLocality}, ${place.locality}, ${place.country}";

      final duration = DateTime.now().difference(startTime).inMilliseconds;

      CrashReportManager.storeLogMessage(
          "event=get_address_success | "
              "planCode=${widget.planCode} | "
              "address=$address | "
              "duration=${duration}ms | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );

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
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      CrashReportManager.storeLogMessage(
          "event=get_address_failed | "
              "planCode=${widget.planCode} | "
              "error=$e | "
              "duration=${duration}ms | "
              "timestamp=${DateTime.now().toIso8601String()}"
      );

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
    final timestamp = DateTime.now().toIso8601String();

    CrashReportManager.storeLogMessage(
        "event=current_location_button_pressed | "
            "planCode=${widget.planCode} | "
            "userSelectedLocation=$_isUserSelectedLocation | "
            "hasBestPosition=${_bestPosition != null} | "
            "timestamp=$timestamp"
    );

    bool wasUserSelected = _isUserSelectedLocation;

    setState(() {
      _isUserSelectedLocation = false;
    });

    if (wasUserSelected) {
      if (_bestPosition != null) {
        _currentPosition = _bestPosition;
        _currentAccuracy = _bestPosition!.accuracy;
        CrashReportManager.storeLogMessage(
            "event=gps_tracking_resumed | "
                "planCode=${widget.planCode} | "
                "accuracy=${_currentAccuracy.toStringAsFixed(1)}m | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
      }

      Fluttertoast.showToast(
        msg: S.of(context).gpsTrackingResumed,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      _updateMarkerAndCircleSmoothly();
      // REMOVED: _zoomToNearbyMarkers();
    } else {
      if (_currentPosition != null) {
        _moveCameraToCurrentLocation(animate: true);
        CrashReportManager.storeLogMessage(
            "event=camera_moved_to_current_location | "
                "planCode=${widget.planCode} | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
      } else {
        CrashReportManager.storeLogMessage(
            "event=get_location_triggered_from_button | "
                "planCode=${widget.planCode} | "
                "timestamp=${DateTime.now().toIso8601String()}"
        );
        _getCurrentLocationWithHighAccuracy();
      }
    }
  }

  Future<bool> _onWillPop() async {
    final timestamp = DateTime.now().toIso8601String();

    CrashReportManager.storeLogMessage(
        "event=back_button_pressed | "
            "screen=MapScreenpointer | "
            "planCode=${widget.planCode} | "
            "villageCode=${widget.VillageCode} | "
            "timestamp=$timestamp"
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    }
    return true;
  }

  Future<void> _proceedToNextScreen() async {
    final timestamp = DateTime.now().toIso8601String();
    final nextButtonLocation = _currentPosition!;

    CrashReportManager.storeLogMessage(
        "event=next_button_tapped | "
            "message=User tapped Next button on MapScreen | "
            "planCode=${widget.planCode} | "
            "villageCode=${widget.VillageCode} | "
            "artworkId=${widget.artworkId} | "
            "artworkName=${widget.brand} | "
            "villageName=${widget.villageName} | "
            "nextButtonLat=${nextButtonLocation.latitude} | "
            "nextButtonLng=${nextButtonLocation.longitude} | "
            "accuracy=${nextButtonLocation.accuracy}m | "
            "altitude=${nextButtonLocation.altitude}m | "
            "timeSpentOnScreen=${DateTime.now().difference(_screenEntryTime!).inSeconds}s | "
            "time=$timestamp"
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          planCode: widget.planCode,
          VillageCode: widget.VillageCode,
          ServerID: widget.ServerID,
          changeLanguage: widget.changeLanguage,
          height: widget.height,
          width: widget.width,
          villageName: widget.villageName,
          brand: widget.brand,
          tensil: widget.tensil,
          artworkId: widget.artworkId,
          projectId: widget.projectId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenBuildTimestamp = DateTime.now().toIso8601String();

    CrashReportManager.storeLogMessage(
        "event=map_screen_building | "
            "planCode=${widget.planCode} | "
            "locationFetched=$_isLocationFetched | "
            "showNextButton=$_showNextButton | "
            "timestamp=$screenBuildTimestamp"
    );

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        top: false,
        child: Scaffold(
          appBar: CommonAppBar(
            title: S.of(context).geoLoc,
            onBackPressed: () {
              final timestamp = DateTime.now().toIso8601String();
              CrashReportManager.storeLogMessage(
                  "event=back_arrow_clicked | "
                      "screen=MapScreenpointer | "
                      "planCode=${widget.planCode} | "
                      "timestamp=$timestamp"
              );
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            actions: [
              IconButton(
                icon: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                onPressed: () {
                  final timestamp = DateTime.now().toIso8601String();
                  CrashReportManager.storeLogMessage(
                      "event=home_button_clicked | "
                          "screen=MapScreenpointer | "
                          "planCode=${widget.planCode} | "
                          "timestamp=$timestamp"
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                tooltip: 'Home',
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
                  CrashReportManager.storeLogMessage(
                      "event=map_created | "
                          "planCode=${widget.planCode} | "
                          "timestamp=${DateTime.now().toIso8601String()}"
                  );
                  // REMOVED: _zoomToNearbyMarkers();
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
                      child: Icon(
                        _isUserSelectedLocation
                            ? Icons.location_searching : Icons.my_location,
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
              // Positioned(
              //   bottom: 100,
              //   right: 10,
              //   child: FloatingActionButton(
              //     heroTag: "street",
              //     backgroundColor: Font.primaryColor,
              //     child: const Icon(
              //       Icons.travel_explore,
              //       color: Colors.white,
              //     ),
              //     onPressed: () {
              //       if (_currentPosition == null) return;
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (_) => Execution360ViewScreen(
              //             latitude: _currentPosition!.latitude,
              //             longitude: _currentPosition!.longitude,
              //           ),
              //         ),
              //       );
              //     },
              //   ),
              // ),
              if (_showNextButton)
                Positioned(
                  left: 10,
                  bottom: 20,
                  child: InkWell(
                    onTap: () {
                      final tapTimestamp = DateTime.now().toIso8601String();

                      CrashReportManager.storeLogMessage(
                        "event=next_button_clicked | "
                            "screen=MapScreen | "
                            "planCode=${widget.planCode} | "
                            "currentAccuracy=${_currentAccuracy}m | "
                            "hasLocation=${_currentPosition != null} | "
                            "isUserSelectedLocation=$_isUserSelectedLocation | "
                            "timestamp=$tapTimestamp",
                      );

                      if (_currentPosition != null) {
                        CrashReportManager.storeLogMessage(
                          "event=next_button_location_capture | "
                              "planCode=${widget.planCode} | "
                              "lat=${_currentPosition!.latitude} | "
                              "lng=${_currentPosition!.longitude} | "
                              "accuracy=${_currentAccuracy}m | "
                              "timestamp=$tapTimestamp",
                        );

                        if (_currentAccuracy > 100) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(S.of(context).lowAccuracy),
                              content: Text(
                                '${S.of(context).locationAccuracy} '
                                    '(${_currentAccuracy.toStringAsFixed(1)}m). '
                                    '${S.of(context).continueAnyway}',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _getCurrentLocationWithHighAccuracy();
                                  },
                                  child: Text(S.of(context).improve),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _proceedToNextScreen();
                                  },
                                  child: Text(S.of(context).continueBtn),
                                ),
                              ],
                            ),
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
                      width: 100,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Font.primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CanImageLoader(
                  spinnerSize: 52,
                  showBrand: true,
                  message: 'Getting your location...',
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

        ),
      ),
    );
  }
}