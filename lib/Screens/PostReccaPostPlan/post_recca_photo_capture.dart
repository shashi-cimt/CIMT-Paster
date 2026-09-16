import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../PostReccaPostPlan/post_recca_image_upload.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/can_image_loader.dart';
import 'post_recca_see_plans.dart';

class PhotoDisplayScreen extends StatefulWidget {
  String? projectID;
  String? VillageName;
  String? width;
  String? height;
  String? printNo;
  String? frontView;
  String? surroundingView;
  String? artworkName;
  String? printId;
  String? planCode;
  String? villageCode;
  String? tensil;
  String? markerLatitude;  // Add marker coordinates
  String? markerLongitude; // Add marker coordinates
  final Function(String) changeLanguage;

  PhotoDisplayScreen({
    super.key,
    required this.projectID,
    required this.VillageName,
    required this.width,
    required this.height,
    required this.printNo,
    required this.frontView,
    required this.surroundingView,
    required this.artworkName,
    required this.printId,
    required this.villageCode,
    required this.planCode,
    required this.tensil,
    required this.markerLatitude,  // Optional parameters
    required this.markerLongitude, // Optional parameters
    required this.changeLanguage
  });

  @override
  _PhotoDisplayScreenState createState() => _PhotoDisplayScreenState();
}

class _PhotoDisplayScreenState extends State<PhotoDisplayScreen> {
  Position? currentPosition;
  bool isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
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
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        currentPosition = position;
        isLoadingLocation = false;
      });
    } catch (e) {
      print('Error fetching current location: $e');
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Widget _buildPhotoSection(String title, String URL) {
    return GestureDetector(
      onTap: () {
        _showZoomableImage(context, URL);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 150,
                color: Colors.grey[300],
                child: Image.network(
                  URL,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CanImageSpinner(size: 32));
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: "Roboto",
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showZoomableImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewGallery.builder(
          itemCount: 1,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered,
            );
          },
          scrollPhysics: BouncingScrollPhysics(),
          backgroundDecoration: BoxDecoration(color: Colors.black),
          pageController: PageController(),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 10),
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoadingLocation ? null : () {
          _onContinue();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Font.primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Font.primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: isLoadingLocation
            ? const CanImageSpinner(
                size: 20,
                primaryColor: Colors.white70,
                accentColor: Colors.white,
              )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_circle_right_sharp, size: 20),
            SizedBox(width: 8),
            Text(
              S.of(context).continueBtn,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: "Roboto",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    // Validate distance before continuing
    if (widget.markerLatitude == null || widget.markerLongitude == null) {
      _showErrorDialog(
          title: S.of(context).locationError,
          message: S.of(context).markerLocationNotAvailable
      );
      return;
    }

    if (currentPosition == null) {
      _showErrorDialog(
          title: S.of(context).locationError,
          message: S.of(context).unableYourCurrentLocation
      );
      return;
    }

    try {
      double markerLat = double.parse(widget.markerLatitude!);
      double markerLng = double.parse(widget.markerLongitude!);

      // Calculate distance in meters
      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        markerLat,
        markerLng,
      );

      print('Distance to marker: ${distanceInMeters.toStringAsFixed(2)} meters');

      // Check if distance is greater than 50 meters
      if (distanceInMeters > 50) {
        _showErrorDialog(
          title: S.of(context).distanceError,
          message: "${S.of(context).youhave} ${distanceInMeters.toStringAsFixed(2)} ${S.of(context).metersAwayMarkerLocationContinue}",
        );
        return;
      }

      // If within 50 meters, proceed to next screen
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SUUploadSeePlanScreen(
                villageName: widget.VillageName,
                brand: widget.artworkName,
                width: widget.width,
                height: widget.height,
                printNo: widget.printNo,
                projectID: widget.projectID,
                printId: widget.printId,
                villageCode: widget.villageCode,
                planCode: widget.planCode,
                tensil: widget.tensil,
                changeLanguage: widget.changeLanguage,
              )
          )
      );

    } catch (e) {
      print('Error validating distance: $e');
      _showErrorDialog(
          title: S.of(context).validationError,
          message: S.of(context).unableValidateLocation
      );
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: "Roboto",
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: "Roboto",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                S.of(context).ok,
                style: TextStyle(
                  color: Font.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Roboto",
                ),
              ),
            ),
          ],
        );
      },
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
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: const CommonAppBar(
            title: "Photo Capture",
            actions: [CommonHomeButton()],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      _buildPhotoSection(S.of(context).nearView, widget.frontView.toString()),
                      SizedBox(height: 20),
                      _buildPhotoSection(S.of(context).surroundingview, widget.surroundingView.toString()),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}