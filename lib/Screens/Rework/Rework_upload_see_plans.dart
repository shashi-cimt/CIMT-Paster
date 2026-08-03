import 'dart:async';
import 'dart:convert';
import 'package:canimage/Screens/Rework/rework_see_plans.dart';
import 'dart:io';
import 'package:canimage/Repository/remarks_repository.dart';
import '../Common/camera_capture_screen.dart';
import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/image_compression_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Hive_Database/execution_image_upload_db.dart';
import '../../Hive_Database/rework_image_draft_db.dart';
import '../../Repository/execution_balance_count_change_repository.dart';
import '../../Repository/execution_image_upload_repository.dart';
import '../../Repository/rework_image_draft_repository.dart';
import '../../Repository/rework_balance_count_change_repository.dart';
import '../../Repository/upload_count_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/crash_manager.dart';
import '../../utils/fonts.dart';
import '../../utils/uid_file_helper.dart';



class ReworkUploadSeePlans extends StatefulWidget {
  String? projectID;
  String? villageName;
  String? brand;
  String? width;
  String? height;
  String? printNo;
  String? printId;
  String? planCode;
  String? villageCode;
  String? tensil;
  String ServerID;
  String VillageCode;
  String Address;
  String artworkId;
  double? latitude;
  double? longitude;
  final Function(String) changeLanguage;

  ReworkUploadSeePlans({
    super.key,
    required this.projectID,
    required this.villageName,
    required this.brand,
    required this.width,
    required this.height,
    required this.printNo,
    required this.printId,
    required this.villageCode,
    required this.planCode,
    required this.tensil,
    required this.ServerID,
    required this.VillageCode,
    required this.Address,
    required this.artworkId,
    this.latitude,
    this.longitude,
    required this.changeLanguage
  });

  @override
  State<ReworkUploadSeePlans> createState() => _ReworkUploadSeePlansState();
}

class _ReworkUploadSeePlansState extends State<ReworkUploadSeePlans> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<ImageData> images = List.generate(7, (index) => ImageData());
  List<bool> _isPickerActiveList = List.generate(7, (index) => false);
  bool isPickingImage = false;
  bool _isProcessingRecoveredImage = false;
  TextEditingController printNoController1 = TextEditingController();
  TextEditingController printNoController2 = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isRefreshing = false;
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();

  // Initialize ImagePicker instance
  // List<CameraDescription>? cameras;
  final ImagePicker _picker = ImagePicker();
  int? _currentImageIndex;

  // Persists already-captured images to Hive as soon as each one is taken,
  // keyed per rework item, so closing this screen (or a camera crash) before
  // Submit does not lose captures already made.
  final ReworkImageDraftHiveRepository _draftRepository =
      ReworkImageDraftHiveRepository();
  late final String _draftKey;

  String _buildDraftKey() {
    return "REWORK_${widget.ServerID}_${widget.VillageCode}_${widget.planCode}_${widget.printId ?? ''}";
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _draftKey = _buildDraftKey();
    _recoverAfterRestart();
  }

  Future<void> _recoverAfterRestart() async {
    // Order matters: recover the one photo that was mid-flight when the
    // process died, THEN layer the already-saved draft on top.
    await _checkForLostCameraData();
    await _restoreDraftIfNeeded();
  }

  /// Recovers a photo that was captured right before Android (commonly MIUI,
  /// due to its aggressive background process killing) killed the app
  /// process while the native camera app had focus. Without this, that one
  /// in-flight photo would be silently lost even though the camera itself
  /// succeeded — everything captured before it is already safe in the Hive
  /// draft.
  Future<void> _checkForLostCameraData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) {
        if (response.exception != null) {
          await CrashReportManager.storeCrashReport(
            error: "retrieveLostData exception: ${response.exception}",
            stackTrace: StackTrace.current.toString(),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt('current_image_index');
      if (savedIndex == null || savedIndex < 0 || savedIndex >= images.length) {
        return;
      }

      final file = File(response.file!.path);
      if (!await file.exists()) return;

      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        );
      } catch (_) {
        // Best effort only; the location captured before the crash is gone.
      }

      if (mounted) {
        setState(() {
          images[savedIndex].imagePath = file.path;
          if (currentPosition != null) {
            images[savedIndex].lat = currentPosition.latitude;
            images[savedIndex].long = currentPosition.longitude;
          }
        });
      }

      await _saveDraftToHive();
      await _clearSavedState();

      Fluttertoast.showToast(
        msg: "Recovered image ${savedIndex + 1} after interruption",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    } catch (e) {
      await CrashReportManager.storeCrashReport(
        error: "retrieveLostData error: $e",
        stackTrace: StackTrace.current.toString(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode1.dispose();
    _focusNode2.dispose();
    printNoController1.dispose();
    printNoController2.dispose();
    _clearSavedState();
    super.dispose();
  }

  /// Restores any images captured on a previous visit to this screen that
  /// were never submitted, so re-opening it (or recovering from a crash)
  /// does not show a blank form.
  Future<void> _restoreDraftIfNeeded() async {
    final draft = await _draftRepository.getDraft(_draftKey);
    if (draft == null || !draft.hasAnyImage) return;

    final paths = draft.imagePathsBySlot;
    final lats = draft.latitudesBySlot;
    final longs = draft.longitudesBySlot;

    bool restoredAny = false;
    for (var i = 0; i < images.length && i < paths.length; i++) {
      final path = paths[i];
      if (path != null && await File(path).exists()) {
        images[i].imagePath = path;
        images[i].lat = lats[i] ?? 0.0;
        images[i].long = longs[i] ?? 0.0;
        restoredAny = true;
      }
    }

    if (draft.printNumber1 != null && draft.printNumber1!.isNotEmpty) {
      printNoController1.text = draft.printNumber1!;
    }
    if (draft.printNumber2 != null && draft.printNumber2!.isNotEmpty) {
      printNoController2.text = draft.printNumber2!;
    }

    if (restoredAny && mounted) {
      setState(() {});
      Fluttertoast.showToast(
        msg: "Restored previously captured images",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    }
  }

  /// Persists the current in-memory capture state (all 7 slots + print
  /// numbers) to Hive so it survives the screen being closed or a crash.
  Future<void> _saveDraftToHive() async {
    final draft = ReworkImageDraft(
      draftKey: _draftKey,
      ServerPlanId: widget.ServerID,
      PlanCode: widget.planCode,
      VillageCode: widget.VillageCode,
      printId: widget.printId,
      printNumber1: printNoController1.text,
      printNumber2: printNoController2.text,
    );
    for (var i = 0; i < images.length; i++) {
      draft.setSlot(i, images[i].imagePath, images[i].lat, images[i].long);
    }
    await _draftRepository.saveDraft(draft);
  }

  void _removeFocus() {
    _focusNode1.unfocus();
    _focusNode2.unfocus();
    FocusScope.of(context).unfocus();
  }

  @override
  bool get wantKeepAlive => true; // Keeps state alive

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      // Save state when app goes to background
        if (isPickingImage) {
          _saveCurrentState();
        }
        break;

      case AppLifecycleState.resumed:
      // Restore state when app comes back
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FocusScope.of(context).unfocus();
            _checkAndRestoreState();
          }
        });
        break;

      case AppLifecycleState.detached:
        _clearSavedState();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }
  Future<void> _checkAndRestoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final wasPicking = prefs.getBool('is_picking_image') ?? false;

    if (wasPicking) {
      await _restoreStateIfNeeded();
      // Clear the picking flag
      await prefs.setBool('is_picking_image', false);
    }
  }

  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();

    // Only save if we're actively picking an image
    if (_currentImageIndex != null && isPickingImage) {
      await prefs.setBool('is_picking_image', true);
      await prefs.setInt('current_image_index', _currentImageIndex!);

      // ✅ ONLY save the current image being captured (not all images)
      final currentImage = images[_currentImageIndex!];
      if (currentImage.imagePath != null) {
        await prefs.setString('current_image_path', currentImage.imagePath!);
        await prefs.setDouble('current_image_lat', currentImage.lat);
        await prefs.setDouble('current_image_long', currentImage.long);
      }
    }
  }

  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_picking_image');
    await prefs.remove('current_image_index');
    await prefs.remove('current_image_path');
    await prefs.remove('current_image_lat');
    await prefs.remove('current_image_long');
  }

  Future<void> _restoreStateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    final savedIndex = prefs.getInt('current_image_index');
    final savedImagePath = prefs.getString('current_image_path');

    // Only restore if we have a saved index and path
    if (savedIndex != null && savedImagePath != null) {
      if (await File(savedImagePath).exists()) {
        setState(() {
          images[savedIndex].imagePath = savedImagePath;
          images[savedIndex].lat = prefs.getDouble('current_image_lat') ?? 0.0;
          images[savedIndex].long = prefs.getDouble('current_image_long') ?? 0.0;
        });

        // print("DEBUG: Restored only image at index $savedIndex");

        Fluttertoast.showToast(
          msg: "Restored interrupted image capture",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
        );
      }
    }
  }

  // New image picker implementation using the plugin

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Raw "deviceUid|userId" content of this device's UID.txt, for tagging
  /// submission log entries with who/what device submitted them.
  Future<String?> _getRawUidForLog() async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return null;
      File uidFile = File('${externalDir.path}/CIMTDWP/Appfiles/UID.txt');
      return await UidFileHelper.readRawUidContent(uidFile);
    } catch (e) {
      return null;
    }
  }


  Future<void> _pickImage(int index) async {
    if (isPickingImage) {
      return;
    }

    try {
      setState(() {
        isPickingImage = true;
        _isPickerActiveList[index] = true;
        _currentImageIndex = index;
      });

      // Get current location first
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: S.of(context).unablePleaseEnableGPS,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          isPickingImage = false;
          _isPickerActiveList[index] = false;
        });
        return;
      }

      // ========== DISTANCE VALIDATION FOR INDEX 0 ==========
      if (index == 0 && widget.latitude != null && widget.longitude != null) {
        double distance = _calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          widget.latitude!,
          widget.longitude!,
        );

        if (distance > 50) {
          setState(() {
            isPickingImage = false;
            _isPickerActiveList[index] = false;
          });

          await _showDistanceDialog(
            context,
            distance,
            "Image 1",
            "The first image must be captured within 50 meters of the selected location.",
            showRefreshOption: true,
          );
          return;
        }
      }

      // ========== DISTANCE VALIDATION FOR INDEX 2 (Image 3) ==========
      if (index == 2 && images[0].imagePath != null) {
        double distanceFromIndex0 = _calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          images[0].lat,
          images[0].long,
        );

        if (distanceFromIndex0 > 50) {
          setState(() {
            isPickingImage = false;
            _isPickerActiveList[index] = false;
          });

          await _showDistanceDialog(
            context,
            distanceFromIndex0,
            "Image 3",
            "Image 3 must be captured within 50 meters of Image 1 location.",
          );
          return;
        }
      }

      // ========== DISTANCE VALIDATION FOR INDEX 6 (Image 7) ==========
      if (index == 6 && images[0].imagePath != null) {
        double distanceFromIndex0 = _calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          images[0].lat,
          images[0].long,
        );

        if (distanceFromIndex0 > 50) {
          setState(() {
            isPickingImage = false;
            _isPickerActiveList[index] = false;
          });

          await _showDistanceDialog(
            context,
            distanceFromIndex0,
            "Image 7",
            "Image 7 must be captured within 50 meters of Image 1 location.",
          );
          return;
        }
      }

      // ========== REQUEST CAMERA PERMISSIONS ==========
      try {
        await _requestCameraPermissions();
      } catch (e) {
        setState(() {
          isPickingImage = false;
          _isPickerActiveList[index] = false;
        });

        await _showErrorDialogWithRetry(
          context,
          'Camera Permission Required',
          'Camera permission is needed to capture images. Please enable it in settings.',
          index,
        );
        return;
      }

      await _saveCurrentState();

      // ========== OPEN IN-APP CAMERA WITH TIMEOUT ==========
      String? capturedImagePath;

      try {
        capturedImagePath = await CameraCaptureScreen.capture(context).timeout(
          Duration(seconds: 120),
          onTimeout: () {
            throw TimeoutException('Camera operation timed out');
          },
        );
      } on TimeoutException catch (e) {
        await _clearSavedState();

        await CrashReportManager.storeCrashReport(
          error: "Camera timeout: $e",
          stackTrace: StackTrace.current.toString(),
        );

        await _showErrorDialogWithRetry(
          context,
          'Camera Timeout',
          'Camera took too long to respond. Please try again.',
          index,
        );
        return;

      } catch (e) {
        // Catch any other unexpected errors
        await _clearSavedState();

        await CrashReportManager.storeCrashReport(
          error: "Camera unexpected error: $e",
          stackTrace: StackTrace.current.toString(),
        );

        await _showErrorDialogWithRetry(
          context,
          'Unexpected Error',
          'An error occurred while opening the camera. Please try again.',
          index,
        );
        return;
      }

      // Process the captured image
      if (capturedImagePath != null) {
        try {
          // Verify file exists
          final file = File(capturedImagePath);
          if (!await file.exists()) {
            throw Exception('Captured image file not found');
          }

          // Verify file is readable
          await file.length();

          await CrashReportManager.logDWPTrace(
            'returneduri uri = $capturedImagePath',
          );

          if (mounted) {
            setState(() {
              images[index].imagePath = capturedImagePath;
              images[index].lat = currentPosition!.latitude;
              images[index].long = currentPosition.longitude;
            });
          }

          await _clearSavedState();

          // Persist immediately so this capture is not lost if the user
          // closes the screen (or the camera crashes) before submitting.
          await _saveDraftToHive();

          await CrashReportManager.logDWPTrace('showImage start');

          Fluttertoast.showToast(
            msg: S.of(context).imageCaptured,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } catch (e) {
          await _clearSavedState();

          await CrashReportManager.storeCrashReport(
            error: "Image file processing error: $e",
            stackTrace: StackTrace.current.toString(),
          );
          await CrashReportManager.logDWPTrace('Image file processing error: $e');

          await _showErrorDialogWithRetry(
            context,
            'Image Processing Error',
            'Failed to process captured image. Please try again.',
            index,
          );
        }
      } else {
        // User cancelled
        await _clearSavedState();
      }

    } catch (e) {
      // Final catch-all for any unexpected errors
      await _clearSavedState();
      FocusScope.of(context).unfocus();

      await CrashReportManager.storeCrashReport(
        error: "Image picker critical error: $e",
        stackTrace: StackTrace.current.toString(),
      );
      await CrashReportManager.logDWPTrace('Image picker critical error: $e');

      if (mounted) {
        await _showErrorDialogWithRetry(
          context,
          'Critical Error',
          'A critical error occurred. The app will return to the previous screen.',
          index,
          isCritical: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPickingImage = false;
          _isPickerActiveList[index] = false;
        });
        FocusScope.of(context).unfocus();
      }
    }
  }

// Add this new method to show error dialog with retry option
  Future<void> _showErrorDialogWithRetry(
      BuildContext context,
      String title,
      String message,
      int imageIndex, {
        bool isCritical = false,
      }) async {
    if (!mounted) return;

    bool? shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isCritical ? Icons.error : Icons.warning_amber_rounded,
                color: isCritical ? Colors.red : Colors.orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Roboto",
                    color: isCritical ? Colors.red : Colors.orange,
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
                message,
                style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
              ),
              if (!isCritical) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can retry capturing the image or go back.',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: "Roboto",
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (isCritical) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('Go Back', style: TextStyle(fontFamily: "Roboto")),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Font.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  'Go Back',
                  style: TextStyle(fontFamily: "Roboto", color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                icon: Icon(Icons.refresh, size: 18),
                label: Text(
                  'Retry',
                  style: TextStyle(fontFamily: "Roboto"),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Font.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        );
      },
    );

    if (isCritical || shouldRetry == false) {
      // Go back to previous screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReworkScreen(changeLanguage: widget.changeLanguage),
          ),
        );
      }
    } else if (shouldRetry == true) {
      // Retry capturing the image
      await Future.delayed(Duration(milliseconds: 300));
      if (mounted) {
        _pickImage(imageIndex);
      }
    }
  }

  // Future<void> _pickImage(int index) async {
  //   if (isPickingImage) {
  //     // print("Image picking already in progress");
  //     return;
  //   }
  //
  //   try {
  //     setState(() {
  //       isPickingImage = true;
  //       _isPickerActiveList[index] = true;
  //       _currentImageIndex = index;
  //     });
  //
  //     // Save state before opening picker
  //     // await _saveCurrentState();
  //
  //     // Get current location first
  //     Position? currentPosition;
  //     try {
  //       currentPosition = await Geolocator.getCurrentPosition(
  //         desiredAccuracy: LocationAccuracy.best,
  //         timeLimit: Duration(seconds: 10),
  //       );
  //     } catch (e) {
  //       Fluttertoast.showToast(
  //         msg: S.of(context).unablePleaseEnableGPS,
  //         toastLength: Toast.LENGTH_LONG,
  //         gravity: ToastGravity.CENTER,
  //         backgroundColor: Colors.red,
  //         textColor: Colors.white,
  //       );
  //       setState(() {
  //         isPickingImage = false;
  //         _isPickerActiveList[index] = false;
  //       });
  //       return;
  //     }
  //
  //     // ========== DISTANCE VALIDATION FOR INDEX 0 ==========
  //     if (index == 0 && widget.latitude != null && widget.longitude != null) {
  //       double distance = _calculateDistance(
  //         currentPosition.latitude,
  //         currentPosition.longitude,
  //         widget.latitude!,
  //         widget.longitude!,
  //       );
  //
  //       if (distance > 50) {
  //         setState(() {
  //           isPickingImage = false;
  //           _isPickerActiveList[index] = false;
  //         });
  //
  //         await _showDistanceDialog(
  //           context,
  //           distance,
  //           "Image 1",
  //           "The first image must be captured within 50 meters of the selected location.",
  //           showRefreshOption: true,
  //         );
  //         return;
  //       }
  //     }
  //
  //     // ========== DISTANCE VALIDATION FOR INDEX 2 (Image 3) ==========
  //     if (index == 2 && images[0].imagePath != null) {
  //       double distanceFromIndex0 = _calculateDistance(
  //         currentPosition.latitude,
  //         currentPosition.longitude,
  //         images[0].lat,
  //         images[0].long,
  //       );
  //
  //       if (distanceFromIndex0 > 50) {
  //         setState(() {
  //           isPickingImage = false;
  //           _isPickerActiveList[index] = false;
  //         });
  //
  //         await _showDistanceDialog(
  //           context,
  //           distanceFromIndex0,
  //           "Image 3",
  //           "Image 3 must be captured within 50 meters of Image 1 location.",
  //         );
  //         return;
  //       }
  //     }
  //
  //     // ========== DISTANCE VALIDATION FOR INDEX 6 (Image 7) ==========
  //     if (index == 6 && images[0].imagePath != null) {
  //       double distanceFromIndex0 = _calculateDistance(
  //         currentPosition.latitude,
  //         currentPosition.longitude,
  //         images[0].lat,
  //         images[0].long,
  //       );
  //
  //       if (distanceFromIndex0 > 50) {
  //         setState(() {
  //           isPickingImage = false;
  //           _isPickerActiveList[index] = false;
  //         });
  //
  //         await _showDistanceDialog(
  //           context,
  //           distanceFromIndex0,
  //           "Image 7",
  //           "Image 7 must be captured within 50 meters of Image 1 location.",
  //         );
  //         return;
  //       }
  //     }
  //
  //
  //
  //
  //     // ========== REQUEST CAMERA PERMISSIONS ==========
  //     await _requestCameraPermissions();
  //
  //     await _saveCurrentState();
  //
  //     // ========== OPEN CAMERA USING IMAGE_PICKER ==========
  //     final XFile? pickedFile = await _picker.pickImage(
  //       source: ImageSource.camera,
  //       imageQuality: 90,
  //       maxWidth: 1920,
  //       maxHeight: 1920,
  //       preferredCameraDevice: CameraDevice.rear,
  //     );
  //
  //     if (pickedFile != null) {
  //       // Store the current location with the image
  //       if (mounted) {
  //         setState(() {
  //           images[index].imagePath = pickedFile.path;
  //           images[index].lat = currentPosition!.latitude;
  //           images[index].long = currentPosition!.longitude;
  //         });
  //       }
  //
  //       // Clear saved state after successful capture
  //       await _clearSavedState();
  //
  //       Fluttertoast.showToast(
  //         msg: S.of(context).imageCaptured,
  //         toastLength: Toast.LENGTH_SHORT,
  //         gravity: ToastGravity.BOTTOM,
  //         backgroundColor: Colors.green,
  //         textColor: Colors.white,
  //       );
  //     } else {
  //       await _clearSavedState();
  //       // User cancelled
  //       // print("User cancelled image picking");
  //     }
  //
  //   } catch (e) {
  //     // print("Error in _pickImage: $e");
  //     await _clearSavedState();
  //     FocusScope.of(context).unfocus();
  //
  //     await CrashReportManager.storeCrashReport(
  //       error: "Camera error: $e",
  //       stackTrace: StackTrace.current.toString(),
  //     );
  //
  //     if (mounted) {
  //       Fluttertoast.showToast(
  //         msg: "Error opening camera. Please try again.",
  //         toastLength: Toast.LENGTH_SHORT,
  //         gravity: ToastGravity.BOTTOM,
  //         backgroundColor: Colors.red,
  //         textColor: Colors.white,
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         isPickingImage = false;
  //         _isPickerActiveList[index] = false;
  //       });
  //       FocusScope.of(context).unfocus();
  //     }
  //   }
  // }


  Future<void> _showDistanceDialog(
      BuildContext context,
      double distance,
      String imageLabel,
      String requirement,
      {bool showRefreshOption = false}
      ) async {
    Fluttertoast.showToast(
      msg: "You are ${distance.toStringAsFixed(0)}m away. Please move closer (within 50m).",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );

    bool? shouldRefresh = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Too Far from $imageLabel Location',
                  style: TextStyle(fontSize: 16, fontFamily: "Roboto"),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are ${distance.toStringAsFixed(0)} meters away.',
                style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠️ $requirement',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (showRefreshOption) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Stay Here',
                  style: TextStyle(fontFamily: "Roboto", color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icon(Icons.refresh, size: 18),
                label: Text(
                  'Refresh Location',
                  style: TextStyle(fontFamily: "Roboto"),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Font.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Understood',
                  style: TextStyle(fontFamily: "Roboto"),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Font.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        );
      },
    );

    if (showRefreshOption && shouldRefresh == true && mounted) {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => MapScreen(
      //       planCode: widget.planCode,
      //       VillageCode: widget.VillageCode,
      //       ServerID: widget.ServerID,
      //       changeLanguage: widget.changeLanguage,
      //       height: widget.height,
      //       width: widget.width,
      //       villageName: widget.villageName,
      //       brand: widget.brand,
      //       tensil: widget.tensil,
      //       artworkId: widget.artworkId,
      //     ),
      //   ),
      // );
    }
  }
  // Simplified recovery method (less needed with image_picker plugin)


  // Request camera permissions
  Future<void> _requestCameraPermissions() async {
    final permissions = await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();

    if (permissions[Permission.camera] != PermissionStatus.granted) {
      throw PlatformException(
        code: "CAMERA_PERMISSION_DENIED",
        message: S.of(context).cameraPermission,
      );
    }
  }

  // Process image from file path

  void _removeImage(int index) {
    if (_isPickerActiveList[index]) return;
    setState(() {
      images[index].imagePath = null;
      images[index].lat = 0.0;
      images[index].long = 0.0;
    });
    _saveDraftToHive();
  }

  Future<String> _storeImageInInternalDocuments(String imagePath) async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw 'Unable to access external storage directory';
      }

      Directory appDocDir = Directory('${externalDir.path}/CIMTDWP');
      if (!await appDocDir.exists()) {
        await appDocDir.create(recursive: true);
      }

      Directory dwPaintingDir = Directory(
          '${appDocDir.path}/Execution/Plans/${widget.ServerID}/${widget.planCode}/${widget.VillageCode}/${printNoController1.text}${printNoController2.text}/Images'
      );

      if (!await dwPaintingDir.exists()) {
        await dwPaintingDir.create(recursive: true);
      }

      File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw 'Source image file does not exist: $imagePath';
      }

      var imageBytes = await imageFile.readAsBytes();

      final result = await ImageCompressionHelper.compressToTargetSize(
        imageBytes,
        targetMinKB: 100,
        targetMaxKB: 150,
      );

      String imageName = 'Img_${DateTime.now().toIso8601String().replaceAll(RegExp('[^0-9]'), '')}.jpg';
      String imagePathInStorage = '${dwPaintingDir.path}/$imageName';

      File compressedImage = File(imagePathInStorage);
      await compressedImage.writeAsBytes(result);

      if (!await compressedImage.exists()) {
        throw 'Failed to write compressed image to storage';
      }

      return imagePathInStorage;

    } catch (e) {
      throw 'Failed to store image: $e';
    }
  }




  bool get _isAnyPickerActive =>
      _isPickerActiveList.any((isActive) => isActive) ||
          _isProcessingRecoveredImage;

  Future<bool> _onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReworkScreen(changeLanguage: widget.changeLanguage,)),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Font.primaryColor,
            title: Text(
              S.of(context).printDetails,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage,)),
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
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Enhanced Header Card
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EnhancedMetaRow(label: S.of(context).villageNameMap, value: widget.villageName ?? ''),
                        _EnhancedMetaRow(label: S.of(context).brand, value: widget.brand ?? ''),
                        _EnhancedMetaRow(
                          // label: S.of(context).villageNameMap,
                          label:  S.of(context).printID,
                          value: " (${widget.printId ?? ''})",
                        ),
                        _EnhancedMetaRowWithInputs(
                          label: S.of(context).size,
                          value: widget.width.toString(),
                          secondValue: widget.height.toString(),
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                S.of(context).printNo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: neutralDarkColor,
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ),
                            Container(
                                width: 100,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: TextField(
                                  keyboardType: TextInputType.text,
                                  controller: printNoController1,
                                  focusNode: _focusNode1,
                                  textAlign: TextAlign.center,
                                  onEditingComplete: _dismissKeyboard,
                                  onSubmitted: (_) => _dismissKeyboard(),
                                  onTapOutside: (_) => _dismissKeyboard(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: neutralDarkColor,
                                    fontFamily: "Roboto",
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]")),
                                    UpperCaseTextInputFormatter(),
                                  ],
                                )
                            ),
                            SizedBox(width: 4),
                            Text('/', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                            SizedBox(width: 4),
                            Container(
                              width: 100,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                controller: printNoController2,
                                textAlign: TextAlign.center,
                                focusNode: _focusNode2,
                                onEditingComplete: _dismissKeyboard,       // <— hides cursor & keyboard
                                onSubmitted: (_) => _dismissKeyboard(),    // <— Android/Hardware enter
                                onTapOutside: (_) => _dismissKeyboard(),   // <— taps outside field
                                style: TextStyle(
                                  fontSize: 12,
                                  color: neutralDarkColor,
                                  fontFamily: "Roboto",
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                // Images Grid Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library, color: Font.primaryColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              S.of(context).uploadImages,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: neutralDarkColor,
                                fontFamily: "Roboto",
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${images.where((img) => img.imagePath != null).length}/7',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Font.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          return _buildEnhancedImageCard(index);
                        },
                        shrinkWrap: true,
                      ),
                    ],
                  ),
                ),

                // Submit Button
                Container(
                  margin: const EdgeInsets.only(bottom: 10, top: 10),
                  width: 200,
                  height: 50,
                  child: GestureDetector(
                    onTap: (isRefreshing || _isAnyPickerActive) ? null : _submitDetails,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: (isRefreshing || _isAnyPickerActive) ? Colors.grey : Font.primaryColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isRefreshing) ...[
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                          ] else if (_isAnyPickerActive) ...[
                            Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                          ] else ...[
                            Icon(Icons.cloud_upload_outlined, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                          ],

                          Text(
                            isRefreshing ? "Saving..." :
                            S.of(context).submitDetails,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: "Roboto",
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildEnhancedImageCard(int index) {
    final hasImage = images[index].imagePath != null;
    final isThisCardActive = _isPickerActiveList[index];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickImage(index),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasImage ? Colors.transparent :
                    isThisCardActive ? Colors.blue : Colors.grey[300]!,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: hasImage ? _buildImageDisplay(index) : _buildPlaceholder(index),
              ),
            ),
          ),

          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasImage ? primaryColor.withOpacity(0.1) :
              isThisCardActive ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasImage ? primaryColor :
                    isThisCardActive ? Colors.blue : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isThisCardActive)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                else
                  Icon(
                    hasImage ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: hasImage ? Colors.green : Colors.grey[400],
                    size: 16,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay(int index) {
    final isThisCardActive = _isPickerActiveList[index];

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: FutureBuilder<bool>(
              future: File(images[index].imagePath!).exists(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Image.file(
                    File(images[index].imagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    // cacheWidth: 200,
                    // cacheHeight: 200,
                    errorBuilder: (context, error, stackTrace) {
                      // print("Image display error: $error");
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      );
                    },
                  );
                }
                return Container(
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: isThisCardActive ? null : () => _removeImage(index),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isThisCardActive ? Colors.grey : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
        // Edit overlay
        if (!isThisCardActive)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.3),
              ),
              child: Center(child: Icon(Icons.edit, color: Colors.white, size: 24)),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(int index) {
    final isThisCardActive = _isPickerActiveList[index];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isThisCardActive ? primaryColor : accentColor).withOpacity(0.1),
            (isThisCardActive ? primaryColor : primaryLightColor).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isThisCardActive ? Colors.blue : primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: isThisCardActive
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 2,
              ),
            )
                : Icon(Icons.add_a_photo, size: 24, color: Font.primaryColor),
          ),
          SizedBox(height: 8),
          Text(
            isThisCardActive ? S.of(context).openingCamera : S.of(context).addPhoto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isThisCardActive ? Font.primaryColor : Font.primaryColor,
              fontFamily: "Roboto",
            ),
          ),
        ],
      ),
    );
  }


  Future<bool> hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 3));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }



  void _submitDetails() async {
    setState(() {
      isRefreshing = true;
    });

    String printNumber1 = printNoController1.text.trim();
    String printNumber2 = printNoController2.text.trim();

    if (printNumber1.isEmpty || printNumber2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).pleaseEnterPrintNumber),
            backgroundColor: Colors.red,
          )
      );
      setState(() {
        isRefreshing = false;
      });
      return;
    }

    String fullPrintNumber =
    '${printNumber1.trim()}${printNumber2.trim()}'.toUpperCase();

    final uploadedCount = images.where((img) => img.imagePath != null).length;
    if (uploadedCount != 7) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context).imageVal),
              backgroundColor: Colors.red
          )
      );
      setState(() {
        isRefreshing = false;
      });
      return;
    }

    Position? submitPosition;
    try {
      submitPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      setState(() {
        isRefreshing = false;
      });
      Fluttertoast.showToast(
        msg: S.of(context).unableCurrentLocationSubmission,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Validate submit location is within 100m of Image 1
    if (images[0].imagePath != null) {
      double distanceFromFirstImage = _calculateDistance(
        submitPosition.latitude,
        submitPosition.longitude,
        images[0].lat,
        images[0].long,
      );

      if (distanceFromFirstImage > 100) {
        setState(() {
          isRefreshing = false;
        });

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.of(context).cannotSubmit,
                      style: TextStyle(fontSize: 16, fontFamily: "Roboto", color: Colors.red),
                    ),
                  ),
                ],
              ),
              content: Text(
                'You are ${distanceFromFirstImage.toStringAsFixed(0)} meters away from Image 1. You must be within 100 meters to submit.',
                style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Understood', style: TextStyle(fontFamily: "Roboto")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Font.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    try {
      // bool isNetworkAvailable = await _checkNetworkConnectivity();
      bool isNetworkAvailable = await hasRealInternet();
      String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Store images
      for (var i = 0; i < images.length; i++) {
        if (images[i].imagePath != null) {
          final compressedImagePath = await _storeImageInInternalDocuments(images[i].imagePath!);
          images[i].imagePath = compressedImagePath;
        }
      }

      // Create metadata
      ImageUploaddata metadata = ImageUploaddata(
        ServerPlanId: widget.ServerID,
        PlanCode: widget.planCode,
        PrintNo: fullPrintNumber,
        VillageCode: widget.VillageCode,
        Address: widget.Address,
        ExecutionDate: currentDate,
        UploadDate: '',
        CleanImage: images[0].imagePath,
        CleanLatitude: images[0].lat.toString(),
        CleanLongitude: images[0].long.toString(),
        WBImage: images[1].imagePath,
        WBLatitude: images[1].lat.toString(),
        WBLongitude: images[1].long.toString(),
        SprayImage: images[2].imagePath,
        SprayLatitude: images[2].lat.toString(),
        SprayLongitude: images[2].long.toString(),
        NearImage: images[3].imagePath,
        NearLatitude: images[3].lat.toString(),
        NearLongitude: images[3].long.toString(),
        FarImage: images[4].imagePath,
        FarLatitude: images[4].lat.toString(),
        FarLongitude: images[4].long.toString(),
        NewImage6: images[5].imagePath,
        New6Latitude: images[5].lat.toString(),
        New6Longitude: images[5].long.toString(),
        NewImage7: images[6].imagePath,
        New7Latitude: images[6].lat.toString(),
        New7Longitude: images[6].long.toString(),
        printId: widget.printId,
        uploadType: "rework",
        VillageName: widget.villageName,
        Tensil: widget.tensil,
        createdAt: DateTime.now(),
        networkFlagString: isNetworkAvailable ? "online" : "offline",
      );

      await ExecutionImageUploadHiveRepository().saveMetadata(metadata);

      // Submission succeeded, so the in-progress draft is no longer needed.
      await _draftRepository.deleteDraft(_draftKey);

      // ========== ACTIVITY LOG: record what was submitted ==========
      final rawUid = await _getRawUidForLog();
      await CrashReportManager.storePrintSubmissionLog({
        'ServerPlanId': metadata.ServerPlanId,
        'VillageCode': metadata.VillageCode,
        'PlanCode': metadata.PlanCode,
        'PrintNo': metadata.PrintNo,
        'Address': metadata.Address,
        'ExecutionDate': metadata.ExecutionDate,
        'UploadDate': metadata.UploadDate,
        'CleanImage': metadata.CleanImage,
        'WBImage': metadata.WBImage,
        'SprayImage': metadata.SprayImage,
        'NearImage': metadata.NearImage,
        'FarImage': metadata.FarImage,
        'NewImage6': metadata.NewImage6,
        'NewImage7': metadata.NewImage7,
        'Clean_Latitude': metadata.CleanLatitude,
        'Clean_Longitude': metadata.CleanLongitude,
        'WB_Latitude': metadata.WBLatitude,
        'WB_Longitude': metadata.WBLongitude,
        'Spray_Latitude': metadata.SprayLatitude,
        'Spray_Longitude': metadata.SprayLongitude,
        'Near_Latitude': metadata.NearLatitude,
        'Near_Longitude': metadata.NearLongitude,
        'Far_Latitude': metadata.FarLatitude,
        'Far_Longitude': metadata.FarLongitude,
        'New6_Latitude': metadata.New6Latitude,
        'New6_Longitude': metadata.New6Longitude,
        'New7_Latitude': metadata.New7Latitude,
        'New7_Longitude': metadata.New7Longitude,
        'NetworkStatus': metadata.networkFlagString,
        'UID': rawUid,
        'uploadType': 'rework',
      });

      // ========== LEGACY-FORMAT LOGS (AllDBPrints/AllPrints/HMData) ==========
      // Same file names/fields as the old native app, for continuity with
      // existing log-review tooling. Snapshot of everything still pending
      // sync, taken right after this record was added to that queue.
      final pendingPrints = await ExecutionImageUploadHiveRepository().getAllMetadata();
      await CrashReportManager.logAllDBPrints(pendingPrints);
      await CrashReportManager.logAllPrints(pendingPrints);
     // await CrashReportManager.logHMData(pendingPrints);

      await ReworkBalanceCountChangeRepository().incrementOfflineCount(
        widget.planCode.toString(),
        widget.VillageCode.toString(),
        widget.villageName.toString(),
        widget.tensil.toString(),
      );

      await PlanCountChangeHiveRepository().incrementArtworkOfflineCount(
        widget.ServerID.toString(),
        widget.planCode.toString(),
        widget.VillageCode.toString(),
        int.tryParse(widget.artworkId) ?? 0,
      );

      String uploadDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await UploadCountRepository().incrementUploadCount(uploadDate);

      await _clearSavedState();

      // Clear in-memory images
      setState(() {
        for (var i = 0; i < images.length; i++) {
          images[i].imagePath = null;
          images[i].lat = 0.0;
          images[i].long = 0.0;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context).submitPlan),
              backgroundColor: Colors.green
          )
      );

      setState(() {
        isRefreshing = false;
      });

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ReworkScreen(changeLanguage: widget.changeLanguage)
          )
      );

    } catch (e) {
      await CrashReportManager.storeCrashReport(
        error: "Submit details error: $e",
        stackTrace: StackTrace.current.toString(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context).errorOccurredSubmitting),
              backgroundColor: Colors.red
          )
      );
      setState(() {
        isRefreshing = false;
      });
    }
  }
// Rest of your build method and other methods remain the same...
// [Include all your existing UI code here]
}

// Your existing classes remain the same
class ImageData {
  String? imagePath;
  String printNumber;
  double lat;
  double long;
  TextEditingController printController;

  ImageData({
    this.imagePath,
    this.printNumber = '',
    this.lat = 0.0,
    this.long = 0.0,
  }) : printController = TextEditingController(text: printNumber);

  void dispose() {
    printController.dispose();
  }
}

// Enhanced Meta Row Components (unchanged)
class _EnhancedMetaRow extends StatelessWidget {
  const _EnhancedMetaRow({
    required this.label,
    required this.value
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: neutralDarkColor,
                fontFamily: "Roboto",
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: neutralDarkColor,
                fontFamily: "Roboto",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedMetaRowWithInputs extends StatelessWidget {
  const _EnhancedMetaRowWithInputs({
    required this.label,
    required this.value,
    required this.secondValue
  });

  final String label;
  final String value;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: neutralDarkColor,
                fontFamily: "Roboto",
              ),
            ),
          ),
          Center(
            child: Text(
              "${value}W",
              style: TextStyle(
                fontSize: 12,
                color: neutralDarkColor,
                fontFamily: "Roboto",
              ),
            ),
          ),
          SizedBox(width: 4),
          Text('×', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          SizedBox(width: 4),
          Center(
            child: Text(
              "${secondValue}H",
              style: TextStyle(
                fontSize: 12,
                color: neutralDarkColor,
                fontFamily: "Roboto",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// Add these color definitions if they're not already in your project
const Color primaryColor = Color(0xFF2196F3);
const Color primaryLightColor = Color(0xFF64B5F6);
const Color accentColor = Color(0xFF03DAC6);
const Color neutralDarkColor = Color(0xFF212121);




// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:canimage/Screens/Rework/rework_see_plans.dart';
// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:canimage/Repository/remarks_repository.dart';
// import 'package:canimage/Screens/landing/landing_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../Hive_Database/execution_image_upload_db.dart';
// import '../../Repository/execution_balance_count_change_repository.dart';
// import '../../Repository/execution_image_upload_repository.dart';
// import '../../Repository/rework_balance_count_change_repository.dart';
// import '../../Repository/upload_count_repository.dart';
// import '../../generated/l10n.dart';
// import '../../utils/crash_manager.dart';
// import '../../utils/fonts.dart';
//
// class ReworkUploadSeePlans extends StatefulWidget {
//   String? projectID;
//   String? villageName;
//   String? brand;
//   String? width;
//   String? height;
//   String? printNo;
//   String? printId;
//   String? planCode;
//   String? villageCode;
//   String? tensil;
//   String ServerID;
//   String VillageCode;
//   String Address;
//   String artworkId;
//   double? latitude;
//   double? longitude;
//   final Function(String) changeLanguage;
//
//   ReworkUploadSeePlans({
//     super.key,
//     required this.projectID,
//     required this.villageName,
//     required this.brand,
//     required this.width,
//     required this.height,
//     required this.printNo,
//     required this.printId,
//     required this.villageCode,
//     required this.planCode,
//     required this.tensil,
//     required this.ServerID,
//     required this.VillageCode,
//     required this.Address,
//     required this.artworkId,
//     this.latitude,
//     this.longitude,
//     required this.changeLanguage
//   });
//
//   @override
//   State<ReworkUploadSeePlans> createState() => _ReworkUploadSeePlansState();
// }
//
// class _ReworkUploadSeePlansState extends State<ReworkUploadSeePlans> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
//   List<ImageData> images = List.generate(7, (index) => ImageData());
//   List<bool> _isPickerActiveList = List.generate(7, (index) => false);
//   bool isPickingImage = false;
//   bool _isProcessingRecoveredImage = false;
//   TextEditingController printNoController1 = TextEditingController();
//   TextEditingController printNoController2 = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   bool isRefreshing = false;
//   final FocusNode _focusNode1 = FocusNode();
//   final FocusNode _focusNode2 = FocusNode();
//
//   // Initialize ImagePicker instance
//   final ImagePicker _picker = ImagePicker();
//   int? _currentImageIndex;
//
//   void _dismissKeyboard() {
//     FocusManager.instance.primaryFocus?.unfocus();
//     SystemChannels.textInput.invokeMethod('TextInput.hide');
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _focusNode1.dispose();
//     _focusNode2.dispose();
//     printNoController1.dispose();
//     printNoController2.dispose();
//     _clearSavedState();
//     super.dispose();
//   }
//
//   void _removeFocus() {
//     _focusNode1.unfocus();
//     _focusNode2.unfocus();
//     FocusScope.of(context).unfocus();
//   }
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//
//     switch (state) {
//       case AppLifecycleState.paused:
//         if (isPickingImage) {
//           _saveCurrentState();
//         }
//         break;
//
//       case AppLifecycleState.resumed:
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             FocusScope.of(context).unfocus();
//             _checkAndRestoreState();
//           }
//         });
//         break;
//
//       case AppLifecycleState.detached:
//         _clearSavedState();
//         break;
//
//       case AppLifecycleState.inactive:
//       case AppLifecycleState.hidden:
//         break;
//     }
//   }
//
//   Future<void> _checkAndRestoreState() async {
//     final prefs = await SharedPreferences.getInstance();
//     final wasPicking = prefs.getBool('is_picking_image') ?? false;
//
//     if (wasPicking) {
//       await _restoreStateIfNeeded();
//       await prefs.setBool('is_picking_image', false);
//     }
//   }
//
//   Future<void> _saveCurrentState() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     if (_currentImageIndex != null && isPickingImage) {
//       await prefs.setBool('is_picking_image', true);
//       await prefs.setInt('current_image_index', _currentImageIndex!);
//
//       final currentImage = images[_currentImageIndex!];
//       if (currentImage.imagePath != null) {
//         await prefs.setString('current_image_path', currentImage.imagePath!);
//         await prefs.setDouble('current_image_lat', currentImage.lat);
//         await prefs.setDouble('current_image_long', currentImage.long);
//       }
//     }
//   }
//
//   Future<void> _clearSavedState() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('is_picking_image');
//     await prefs.remove('current_image_index');
//     await prefs.remove('current_image_path');
//     await prefs.remove('current_image_lat');
//     await prefs.remove('current_image_long');
//   }
//
//   Future<void> _restoreStateIfNeeded() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final savedIndex = prefs.getInt('current_image_index');
//     final savedImagePath = prefs.getString('current_image_path');
//
//     if (savedIndex != null && savedImagePath != null) {
//       if (await File(savedImagePath).exists()) {
//         setState(() {
//           images[savedIndex].imagePath = savedImagePath;
//           images[savedIndex].lat = prefs.getDouble('current_image_lat') ?? 0.0;
//           images[savedIndex].long = prefs.getDouble('current_image_long') ?? 0.0;
//         });
//
//         Fluttertoast.showToast(
//           msg: "Restored interrupted image capture",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.blue,
//           textColor: Colors.white,
//         );
//       }
//     }
//   }
//
//   double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
//   }
//
//   Future<void> _pickImage(int index) async {
//     if (isPickingImage) {
//       return;
//     }
//
//     try {
//       setState(() {
//         isPickingImage = true;
//         _isPickerActiveList[index] = true;
//         _currentImageIndex = index;
//       });
//
//       Position? currentPosition;
//       try {
//         currentPosition = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.best,
//           timeLimit: Duration(seconds: 10),
//         );
//       } catch (e) {
//         Fluttertoast.showToast(
//           msg: S.of(context).unablePleaseEnableGPS,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.CENTER,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//         );
//         setState(() {
//           isPickingImage = false;
//           _isPickerActiveList[index] = false;
//         });
//         return;
//       }
//
//       if (index == 0 && widget.latitude != null && widget.longitude != null) {
//         double distance = _calculateDistance(
//           currentPosition.latitude,
//           currentPosition.longitude,
//           widget.latitude!,
//           widget.longitude!,
//         );
//
//         if (distance > 50) {
//           setState(() {
//             isPickingImage = false;
//             _isPickerActiveList[index] = false;
//           });
//
//           await _showDistanceDialog(
//             context,
//             distance,
//             "Image 1",
//             "The first image must be captured within 50 meters of the selected location.",
//             showRefreshOption: true,
//           );
//           return;
//         }
//       }
//
//       if (index == 2 && images[0].imagePath != null) {
//         double distanceFromIndex0 = _calculateDistance(
//           currentPosition.latitude,
//           currentPosition.longitude,
//           images[0].lat,
//           images[0].long,
//         );
//
//         if (distanceFromIndex0 > 50) {
//           setState(() {
//             isPickingImage = false;
//             _isPickerActiveList[index] = false;
//           });
//
//           await _showDistanceDialog(
//             context,
//             distanceFromIndex0,
//             "Image 3",
//             "Image 3 must be captured within 50 meters of Image 1 location.",
//           );
//           return;
//         }
//       }
//
//       if (index == 6 && images[0].imagePath != null) {
//         double distanceFromIndex0 = _calculateDistance(
//           currentPosition.latitude,
//           currentPosition.longitude,
//           images[0].lat,
//           images[0].long,
//         );
//
//         if (distanceFromIndex0 > 50) {
//           setState(() {
//             isPickingImage = false;
//             _isPickerActiveList[index] = false;
//           });
//
//           await _showDistanceDialog(
//             context,
//             distanceFromIndex0,
//             "Image 7",
//             "Image 7 must be captured within 50 meters of Image 1 location.",
//           );
//           return;
//         }
//       }
//
//       try {
//         await _requestCameraPermissions();
//       } catch (e) {
//         setState(() {
//           isPickingImage = false;
//           _isPickerActiveList[index] = false;
//         });
//
//         await _showErrorDialogWithRetry(
//           context,
//           'Camera Permission Required',
//           'Camera permission is needed to capture images. Please enable it in settings.',
//           index,
//         );
//         return;
//       }
//
//       await _saveCurrentState();
//
//       XFile? pickedFile;
//
//       try {
//         pickedFile = await _picker.pickImage(
//           source: ImageSource.camera,
//           imageQuality: 90,
//           maxWidth: 1920,
//           maxHeight: 1920,
//           preferredCameraDevice: CameraDevice.rear,
//         ).timeout(
//           Duration(seconds: 60),
//           onTimeout: () {
//             throw TimeoutException('Camera operation timed out');
//           },
//         );
//       } on PlatformException catch (e) {
//         await _clearSavedState();
//
//         String errorMessage = 'Camera error occurred';
//         if (e.code == 'camera_access_denied') {
//           errorMessage = 'Camera access was denied';
//         } else if (e.code == 'camera_access_denied_permanently') {
//           errorMessage = 'Camera access permanently denied. Please enable in settings.';
//         }
//
//         await CrashReportManager.storeCrashReport(
//           error: "Camera PlatformException: ${e.code} - ${e.message}",
//           stackTrace: e.stacktrace?.toString() ?? StackTrace.current.toString(),
//         );
//
//         await _showErrorDialogWithRetry(context, 'Camera Error', errorMessage, index);
//         return;
//
//       } on TimeoutException catch (e) {
//         await _clearSavedState();
//
//         await CrashReportManager.storeCrashReport(
//           error: "Camera timeout: $e",
//           stackTrace: StackTrace.current.toString(),
//         );
//
//         await _showErrorDialogWithRetry(
//           context,
//           'Camera Timeout',
//           'Camera took too long to respond. Please try again.',
//           index,
//         );
//         return;
//
//       } catch (e) {
//         await _clearSavedState();
//
//         await CrashReportManager.storeCrashReport(
//           error: "Camera unexpected error: $e",
//           stackTrace: StackTrace.current.toString(),
//         );
//
//         await _showErrorDialogWithRetry(
//           context,
//           'Unexpected Error',
//           'An error occurred while opening the camera. Please try again.',
//           index,
//         );
//         return;
//       }
//
//       if (pickedFile != null) {
//         try {
//           final file = File(pickedFile.path);
//           if (!await file.exists()) {
//             throw Exception('Captured image file not found');
//           }
//
//           await file.length();
//
//           if (mounted) {
//             setState(() {
//               images[index].imagePath = pickedFile!.path;
//               images[index].lat = currentPosition!.latitude;
//               images[index].long = currentPosition.longitude;
//             });
//           }
//
//           await _clearSavedState();
//
//           Fluttertoast.showToast(
//             msg: S.of(context).imageCaptured,
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.green,
//             textColor: Colors.white,
//           );
//         } catch (e) {
//           await _clearSavedState();
//
//           await CrashReportManager.storeCrashReport(
//             error: "Image file processing error: $e",
//             stackTrace: StackTrace.current.toString(),
//           );
//
//           await _showErrorDialogWithRetry(
//             context,
//             'Image Processing Error',
//             'Failed to process captured image. Please try again.',
//             index,
//           );
//         }
//       } else {
//         await _clearSavedState();
//       }
//
//     } catch (e) {
//       await _clearSavedState();
//       FocusScope.of(context).unfocus();
//
//       await CrashReportManager.storeCrashReport(
//         error: "Image picker critical error: $e",
//         stackTrace: StackTrace.current.toString(),
//       );
//
//       if (mounted) {
//         await _showErrorDialogWithRetry(
//           context,
//           'Critical Error',
//           'A critical error occurred. The app will return to the previous screen.',
//           index,
//           isCritical: true,
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isPickingImage = false;
//           _isPickerActiveList[index] = false;
//         });
//         FocusScope.of(context).unfocus();
//       }
//     }
//   }
//
//   Future<void> _showErrorDialogWithRetry(
//       BuildContext context,
//       String title,
//       String message,
//       int imageIndex, {
//         bool isCritical = false,
//       }) async {
//     if (!mounted) return;
//
//     bool? shouldRetry = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Row(
//             children: [
//               Icon(
//                 isCritical ? Icons.error : Icons.warning_amber_rounded,
//                 color: isCritical ? Colors.red : Colors.orange,
//               ),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontFamily: "Roboto",
//                     color: isCritical ? Colors.red : Colors.orange,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 message,
//                 style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
//               ),
//               if (!isCritical) ...[
//                 SizedBox(height: 16),
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.info_outline, size: 16, color: Colors.blue),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'You can retry capturing the image or go back.',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontFamily: "Roboto",
//                             color: Colors.blue[900],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ],
//           ),
//           actions: [
//             if (isCritical) ...[
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(false);
//                 },
//                 child: Text('Go Back', style: TextStyle(fontFamily: "Roboto")),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Font.primaryColor,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ] else ...[
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(false);
//                 },
//                 child: Text(
//                   'Go Back',
//                   style: TextStyle(fontFamily: "Roboto", color: Colors.grey),
//                 ),
//               ),
//               ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.of(context).pop(true);
//                 },
//                 icon: Icon(Icons.refresh, size: 18),
//                 label: Text(
//                   'Retry',
//                   style: TextStyle(fontFamily: "Roboto"),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Font.primaryColor,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ],
//           ],
//         );
//       },
//     );
//
//     if (isCritical || shouldRetry == false) {
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ReworkScreen(changeLanguage: widget.changeLanguage),
//           ),
//         );
//       }
//     } else if (shouldRetry == true) {
//       await Future.delayed(Duration(milliseconds: 300));
//       if (mounted) {
//         _pickImage(imageIndex);
//       }
//     }
//   }
//
//   Future<void> _showDistanceDialog(
//       BuildContext context,
//       double distance,
//       String imageLabel,
//       String requirement,
//       {bool showRefreshOption = false}
//       ) async {
//     Fluttertoast.showToast(
//       msg: "You are ${distance.toStringAsFixed(0)}m away. Please move closer (within 50m).",
//       toastLength: Toast.LENGTH_LONG,
//       gravity: ToastGravity.CENTER,
//       backgroundColor: Colors.orange,
//       textColor: Colors.white,
//     );
//
//     bool? shouldRefresh = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Row(
//             children: [
//               Icon(Icons.location_off, color: Colors.orange),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'Too Far from $imageLabel Location',
//                   style: TextStyle(fontSize: 16, fontFamily: "Roboto"),
//                 ),
//               ),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'You are ${distance.toStringAsFixed(0)} meters away.',
//                 style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
//               ),
//               SizedBox(height: 12),
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   '⚠️ $requirement',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontFamily: "Roboto",
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             if (showRefreshOption) ...[
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: Text(
//                   'Stay Here',
//                   style: TextStyle(fontFamily: "Roboto", color: Colors.grey),
//                 ),
//               ),
//               ElevatedButton.icon(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 icon: Icon(Icons.refresh, size: 18),
//                 label: Text(
//                   'Refresh Location',
//                   style: TextStyle(fontFamily: "Roboto"),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Font.primaryColor,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ] else ...[
//               ElevatedButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: Text(
//                   'Understood',
//                   style: TextStyle(fontFamily: "Roboto"),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Font.primaryColor,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ],
//           ],
//         );
//       },
//     );
//
//     if (showRefreshOption && shouldRefresh == true && mounted) {
//       // Navigator.pushReplacement(
//       //   context,
//       //   MaterialPageRoute(
//       //     builder: (context) => MapScreen(
//       //       planCode: widget.planCode,
//       //       VillageCode: widget.VillageCode,
//       //       ServerID: widget.ServerID,
//       //       changeLanguage: widget.changeLanguage,
//       //       height: widget.height,
//       //       width: widget.width,
//       //       villageName: widget.villageName,
//       //       brand: widget.brand,
//       //       tensil: widget.tensil,
//       //       artworkId: widget.artworkId,
//       //     ),
//       //   ),
//       // );
//     }
//   }
//
//   Future<void> _requestCameraPermissions() async {
//     final permissions = await [
//       Permission.camera,
//       Permission.storage,
//       Permission.photos,
//     ].request();
//
//     if (permissions[Permission.camera] != PermissionStatus.granted) {
//       throw PlatformException(
//         code: "CAMERA_PERMISSION_DENIED",
//         message: S.of(context).cameraPermission,
//       );
//     }
//   }
//
//   void _removeImage(int index) {
//     if (_isPickerActiveList[index]) return;
//     setState(() {
//       images[index].imagePath = null;
//       images[index].lat = 0.0;
//       images[index].long = 0.0;
//     });
//   }
//
//   // ========== IMPROVED COMPRESSION METHOD (150-200 KB) ==========
//   Future<String> _storeImageInInternalDocuments(String imagePath) async {
//     try {
//       Directory? externalDir = await getExternalStorageDirectory();
//
//       if (externalDir == null) {
//         throw 'Unable to access external storage directory';
//       }
//
//       Directory appDocDir = Directory('${externalDir.path}/CIMTDWP');
//
//       if (!await appDocDir.exists()) {
//         await appDocDir.create(recursive: true);
//       }
//
//       Directory dwPaintingDir = Directory(
//         '${appDocDir.path}/Execution/Plans/${widget.ServerID}/${widget.planCode}/${widget.VillageCode}/${printNoController1.text}${printNoController2.text}/Images',
//       );
//
//       if (!await dwPaintingDir.exists()) {
//         await dwPaintingDir.create(recursive: true);
//       }
//
//       File imageFile = File(imagePath);
//
//       if (!await imageFile.exists()) {
//         throw 'Source image file does not exist: $imagePath';
//       }
//
//       // Read original image bytes as Uint8List
//       List<int> imageBytesList = await imageFile.readAsBytes();
//       Uint8List imageBytes = Uint8List.fromList(imageBytesList);
//       int originalSizeBytes = imageBytes.length;
//       double originalSizeKB = originalSizeBytes / 1024;
//
//       // Target size: 150-200 KB
//       const int targetMinKB = 150;
//       const int targetMaxKB = 200;
//       const int targetMinBytes = targetMinKB * 1024;
//       const int targetMaxBytes = targetMaxKB * 1024;
//
//       // Start with higher quality and dimensions
//       int quality = 92;
//       int minWidth = 1600;
//       int minHeight = 1600;
//       Uint8List? bestCompressedBytes;
//       int? bestSize;
//       int attempt = 0;
//       const maxAttempts = 15;
//
//       debugPrint('==================================================');
//       debugPrint('📸 IMAGE COMPRESSION STARTED');
//       debugPrint('📁 Original Size: ${originalSizeKB.toStringAsFixed(2)} KB');
//       debugPrint('🎯 Target Range: $targetMinKB - $targetMaxKB KB');
//       debugPrint('==================================================');
//
//       // Try different compression settings
//       while (attempt < maxAttempts) {
//         // Dynamic adjustment strategy
//         if (attempt > 0) {
//           // Reduce quality gradually
//           if (quality > 60) {
//             quality = (92 - (attempt * 3)).clamp(30, 92);
//           }
//
//           // Reduce dimensions more gradually
//           if (quality < 70 && minWidth > 800) {
//             minWidth = (minWidth * 0.92).round();
//             minHeight = (minHeight * 0.92).round();
//           }
//         }
//
//         // Compress with current settings
//         Uint8List? compressedBytes = await FlutterImageCompress.compressWithList(
//           imageBytes,
//           minWidth: minWidth,
//           minHeight: minHeight,
//           quality: quality,
//           format: CompressFormat.jpeg,
//         );
//
//         if (compressedBytes == null) {
//           debugPrint('❌ Compression failed at attempt $attempt');
//           attempt++;
//           continue;
//         }
//
//         int compressedSize = compressedBytes.length;
//         double compressedSizeKB = compressedSize / 1024;
//
//         // Log current attempt
//         debugPrint('🔁 Attempt ${attempt + 1}:');
//         debugPrint('   Quality: $quality');
//         debugPrint('   Dimensions: ${minWidth}x$minHeight');
//         debugPrint('   Size: ${compressedSizeKB.toStringAsFixed(2)} KB');
//
//         // Check if size is within target range
//         if (compressedSize >= targetMinBytes && compressedSize <= targetMaxBytes) {
//           bestCompressedBytes = compressedBytes;
//           bestSize = compressedSize;
//           debugPrint('✅ PERFECT! Within target range ✅');
//           debugPrint('   Final Size: ${compressedSizeKB.toStringAsFixed(2)} KB');
//           break;
//         }
//
//         // Store best result
//         if (bestCompressedBytes == null) {
//           bestCompressedBytes = compressedBytes;
//           bestSize = compressedSize;
//         } else if (compressedSize >= targetMinBytes &&
//             compressedSize <= targetMaxBytes) {
//           bestCompressedBytes = compressedBytes;
//           bestSize = compressedSize;
//           break;
//         } else if (compressedSize < targetMinBytes &&
//             compressedSize > (bestSize ?? 0)) {
//           bestCompressedBytes = compressedBytes;
//           bestSize = compressedSize;
//         } else if (compressedSize > targetMaxBytes &&
//             (bestSize == null || compressedSize < bestSize)) {
//           if (bestSize == null || compressedSize < bestSize) {
//             bestCompressedBytes = compressedBytes;
//             bestSize = compressedSize;
//           }
//         }
//
//         attempt++;
//       }
//
//       if (bestCompressedBytes == null) {
//         debugPrint('❌ No compression result found');
//         throw 'Compression failed';
//       }
//
//       // If best result is below target, try one more time with higher quality
//       if (bestSize != null && bestSize < targetMinBytes) {
//         debugPrint('⚠️ Final size ${(bestSize / 1024).toStringAsFixed(2)} KB below target');
//         debugPrint('🔄 Attempting final adjustment with higher quality...');
//
//         Uint8List? finalCompressed = await FlutterImageCompress.compressWithList(
//           imageBytes,
//           minWidth: 1800,
//           minHeight: 1800,
//           quality: 95,
//           format: CompressFormat.jpeg,
//         );
//
//         if (finalCompressed != null) {
//           int finalSize = finalCompressed.length;
//           double finalSizeKB = finalSize / 1024;
//
//           if (finalSize >= targetMinBytes && finalSize <= targetMaxBytes) {
//             bestCompressedBytes = finalCompressed;
//             bestSize = finalSize;
//             debugPrint('✅ Final adjustment successful: ${finalSizeKB.toStringAsFixed(2)} KB');
//           } else if (finalSize > (bestSize ?? 0) && finalSize <= targetMaxBytes) {
//             bestCompressedBytes = finalCompressed;
//             bestSize = finalSize;
//             debugPrint('⚠️ Final adjustment: ${finalSizeKB.toStringAsFixed(2)} KB');
//           } else {
//             debugPrint('⚠️ Final adjustment: ${finalSizeKB.toStringAsFixed(2)} KB (still outside range)');
//           }
//         }
//       }
//
//       // Final size check
//       double finalSizeKB = (bestSize ?? 0) / 1024;
//
//       debugPrint('==================================================');
//       debugPrint('📊 COMPRESSION SUMMARY');
//       debugPrint('📁 Original Size: ${originalSizeKB.toStringAsFixed(2)} KB');
//       debugPrint('📁 Final Size: ${finalSizeKB.toStringAsFixed(2)} KB');
//       debugPrint('📉 Space Saved: ${(originalSizeKB - finalSizeKB).toStringAsFixed(2)} KB');
//       debugPrint('📊 Compression Ratio: ${((originalSizeKB - finalSizeKB) / originalSizeKB * 100).toStringAsFixed(1)}%');
//
//       if (bestSize != null && bestSize >= targetMinBytes && bestSize <= targetMaxBytes) {
//         debugPrint('✅ STATUS: WITHIN TARGET RANGE (150-200 KB) ✅');
//       } else if (bestSize != null && bestSize < targetMinBytes) {
//         debugPrint('⚠️ STATUS: BELOW TARGET (${finalSizeKB.toStringAsFixed(2)} KB < 150 KB)');
//       } else if (bestSize != null && bestSize > targetMaxBytes) {
//         debugPrint('⚠️ STATUS: ABOVE TARGET (${finalSizeKB.toStringAsFixed(2)} KB > 200 KB)');
//       }
//       debugPrint('==================================================');
//
//       // Generate unique filename
//       String imageName = 'Img_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       String imagePathInStorage = '${dwPaintingDir.path}/$imageName';
//
//       // Save compressed image
//       File compressedImage = File(imagePathInStorage);
//       await compressedImage.writeAsBytes(bestCompressedBytes);
//
//       if (!await compressedImage.exists()) {
//         throw 'Failed to write compressed image';
//       }
//
//       int diskSize = await compressedImage.length();
//       double diskSizeKB = diskSize / 1024;
//       debugPrint('💾 Disk Size: ${diskSizeKB.toStringAsFixed(2)} KB');
//       debugPrint('==================================================');
//
//       return imagePathInStorage;
//
//     } catch (e) {
//       debugPrint('❌ ERROR in compression: $e');
//       throw 'Failed to store image: $e';
//     }
//   }
//
//   bool get _isAnyPickerActive =>
//       _isPickerActiveList.any((isActive) => isActive) ||
//           _isProcessingRecoveredImage;
//
//   Future<bool> _onWillPop() async {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => ReworkScreen(changeLanguage: widget.changeLanguage,)),
//     );
//     return false;
//   }
//
//   Future<bool> hasRealInternet() async {
//     try {
//       final result = await InternetAddress.lookup('google.com')
//           .timeout(Duration(seconds: 3));
//
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   void _submitDetails() async {
//     setState(() {
//       isRefreshing = true;
//     });
//
//     String printNumber1 = printNoController1.text.trim();
//     String printNumber2 = printNoController2.text.trim();
//
//     if (printNumber1.isEmpty || printNumber2.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(S.of(context).pleaseEnterPrintNumber),
//             backgroundColor: Colors.red,
//           )
//       );
//       setState(() {
//         isRefreshing = false;
//       });
//       return;
//     }
//
//     String fullPrintNumber = '${printNumber1.trim()}${printNumber2.trim()}'.toUpperCase();
//
//     final uploadedCount = images.where((img) => img.imagePath != null).length;
//     if (uploadedCount != 7) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text(S.of(context).imageVal),
//               backgroundColor: Colors.red
//           )
//       );
//       setState(() {
//         isRefreshing = false;
//       });
//       return;
//     }
//
//     Position? submitPosition;
//     try {
//       submitPosition = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best,
//         timeLimit: Duration(seconds: 10),
//       );
//     } catch (e) {
//       setState(() {
//         isRefreshing = false;
//       });
//       Fluttertoast.showToast(
//         msg: S.of(context).unableCurrentLocationSubmission,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.CENTER,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//       return;
//     }
//
//     if (images[0].imagePath != null) {
//       double distanceFromFirstImage = _calculateDistance(
//         submitPosition.latitude,
//         submitPosition.longitude,
//         images[0].lat,
//         images[0].long,
//       );
//
//       if (distanceFromFirstImage > 100) {
//         setState(() {
//           isRefreshing = false;
//         });
//
//         await showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: Row(
//                 children: [
//                   Icon(Icons.warning_amber_rounded, color: Colors.red),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       S.of(context).cannotSubmit,
//                       style: TextStyle(fontSize: 16, fontFamily: "Roboto", color: Colors.red),
//                     ),
//                   ),
//                 ],
//               ),
//               content: Text(
//                 'You are ${distanceFromFirstImage.toStringAsFixed(0)} meters away from Image 1. You must be within 100 meters to submit.',
//                 style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
//               ),
//               actions: [
//                 ElevatedButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: Text('Understood', style: TextStyle(fontFamily: "Roboto")),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Font.primaryColor,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//         return;
//       }
//     }
//
//     try {
//       bool isNetworkAvailable = await hasRealInternet();
//       String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//
//       debugPrint('==================================================');
//       debugPrint('📸 SUBMITTING IMAGES - SIZE CHECK');
//       debugPrint('==================================================');
//
//       // Store images with compression and log each size
//       List<double> imageSizes = [];
//       for (var i = 0; i < images.length; i++) {
//         if (images[i].imagePath != null) {
//           File originalFile = File(images[i].imagePath!);
//           int originalSize = await originalFile.length();
//           double originalSizeKB = originalSize / 1024;
//
//           debugPrint('📷 Image ${i+1} Original Size: ${originalSizeKB.toStringAsFixed(2)} KB');
//
//           final compressedImagePath = await _storeImageInInternalDocuments(images[i].imagePath!);
//           images[i].imagePath = compressedImagePath;
//
//           File compressedFile = File(compressedImagePath);
//           int compressedSize = await compressedFile.length();
//           double compressedSizeKB = compressedSize / 1024;
//           imageSizes.add(compressedSizeKB);
//
//           debugPrint('📷 Image ${i+1} Compressed Size: ${compressedSizeKB.toStringAsFixed(2)} KB');
//           debugPrint('---');
//         }
//       }
//
//       // Log summary of all images
//       debugPrint('==================================================');
//       debugPrint('📊 ALL IMAGES SIZE SUMMARY');
//       debugPrint('==================================================');
//       for (var i = 0; i < imageSizes.length; i++) {
//         String status = '';
//         if (imageSizes[i] >= 150 && imageSizes[i] <= 200) {
//           status = '✅ IN RANGE';
//         } else if (imageSizes[i] < 150) {
//           status = '⚠️ BELOW RANGE';
//         } else {
//           status = '⚠️ ABOVE RANGE';
//         }
//         debugPrint('Image ${i+1}: ${imageSizes[i].toStringAsFixed(2)} KB - $status');
//       }
//
//       double totalSize = imageSizes.fold(0, (sum, size) => sum + size);
//       double averageSize = imageSizes.isNotEmpty ? totalSize / imageSizes.length : 0;
//       debugPrint('----------------------------------------');
//       debugPrint('📊 Total Size: ${totalSize.toStringAsFixed(2)} KB');
//       debugPrint('📊 Average Size: ${averageSize.toStringAsFixed(2)} KB');
//       debugPrint('==================================================');
//
//       // Create metadata
//       ImageUploaddata metadata = ImageUploaddata(
//         ServerPlanId: widget.ServerID,
//         PlanCode: widget.planCode,
//         PrintNo: fullPrintNumber,
//         VillageCode: widget.VillageCode,
//         Address: widget.Address,
//         ExecutionDate: currentDate,
//         UploadDate: '',
//         CleanImage: images[0].imagePath,
//         CleanLatitude: images[0].lat.toString(),
//         CleanLongitude: images[0].long.toString(),
//         WBImage: images[1].imagePath,
//         WBLatitude: images[1].lat.toString(),
//         WBLongitude: images[1].long.toString(),
//         SprayImage: images[2].imagePath,
//         SprayLatitude: images[2].lat.toString(),
//         SprayLongitude: images[2].long.toString(),
//         NearImage: images[3].imagePath,
//         NearLatitude: images[3].lat.toString(),
//         NearLongitude: images[3].long.toString(),
//         FarImage: images[4].imagePath,
//         FarLatitude: images[4].lat.toString(),
//         FarLongitude: images[4].long.toString(),
//         NewImage6: images[5].imagePath,
//         New6Latitude: images[5].lat.toString(),
//         New6Longitude: images[5].long.toString(),
//         NewImage7: images[6].imagePath,
//         New7Latitude: images[6].lat.toString(),
//         New7Longitude: images[6].long.toString(),
//         printId: widget.printId,
//         uploadType: "rework",
//         VillageName: widget.villageName,
//         Tensil: widget.tensil,
//         createdAt: DateTime.now(),
//         networkFlagString: isNetworkAvailable ? "online" : "offline",
//       );
//
//       await ExecutionImageUploadHiveRepository().saveMetadata(metadata);
//       await ReworkBalanceCountChangeRepository().incrementOfflineCount(
//         widget.planCode.toString(),
//         widget.VillageCode.toString(),
//         widget.villageName.toString(),
//         widget.tensil.toString(),
//       );
//
//       await PlanCountChangeHiveRepository().incrementArtworkOfflineCount(
//         widget.ServerID.toString(),
//         widget.planCode.toString(),
//         widget.VillageCode.toString(),
//         int.tryParse(widget.artworkId) ?? 0,
//       );
//
//       String uploadDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
//       await UploadCountRepository().incrementUploadCount(uploadDate);
//
//       await _clearSavedState();
//
//       setState(() {
//         for (var i = 0; i < images.length; i++) {
//           images[i].imagePath = null;
//           images[i].lat = 0.0;
//           images[i].long = 0.0;
//         }
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text(S.of(context).submitPlan),
//               backgroundColor: Colors.green
//           )
//       );
//
//       setState(() {
//         isRefreshing = false;
//       });
//
//       Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (context) => ReworkScreen(changeLanguage: widget.changeLanguage)
//           )
//       );
//
//     } catch (e) {
//       await CrashReportManager.storeCrashReport(
//         error: "Submit details error: $e",
//         stackTrace: StackTrace.current.toString(),
//       );
//
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text(S.of(context).errorOccurredSubmitting),
//               backgroundColor: Colors.red
//           )
//       );
//       setState(() {
//         isRefreshing = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cs = theme.colorScheme;
//
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: SafeArea(
//         child: Scaffold(
//           backgroundColor: Color(0xFFF8F9FA),
//           resizeToAvoidBottomInset: true,
//           appBar: AppBar(
//             elevation: 0,
//             backgroundColor: Font.primaryColor,
//             title: Text(
//               S.of(context).printDetails,
//               style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 18,
//                   letterSpacing: 1,
//                   fontFamily: "Roboto"
//               ),
//             ),
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage,)),
//                 );
//               },
//             ),
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.home, color: Colors.white),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
//                   );
//                 },
//               ),
//             ],
//           ),
//           body: SingleChildScrollView(
//             child: Column(
//               children: [
//                 Container(
//                   margin: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         Colors.white,
//                         Colors.grey[50]!,
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.12),
//                         blurRadius: 20,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _EnhancedMetaRow(label: S.of(context).villageNameMap, value: widget.villageName ?? ''),
//                         _EnhancedMetaRow(label: S.of(context).brand, value: widget.brand ?? ''),
//                         _EnhancedMetaRow(
//                           label: "Print ID",
//                           value: " (${widget.printId ?? ''})",
//                         ),
//                         _EnhancedMetaRowWithInputs(
//                           label: S.of(context).size,
//                           value: widget.width.toString(),
//                           secondValue: widget.height.toString(),
//                         ),
//                         Row(
//                           children: [
//                             Expanded(
//                               flex: 2,
//                               child: Text(
//                                 S.of(context).printNo,
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                   color: neutralDarkColor,
//                                   fontFamily: "Roboto",
//                                 ),
//                               ),
//                             ),
//                             Container(
//                                 width: 100,
//                                 height: 50,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[50],
//                                   borderRadius: BorderRadius.circular(8),
//                                   border: Border.all(color: Colors.grey),
//                                 ),
//                                 child: TextField(
//                                   keyboardType: TextInputType.text,
//                                   controller: printNoController1,
//                                   focusNode: _focusNode1,
//                                   textAlign: TextAlign.center,
//                                   onEditingComplete: _dismissKeyboard,
//                                   onSubmitted: (_) => _dismissKeyboard(),
//                                   onTapOutside: (_) => _dismissKeyboard(),
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: neutralDarkColor,
//                                     fontFamily: "Roboto",
//                                   ),
//                                   decoration: InputDecoration(
//                                     border: InputBorder.none,
//                                     contentPadding: EdgeInsets.symmetric(vertical: 8),
//                                   ),
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]")),
//                                     UpperCaseTextInputFormatter(),
//                                   ],
//                                 )
//                             ),
//                             SizedBox(width: 4),
//                             Text('/', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
//                             SizedBox(width: 4),
//                             Container(
//                               width: 100,
//                               height: 50,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[50],
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: Colors.grey),
//                               ),
//                               child: TextField(
//                                 keyboardType: TextInputType.number,
//                                 controller: printNoController2,
//                                 textAlign: TextAlign.center,
//                                 focusNode: _focusNode2,
//                                 onEditingComplete: _dismissKeyboard,
//                                 onSubmitted: (_) => _dismissKeyboard(),
//                                 onTapOutside: (_) => _dismissKeyboard(),
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: neutralDarkColor,
//                                   fontFamily: "Roboto",
//                                 ),
//                                 decoration: InputDecoration(
//                                   border: InputBorder.none,
//                                   contentPadding: EdgeInsets.symmetric(vertical: 8),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(left: 4, bottom: 12),
//                         child: Row(
//                           children: [
//                             Icon(Icons.photo_library, color: Font.primaryColor, size: 20),
//                             SizedBox(width: 8),
//                             Text(
//                               S.of(context).uploadImages,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: neutralDarkColor,
//                                 fontFamily: "Roboto",
//                               ),
//                             ),
//                             Spacer(),
//                             Container(
//                               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: accentColor.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 '${images.where((img) => img.imagePath != null).length}/7',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                   color: Font.primaryColor,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       GridView.builder(
//                         physics: const BouncingScrollPhysics(),
//                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2,
//                           crossAxisSpacing: 12,
//                           mainAxisSpacing: 12,
//                           childAspectRatio: 0.85,
//                         ),
//                         itemCount: 7,
//                         itemBuilder: (context, index) {
//                           return _buildEnhancedImageCard(index);
//                         },
//                         shrinkWrap: true,
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 Container(
//                   margin: const EdgeInsets.only(bottom: 10, top: 10),
//                   width: 200,
//                   height: 50,
//                   child: GestureDetector(
//                     onTap: (isRefreshing || _isAnyPickerActive) ? null : _submitDetails,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                       decoration: BoxDecoration(
//                         color: (isRefreshing || _isAnyPickerActive) ? Colors.grey : Font.primaryColor,
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           if (isRefreshing) ...[
//                             SizedBox(
//                               width: 12,
//                               height: 12,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                           ] else if (_isAnyPickerActive) ...[
//                             Icon(Icons.camera_alt, size: 20, color: Colors.white),
//                             SizedBox(width: 8),
//                           ] else ...[
//                             Icon(Icons.cloud_upload_outlined, size: 20, color: Colors.white),
//                             SizedBox(width: 8),
//                           ],
//
//                           Text(
//                             isRefreshing ? "Saving..." :
//                             S.of(context).submitDetails,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 16,
//                               fontFamily: "Roboto",
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEnhancedImageCard(int index) {
//     final hasImage = images[index].imagePath != null;
//     final isThisCardActive = _isPickerActiveList[index];
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Expanded(
//             child: GestureDetector(
//               onTap: () => _pickImage(index),
//               child: Container(
//                 width: double.infinity,
//                 margin: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: hasImage ? Colors.transparent :
//                     isThisCardActive ? Colors.blue : Colors.grey[300]!,
//                     width: 1.5,
//                     style: BorderStyle.solid,
//                   ),
//                 ),
//                 child: hasImage ? _buildImageDisplay(index) : _buildPlaceholder(index),
//               ),
//             ),
//           ),
//
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: hasImage ? primaryColor.withOpacity(0.1) :
//               isThisCardActive ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(16),
//                 bottomRight: Radius.circular(16),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: hasImage ? primaryColor :
//                     isThisCardActive ? Colors.blue : Colors.grey[400],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     '${index + 1}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 if (isThisCardActive)
//                   SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//                     ),
//                   )
//                 else
//                   Icon(
//                     hasImage ? Icons.check_circle : Icons.radio_button_unchecked,
//                     color: hasImage ? Colors.green : Colors.grey[400],
//                     size: 16,
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImageDisplay(int index) {
//     final isThisCardActive = _isPickerActiveList[index];
//
//     return Stack(
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Container(
//             width: double.infinity,
//             height: double.infinity,
//             child: FutureBuilder<bool>(
//               future: File(images[index].imagePath!).exists(),
//               builder: (context, snapshot) {
//                 if (snapshot.data == true) {
//                   return Image.file(
//                     File(images[index].imagePath!),
//                     fit: BoxFit.cover,
//                     width: double.infinity,
//                     height: double.infinity,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         color: Colors.grey[300],
//                         child: Icon(Icons.error, color: Colors.red),
//                       );
//                     },
//                   );
//                 }
//                 return Container(
//                   color: Colors.grey[300],
//                   child: Center(child: CircularProgressIndicator()),
//                 );
//               },
//             ),
//           ),
//         ),
//         Positioned(
//           top: 4,
//           right: 4,
//           child: GestureDetector(
//             onTap: isThisCardActive ? null : () => _removeImage(index),
//             child: Container(
//               padding: EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: isThisCardActive ? Colors.grey : Colors.red,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(Icons.close, color: Colors.white, size: 14),
//             ),
//           ),
//         ),
//         if (!isThisCardActive)
//           Positioned.fill(
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12),
//                 color: Colors.black.withOpacity(0.3),
//               ),
//               child: Center(child: Icon(Icons.edit, color: Colors.white, size: 24)),
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildPlaceholder(int index) {
//     final isThisCardActive = _isPickerActiveList[index];
//
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             (isThisCardActive ? primaryColor : accentColor).withOpacity(0.1),
//             (isThisCardActive ? primaryColor : primaryLightColor).withOpacity(0.1),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: (isThisCardActive ? Colors.blue : primaryColor).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: isThisCardActive
//                 ? SizedBox(
//               width: 24,
//               height: 24,
//               child: CircularProgressIndicator(
//                 color: Colors.blue,
//                 strokeWidth: 2,
//               ),
//             )
//                 : Icon(Icons.add_a_photo, size: 24, color: Font.primaryColor),
//           ),
//           SizedBox(height: 8),
//           Text(
//             isThisCardActive ? S.of(context).openingCamera : S.of(context).addPhoto,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: isThisCardActive ? Font.primaryColor : Font.primaryColor,
//               fontFamily: "Roboto",
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class ImageData {
//   String? imagePath;
//   String printNumber;
//   double lat;
//   double long;
//   TextEditingController printController;
//
//   ImageData({
//     this.imagePath,
//     this.printNumber = '',
//     this.lat = 0.0,
//     this.long = 0.0,
//   }) : printController = TextEditingController(text: printNumber);
//
//   void dispose() {
//     printController.dispose();
//   }
// }
//
// class _EnhancedMetaRow extends StatelessWidget {
//   const _EnhancedMetaRow({
//     required this.label,
//     required this.value
//   });
//
//   final String label;
//   final String value;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: neutralDarkColor,
//                 fontFamily: "Roboto",
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 4,
//             child: Text(
//               value,
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: neutralDarkColor,
//                 fontFamily: "Roboto",
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _EnhancedMetaRowWithInputs extends StatelessWidget {
//   const _EnhancedMetaRowWithInputs({
//     required this.label,
//     required this.value,
//     required this.secondValue
//   });
//
//   final String label;
//   final String value;
//   final String secondValue;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: neutralDarkColor,
//                 fontFamily: "Roboto",
//               ),
//             ),
//           ),
//           Center(
//             child: Text(
//               "${value}W",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: neutralDarkColor,
//                 fontFamily: "Roboto",
//               ),
//             ),
//           ),
//           SizedBox(width: 4),
//           Text('×', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
//           SizedBox(width: 4),
//           Center(
//             child: Text(
//               "${secondValue}H",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: neutralDarkColor,
//                 fontFamily: "Roboto",
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class UpperCaseTextInputFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     return newValue.copyWith(text: newValue.text.toUpperCase());
//   }
// }
//
// const Color primaryColor = Color(0xFF2196F3);
// const Color primaryLightColor = Color(0xFF64B5F6);
// const Color accentColor = Color(0xFF03DAC6);
// const Color neutralDarkColor = Color(0xFF212121);