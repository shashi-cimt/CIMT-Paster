import 'dart:async';
import 'dart:io';
import 'package:canimage/Screens/ExecutionSeePlans/execution_see_plans.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/can_image_loader.dart';
import '../../widgets/app_snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Hive_Database/execution_seeplan_db.dart';
import '../../utils/image_compression_helper.dart';
import '../../Hive_Database/execution_image_upload_db.dart';
import '../../Hive_Database/execution_image_draft_db.dart';
import '../../Repository/Map_pointer_locate_repository.dart';
import '../../Repository/execution_image_upload_repository.dart';
import '../../Repository/execution_image_draft_repository.dart';
import '../../utils/uid_file_helper.dart';
import '../../utils/image_orientation_utils.dart';
import '../../utils/persistent_capture_store.dart';
import '../../Repository/execution_balance_count_change_repository.dart';
import '../../Repository/upload_count_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/app_storage_helper.dart';
import '../../utils/crash_manager.dart';
import '../../utils/fonts.dart';
import '../../utils/location_evidence/location_config.dart';
import '../../utils/location_evidence/location_sample.dart';
import '../../utils/location_evidence/location_tracking_session.dart';
import '../landing/landing_screen.dart';
import 'execution_map_screen.dart';

class UploadSeePlanScreen extends StatefulWidget {
  String? planCode;
  String? locateId;
  String? VillageCode;
  String? ServerID;
  String? Address;
  double? latitude;
  double? longitude;
  final Function(String) changeLanguage;
  var width;
  var height;
  var villageName;
  var tensil;
  var brand;
  var artworkId;
  String? projectId;

  UploadSeePlanScreen({
    super.key,
    required this.ServerID,
    required this.Address,
    required this.planCode,
    required this.VillageCode,
    required this.latitude,
    required this.longitude,
    required this.changeLanguage,
    required this.height,
    required this.width,
    required this.villageName,
    required this.brand,
    required this.tensil,
    required this.artworkId,
    this.locateId,
    this.projectId,
  });

  @override
  State<UploadSeePlanScreen> createState() => _UploadSeePlanScreenState();
}

class _UploadSeePlanScreenState extends State<UploadSeePlanScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
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

  // Owns the ONE continuous background location stream for this capture
  // session (started in initState), the rolling evidence buffer behind it,
  // and the evaluation/logging of Image 1/3/7 movement. Replaces the old
  // bare `_latestPosition` + `StreamSubscription<Position>` fields.
  final LocationTrackingSession _locationSession = LocationTrackingSession();

  // Persists already-captured images to Hive as soon as each one is taken,
  // keyed per plan/village/print location, so closing this screen before
  // Submit does not lose captures already made.
  final ExecutionImageDraftHiveRepository _draftRepository =
      ExecutionImageDraftHiveRepository();
  late final String _draftKey;

  String _buildDraftKey() {
    return "EXEC_${widget.ServerID}_${widget.VillageCode}_${widget.planCode}_${widget.locateId ?? ''}";
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
    _locationSession.start();
  }

  Future<void> _recoverAfterRestart() async {
    // Order matters: restore the already-saved draft FIRST, then layer the
    // one photo that was mid-flight when the process died on top. Doing it
    // the other way round made _checkForLostCameraData's own
    // _saveDraftToHive() overwrite the Hive draft while `images` still only
    // held that one recovered slot — wiping every other already-captured
    // image from the draft before _restoreDraftIfNeeded ever got to load them.
    await _restoreDraftIfNeeded();
    await _checkForLostCameraData();
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

      // Move it out of the picker's cache into permanent storage right away
      // — otherwise this just-recovered photo is still sitting in a
      // cache dir the OS can reclaim before the user gets to Submit.
      final String permanentPath = await PersistentCaptureStore.persist(
        file.path,
        subfolder: 'Execution',
      );

      // The real capture-time location is gone — this is a best-effort
      // backfill, explicitly tagged as a post-recovery read (never a live
      // fix) throughout the GPS evidence log.
      final recoveryEvidence = await _locationSession.recordRecoveryCapture(
        savedIndex,
        imageLabel: 'IMAGE_${savedIndex + 1}',
      );

      if (mounted) {
        setState(() {
          images[savedIndex].imagePath = permanentPath;
          if (recoveryEvidence.isValid) {
            images[savedIndex].lat = recoveryEvidence.latitude;
            images[savedIndex].long = recoveryEvidence.longitude;
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
    PaintingBinding.instance.imageCache.clearLiveImages();
    PaintingBinding.instance.imageCache.clear();
    WidgetsBinding.instance.removeObserver(this);
    _locationSession.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    printNoController1.dispose();
    printNoController2.dispose();
    _clearSavedState();
    super.dispose();
  }

  /// Restores any images captured on a previous visit to this screen that
  /// were never submitted, so re-opening it does not show a blank form.
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
  /// numbers) to Hive so it survives the screen being closed.
  Future<void> _saveDraftToHive() async {
    final draft = ExecutionImageDraft(
      draftKey: _draftKey,
      ServerPlanId: widget.ServerID,
      PlanCode: widget.planCode,
      VillageCode: widget.VillageCode,
      locateId: widget.locateId,
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

      //  ONLY save the current image being captured (not all images)
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
          images[savedIndex].long =
              prefs.getDouble('current_image_long') ?? 0.0;
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

  /// The trusted Image 1 baseline for Image 3/7/Submit checks. Prefers this
  /// session's own stabilized capture evidence; falls back to the raw
  /// lat/long stored on [images]\[0\] (e.g. restored from a Hive draft on a
  /// previous visit to this screen) so those flows still get an evidence-
  /// aware check instead of silently skipping it.
  RawLocationSample? _image1Baseline() {
    final sessionEvidence = _locationSession.imageEvidence(0)?.trusted;
    if (sessionEvidence != null) return sessionEvidence;
    if (images[0].imagePath == null) return null;
    return RawLocationSample.referencePoint(
      latitude: images[0].lat,
      longitude: images[0].long,
      sessionId: _locationSession.sessionId,
    );
  }

  /// Physically corrects a freshly captured photo's orientation. The
  /// device's camera (via image_picker) can return a JPEG whose pixels are
  /// stored sideways with an EXIF "rotate" instruction — Flutter's Image
  /// widget ignores that tag, so without this every landscape photo would
  /// display portrait (or upside down) everywhere in the app.
  Future<String> _normalizeOrientation(String sourcePath) async {
    try {
      final Uint8List rawBytes = await File(sourcePath).readAsBytes();
      // Decode/bake/encode is CPU-heavy enough to freeze the UI thread if run
      // inline, which is what made the captured photo feel slow to appear in
      // the thumbnail box — run it on a background isolate instead.
      final Uint8List? uprightBytes = await compute(
        bakeJpegOrientation,
        rawBytes,
      );
      if (uprightBytes == null) return sourcePath;

      final int dot = sourcePath.lastIndexOf('.');
      final String normalizedPath =
          '${dot == -1 ? sourcePath : sourcePath.substring(0, dot)}_upright.jpg';
      await File(normalizedPath).writeAsBytes(uprightBytes);
      return normalizedPath;
    } catch (_) {
      return sourcePath;
    }
  }

  /// Raw "deviceUid|userId" content of this device's UID.txt, for tagging
  /// submission log entries with who/what device submitted them.
  Future<String?> _getRawUidForLog() async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return null;
      File uidFile = File('${externalDir.path}/CIMTDWP/Appfiles/UID.txt');
      return UidFileHelper.canonicalize(
        await UidFileHelper.readRawUidContent(uidFile),
      );
    } catch (e) {
      return null;
    }
  }

  double _calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<void> _cleanupOldCapture(String? oldPath) async {
    if (oldPath == null || oldPath.isEmpty) return;
    try {
      final file = File(oldPath);
      await FileImage(file).evict();
      if (oldPath.contains('PendingCaptures') && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  ///
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

      // ========== GET CURRENT LOCATION ==========
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 10),
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

      final Position currentPosition = position!;

      // ========== DISTANCE VALIDATIONS ==========

      // ---------- Image 1 (index 0) : distance from plan location ----------
      if (index == 0 && widget.latitude != null && widget.longitude != null) {
        final double distance = _calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          widget.latitude!,
          widget.longitude!,
        );

        if (distance > LocationConfig.image1PlanThresholdMeters) {
          setState(() {
            isPickingImage = false;
            _isPickerActiveList[index] = false;
          });

          await _showDistanceDialog(
            context,
            distance,
            "Image 1",
            "Distance is greater than ${LocationConfig.image1PlanThresholdMeters.toInt()} meters. "
                "The first image must be captured within "
                "${LocationConfig.image1PlanThresholdMeters.toInt()} meters of the selected location.",
            showRefreshOption: true,
            thresholdMeters: LocationConfig.image1PlanThresholdMeters.toInt(),
          );
          return;
        }
      }

      // ---------- Image 3 (index 2) & Image 7 (index 6) : distance from Image 1 ----------
      if ((index == 2 || index == 6) && images[0].imagePath != null) {
        final double distanceFromImage1 = _calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          images[0].lat,
          images[0].long,
        );

        if (distanceFromImage1 > LocationConfig.image1To37ThresholdMeters) {
          final String label = index == 2 ? "Image 3" : "Image 7";

          setState(() {
            isPickingImage = false;
            _isPickerActiveList[index] = false;
          });

          await _showDistanceDialog(
            context,
            distanceFromImage1,
            label,
            "$label must be captured within "
            "${LocationConfig.image1To37ThresholdMeters.toInt()} meters of Image 1 location.",
          );
          return;
        }
      }

      // ========== REQUEST CAMERA & STORAGE PERMISSIONS ==========
      try {
        await _requestCameraPermissions();
        if (mounted) {
          setState(() {
            _isPickerActiveList[index] = false;
          });
        }
        final hasStorage = await AppStorageHelper.ensureStoragePermission(
          context: context,
        );
        if (!hasStorage) {
          if (mounted) {
            setState(() {
              isPickingImage = false;
              _isPickerActiveList[index] = false;
            });
          }
          return;
        }
        if (mounted) {
          setState(() {
            _isPickerActiveList[index] = true;
          });
        }
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

      // Flush Flutter image cache to release GPU textures before OEM camera launch
      PaintingBinding.instance.imageCache.clearLiveImages();
      PaintingBinding.instance.imageCache.clear();

      // ========== OPEN CAMERA (image_picker) ==========
      XFile? pickedFile;

      try {
        pickedFile = await _picker
            .pickImage(
              source: ImageSource.camera,
              preferredCameraDevice: CameraDevice.rear,
              maxWidth: 1920,
              maxHeight: 1920,
              imageQuality: 85,
            )
            .timeout(
              const Duration(seconds: 120),
              onTimeout: () {
                throw TimeoutException('Camera operation timed out');
              },
            );
      } on PlatformException catch (e) {
        await _clearSavedState();

        String errorMessage = 'Camera error occurred';
        if (e.code == 'camera_access_denied') {
          errorMessage = 'Camera access was denied';
        } else if (e.code == 'camera_access_denied_permanently') {
          errorMessage =
              'Camera access permanently denied. Please enable in settings.';
        }

        await CrashReportManager.storeCrashReport(
          error: "Camera PlatformException: ${e.code} - ${e.message}",
          stackTrace: StackTrace.current.toString(),
        );

        await _showErrorDialogWithRetry(
          context,
          'Camera Error',
          errorMessage,
          index,
        );
        return;
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

      // ========== PROCESS CAPTURED IMAGE ==========
      if (pickedFile != null) {
        try {
          final XFile imageFile = pickedFile;
          final file = File(imageFile.path);

          if (!await file.exists()) {
            throw Exception('Captured image file not found');
          }

          // Move out of image_picker's own cache dir into permanent storage immediately
          final String permanentPath = await PersistentCaptureStore.persist(
            imageFile.path,
            subfolder: 'Execution',
          );

          // If this slot already had an image (Retake), evict from memory and clean disk
          final String? oldPath = images[index].imagePath;
          if (oldPath != null && oldPath != permanentPath) {
            _cleanupOldCapture(oldPath);
          }

          // Show the captured image immediately without any delay!
          if (mounted) {
            setState(() {
              images[index].imagePath = permanentPath;
              images[index].lat = currentPosition.latitude;
              images[index].long = currentPosition.longitude;
            });
          }

          await _clearSavedState();

          Fluttertoast.showToast(
            msg: S.of(context).imageCaptured,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Persist the draft (cheap — no image work here)
          await _saveDraftToHive();

          await CrashReportManager.logDWPTrace(
            'Image captured: $permanentPath',
          );
        } catch (e) {
          await _clearSavedState();

          await CrashReportManager.storeCrashReport(
            error: "Image processing error: $e",
            stackTrace: StackTrace.current.toString(),
          );

          await _showErrorDialogWithRetry(
            context,
            'Image Processing Error',
            'Failed to process captured image. Please try again.',
            index,
          );
        }
      } else {
        await _clearSavedState();
      }
    } catch (e) {
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
                label: Text('Retry', style: TextStyle(fontFamily: "Roboto")),
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SeePlanScreen(changeLanguage: widget.changeLanguage),
          ),
          (route) => route.isFirst,
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
    String requirement, {
    bool showRefreshOption = false,
    int thresholdMeters = 50,
  }) async {
    Fluttertoast.showToast(
      msg:
          "You are ${distance.toStringAsFixed(0)}m away. Please move closer (within ${thresholdMeters}m).",
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
                  ' $requirement',
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
      Navigator.pushReplacement(
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
          ),
        ),
      );
    }
  }
  // Simplified recovery method (less needed with image_picker plugin)

  // Request camera permissions
  Future<void> _requestCameraPermissions() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      throw PlatformException(
        code: "CAMERA_PERMISSION_DENIED",
        message: S.of(context).cameraPermission,
      );
    }
  }

  String _resolveProjectId() {
    if (widget.projectId != null && widget.projectId!.trim().isNotEmpty) {
      return widget.projectId!.trim();
    }
    try {
      if (Hive.isBoxOpen('plans')) {
        final box = Hive.box<PlanItem>('plans');
        for (final plan in box.values) {
          if ((widget.ServerID != null && plan.planServerId.toString() == widget.ServerID) ||
              (widget.planCode != null && plan.planCode == widget.planCode)) {
            if (plan.projectId.trim().isNotEmpty) {
              return plan.projectId.trim();
            }
          }
        }
        if (box.values.isNotEmpty && box.values.first.projectId.trim().isNotEmpty) {
          return box.values.first.projectId.trim();
        }
      }
    } catch (_) {}
    return 'UnknownProject';
  }

  String _resolvePlanServerId() {
    if (widget.ServerID != null && widget.ServerID!.trim().isNotEmpty && widget.ServerID != 'null') {
      return widget.ServerID!.trim();
    }
    return 'UnknownServerID';
  }

  String _resolvePlanCode() {
    if (widget.planCode != null && widget.planCode!.trim().isNotEmpty && widget.planCode != 'null') {
      return widget.planCode!.trim();
    }
    return 'UnknownPlanId';
  }

  String _resolveVillageCode() {
    if (widget.VillageCode != null && widget.VillageCode!.trim().isNotEmpty && widget.VillageCode != 'null') {
      return widget.VillageCode!.trim();
    }
    return 'UnknownVillage';
  }

  String _resolvePrintName() {
    final String fullPrintNo =
        '${printNoController1.text.trim()}${printNoController2.text.trim()}';
    if (fullPrintNo.isNotEmpty) {
      return fullPrintNo;
    }
    return 'Print';
  }

  // Process image from file path

  /// Compresses and moves a captured image into permanent storage. Runs at
  /// Submit time (not right after capture) to keep memory pressure low
  /// immediately after the camera closes.
  Future<String> _storeImageInInternalDocuments(
    String imagePath, {
    required int slotIndex,
    int rotationQuarterTurns = 0,
  }) async {
    try {
      File sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        throw 'Source image file does not exist: $imagePath';
      }

      var imageBytes = await sourceFile.readAsBytes();

      // Bake the manual rotate-button turns into the pixels, so the stored
      // file matches what the user saw in the card.
      final int turns = rotationQuarterTurns % 4;
      if (turns != 0) {
        final img.Image? decoded = img.decodeImage(imageBytes);
        if (decoded != null) {
          final rotated = img.copyRotate(decoded, angle: turns * 90);
          imageBytes = Uint8List.fromList(img.encodeJpg(rotated, quality: 98));
        }
      }

      final result = await ImageCompressionHelper.compressToTargetSize(
        imageBytes,
        targetMinKB: 300,
        targetMaxKB: 400,
      );

      final String imagePathInStorage = await AppStorageHelper.getPhotoFilePath(
        projectId: _resolveProjectId(),
        planServerId: _resolvePlanServerId(),
        planId: _resolvePlanCode(),
        villageCode: _resolveVillageCode(),
        printName: _resolvePrintName(),
        photoNumber: slotIndex + 1,
      );

      File compressedImage = File(imagePathInStorage);
      await compressedImage.writeAsBytes(result);

      if (!await compressedImage.exists()) {
        throw 'Failed to write compressed image to storage';
      }

      try {
        await sourceFile.delete();
      } catch (_) {}

      return imagePathInStorage;
    } catch (e) {
      throw 'Failed to store image: $e';
    }
  }

  bool get _isAnyPickerActive =>
      _isPickerActiveList.any((isActive) => isActive) ||
      _isProcessingRecoveredImage;

  Future<bool> _onWillPop() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SeePlanScreen(changeLanguage: widget.changeLanguage),
      ),
      (route) => route.isFirst,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        resizeToAvoidBottomInset: true,
        appBar: CommonAppBar(
          title: S.of(context).printDetails,
          onBackPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SeePlanScreen(changeLanguage: widget.changeLanguage),
                ),
                (route) => route.isFirst,
              );
            }
          },
          actions: const [CommonHomeButton()],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                // Clean & Minimal Header Card
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EnhancedMetaRow(
                          label: S.of(context).villageNameMap,
                          value: widget.villageName,
                        ),
                        _EnhancedMetaRow(
                          label: S.of(context).brand,
                          value: widget.brand,
                        ),
                        _EnhancedMetaRowWithInputs(
                          label: S.of(context).size,
                          value: widget.width.toString(),
                          secondValue: widget.height.toString(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  S.of(context).printNo,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: neutralDarkColor,
                                    fontFamily: "Roboto",
                                  ),
                                ),
                              ),
                              Container(
                                width: 85,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.2,
                                  ),
                                ),
                                child: TextField(
                                  keyboardType: TextInputType.text,
                                  controller: printNoController1,
                                  focusNode: _focusNode1,
                                  textAlign: TextAlign.center,
                                  onEditingComplete: _dismissKeyboard,
                                  onSubmitted: (_) => _dismissKeyboard(),
                                  onTapOutside: (_) => _dismissKeyboard(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: neutralDarkColor,
                                    fontFamily: "Roboto",
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp("[a-zA-Z]"),
                                    ),
                                    UpperCaseTextInputFormatter(),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '/',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                width: 85,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.2,
                                  ),
                                ),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  controller: printNoController2,
                                  textAlign: TextAlign.center,
                                  focusNode: _focusNode2,
                                  onEditingComplete: _dismissKeyboard,
                                  onSubmitted: (_) => _dismissKeyboard(),
                                  onTapOutside: (_) => _dismissKeyboard(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: neutralDarkColor,
                                    fontFamily: "Roboto",
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Images Grid Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 2,
                          right: 2,
                          bottom: 10,
                          top: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: Font.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              S.of(context).uploadImages,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: neutralDarkColor,
                                fontFamily: "Roboto",
                              ),
                            ),
                            const Spacer(),
                            Builder(
                              builder: (context) {
                                final count = images
                                    .where((img) => img.imagePath != null)
                                    .length;
                                final allDone = count == 7;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: allDone
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: allDone
                                          ? const Color(0xFF16A34A)
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        allDone
                                            ? Icons.check_circle_rounded
                                            : Icons.camera_alt_outlined,
                                        size: 14,
                                        color: allDone
                                            ? const Color(0xFF16A34A)
                                            : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$count / 7 Photos',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: allDone
                                              ? const Color(0xFF16A34A)
                                              : Colors.grey.shade800,
                                          fontFamily: "Roboto",
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                    onTap: (isRefreshing || _isAnyPickerActive)
                        ? null
                        : _submitDetails,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: (isRefreshing || _isAnyPickerActive)
                            ? Colors.grey
                            : Font.primaryColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isRefreshing) ...[
                            const CanImageSpinner(
                              size: 14,
                              primaryColor: Colors.white70,
                              accentColor: Colors.white,
                            ),
                            const SizedBox(width: 8),
                          ] else if (_isAnyPickerActive) ...[
                            Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                          ] else ...[
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                          ],

                          Text(
                            isRefreshing
                                ? "Saving..."
                                : S.of(context).submitDetails,
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

  void _rotateImage(int index) {
    setState(() {
      images[index].rotationQuarterTurns =
          (images[index].rotationQuarterTurns + 1) % 4;
    });
    _saveDraftToHive();
  }

  void _showImagePreview(int index) {
    if (images[index].imagePath == null) return;
    final file = File(images[index].imagePath!);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 24,
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF18181B),
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF27272A),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Photo ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Roboto",
                                ),
                              ),
                              if (images[index].lat != 0.0) ...[
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${images[index].lat.toStringAsFixed(4)}, ${images[index].long.toStringAsFixed(4)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                        fontFamily: "Roboto",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),

                    // Interactive Zoomable Image
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.65,
                          minHeight: 260,
                        ),
                        width: double.infinity,
                        color: Colors.black,
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: images[index].rotationQuarterTurns,
                              child: Image.file(
                                file,
                                cacheWidth: 1080,
                                cacheHeight: 1080,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom Action Bar - Clean & Minimal
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF18181B),
                        border: Border(
                          top: BorderSide(color: Color(0xFF27272A), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rotate Button (Clean Outlined)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _rotateImage(index);
                                setDialogState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFF3F3F46),
                                  width: 1.2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.rotate_right_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Rotate',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Retake Button (Clean Primary)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    _pickImage(index);
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Font.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Retake Photo',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedImageCard(int index) {
    final hasImage = images[index].imagePath != null;
    final isThisCardActive = _isPickerActiveList[index];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isThisCardActive ? Font.primaryColor : Colors.grey.shade300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image thumbnail with photo number and check icon
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImagePreview(index),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageDisplay(index),

                        // Photo number pill in top-left
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Photo ${index + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: "Roboto",
                              ),
                            ),
                          ),
                        ),

                        // Green check circle top-right
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF16A34A),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Clean Minimal Retake Button at the bottom
                InkWell(
                  onTap: () => _pickImage(index),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 15,
                          color: Font.primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Retake",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Font.primaryColor,
                            fontFamily: "Roboto",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _buildPlaceholder(index),
    );
  }

  Widget _buildImageDisplay(int index) {
    final isThisCardActive = _isPickerActiveList[index];

    return Stack(
      fit: StackFit.expand,
      children: [
        RotatedBox(
          quarterTurns: images[index].rotationQuarterTurns,
          child: Image.file(
            File(images[index].imagePath!),
            cacheWidth: 600,
            cacheHeight: 600,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.red, size: 30),
                ),
              );
            },
          ),
        ),

        // Loading indicator if card is active
        if (isThisCardActive)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CanImageSpinner(
                size: 36,
                primaryColor: Colors.white70,
                accentColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(int index) {
    final isThisCardActive = _isPickerActiveList[index];

    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        color: const Color(0xFFFAFAFA),
        child: Stack(
          children: [
            // Top-left photo number
            Positioned(
              top: 8,
              left: 10,
              child: Text(
                'Photo ${index + 1}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  fontFamily: "Roboto",
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Font.primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: isThisCardActive
                        ? const CanImageSpinner(size: 24)
                        : Icon(
                            Icons.add_a_photo_outlined,
                            size: 24,
                            color: Font.primaryColor,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isThisCardActive
                        ? S.of(context).openingCamera
                        : S.of(context).addPhoto,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      fontFamily: "Roboto",
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tap to capture",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                      fontFamily: "Roboto",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Future<bool> _checkNetworkConnectivity() async {
  //   try {
  //     final connectivityResult = await Connectivity().checkConnectivity();
  //     return connectivityResult == ConnectivityResult.mobile ||
  //         connectivityResult == ConnectivityResult.wifi;
  //   } catch (e) {
  //     // print("Error checking connectivity: $e");
  //     return false;
  //   }
  // }
  Future<bool> hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(Duration(seconds: 3));

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
      AppSnackBar.showError(
        context,
        S.of(context).pleaseEnterPrintNumber,
      );
      setState(() {
        isRefreshing = false;
      });
      return;
    }

    String fullPrintNumber = '$printNumber1$printNumber2';

    // Ensure photos are filed under the finalized printNumber folder
    for (int i = 0; i < images.length; i++) {
      if (images[i].imagePath != null && images[i].imagePath!.isNotEmpty) {
        images[i].imagePath = await AppStorageHelper.relocatePhotoIfPrintNameChanged(
          currentPath: images[i].imagePath!,
          projectId: _resolveProjectId(),
          planServerId: _resolvePlanServerId(),
          planId: _resolvePlanCode(),
          villageCode: _resolveVillageCode(),
          printName: fullPrintNumber,
          photoNumber: i + 1,
        );
      }
    }

    final uploadedCount = images.where((img) => img.imagePath != null).length;
    if (uploadedCount != 7) {
      AppSnackBar.showError(
        context,
        S.of(context).imageVal,
      );
      setState(() {
        isRefreshing = false;
      });
      return;
    }

    final submitEvidence = await _locationSession.recordSubmitCapture();
    if (!submitEvidence.isValid) {
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

    // Validate submit location is within 100m of Image 1 (evidence-aware:
    // ordinary GPS drift at submit time no longer blocks a stationary
    // vendor from finishing a print they physically completed).
    if (images[0].imagePath != null) {
      final baseline = _image1Baseline();
      if (baseline != null) {
        final evalResult = _locationSession.evaluateAgainstSample(
          baseline: baseline,
          target: submitEvidence.trusted!,
          thresholdMeters: LocationConfig.submitThresholdMeters,
          fromLabel: 'IMAGE_1',
          toLabel: 'SUBMIT',
        );

        if (evalResult.shouldBlock) {
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
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: "Roboto",
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'You are ${evalResult.trustedDistanceMeters.toStringAsFixed(0)} meters away from Image 1. You must be within ${LocationConfig.submitThresholdMeters.toInt()} meters to submit.',
                  style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
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
              );
            },
          );
          return;
        }
      }
    }

    try {
      bool isNetworkAvailable = await hasRealInternet();
      String currentDate = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());

      // Store images
      for (var i = 0; i < images.length; i++) {
        if (images[i].imagePath != null) {
          final compressedImagePath = await _storeImageInInternalDocuments(
            images[i].imagePath!,
            slotIndex: i,
            rotationQuarterTurns: images[i].rotationQuarterTurns,
          );
          images[i].imagePath = compressedImagePath;
          images[i].rotationQuarterTurns = 0;
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
        VillageName: widget.villageName,
        Tensil: widget.tensil,
        createdAt: DateTime.now(),
        networkFlagString: isNetworkAvailable ? "online" : "offline",
        locateId: widget.locateId,
      );

      // ========== SAVE METADATA ==========
      await ExecutionImageUploadHiveRepository().saveMetadata(metadata);

      // Submission succeeded, so the in-progress draft is no longer needed.
      await _draftRepository.deleteDraft(_draftKey);

      // Force any buffered GPS evidence lines to disk now, so
      // gps_tracking_log_<date>.jsonl always has this session's samples on
      // disk at the same moment the print submission record is written —
      // never missing, never waiting on the debounce timer.
      await _locationSession.flushLogs();

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
        'projectId': widget.projectId,
        'uploadType': 'normal',
      });

      // ========== LEGACY-FORMAT LOGS (AllDBPrints/AllPrints/HMData) ==========
      // Same file names/fields as the old native app, for continuity with
      // existing log-review tooling. Snapshot of everything still pending
      // sync, taken right after this record was added to that queue.
      final pendingPrints = await ExecutionImageUploadHiveRepository()
          .getAllMetadata();
      await CrashReportManager.logAllDBPrints(pendingPrints);
      await CrashReportManager.logAllPrints(pendingPrints);
      //await CrashReportManager.logHMData(pendingPrints);

      // ========== INCREMENT OFFLINE COUNTS ==========
      await PlanCountChangeHiveRepository().incrementOfflineCount(
        widget.planCode.toString(),
        widget.VillageCode.toString(),
        widget.villageName.toString(),
        widget.tensil.toString(),
      );

      await PlanCountChangeHiveRepository().incrementArtworkOfflineCount(
        widget.ServerID.toString(),
        widget.planCode.toString(),
        widget.VillageCode.toString(),
        widget.artworkId,
      );

      // ========== MARK LOCATE AS CAPTURED ==========
      // Check if locateId exists and is not empty
      if (widget.locateId != null &&
          widget.locateId!.trim().isNotEmpty &&
          widget.ServerID != null &&
          widget.ServerID!.trim().isNotEmpty) {
        try {
          await CapturedLocateRepository().markAsCaptured(
            widget.locateId!.trim(),
            widget.ServerID!.trim(),
          );
          print(
            "✅ Successfully marked locateId ${widget.locateId} as captured",
          );
        } catch (e) {
          print("⚠️ Failed to mark locate as captured: $e");
          // Don't fail the submission if marking fails
          // Log the error but continue with the submission
          await CrashReportManager.storeLogMessage(
            "event=mark_captured_failed | "
            "locateId=${widget.locateId} | "
            "error=$e | "
            "timestamp=${DateTime.now().toIso8601String()}",
          );
        }
      } else {
        print(
          "ℹ️ No locateId to mark as captured (locateId: ${widget.locateId})",
        );
      }

      // ========== UPLOAD COUNT ==========
      String uploadDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await UploadCountRepository().incrementUploadCount(uploadDate);

      // ========== CLEAR STATE ==========
      await _clearSavedState();

      // Clear in-memory images
      setState(() {
        for (var i = 0; i < images.length; i++) {
          images[i].imagePath = null;
          images[i].lat = 0.0;
          images[i].long = 0.0;
        }
      });

      AppSnackBar.showSuccess(
        context,
        S.of(context).submitPlan,
      );

      setState(() {
        isRefreshing = false;
      });

      // ========== NAVIGATE BACK ==========
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SeePlanScreen(changeLanguage: widget.changeLanguage),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      await CrashReportManager.storeCrashReport(
        error: "Submit details error: $e",
        stackTrace: StackTrace.current.toString(),
      );

      AppSnackBar.showError(
        context,
        S.of(context).errorOccurredSubmitting,
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
  // Manual rotate-button state (0-3 quarter turns), independent of the
  // baked-in orientation correction applied right after capture.
  int rotationQuarterTurns;
  TextEditingController printController;

  ImageData({
    this.imagePath,
    this.printNumber = '',
    this.lat = 0.0,
    this.long = 0.0,
    this.rotationQuarterTurns = 0,
  }) : printController = TextEditingController(text: printNumber);

  void dispose() {
    printController.dispose();
  }
}

// Enhanced Meta Row Components
class _EnhancedMetaRow extends StatelessWidget {
  const _EnhancedMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
    required this.secondValue,
  });

  final String label;
  final String value;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: neutralDarkColor,
                fontFamily: "Roboto",
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              "${value}W × ${secondValue}H",
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// Add these color definitions if they're not already in your project
const Color primaryColor = Color(0xFF2196F3);
const Color primaryLightColor = Color(0xFF64B5F6);
const Color accentColor = Color(0xFF03DAC6);
const Color neutralDarkColor = Color(0xFF212121);
