
import 'package:canimage/Screens/ExecutionSeePlans/execution_see_plans.dart';
import 'package:canimage/Screens/ExecutionSeePlans/execution_upload_see_plan.dart';
import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/can_image_loader.dart';
import '../Rework/Rework_upload_see_plans.dart' as ColorsConst;

class ExecutionDisplayPage extends StatefulWidget {
  final Function(String) changeLanguage;
  final double? pointerLat;
  final double? pointerLng;
  final String? pointerTitle;
  final String? planCode;
  final String? villageCode;
  final String? serverId;
  final String? artworkId;
  final String? artworkName;
  final String? villageName;
  final String? tensil;
  final String? address;

  const ExecutionDisplayPage({
    super.key,
    required this.changeLanguage,
    this.pointerLat,
    this.pointerLng,
    this.pointerTitle,
    this.planCode,
    this.villageCode,
    this.serverId,
    this.artworkId,
    this.artworkName,
    this.villageName,
    this.tensil,
    this.address,
  });

  @override
  State<ExecutionDisplayPage> createState() => _ExecutionDisplayPageState();
}

class _ExecutionDisplayPageState extends State<ExecutionDisplayPage> {
  late final WebViewController _webViewController;
  Position? currentPosition;
  bool isLoadingLocation = false;
  bool isLoadingWebView = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initWebView();
  }

  void _initWebView() {
    // Use pointer coordinates
    double lat = widget.pointerLat ?? 0.0;
    double lng = widget.pointerLng ?? 0.0;

    // Create Google Maps Street View URL (same as Execution360ViewScreen)
    String streetViewUrl = "https://maps.google.com/maps?q=&layer=c&cbll=${lat},${lng}";

    print("📍 Loading 360 View for pointer");
    print("🔗 URL: $streetViewUrl");

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              isLoadingWebView = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith("intent://")) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(streetViewUrl));

    // Add a timer to hide loading if it takes too long
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && isLoadingWebView) {
        setState(() {
          isLoadingWebView = false;
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: "Please enable location");
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = position;
        isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Widget _build360View() {
    double lat = widget.pointerLat ?? 0.0;
    double lng = widget.pointerLng ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.streetview, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.pointerTitle ?? "360° Street View",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Fullscreen button
                GestureDetector(
                  onTap: _openFullscreen360View,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // WebView for 360 Street View (same as Execution360ViewScreen)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (isLoadingWebView)
                  Container(
                    color: Colors.white,
                    child: const Center(
                      child: CanImageLoader(
                        spinnerSize: 52,
                        showBrand: true,
                        message: "Loading 360° Street View...",
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Footer with location info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.villageName ?? widget.pointerTitle ?? "Street View Location",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  "Google Maps",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen360View() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Execution360ViewScreen(
          latitude: widget.pointerLat ?? 0.0,
          longitude: widget.pointerLng ?? 0.0,
          title: widget.pointerTitle ?? "360° Street View",
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 20,
      ),
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsConst.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: isLoadingLocation ? null : _onContinue,
        child: isLoadingLocation
            ? const CanImageSpinner(
                size: 22,
                primaryColor: Colors.white70,
                accentColor: Colors.white,
              )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_circle_right, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Continue",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    String finalPlanCode = widget.planCode ?? "";
    String finalVillageCode = widget.villageCode ?? "";
    String finalServerId = widget.serverId ?? "";
    String finalArtworkId = widget.artworkId ?? "";
    String finalArtworkName = widget.artworkName ?? "";
    String finalVillageName = widget.villageName ?? "";
    String finalTensil = widget.tensil ?? "";
    String finalAddress = widget.address ?? "";
    double finalLatitude = widget.pointerLat ?? 0.0;
    double finalLongitude = widget.pointerLng ?? 0.0;

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => UploadSeePlanScreen(
    //       villageName: finalVillageName,
    //       brand: finalArtworkName,
    //       width: "",
    //       height: "",
    //       planCode: finalPlanCode,
    //       tensil: finalTensil,
    //       ServerID: finalServerId,
    //       VillageCode: finalVillageCode,
    //       Address: finalAddress,
    //       artworkId: finalArtworkId,
    //       latitude: finalLatitude,
    //       longitude: finalLongitude,
    //       changeLanguage: widget.changeLanguage,
    //     ),
    //   ),
    // );
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
    String title = widget.pointerTitle ?? widget.artworkName ?? "360° Street View";

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: CommonAppBar(
            title: title,
            actions: [
              IconButton(
                icon: const Icon(Icons.streetview_rounded, color: Colors.white, size: 24),
                tooltip: '360° View',
                onPressed: () {
                  if (_currentPosition == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Execution360ViewScreen(
                        latitude: _currentPosition!.latitude,
                        longitude: _currentPosition!.longitude,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Location Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.villageName ?? widget.pointerTitle ?? "Location",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Tap any pointer to view details",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ColorsConst.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Street View",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 360 View - Main Content (same as Execution360ViewScreen)
                      _build360View(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep this class for fullscreen view
class Execution360ViewScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;

  const Execution360ViewScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title = "360° Street View",
  });

  @override
  State<Execution360ViewScreen> createState() => _Execution360ViewScreenState();
}

class _Execution360ViewScreenState extends State<Execution360ViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    String url = "https://maps.google.com/maps?q=&layer=c&cbll=${widget.latitude},${widget.longitude}";

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith("intent://")) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.title,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CanImageLoader(
                  spinnerSize: 52,
                  showBrand: true,
                  message: "Loading 360° Street View...",
                ),
              ),
            ),
        ],
      ),
    );
  }
}