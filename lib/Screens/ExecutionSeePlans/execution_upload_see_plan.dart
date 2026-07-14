// import 'dart:async';
// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:canimage/Screens/ExecutionSeePlans/execution_see_plans.dart';
// import 'package:camera/camera.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:path/path.dart' as path;
// import '../../Hive_Database/execution_image_upload_db.dart';
// import '../../Repository/execution_image_upload_repository.dart';
// import '../../Repository/execution_balance_count_change_repository.dart';
// import '../../Repository/upload_count_repository.dart';
// import '../../generated/l10n.dart';
// import '../../main.dart';
// import '../../utils/crash_manager.dart';
// import '../../utils/fonts.dart';
// import '../landing/landing_screen.dart';
// import 'execution_map_screen.dart';
//
//
// class UploadSeePlanScreen extends StatefulWidget {
//   String? planCode;
//   String? VillageCode;
//   String? ServerID;
//   String? Address;
//   double? latitude;
//   double? longitude;
//   String? locateId;
//   final Function(String) changeLanguage;
//   var width;
//   var height;
//   var villageName;
//   var tensil;
//   var brand;
//   var artworkId;
//
//   UploadSeePlanScreen({
//     super.key,
//     required this.ServerID,
//     required this.Address,
//     required this.planCode,
//     required this.VillageCode,
//     required this.latitude,
//     required this.longitude,
//     required this.changeLanguage,
//     required this.height,
//     required this.width,
//     required this.villageName,
//     required this.brand,
//     required this.tensil,
//     required this.artworkId,
//     this.locateId,
//   });
//
//   static bool get isCameraActive => _UploadSeePlanScreenState.isCameraOpen;
//
//   @override
//   State<UploadSeePlanScreen> createState() => _UploadSeePlanScreenState();
// }
//
// class _UploadSeePlanScreenState extends State<UploadSeePlanScreen>
//     with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
//
//   static bool isCameraOpen = false;
//
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
//   // Camera controller
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isCameraInitialized = false;
//   bool _isCapturing = false;
//
//   int? _currentImageIndex;
//   int _timeoutRetryCount = 0;
//   DateTime? _lastTimeoutTime;
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
//
//     // Initialize cameras
//     _initCameras();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkAndRestoreState();
//     });
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
//     isCameraOpen = false;
//     _cameraController?.dispose();
//     super.dispose();
//   }
//
//   Future<void> _initCameras() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras != null && _cameras!.isNotEmpty) {
//         print("📷 Found ${_cameras!.length} cameras");
//         for (var cam in _cameras!) {
//           print("   - ${cam.name} (${cam.lensDirection})");
//         }
//       }
//     } catch (e) {
//       print("❌ Error initializing cameras: $e");
//     }
//   }
//
//   Future<void> _initializeCameraController() async {
//     if (_cameras == null || _cameras!.isEmpty) {
//       await _initCameras();
//     }
//
//     if (_cameras == null || _cameras!.isEmpty) {
//       throw Exception('No cameras available');
//     }
//
//     // Find rear camera (preferred) or fallback to first camera
//     CameraDescription cameraDescription = _cameras!.firstWhere(
//           (cam) => cam.lensDirection == CameraLensDirection.back,
//       orElse: () => _cameras!.first,
//     );
//
//     _cameraController = CameraController(
//       cameraDescription,
//       ResolutionPreset.medium, // Use medium for better performance
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.jpeg,
//     );
//
//     await _cameraController!.initialize();
//     _isCameraInitialized = true;
//     print("✅ Camera initialized: ${cameraDescription.name}");
//   }
//
//   void _cleanMemory() {
//     try {
//       imageCache.clear();
//       imageCache.clearLiveImages();
//       print("✅ Image cache cleared");
//     } catch (e) {
//       print("❌ Error clearing image cache: $e");
//     }
//     _cleanupTempFiles();
//   }
//
//   Future<void> _cleanupTempFiles() async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final files = tempDir.listSync();
//       int deletedCount = 0;
//
//       for (var file in files) {
//         if (file is File && (file.path.contains('.jpg') || file.path.contains('.png'))) {
//           try {
//             await file.delete();
//             deletedCount++;
//           } catch (e) {
//             // Ignore
//           }
//         }
//       }
//
//       if (deletedCount > 0) {
//         print("🗑️ Cleaned up $deletedCount temporary image files");
//       }
//     } catch (e) {
//       // Ignore
//     }
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
//         _cleanupTempFiles();
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
//         isCameraOpen = false;
//         _clearSavedState();
//         _cameraController?.dispose();
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
//   Future<String> _getDeviceInfo() async {
//     try {
//       final deviceInfo = await DeviceInfoPlugin().androidInfo;
//       return "Android ${deviceInfo.version.release} (SDK ${deviceInfo.version.sdkInt}) - ${deviceInfo.model}";
//     } catch (e) {
//       return "Unknown Device";
//     }
//   }
//
//   Future<bool> _isDeviceLowOnMemory() async {
//     try {
//       final info = await Process.run('dumpsys', ['meminfo']);
//       final output = info.stdout.toString();
//
//       final totalMatch = RegExp(r'Total RAM:\s+(\d+)').firstMatch(output);
//       final freeMatch = RegExp(r'Free RAM:\s+(\d+)').firstMatch(output);
//
//       if (totalMatch != null && freeMatch != null) {
//         final total = int.parse(totalMatch.group(1)!);
//         final free = int.parse(freeMatch.group(1)!);
//         final freePercent = (free / total) * 100;
//         print("📊 Memory: ${freePercent.toStringAsFixed(1)}% free");
//         return freePercent < 15;
//       }
//       return false;
//     } catch (e) {
//       print("⚠️ Could not check memory: $e");
//       return false;
//     }
//   }
//
//   Future<void> _pickImage(int index) async {
//     if (isPickingImage) {
//       print("🔄 Image picking already in progress, skipping");
//       return;
//     }
//
//     if (_timeoutRetryCount >= 3 && _lastTimeoutTime != null) {
//       final elapsed = DateTime.now().difference(_lastTimeoutTime!);
//       if (elapsed.inMinutes < 1) {
//         Fluttertoast.showToast(
//           msg: "⚠️ Too many retries. Please wait a moment.",
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.CENTER,
//           backgroundColor: Colors.orange,
//           textColor: Colors.white,
//         );
//         setState(() {
//           isPickingImage = false;
//           _isPickerActiveList[index] = false;
//         });
//         return;
//       }
//       _timeoutRetryCount = 0;
//     }
//
//     print("==============================================");
//     print("📸 CAMERA PICKER STARTED - Image ${index + 1}");
//     print("==============================================");
//     print("🕐 Timestamp: ${DateTime.now().toIso8601String()}");
//     print("📱 Device Info: ${await _getDeviceInfo()}");
//     print("📍 Image Index: $index");
//     print("==============================================");
//
//     try {
//       isCameraOpen = true;
//
//       setState(() {
//         isPickingImage = true;
//         _isPickerActiveList[index] = true;
//         _currentImageIndex = index;
//       });
//
//       // Check memory
//       if (await _isDeviceLowOnMemory()) {
//         print("⚠️ Device is low on memory");
//         Fluttertoast.showToast(
//           msg: "⚠️ Low memory detected. Please close other apps.",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.orange,
//           textColor: Colors.white,
//         );
//       }
//
//       // Request permissions
//       try {
//         print("🔐 Requesting camera permissions...");
//         await _requestCameraPermissions();
//         print("✅ Camera permissions granted");
//       } catch (e) {
//         print("❌ Camera permission error: $e");
//         isCameraOpen = false;
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
//       // Initialize camera
//       try {
//         await _initializeCameraController();
//         print("✅ Camera controller initialized");
//       } catch (e) {
//         print("❌ Camera initialization error: $e");
//         isCameraOpen = false;
//         setState(() {
//           isPickingImage = false;
//           _isPickerActiveList[index] = false;
//         });
//
//         await _showErrorDialogWithRetry(
//           context,
//           'Camera Error',
//           'Failed to initialize camera. Please try again.',
//           index,
//         );
//         return;
//       }
//
//       print("💾 Saving current state before opening camera...");
//       await _saveCurrentState();
//
//       // ========== OPEN CAMERA SCREEN ==========
//       final result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => CameraScreen(
//             imageIndex: index,
//             imageLabel: 'Image ${index + 1}',
//             targetLatitude: index == 0 ? widget.latitude : null,
//             targetLongitude: index == 0 ? widget.longitude : null,
//             referenceLatitude: (index == 2 || index == 6) && images[0].imagePath != null
//                 ? images[0].lat
//                 : null,
//             referenceLongitude: (index == 2 || index == 6) && images[0].imagePath != null
//                 ? images[0].long
//                 : null,
//             requirementText: _getRequirementText(index),
//             onImageCaptured: (path, lat, long) {
//               setState(() {
//                 images[index].imagePath = path;
//                 images[index].lat = lat;
//                 images[index].long = long;
//               });
//             },
//           ),
//         ),
//       );
//
//       // If user cancelled or returned
//       if (result == null) {
//         print("👤 User cancelled camera");
//       }
//
//       isCameraOpen = false;
//       await _clearSavedState();
//       print("✅ Saved state cleared successfully");
//
//       setState(() {
//         isPickingImage = false;
//         _isPickerActiveList[index] = false;
//       });
//
//     } catch (e, stackTrace) {
//       print("💥 ERROR in _pickImage:");
//       print("   Error: $e");
//       print("   StackTrace: $stackTrace");
//
//       isCameraOpen = false;
//       await _clearSavedState();
//
//       await CrashReportManager.storeCrashReport(
//         error: "Image picker error: $e",
//         stackTrace: stackTrace.toString(),
//       );
//
//       if (mounted) {
//         await _showErrorDialogWithRetry(
//           context,
//           'Camera Error',
//           'An error occurred. Please try again.',
//           index,
//         );
//       }
//     } finally {
//       print("🧹 Cleaning up camera picker state for index $index");
//       isCameraOpen = false;
//       if (mounted) {
//         setState(() {
//           isPickingImage = false;
//           _isPickerActiveList[index] = false;
//         });
//         FocusScope.of(context).unfocus();
//       }
//       print("==============================================");
//       print("📸 CAMERA PICKER COMPLETED - Image ${index + 1}");
//       print("==============================================");
//     }
//   }
//
//   String _getRequirementText(int index) {
//     if (index == 0) {
//       return '📍 Capture within 50m of target location';
//     } else if (index == 2) {
//       return '📍 Capture within 50m of Image 1 location';
//     } else if (index == 6) {
//       return '📍 Capture within 50m of Image 1 location';
//     } else {
//       return '📸 Capture clear photo of the area';
//     }
//   }
//
//   /// Compresses a captured image to the best possible quality while staying under 200 KB.
//   /// Single-pass with at most one corrective pass (no loop). Returns null on failure.
//   // Future<File?> _compressImageOnCapture(File imageFile, int imageIndex) async {
//   //   const int maxSizeKB = 200;
//   //
//   //   Future<File?> _compress(String srcPath, String dstPath, int quality) async {
//   //     final result = await FlutterImageCompress.compressAndGetFile(
//   //       srcPath,
//   //       dstPath,
//   //       quality: quality,
//   //       minHeight: 1024,
//   //       minWidth: 1024,
//   //       format: CompressFormat.jpeg,
//   //     );
//   //     if (result == null) return null;
//   //     final f = File(result.path);
//   //     return await f.exists() ? f : null;
//   //   }
//   //
//   //   try {
//   //     if (!await imageFile.exists()) return null;
//   //
//   //     final originalSizeKB = await imageFile.length() / 1024;
//   //     final dir = await getTemporaryDirectory();
//   //     final ts = DateTime.now().millisecondsSinceEpoch;
//   //
//   //     // Pick quality once, based on original size. Smaller originals keep higher quality.
//   //     final int quality = originalSizeKB <= maxSizeKB
//   //         ? 92
//   //         : originalSizeKB <= 500
//   //         ? 82
//   //         : originalSizeKB <= 1000
//   //         ? 72
//   //         : originalSizeKB <= 2000
//   //         ? 58
//   //         : originalSizeKB <= 4000
//   //         ? 46
//   //         : 36;
//   //
//   //     File? out = await _compress(imageFile.path, "${dir.path}/IMG_$ts.jpg", quality);
//   //     if (out == null) return null;
//   //
//   //     double sizeKB = await out.length() / 1024;
//   //
//   //     // Single bounded corrective pass — only if still over the limit.
//   //     if (sizeKB > maxSizeKB) {
//   //       final int corrected =
//   //       (quality * (maxSizeKB / sizeKB)).floor().clamp(15, 92);
//   //       final File? retry =
//   //       await _compress(imageFile.path, "${dir.path}/IMG_${ts}_c.jpg", corrected);
//   //       if (retry != null) {
//   //         try { await out!.delete(); } catch (_) {}
//   //         out = retry;
//   //         sizeKB = await out.length() / 1024;
//   //       }
//   //     }
//   //
//   //     // Best-effort cleanup of the original capture.
//   //     try { await imageFile.delete(); } catch (_) {}
//   //
//   //     if (kDebugMode) {
//   //       print("Image ${imageIndex + 1}: "
//   //           "${originalSizeKB.toStringAsFixed(0)}KB → ${sizeKB.toStringAsFixed(0)}KB (q=$quality)");
//   //     }
//   //
//   //     return out;
//   //   } catch (e, st) {
//   //     await CrashReportManager.storeCrashReport(
//   //       error: "Compression error: $e",
//   //       stackTrace: st.toString(),
//   //     );
//   //     return null;
//   //   }
//   // }
//
//   ///
//   /// Compresses a captured image to the best possible quality while staying under 200 KB.
//   /// Single-pass with at most one corrective pass (no loop). Returns null on failure.
//   Future<File?> _compressImageOnCapture(File imageFile, int imageIndex) async {
//     const int maxSizeKB = 200;
//
//     // ========== PRINT HEADER ==========
//     print("╔═════════════════════════════════════════════════════════════════════════╗");
//     print("║                    IMAGE PROCESSING FLOW                               ║");
//     print("╠═════════════════════════════════════════════════════════════════════════╣");
//     print("║  Image ${imageIndex + 1} of 7                                          ║");
//     print("╠═════════════════════════════════════════════════════════════════════════╣");
//
//     Future<File?> _compress(String srcPath, String dstPath, int quality) async {
//       final result = await FlutterImageCompress.compressAndGetFile(
//         srcPath,
//         dstPath,
//         quality: quality,
//         minHeight: 1024,
//         minWidth: 1024,
//         format: CompressFormat.jpeg,
//       );
//       if (result == null) return null;
//       final f = File(result.path);
//       return await f.exists() ? f : null;
//     }
//
//     try {
//       if (!await imageFile.exists()) {
//         print("║  ❌ ERROR: Source image file does not exist                           ║");
//         print("╚═════════════════════════════════════════════════════════════════════════╝");
//         return null;
//       }
//
//       // ========== STEP 1: USER TAKES PHOTO ==========
//       print("║                                                                         ║");
//       print("║  1. USER TAKES PHOTO                                                    ║");
//       print("║     ↓                                                                   ║");
//
//       final originalSizeBytes = await imageFile.length();
//       final originalSizeKB = originalSizeBytes / 1024;
//       final originalSizeMB = originalSizeKB / 1024;
//
//       String sizeStr;
//       if (originalSizeMB >= 1) {
//         sizeStr = "${originalSizeMB.toStringAsFixed(2)} MB";
//       } else {
//         sizeStr = "${originalSizeKB.toStringAsFixed(0)} KB";
//       }
//
//       print("║     Camera saves: ${imageFile.path.split('/').last} ($sizeStr)          ║");
//       print("║                                                                         ║");
//
//       // ========== STEP 2: DETERMINE QUALITY BASED ON SIZE ==========
//       print("║  2. ANALYZING IMAGE SIZE                                               ║");
//       print("║     ↓                                                                   ║");
//
//       // Pick quality based on original size
//       final int quality = originalSizeKB <= maxSizeKB
//           ? 92
//           : originalSizeKB <= 500
//           ? 82
//           : originalSizeKB <= 1000
//           ? 72
//           : originalSizeKB <= 2000
//           ? 58
//           : originalSizeKB <= 4000
//           ? 46
//           : 36;
//
//       print("║     Original Size: ${originalSizeKB.toStringAsFixed(0)} KB              ║");
//       print("║     Selected Quality: $quality%                                         ║");
//       print("║                                                                         ║");
//
//       // ========== STEP 3: COMPRESSING IMAGE ==========
//       print("║  3. COMPRESSING IMAGE                                                  ║");
//       print("║     ↓                                                                   ║");
//
//       final dir = await getTemporaryDirectory();
//       final ts = DateTime.now().millisecondsSinceEpoch;
//       final String tempPath = "${dir.path}/IMG_$ts.jpg";
//
//       File? out = await _compress(imageFile.path, tempPath, quality);
//       if (out == null) {
//         print("║  ❌ Compression failed                                                 ║");
//         print("╚═════════════════════════════════════════════════════════════════════════╝");
//         return null;
//       }
//
//       final compressedSizeBytes = await out.length();
//       final compressedSizeKB = compressedSizeBytes / 1024;
//       final compressedSizeMB = compressedSizeKB / 1024;
//
//       String compressedStr;
//       if (compressedSizeMB >= 1) {
//         compressedStr = "${compressedSizeMB.toStringAsFixed(2)} MB";
//       } else {
//         compressedStr = "${compressedSizeKB.toStringAsFixed(0)} KB";
//       }
//
//       print("║     Compressed to: $compressedStr (q=$quality%)                         ║");
//       print("║                                                                         ║");
//
//       // ========== STEP 4: CHECK IF UNDER 200KB ==========
//       print("║  4. CHECKING SIZE LIMIT                                                ║");
//       print("║     ↓                                                                   ║");
//       print("║     Target Size: ≤ $maxSizeKB KB                                        ║");
//       print("║     Current Size: ${compressedSizeKB.toStringAsFixed(0)} KB              ║");
//
//       // Single bounded corrective pass — only if still over the limit
//       if (compressedSizeKB > maxSizeKB) {
//         print("║     ⚠️  Over limit! Correcting...                                       ║");
//         print("║     ↓                                                                   ║");
//
//         final int corrected = (quality * (maxSizeKB / compressedSizeKB)).floor().clamp(15, 92);
//         final File? retry = await _compress(
//             imageFile.path,
//             "${dir.path}/IMG_${ts}_c.jpg",
//             corrected
//         );
//
//         if (retry != null) {
//           try { await out!.delete(); } catch (_) {}
//           out = retry;
//           final correctedSizeBytes = await out.length();
//           final correctedSizeKB = correctedSizeBytes / 1024;
//
//           String correctedStr;
//           if (correctedSizeKB >= 1024) {
//             correctedStr = "${(correctedSizeKB / 1024).toStringAsFixed(2)} MB";
//           } else {
//             correctedStr = "${correctedSizeKB.toStringAsFixed(0)} KB";
//           }
//
//           print("║     Retry with Quality: $corrected%                                   ║");
//           print("║     New Size: $correctedStr                                           ║");
//           print("║     ↓                                                                   ║");
//         }
//       } else {
//         print("║     ✅ Within target size!                                              ║");
//       }
//
//       // ========== STEP 5: FINAL SIZE ==========
//       final finalSizeBytes = await out.length();
//       final finalSizeKB = finalSizeBytes / 1024;
//       final finalSizeMB = finalSizeKB / 1024;
//
//       String finalStr;
//       if (finalSizeMB >= 1) {
//         finalStr = "${finalSizeMB.toStringAsFixed(2)} MB";
//       } else {
//         finalStr = "${finalSizeKB.toStringAsFixed(0)} KB";
//       }
//
//       print("║                                                                         ║");
//       print("║  5. FINAL RESULT                                                       ║");
//       print("║     ↓                                                                   ║");
//       print("║     📁 Original: ${originalSizeKB.toStringAsFixed(0)} KB                 ║");
//       print("║     📁 Final:    $finalStr                                              ║");
//
//       final savedKB = originalSizeKB - finalSizeKB;
//       final savedPercent = (savedKB / originalSizeKB * 100);
//       print("║     💾 Saved:    ${savedKB.toStringAsFixed(0)} KB (${savedPercent.toStringAsFixed(0)}%)   ║");
//
//       final isWithinTarget = finalSizeKB >= 100 && finalSizeKB <= 200;
//       if (isWithinTarget) {
//         print("║     ✅ Status:   Within target (100-200 KB)                            ║");
//       } else if (finalSizeKB < 100) {
//         print("║     ⚠️  Status:   Below target (< 100 KB) - Quality may be low         ║");
//       } else {
//         print("║     ⚠️  Status:   Above target (> 200 KB) - Try lower quality          ║");
//       }
//
//       // ========== STEP 6: CLEANUP ==========
//       print("║                                                                         ║");
//       print("║  6. CLEANUP                                                           ║");
//       print("║     ↓                                                                   ║");
//
//       // Best-effort cleanup of the original capture
//       try {
//         await imageFile.delete();
//         print("║     🗑️  Original file deleted                                          ║");
//       } catch (_) {
//         print("║     ⚠️  Could not delete original file                                 ║");
//       }
//
//       // ========== FOOTER ==========
//       print("╚═════════════════════════════════════════════════════════════════════════╝");
//
//       // Single line summary for quick view
//       print("📊 Image ${imageIndex + 1}: ${originalSizeKB.toStringAsFixed(0)}KB → ${finalSizeKB.toStringAsFixed(0)}KB (q=$quality)");
//
//       return out;
//
//     } catch (e, st) {
//       print("║  ❌ ERROR: ${e.toString().substring(0, 70)}...                          ║");
//       print("╚═════════════════════════════════════════════════════════════════════════╝");
//
//       await CrashReportManager.storeCrashReport(
//         error: "Compression error: $e",
//         stackTrace: st.toString(),
//       );
//       return null;
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
//             builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage),
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
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MapScreen(
//             planCode: widget.planCode,
//             VillageCode: widget.VillageCode,
//             ServerID: widget.ServerID,
//             changeLanguage: widget.changeLanguage,
//             height: widget.height,
//             width: widget.width,
//             villageName: widget.villageName,
//             brand: widget.brand,
//             tensil: widget.tensil,
//             artworkId: widget.artworkId,
//           ),
//         ),
//       );
//     }
//   }
//
//   Future<void> _requestCameraPermissions() async {
//     print("🔐 Checking camera permissions...");
//
//     final permissions = await [
//       Permission.camera,
//       Permission.storage,
//       Permission.photos,
//     ].request();
//
//     print("📊 Permission results:");
//     print("   Camera: ${permissions[Permission.camera]}");
//     print("   Storage: ${permissions[Permission.storage]}");
//     print("   Photos: ${permissions[Permission.photos]}");
//
//     if (permissions[Permission.camera] != PermissionStatus.granted) {
//       print("❌ Camera permission NOT granted");
//       throw PlatformException(
//         code: "CAMERA_PERMISSION_DENIED",
//         message: S.of(context).cameraPermission,
//       );
//     }
//     print("✅ All permissions granted");
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
//   Future<String> _storeImageInInternalDocuments(String imagePath) async {
//     try {
//       Directory? externalDir = await getExternalStorageDirectory();
//       if (externalDir == null) {
//         throw 'Unable to access external storage directory';
//       }
//
//       Directory appDocDir = Directory('${externalDir.path}/CIMTDWP');
//       if (!await appDocDir.exists()) {
//         await appDocDir.create(recursive: true);
//       }
//
//       Directory dwPaintingDir = Directory(
//           '${appDocDir.path}/Execution/Plans/${widget.ServerID}/${widget.planCode}/${widget.VillageCode}/${printNoController1.text}${printNoController2.text}/Images'
//       );
//
//       if (!await dwPaintingDir.exists()) {
//         await dwPaintingDir.create(recursive: true);
//       }
//
//       File imageFile = File(imagePath);
//       if (!await imageFile.exists()) {
//         throw 'Source image file does not exist: $imagePath';
//       }
//
//       var imageBytes = await imageFile.readAsBytes();
//
//       var result = await FlutterImageCompress.compressWithList(
//         imageBytes,
//         minWidth: 800,
//         minHeight: 800,
//         quality: 80,
//         format: CompressFormat.png,
//       );
//
//       if (result == null) {
//         throw 'Image compression failed';
//       }
//
//       String imageName = 'Img_${DateTime.now().toIso8601String().replaceAll(RegExp('[^0-9]'), '')}.png';
//       String imagePathInStorage = '${dwPaintingDir.path}/$imageName';
//
//       File compressedImage = File(imagePathInStorage);
//       await compressedImage.writeAsBytes(result);
//
//       if (!await compressedImage.exists()) {
//         throw 'Failed to write compressed image to storage';
//       }
//
//       return imagePathInStorage;
//
//     } catch (e) {
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
//       MaterialPageRoute(builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage,)),
//     );
//     return false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
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
//                 // Header Card
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
//                         _EnhancedMetaRow(label: S.of(context).villageNameMap, value: widget.villageName),
//                         _EnhancedMetaRow(label: S.of(context).brand, value: widget.brand),
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
//                 // Images Grid Section
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
//                 // Submit Button
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
//
//   Future<bool> _checkNetworkConnectivity() async {
//     try {
//       final connectivityResult = await Connectivity().checkConnectivity();
//       return connectivityResult == ConnectivityResult.mobile ||
//           connectivityResult == ConnectivityResult.wifi;
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
//     String fullPrintNumber = '$printNumber1$printNumber2';
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
//       bool isNetworkAvailable = await _checkNetworkConnectivity();
//       String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//
//       // Store images with improved compression
//       for (var i = 0; i < images.length; i++) {
//         if (images[i].imagePath != null) {
//           final compressedImagePath = await _storeImageInInternalDocuments(images[i].imagePath!);
//           images[i].imagePath = compressedImagePath;
//         }
//       }
//
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
//         VillageName: widget.villageName,
//         Tensil: widget.tensil,
//         createdAt: DateTime.now(),
//         networkFlagString: isNetworkAvailable ? "online" : "offline",
//         locateId: widget.locateId,
//       );
//
//       await ExecutionImageUploadHiveRepository().saveMetadata(metadata);
//       await PlanCountChangeHiveRepository().incrementOfflineCount(
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
//         widget.artworkId,
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
//               builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage)
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
// }
//
// // ImageData class
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
// // Enhanced Meta Row Components
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
// // Colors
// const Color primaryColor = Color(0xFF2196F3);
// const Color primaryLightColor = Color(0xFF64B5F6);
// const Color accentColor = Color(0xFF03DAC6);
// const Color neutralDarkColor = Color(0xFF212121);
//
//
//
//
// // class CameraScreen extends StatefulWidget {
// //   final Function(String, double, double) onImageCaptured;
// //   final int imageIndex;
// //   final double? targetLatitude;
// //   final double? targetLongitude;
// //   final double? referenceLatitude;
// //   final double? referenceLongitude;
// //   final String imageLabel;
// //   final String requirementText;
// //   final VoidCallback? onRefreshLocation;
// //
// //   const CameraScreen({
// //     super.key,
// //     required this.onImageCaptured,
// //     required this.imageIndex,
// //     this.targetLatitude,
// //     this.targetLongitude,
// //     this.referenceLatitude,
// //     this.referenceLongitude,
// //     required this.imageLabel,
// //     required this.requirementText,
// //     this.onRefreshLocation,
// //   });
// //
// //   @override
// //   State<CameraScreen> createState() => _CameraScreenState();
// // }
// //
// // class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
// //   CameraController? _cameraController;
// //   bool _isCameraInitialized = false;
// //   bool _isCapturing = false;
// //   bool _isProcessing = false;
// //   Position? _currentPosition;
// //   bool _isLocationValid = false;
// //   String _locationError = '';
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addObserver(this);
// //     _initializeCamera();
// //     _getCurrentLocation();
// //   }
// //
// //   @override
// //   void dispose() {
// //     WidgetsBinding.instance.removeObserver(this);
// //     _cameraController?.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   void didChangeAppLifecycleState(AppLifecycleState state) {
// //     if (state == AppLifecycleState.paused) {
// //       _cameraController?.pausePreview();
// //     } else if (state == AppLifecycleState.resumed) {
// //       _cameraController?.resumePreview();
// //     }
// //   }
// //
// //   Future<void> _getCurrentLocation() async {
// //     try {
// //       setState(() {
// //         _isLocationValid = false;
// //         _locationError = '';
// //       });
// //
// //       final position = await Geolocator.getCurrentPosition(
// //         desiredAccuracy: LocationAccuracy.high,
// //         timeLimit: Duration(seconds: 10),
// //       );
// //
// //       setState(() {
// //         _currentPosition = position;
// //         _isLocationValid = true;
// //         _locationError = '';
// //       });
// //
// //       // Check location validity
// //       if (widget.targetLatitude != null && widget.targetLongitude != null) {
// //         double distance = _calculateDistance(
// //           position.latitude,
// //           position.longitude,
// //           widget.targetLatitude!,
// //           widget.targetLongitude!,
// //         );
// //
// //         if (distance > 50) {
// //           setState(() {
// //             _isLocationValid = false;
// //             _locationError = 'You are ${distance.toStringAsFixed(0)}m away. Must be within 50m.';
// //           });
// //           Fluttertoast.showToast(
// //             msg: " ${_locationError}",
// //             toastLength: Toast.LENGTH_LONG,
// //             gravity: ToastGravity.CENTER,
// //             backgroundColor: Colors.orange,
// //             textColor: Colors.white,
// //           );
// //         }
// //       }
// //
// //       // Check distance from reference image (for image 3 and 7)
// //       if (widget.referenceLatitude != null && widget.referenceLongitude != null) {
// //         double distanceFromReference = _calculateDistance(
// //           position.latitude,
// //           position.longitude,
// //           widget.referenceLatitude!,
// //           widget.referenceLongitude!,
// //         );
// //
// //         if (distanceFromReference > 50) {
// //           setState(() {
// //             _isLocationValid = false;
// //             _locationError = 'You are ${distanceFromReference.toStringAsFixed(0)}m away from reference image. Must be within 50m.';
// //           });
// //           Fluttertoast.showToast(
// //             msg: " ${_locationError}",
// //             toastLength: Toast.LENGTH_LONG,
// //             gravity: ToastGravity.CENTER,
// //             backgroundColor: Colors.orange,
// //             textColor: Colors.white,
// //           );
// //         }
// //       }
// //
// //     } catch (e) {
// //       setState(() {
// //         _isLocationValid = false;
// //         _locationError = 'Unable to get location. Please enable GPS.';
// //       });
// //       Fluttertoast.showToast(
// //         msg: " Please enable GPS",
// //         toastLength: Toast.LENGTH_LONG,
// //         gravity: ToastGravity.CENTER,
// //         backgroundColor: Colors.red,
// //         textColor: Colors.white,
// //       );
// //     }
// //   }
// //
// //   double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
// //     return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
// //   }
// //
// //   Future<void> _initializeCamera() async {
// //     try {
// //       if (cameras == null || cameras!.isEmpty) {
// //         throw Exception('No cameras available');
// //       }
// //
// //       CameraDescription cameraDescription = cameras!.firstWhere(
// //             (cam) => cam.lensDirection == CameraLensDirection.back,
// //         orElse: () => cameras!.first,
// //       );
// //
// //       _cameraController = CameraController(
// //         cameraDescription,
// //         ResolutionPreset.high,
// //         enableAudio: false,
// //         imageFormatGroup: ImageFormatGroup.jpeg,
// //       );
// //
// //       await _cameraController!.initialize();
// //
// //       setState(() {
// //         _isCameraInitialized = true;
// //       });
// //
// //       print(" Camera initialized: ${cameraDescription.name}");
// //
// //     } catch (e) {
// //       print(" Camera initialization error: $e");
// //       Fluttertoast.showToast(
// //         msg: "Failed to initialize camera: $e",
// //         toastLength: Toast.LENGTH_LONG,
// //         gravity: ToastGravity.CENTER,
// //         backgroundColor: Colors.red,
// //         textColor: Colors.white,
// //       );
// //     }
// //   }
// //
// //   Future<void> _captureImage() async {
// //     if (_isCapturing || _isProcessing || !_isCameraInitialized || _cameraController == null) {
// //       return;
// //     }
// //
// //     if (!_isLocationValid) {
// //       Fluttertoast.showToast(
// //         msg: "⚠️ Please move to valid location first",
// //         toastLength: Toast.LENGTH_LONG,
// //         gravity: ToastGravity.CENTER,
// //         backgroundColor: Colors.orange,
// //         textColor: Colors.white,
// //       );
// //       return;
// //     }
// //
// //     setState(() {
// //       _isCapturing = true;
// //     });
// //
// //     try {
// //       final XFile picture = await _cameraController!.takePicture();
// //       print("📸 Picture captured: ${picture.path}");
// //
// //       setState(() {
// //         _isProcessing = true;
// //       });
// //
// //       final File imageFile = File(picture.path);
// //       File? compressedFile = await _compressImageOnCapture(imageFile);
// //
// //       String finalImagePath;
// //       if (compressedFile != null) {
// //         finalImagePath = compressedFile.path;
// //       } else {
// //         finalImagePath = picture.path;
// //       }
// //
// //       widget.onImageCaptured(
// //         finalImagePath,
// //         _currentPosition!.latitude,
// //         _currentPosition!.longitude,
// //       );
// //
// //       Fluttertoast.showToast(
// //         msg: "✅ Image captured successfully",
// //         toastLength: Toast.LENGTH_SHORT,
// //         gravity: ToastGravity.BOTTOM,
// //         backgroundColor: Colors.green,
// //         textColor: Colors.white,
// //       );
// //
// //       if (mounted) {
// //         Navigator.pop(context);
// //       }
// //
// //     } catch (e) {
// //       print("❌ Capture error: $e");
// //       Fluttertoast.showToast(
// //         msg: "Failed to capture image: $e",
// //         toastLength: Toast.LENGTH_LONG,
// //         gravity: ToastGravity.CENTER,
// //         backgroundColor: Colors.red,
// //         textColor: Colors.white,
// //       );
// //
// //       setState(() {
// //         _isCapturing = false;
// //         _isProcessing = false;
// //       });
// //     }
// //   }
// //
// //   Future<File?> _compressImageOnCapture(File imageFile) async {
// //     try {
// //       final originalSizeKB = await imageFile.length() / 1024;
// //       print(" Original Size: ${originalSizeKB.toStringAsFixed(2)} KB");
// //
// //       final dir = await getTemporaryDirectory();
// //       final targetPath = "${dir.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.jpg";
// //
// //       final compressed = await FlutterImageCompress.compressAndGetFile(
// //         imageFile.path,
// //         targetPath,
// //         quality: 75,
// //         minHeight: 800,
// //         format: CompressFormat.jpeg,
// //       );
// //
// //       if (compressed != null) {
// //         final compressedSizeKB = await File(compressed.path).length() / 1024;
// //         print(" Compressed Size: ${compressedSizeKB.toStringAsFixed(2)} KB");
// //         return File(compressed.path);
// //       }
// //
// //       return null;
// //
// //     } catch (e) {
// //       print(" Compression error: $e");
// //       return null;
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       body: SafeArea(
// //         child: Stack(
// //           children: [
// //             // Camera Preview
// //             if (_isCameraInitialized && _cameraController != null)
// //               Positioned.fill(
// //                 child: CameraPreview(_cameraController!),
// //               )
// //             else
// //               const Center(
// //                 child: CircularProgressIndicator(
// //                   color: Colors.white,
// //                 ),
// //               ),
// //
// //             // Location Status
// //             // Positioned(
// //             //   top: 16,
// //             //   left: 16,
// //             //   right: 16,
// //             //   child: Container(
// //             //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //             //     // decoration: BoxDecoration(
// //             //     //   color: _isLocationValid
// //             //     //       ? Colors.green.withOpacity(0.8)
// //             //     //       : Colors.red.withOpacity(0.8),
// //             //     //   borderRadius: BorderRadius.circular(12),
// //             //     // ),
// //             //     child: Row(
// //             //       children: [
// //             //         // Icon(
// //             //         //   _isLocationValid ? Icons.check_circle : Icons.warning,
// //             //         //   color: Colors.white,
// //             //         //   size: 20,
// //             //         // ),
// //             //         SizedBox(width: 8),
// //             //         // Expanded(
// //             //         //   child: Text(
// //             //         //     _isLocationValid
// //             //         //         ? '✅ Location valid'
// //             //         //         : _locationError.isNotEmpty ? _locationError : '⚠️ Location invalid',
// //             //         //     style: TextStyle(
// //             //         //       color: Colors.white,
// //             //         //       fontSize: 12,
// //             //         //       fontWeight: FontWeight.w500,
// //             //         //     ),
// //             //         //   ),
// //             //         // ),
// //             //        // if (!_isLocationValid)
// //             //           // IconButton(
// //             //           //   icon: Icon(Icons.refresh, color: Colors.white, size: 20),
// //             //           //   onPressed: _getCurrentLocation,
// //             //           // ),
// //             //       ],
// //             //     ),
// //             //   ),
// //             // ),
// //
// //             // Image Label
// //
// //             Positioned(
// //               top: 80,
// //               left: 0,
// //               right: 0,
// //               child: Center(
// //                 child: Container(
// //                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
// //                   decoration: BoxDecoration(
// //                     color: Colors.black.withOpacity(0.6),
// //                     borderRadius: BorderRadius.circular(20),
// //                   ),
// //                   child: Text(
// //                     '${widget.imageLabel} (${widget.imageIndex + 1}/7)',
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //
// //             // Requirement Text
// //             Positioned(
// //               top: 130,
// //               left: 16,
// //               right: 16,
// //               child: Center(
// //                 child: Container(
// //                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
// //                   decoration: BoxDecoration(
// //                     color: Colors.black.withOpacity(0.5),
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   child: Text(
// //                     widget.requirementText,
// //                     style: TextStyle(
// //                       color: Colors.white70,
// //                       fontSize: 11,
// //                     ),
// //                     textAlign: TextAlign.center,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //
// //             // Capture Button
// //             Positioned(
// //               bottom: 50,
// //               left: 0,
// //               right: 0,
// //               child: Center(
// //                 child: GestureDetector(
// //                   onTap: _captureImage,
// //                   child: Container(
// //                     width: 80,
// //                     height: 80,
// //                     decoration: BoxDecoration(
// //                       shape: BoxShape.circle,
// //                       color: Colors.white,
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.black.withOpacity(0.3),
// //                           blurRadius: 10,
// //                           offset: Offset(0, 4),
// //                         ),
// //                       ],
// //                     ),
// //                     child: Center(
// //                       child: Container(
// //                         width: 68,
// //                         height: 68,
// //                         decoration: BoxDecoration(
// //                           shape: BoxShape.circle,
// //                           color: Colors.white,
// //                           border: Border.all(
// //                             color: Colors.grey[400]!,
// //                             width: 2,
// //                           ),
// //                         ),
// //                         child: _isCapturing || _isProcessing
// //                             ? Center(
// //                           child: SizedBox(
// //                             width: 30,
// //                             height: 30,
// //                             child: CircularProgressIndicator(
// //                               strokeWidth: 3,
// //                               valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
// //                             ),
// //                           ),
// //                         )
// //                             : null,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //
// //             // Cancel Button
// //             Positioned(
// //               bottom: 50,
// //               left: 30,
// //               child: GestureDetector(
// //                 onTap: () {
// //                   _cameraController?.dispose();
// //                   Navigator.pop(context);
// //                 },
// //                 child: Container(
// //                   padding: EdgeInsets.all(12),
// //                   decoration: BoxDecoration(
// //                     color: Colors.black.withOpacity(0.6),
// //                     shape: BoxShape.circle,
// //                   ),
// //                   child: Icon(
// //                     Icons.close,
// //                     color: Colors.white,
// //                     size: 28,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //
// //             // Retry Location Button
// //             // Positioned(
// //             //   bottom: 50,
// //             //   right: 30,
// //             //   child: GestureDetector(
// //             //     onTap: _getCurrentLocation,
// //             //     child: Container(
// //             //       padding: EdgeInsets.all(12),
// //             //       // decoration: BoxDecoration(
// //             //       //   color: Colors.black.withOpacity(0.6),
// //             //       //   shape: BoxShape.circle,
// //             //       // ),
// //             //       // child: Icon(
// //             //       //   Icons.gps_fixed,
// //             //       //   color: _isLocationValid ? Colors.green : Colors.white,
// //             //       //   size: 28,
// //             //       // ),
// //             //     ),
// //             //   ),
// //             // ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
// class CameraScreen extends StatefulWidget {
//   final Function(String, double, double) onImageCaptured;
//   final int imageIndex;
//   final double? targetLatitude;
//   final double? targetLongitude;
//   final double? referenceLatitude;
//   final double? referenceLongitude;
//   final String imageLabel;
//   final String requirementText;
//   final VoidCallback? onRefreshLocation;
//
//   const CameraScreen({
//     super.key,
//     required this.onImageCaptured,
//     required this.imageIndex,
//     this.targetLatitude,
//     this.targetLongitude,
//     this.referenceLatitude,
//     this.referenceLongitude,
//     required this.imageLabel,
//     required this.requirementText,
//     this.onRefreshLocation,
//   });
//
//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }
//
// class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
//   CameraController? _cameraController;
//   bool _isCameraInitialized = false;
//   bool _isCapturing = false;
//   bool _isProcessing = false;
//   Position? _currentPosition;
//   bool _isLocationValid = false;
//   String _locationError = '';
//
//   // Camera toggle
//   int _cameraIndex = 0; // 0 = back, 1 = front
//   List<CameraDescription> _availableCameras = [];
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeCameras();
//     _getCurrentLocation();
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _cameraController?.dispose();
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       _cameraController?.pausePreview();
//     } else if (state == AppLifecycleState.resumed) {
//       _cameraController?.resumePreview();
//     }
//   }
//
//   Future<void> _initializeCameras() async {
//     try {
//       if (cameras == null || cameras!.isEmpty) {
//         throw Exception('No cameras available');
//       }
//
//       _availableCameras = cameras!;
//
//       // Start with back camera
//       _cameraIndex = 0;
//       for (int i = 0; i < _availableCameras.length; i++) {
//         if (_availableCameras[i].lensDirection == CameraLensDirection.back) {
//           _cameraIndex = i;
//           break;
//         }
//       }
//
//       await _initializeCamera(_cameraIndex);
//
//     } catch (e) {
//       print("❌ Camera initialization error: $e");
//       Fluttertoast.showToast(
//         msg: "Failed to initialize camera: $e",
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.CENTER,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     }
//   }
//
//   Future<void> _initializeCamera(int index) async {
//     try {
//       if (_availableCameras.isEmpty) {
//         throw Exception('No cameras available');
//       }
//
//       if (index >= _availableCameras.length) {
//         index = 0;
//       }
//
//       // Dispose old controller if exists
//       if (_cameraController != null) {
//         await _cameraController!.dispose();
//       }
//
//       final cameraDescription = _availableCameras[index];
//
//       _cameraController = CameraController(
//         cameraDescription,
//         ResolutionPreset.high,
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.jpeg,
//       );
//
//       await _cameraController!.initialize();
//
//       setState(() {
//         _isCameraInitialized = true;
//       });
//
//       print("✅ Camera initialized: ${cameraDescription.name} (${cameraDescription.lensDirection})");
//
//     } catch (e) {
//       print("❌ Camera initialization error: $e");
//       setState(() {
//         _isCameraInitialized = false;
//       });
//       Fluttertoast.showToast(
//         msg: "Failed to switch camera: $e",
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.CENTER,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     }
//   }
//
//   Future<void> _toggleCamera() async {
//     if (_availableCameras.length < 2) {
//       Fluttertoast.showToast(
//         msg: "Only one camera available",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.CENTER,
//         backgroundColor: Colors.orange,
//         textColor: Colors.white,
//       );
//       return;
//     }
//
//     setState(() {
//       _isCameraInitialized = false;
//     });
//
//     // Switch to next camera
//     _cameraIndex = (_cameraIndex + 1) % _availableCameras.length;
//
//     await _initializeCamera(_cameraIndex);
//   }
//
//   Future<void> _getCurrentLocation() async {
//     try {
//       setState(() {
//         _isLocationValid = false;
//         _locationError = '';
//       });
//
//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: Duration(seconds: 10),
//       );
//
//       setState(() {
//         _currentPosition = position;
//         _isLocationValid = true;
//         _locationError = '';
//       });
//
//       if (widget.targetLatitude != null && widget.targetLongitude != null) {
//         double distance = _calculateDistance(
//           position.latitude,
//           position.longitude,
//           widget.targetLatitude!,
//           widget.targetLongitude!,
//         );
//
//         if (distance > 50) {
//           setState(() {
//             _isLocationValid = false;
//             _locationError = 'You are ${distance.toStringAsFixed(0)}m away. Must be within 50m.';
//           });
//           Fluttertoast.showToast(
//             msg: "⚠️ ${_locationError}",
//             toastLength: Toast.LENGTH_LONG,
//             gravity: ToastGravity.CENTER,
//             backgroundColor: Colors.orange,
//             textColor: Colors.white,
//           );
//         }
//       }
//
//       if (widget.referenceLatitude != null && widget.referenceLongitude != null) {
//         double distanceFromReference = _calculateDistance(
//           position.latitude,
//           position.longitude,
//           widget.referenceLatitude!,
//           widget.referenceLongitude!,
//         );
//
//         if (distanceFromReference > 50) {
//           setState(() {
//             _isLocationValid = false;
//             _locationError = 'You are ${distanceFromReference.toStringAsFixed(0)}m away from reference image. Must be within 50m.';
//           });
//           Fluttertoast.showToast(
//             msg: "⚠️ ${_locationError}",
//             toastLength: Toast.LENGTH_LONG,
//             gravity: ToastGravity.CENTER,
//             backgroundColor: Colors.orange,
//             textColor: Colors.white,
//           );
//         }
//       }
//
//     } catch (e) {
//       setState(() {
//         _isLocationValid = false;
//         _locationError = 'Unable to get location. Please enable GPS.';
//       });
//       Fluttertoast.showToast(
//         msg: "⚠️ Please enable GPS",
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.CENTER,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     }
//   }
//
//   double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
//   }
//
//   Future<void> _captureImage() async {
//     if (_isCapturing || _isProcessing || !_isCameraInitialized || _cameraController == null) {
//       return;
//     }
//
//     if (!_isLocationValid) {
//       Fluttertoast.showToast(
//         msg: "⚠️ Please move to valid location first",
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.CENTER,
//         backgroundColor: Colors.orange,
//         textColor: Colors.white,
//       );
//       return;
//     }
//
//     setState(() {
//       _isCapturing = true;
//     });
//
//     try {
//       final XFile picture = await _cameraController!.takePicture();
//       print("📸 Picture captured: ${picture.path}");
//
//       setState(() {
//         _isProcessing = true;
//       });
//
//       final File imageFile = File(picture.path);
//       File? compressedFile = await _compressImageOnCapture(imageFile);
//
//       String finalImagePath;
//       if (compressedFile != null) {
//         finalImagePath = compressedFile.path;
//       } else {
//         finalImagePath = picture.path;
//       }
//
//       widget.onImageCaptured(
//         finalImagePath,
//         _currentPosition!.latitude,
//         _currentPosition!.longitude,
//       );
//
//       Fluttertoast.showToast(
//         msg: "✅ Image captured successfully",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.green,
//         textColor: Colors.white,
//       );
//
//       if (mounted) {
//         Navigator.pop(context);
//       }
//
//     } catch (e) {
//       print("❌ Capture error: $e");
//       Fluttertoast.showToast(
//         msg: "Failed to capture image: $e",
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.CENTER,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//
//       setState(() {
//         _isCapturing = false;
//         _isProcessing = false;
//       });
//     }
//   }
//
//   Future<File?> _compressImageOnCapture(File imageFile) async {
//     try {
//       final originalSizeKB = await imageFile.length() / 1024;
//       print("📁 Original Size: ${originalSizeKB.toStringAsFixed(2)} KB");
//
//       final dir = await getTemporaryDirectory();
//       final targetPath = "${dir.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.jpg";
//
//       final compressed = await FlutterImageCompress.compressAndGetFile(
//         imageFile.path,
//         targetPath,
//         quality: 75,
//         minHeight: 800,
//         format: CompressFormat.jpeg,
//       );
//
//       if (compressed != null) {
//         final compressedSizeKB = await File(compressed.path).length() / 1024;
//         print("📁 Compressed Size: ${compressedSizeKB.toStringAsFixed(2)} KB");
//         return File(compressed.path);
//       }
//
//       return null;
//
//     } catch (e) {
//       print("❌ Compression error: $e");
//       return null;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // Camera Preview
//             if (_isCameraInitialized && _cameraController != null)
//               Positioned.fill(
//                 child: CameraPreview(_cameraController!),
//               )
//             else
//               const Center(
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                 ),
//               ),
//
//             // ========== LOCATION STATUS ==========
//
//
//             // ========== CAMERA INDICATOR ==========
//             // Positioned(
//             //   top: 80,
//             //   left: 20,
//             //   child: Container(
//             //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             //     // decoration: BoxDecoration(
//             //     //   color: Colors.black.withOpacity(0.6),
//             //     //   borderRadius: BorderRadius.circular(12),
//             //     // ),
//             //     child: Text(
//             //       _cameraController != null && _cameraController!.description.lensDirection == CameraLensDirection.front
//             //           ? '📸 Front'
//             //           : '📸 Back',
//             //       style: TextStyle(
//             //         color: Colors.white,
//             //         fontSize: 12,
//             //         fontWeight: FontWeight.w500,
//             //       ),
//             //     ),
//             //   ),
//             // ),
//
//             // ========== IMAGE LABEL - HIDDEN ==========
//             // Positioned(
//             //   top: 130,
//             //   left: 0,
//             //   right: 0,
//             //   child: Center(
//             //     child: Container(
//             //       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//             //       decoration: BoxDecoration(
//             //         color: Colors.black.withOpacity(0.6),
//             //         borderRadius: BorderRadius.circular(20),
//             //       ),
//             //       child: Text(
//             //         '${widget.imageLabel} (${widget.imageIndex + 1}/7)',
//             //         style: TextStyle(
//             //           color: Colors.white,
//             //           fontSize: 16,
//             //           fontWeight: FontWeight.w600,
//             //         ),
//             //       ),
//             //     ),
//             //   ),
//             // ),
//
//             // ========== REQUIREMENT TEXT - HIDDEN ==========
//             // Positioned(
//             //   top: 170,
//             //   left: 16,
//             //   right: 16,
//             //   child: Center(
//             //     child: Container(
//             //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//             //       decoration: BoxDecoration(
//             //         color: Colors.black.withOpacity(0.5),
//             //         borderRadius: BorderRadius.circular(12),
//             //       ),
//             //       child: Text(
//             //         widget.requirementText,
//             //         style: TextStyle(
//             //           color: Colors.white70,
//             //           fontSize: 11,
//             //         ),
//             //         textAlign: TextAlign.center,
//             //       ),
//             //     ),
//             //   ),
//             // ),
//
//             // Capture Button
//             Positioned(
//               bottom: 50,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: GestureDetector(
//                   onTap: _captureImage,
//                   child: Container(
//                     width: 80,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.3),
//                           blurRadius: 10,
//                           offset: Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Center(
//                       child: Container(
//                         width: 68,
//                         height: 68,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white,
//                           border: Border.all(
//                             color: Colors.grey[400]!,
//                             width: 2,
//                           ),
//                         ),
//                         child: _isCapturing || _isProcessing
//                             ? Center(
//                           child: SizedBox(
//                             width: 30,
//                             height: 30,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 3,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//                             ),
//                           ),
//                         )
//                             : null,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//             // Cancel Button (Left)
//             Positioned(
//               bottom: 50,
//               left: 30,
//               child: GestureDetector(
//                 onTap: () {
//                   _cameraController?.dispose();
//                   Navigator.pop(context);
//                 },
//                 child: Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.6),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.close,
//                     color: Colors.white,
//                     size: 28,
//                   ),
//                 ),
//               ),
//             ),
//
//             // ========== FLIP CAMERA BUTTON (Right) - REPLACED GPS ==========
//             Positioned(
//               bottom: 50,
//               right: 30,
//               child: GestureDetector(
//                 onTap: _toggleCamera,
//                 child: Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.6),
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.3),
//                       width: 1,
//                     ),
//                   ),
//                   child: Icon(
//                     Icons.flip_camera_ios,
//                     color: Colors.white,
//                     size: 28,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//


import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:canimage/Screens/ExecutionSeePlans/execution_see_plans.dart';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as path;
import '../../Hive_Database/execution_image_upload_db.dart';
import '../../Repository/Map_pointer_locate_repository.dart';
import '../../Repository/execution_image_upload_repository.dart';
import '../../Repository/execution_balance_count_change_repository.dart';
import '../../Repository/upload_count_repository.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../utils/crash_manager.dart';
import '../../utils/fonts.dart';
import '../landing/landing_screen.dart';
import 'execution_map_screen.dart';


class UploadSeePlanScreen extends StatefulWidget {
  String? planCode;
  String? VillageCode;
  String? ServerID;
  String? Address;
  double? latitude;
  double? longitude;
  String? locateId;
  final Function(String) changeLanguage;
  var width;
  var height;
  var villageName;
  var tensil;
  var brand;
  var artworkId;

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
  });

  static bool get isCameraActive => _UploadSeePlanScreenState.isCameraOpen;

  @override
  State<UploadSeePlanScreen> createState() => _UploadSeePlanScreenState();
}

class _UploadSeePlanScreenState extends State<UploadSeePlanScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {

  static bool isCameraOpen = false;

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

  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  int? _currentImageIndex;
  int _timeoutRetryCount = 0;
  DateTime? _lastTimeoutTime;

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize cameras
    _initCameras();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRestoreState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode1.dispose();
    _focusNode2.dispose();
    printNoController1.dispose();
    printNoController2.dispose();
    _clearSavedState();
    isCameraOpen = false;
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        print("📷 Found ${_cameras!.length} cameras");
        for (var cam in _cameras!) {
          print("   - ${cam.name} (${cam.lensDirection})");
        }
      }
    } catch (e) {
      print("❌ Error initializing cameras: $e");
    }
  }

  Future<void> _initializeCameraController() async {
    if (_cameras == null || _cameras!.isEmpty) {
      await _initCameras();
    }

    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('No cameras available');
    }

    // Find rear camera (preferred) or fallback to first camera
    CameraDescription cameraDescription = _cameras!.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium, // Use medium for better performance
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();
    _isCameraInitialized = true;
    print("✅ Camera initialized: ${cameraDescription.name}");
  }

  void _cleanMemory() {
    try {
      imageCache.clear();
      imageCache.clearLiveImages();
      print("✅ Image cache cleared");
    } catch (e) {
      print("❌ Error clearing image cache: $e");
    }
    _cleanupTempFiles();
  }

  Future<void> _cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      int deletedCount = 0;

      for (var file in files) {
        if (file is File && (file.path.contains('.jpg') || file.path.contains('.png'))) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            // Ignore
          }
        }
      }

      if (deletedCount > 0) {
        print("🗑️ Cleaned up $deletedCount temporary image files");
      }
    } catch (e) {
      // Ignore
    }
  }

  void _removeFocus() {
    _focusNode1.unfocus();
    _focusNode2.unfocus();
    FocusScope.of(context).unfocus();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        if (isPickingImage) {
          _saveCurrentState();
        }
        _cleanupTempFiles();
        break;

      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FocusScope.of(context).unfocus();
            _checkAndRestoreState();
          }
        });
        break;

      case AppLifecycleState.detached:
        isCameraOpen = false;
        _clearSavedState();
        _cameraController?.dispose();
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
      await prefs.setBool('is_picking_image', false);
    }
  }

  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentImageIndex != null && isPickingImage) {
      await prefs.setBool('is_picking_image', true);
      await prefs.setInt('current_image_index', _currentImageIndex!);

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

    if (savedIndex != null && savedImagePath != null) {
      if (await File(savedImagePath).exists()) {
        setState(() {
          images[savedIndex].imagePath = savedImagePath;
          images[savedIndex].lat = prefs.getDouble('current_image_lat') ?? 0.0;
          images[savedIndex].long = prefs.getDouble('current_image_long') ?? 0.0;
        });

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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      return "Android ${deviceInfo.version.release} (SDK ${deviceInfo.version.sdkInt}) - ${deviceInfo.model}";
    } catch (e) {
      return "Unknown Device";
    }
  }

  Future<bool> _isDeviceLowOnMemory() async {
    try {
      final info = await Process.run('dumpsys', ['meminfo']);
      final output = info.stdout.toString();

      final totalMatch = RegExp(r'Total RAM:\s+(\d+)').firstMatch(output);
      final freeMatch = RegExp(r'Free RAM:\s+(\d+)').firstMatch(output);

      if (totalMatch != null && freeMatch != null) {
        final total = int.parse(totalMatch.group(1)!);
        final free = int.parse(freeMatch.group(1)!);
        final freePercent = (free / total) * 100;
        print("📊 Memory: ${freePercent.toStringAsFixed(1)}% free");
        return freePercent < 15;
      }
      return false;
    } catch (e) {
      print("⚠️ Could not check memory: $e");
      return false;
    }
  }

  Future<void> _pickImage(int index) async {
    if (isPickingImage) {
      print("🔄 Image picking already in progress, skipping");
      return;
    }

    if (_timeoutRetryCount >= 3 && _lastTimeoutTime != null) {
      final elapsed = DateTime.now().difference(_lastTimeoutTime!);
      if (elapsed.inMinutes < 1) {
        Fluttertoast.showToast(
          msg: "⚠️ Too many retries. Please wait a moment.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        setState(() {
          isPickingImage = false;
          _isPickerActiveList[index] = false;
        });
        return;
      }
      _timeoutRetryCount = 0;
    }

    print("==============================================");
    print("📸 CAMERA PICKER STARTED - Image ${index + 1}");
    print("==============================================");
    print("🕐 Timestamp: ${DateTime.now().toIso8601String()}");
    print("📱 Device Info: ${await _getDeviceInfo()}");
    print("📍 Image Index: $index");
    print("==============================================");

    try {
      isCameraOpen = true;

      setState(() {
        isPickingImage = true;
        _isPickerActiveList[index] = true;
        _currentImageIndex = index;
      });

      // Check memory
      if (await _isDeviceLowOnMemory()) {
        print("⚠️ Device is low on memory");
        Fluttertoast.showToast(
          msg: "⚠️ Low memory detected. Please close other apps.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }

      // Request permissions
      try {
        print("🔐 Requesting camera permissions...");
        await _requestCameraPermissions();
        print("✅ Camera permissions granted");
      } catch (e) {
        print("❌ Camera permission error: $e");
        isCameraOpen = false;
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

      // Initialize camera
      try {
        await _initializeCameraController();
        print("✅ Camera controller initialized");
      } catch (e) {
        print("❌ Camera initialization error: $e");
        isCameraOpen = false;
        setState(() {
          isPickingImage = false;
          _isPickerActiveList[index] = false;
        });

        await _showErrorDialogWithRetry(
          context,
          'Camera Error',
          'Failed to initialize camera. Please try again.',
          index,
        );
        return;
      }

      print("💾 Saving current state before opening camera...");
      await _saveCurrentState();

      // ========== OPEN CAMERA SCREEN ==========
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            imageIndex: index,
            imageLabel: 'Image ${index + 1}',
            targetLatitude: index == 0 ? widget.latitude : null,
            targetLongitude: index == 0 ? widget.longitude : null,
            referenceLatitude: (index == 2 || index == 6) && images[0].imagePath != null
                ? images[0].lat
                : null,
            referenceLongitude: (index == 2 || index == 6) && images[0].imagePath != null
                ? images[0].long
                : null,
            requirementText: _getRequirementText(index),
            onImageCaptured: (path, lat, long) {
              setState(() {
                images[index].imagePath = path;
                images[index].lat = lat;
                images[index].long = long;
              });
            },
          ),
        ),
      );

      // If user cancelled or returned
      if (result == null) {
        print("👤 User cancelled camera");
      }

      isCameraOpen = false;
      await _clearSavedState();
      print("✅ Saved state cleared successfully");

      setState(() {
        isPickingImage = false;
        _isPickerActiveList[index] = false;
      });

    } catch (e, stackTrace) {
      print("💥 ERROR in _pickImage:");
      print("   Error: $e");
      print("   StackTrace: $stackTrace");

      isCameraOpen = false;
      await _clearSavedState();

      await CrashReportManager.storeCrashReport(
        error: "Image picker error: $e",
        stackTrace: stackTrace.toString(),
      );

      if (mounted) {
        await _showErrorDialogWithRetry(
          context,
          'Camera Error',
          'An error occurred. Please try again.',
          index,
        );
      }
    } finally {
      print(" Cleaning up camera picker state for index $index");
      isCameraOpen = false;
      if (mounted) {
        setState(() {
          isPickingImage = false;
          _isPickerActiveList[index] = false;
        });
        FocusScope.of(context).unfocus();
      }
      print("==============================================");
      print("📸 CAMERA PICKER COMPLETED - Image ${index + 1}");
      print("==============================================");
    }
  }

  String _getRequirementText(int index) {
    if (index == 0) {
      return '📍 Capture within 50m of target location';
    } else if (index == 2) {
      return '📍 Capture within 50m of Image 1 location';
    } else if (index == 6) {
      return '📍 Capture within 50m of Image 1 location';
    } else {
      return '📸 Capture clear photo of the area';
    }
  }

  /// ============================================================
  /// COMPRESS IMAGE ON CAPTURE
  /// ============================================================
  /// Compresses a captured image to the best possible quality while
  /// staying under 200 KB. Uses adaptive quality and auto width.
  /// Min height is fixed at 1024 to maintain quality.
  /// ============================================================
  /// COMPRESS IMAGE ON CAPTURE
  /// ============================================================
  /// Compresses a captured image to achieve 100-200 KB target.
  /// Min height is fixed at 1024, auto width.
  Future<File?> _compressImageOnCapture(File imageFile, int imageIndex) async {
    const int minTargetKB = 100;
    const int maxTargetKB = 200;
    const int minHeight = 1024; // Fixed min height, auto width

    // ========== PRINT HEADER ==========
    print("╔═════════════════════════════════════════════════════════════════════════╗");
    print("║                    IMAGE PROCESSING FLOW                               ║");
    print("╠═════════════════════════════════════════════════════════════════════════╣");
    print("║  Image ${imageIndex + 1} of 7                                          ║");
    print("╠═════════════════════════════════════════════════════════════════════════╣");

    Future<File?> _compress(String srcPath, String dstPath, int quality) async {
      final result = await FlutterImageCompress.compressAndGetFile(
        srcPath,
        dstPath,
        quality: quality,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );
      if (result == null) return null;
      final f = File(result.path);
      return await f.exists() ? f : null;
    }

    try {
      if (!await imageFile.exists()) {
        print("║  ❌ ERROR: Source image file does not exist                           ║");
        print("╚═════════════════════════════════════════════════════════════════════════╝");
        return null;
      }

      // ========== STEP 1: USER TAKES PHOTO ==========
      print("║                                                                         ║");
      print("║  1. USER TAKES PHOTO                                                    ║");
      print("║     ↓                                                                   ║");

      final originalSizeBytes = await imageFile.length();
      final originalSizeKB = originalSizeBytes / 1024;
      final originalSizeMB = originalSizeKB / 1024;

      String sizeStr;
      if (originalSizeMB >= 1) {
        sizeStr = "${originalSizeMB.toStringAsFixed(2)} MB";
      } else {
        sizeStr = "${originalSizeKB.toStringAsFixed(0)} KB";
      }

      print("║     Camera saves: ${imageFile.path.split('/').last} ($sizeStr)          ║");
      print("║                                                                         ║");

      // ========== STEP 2: DETERMINE QUALITY BASED ON SIZE (HIGHER VALUES) ==========
      print("║  2. ANALYZING IMAGE SIZE                                               ║");
      print("║     ↓                                                                   ║");

      // HIGHER quality values to avoid over-compression
      final int quality = originalSizeKB <= 300
          ? 95  // Very small images - keep high quality
          : originalSizeKB <= 600
          ? 90
          : originalSizeKB <= 1000
          ? 85
          : originalSizeKB <= 2000
          ? 75
          : originalSizeKB <= 3000
          ? 65
          : originalSizeKB <= 5000
          ? 55
          : 45;

      print("║     Original Size: ${originalSizeKB.toStringAsFixed(0)} KB              ║");
      print("║     Min Height: $minHeight px (width auto-calculated)                   ║");
      print("║     Target: ${minTargetKB}-${maxTargetKB} KB                            ║");
      print("║     Selected Quality: $quality%                                         ║");
      print("║                                                                         ║");

      // ========== STEP 3: COMPRESSING IMAGE ==========
      print("║  3. COMPRESSING IMAGE                                                  ║");
      print("║     ↓                                                                   ║");

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final String tempPath = "${dir.path}/IMG_$ts.jpg";

      File? out = await _compress(imageFile.path, tempPath, quality);
      if (out == null) {
        print("║  ❌ Compression failed                                                 ║");
        print("╚═════════════════════════════════════════════════════════════════════════╝");
        return null;
      }

      final compressedSizeBytes = await out.length();
      final compressedSizeKB = compressedSizeBytes / 1024;

      print("║     Compressed to: ${compressedSizeKB.toStringAsFixed(0)} KB (q=$quality%) ║");
      print("║                                                                         ║");

      // ========== STEP 4: CHECK SIZE - ADJUST IF BELOW 100KB ==========
      print("║  4. CHECKING SIZE TARGET                                               ║");
      print("║     ↓                                                                   ║");
      print("║     Target Range: $minTargetKB-$maxTargetKB KB                          ║");
      print("║     Current Size: ${compressedSizeKB.toStringAsFixed(0)} KB              ║");

      // If below 100 KB, increase quality (less compression)
      if (compressedSizeKB < minTargetKB) {
        print("║     ⚠️  Below target! Increasing quality...                             ║");
        print("║     ↓                                                                   ║");

        // Calculate higher quality to increase file size
        final int higherQuality = (quality * (minTargetKB / compressedSizeKB)).ceil().clamp(quality + 5, 98);
        final File? retry = await _compress(
          imageFile.path,
          "${dir.path}/IMG_${ts}_h.jpg",
          higherQuality,
        );

        if (retry != null) {
          try { await out!.delete(); } catch (_) {}
          out = retry;
          final improvedSizeBytes = await out.length();
          final improvedSizeKB = improvedSizeBytes / 1024;
          print("║     Higher Quality: $higherQuality%                                   ║");
          print("║     New Size: ${improvedSizeKB.toStringAsFixed(0)} KB                ║");
          print("║     ↓                                                                   ║");
        }
      }
      // If over 200 KB, reduce quality (more compression)
      else if (compressedSizeKB > maxTargetKB) {
        print("║     ⚠️  Over target! Reducing quality...                                ║");
        print("║     ↓                                                                   ║");

        final int lowerQuality = (quality * (maxTargetKB / compressedSizeKB)).floor().clamp(15, quality - 5);
        final File? retry = await _compress(
          imageFile.path,
          "${dir.path}/IMG_${ts}_l.jpg",
          lowerQuality,
        );

        if (retry != null) {
          try { await out!.delete(); } catch (_) {}
          out = retry;
          final reducedSizeBytes = await out.length();
          final reducedSizeKB = reducedSizeBytes / 1024;
          print("║     Lower Quality: $lowerQuality%                                     ║");
          print("║     New Size: ${reducedSizeKB.toStringAsFixed(0)} KB                ║");
          print("║     ↓                                                                   ║");
        }
      } else {
        print("║     ✅ Within target range!                                             ║");
      }

      // ========== STEP 5: FINAL SIZE ==========
      final finalSizeBytes = await out.length();
      final finalSizeKB = finalSizeBytes / 1024;

      print("║                                                                         ║");
      print("║  5. FINAL RESULT                                                       ║");
      print("║     ↓                                                                   ║");
      print("║     📁 Original: ${originalSizeKB.toStringAsFixed(0)} KB                 ║");
      print("║     📁 Final:    ${finalSizeKB.toStringAsFixed(0)} KB                    ║");

      final savedKB = originalSizeKB - finalSizeKB;
      final savedPercent = originalSizeKB > 0 ? (savedKB / originalSizeKB * 100) : 0;
      print("║     💾 Saved:    ${savedKB.toStringAsFixed(0)} KB (${savedPercent.toStringAsFixed(0)}%)   ║");

      final isWithinTarget = finalSizeKB >= minTargetKB && finalSizeKB <= maxTargetKB;
      if (isWithinTarget) {
        print("║     ✅ Status:   Within target ($minTargetKB-$maxTargetKB KB)           ║");
      } else if (finalSizeKB < minTargetKB) {
        print("║     ⚠️  Status:   Below target (< $minTargetKB KB)                      ║");
      } else {
        print("║     ⚠️  Status:   Above target (> $maxTargetKB KB)                      ║");
      }

      // ========== STEP 6: CLEANUP ==========
      print("║                                                                         ║");
      print("║  6. CLEANUP                                                           ║");
      print("║     ↓                                                                   ║");

      try {
        await imageFile.delete();
        print("║     🗑️  Original file deleted                                          ║");
      } catch (_) {
        print("║     ⚠️  Could not delete original file                                 ║");
      }

      // ========== FOOTER ==========
      print("╚═════════════════════════════════════════════════════════════════════════╝");
      print("📊 Image ${imageIndex + 1}: ${originalSizeKB.toStringAsFixed(0)}KB → ${finalSizeKB.toStringAsFixed(0)}KB (q=$quality)");

      // ========== SHOW TOAST WITH SIZE ==========
      if (mounted) {
        String sizeDisplay;
        if (finalSizeKB >= 1024) {
          sizeDisplay = "${(finalSizeKB / 1024).toStringAsFixed(1)} MB";
        } else {
          sizeDisplay = "${finalSizeKB.toStringAsFixed(0)} KB";
        }

        Color toastColor;
        String statusIcon;
        if (finalSizeKB >= minTargetKB && finalSizeKB <= maxTargetKB) {
          toastColor = Colors.green;
          statusIcon = "✅";
        } else if (finalSizeKB < minTargetKB) {
          toastColor = Colors.orange;
          statusIcon = "⚠️";
        } else {
          toastColor = Colors.orange;
          statusIcon = "⚠️";
        }

        Fluttertoast.showToast(
          msg: "$statusIcon Image ${imageIndex + 1}: $sizeDisplay (Target: $minTargetKB-$maxTargetKB KB)",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: toastColor,
          textColor: Colors.white,
        );
      }

      return out;

    } catch (e, st) {
      print("║  ❌ ERROR: ${e.toString().substring(0, 70)}...                          ║");
      print("╚═════════════════════════════════════════════════════════════════════════╝");

      await CrashReportManager.storeCrashReport(
        error: "Compression error: $e",
        stackTrace: st.toString(),
      );
      return null;
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
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage),
          ),
        );
      }
    } else if (shouldRetry == true) {
      await Future.delayed(Duration(milliseconds: 300));
      if (mounted) {
        _pickImage(imageIndex);
      }
    }
  }

  Future<void> _showDistanceDialog(
      BuildContext context,
      double distance,
      String imageLabel,
      String requirement,
      {bool showRefreshOption = false}
      ) async {
    Fluttertoast.showToast(
    //  msg: "You are ${distance.toStringAsFixed(0)}m away. Please move closer (within 50m).",
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

  Future<void> _requestCameraPermissions() async {
    print("🔐 Checking camera permissions...");

    final permissions = await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();

    print("📊 Permission results:");
    print("   Camera: ${permissions[Permission.camera]}");
    print("   Storage: ${permissions[Permission.storage]}");
    print("   Photos: ${permissions[Permission.photos]}");

    if (permissions[Permission.camera] != PermissionStatus.granted) {
      print("❌ Camera permission NOT granted");
      throw PlatformException(
        code: "CAMERA_PERMISSION_DENIED",
        message: S.of(context).cameraPermission,
      );
    }
    print("✅ All permissions granted");
  }

  void _removeImage(int index) {
    if (_isPickerActiveList[index]) return;
    setState(() {
      images[index].imagePath = null;
      images[index].lat = 0.0;
      images[index].long = 0.0;
    });
  }

  /// ============================================================
  /// STORE IMAGE IN INTERNAL DOCUMENTS (NO RE-COMPRESSION)
  /// ============================================================
  /// Stores an image in internal documents WITHOUT re-compressing.
  /// The image is already compressed during capture.
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
        '${appDocDir.path}/Execution/Plans/${widget.ServerID}/${widget.planCode}/${widget.VillageCode}/${printNoController1.text}${printNoController2.text}/Images',
      );

      if (!await dwPaintingDir.exists()) {
        await dwPaintingDir.create(recursive: true);
      }

      File sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        throw 'Source image file does not exist: $imagePath';
      }

      final originalSizeKB = await sourceFile.length() / 1024;
      print("📊 Image size before storing: ${originalSizeKB.toStringAsFixed(2)} KB");

      // Generate unique image name
      String imageName = 'Img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String imagePathInStorage = '${dwPaintingDir.path}/$imageName';

      // ========== COPY THE FILE (NO RE-COMPRESSION) ==========
      await sourceFile.copy(imagePathInStorage);

      // Verify the copied file
      File copiedFile = File(imagePathInStorage);
      if (!await copiedFile.exists()) {
        throw 'Failed to copy image to storage';
      }

      final copiedSizeKB = await copiedFile.length() / 1024;
      print("📊 Image size after storing: ${copiedSizeKB.toStringAsFixed(2)} KB");

      // Delete the source file (temporary compressed file)
      try {
        await sourceFile.delete();
        print("🗑️ Temporary file deleted: $imagePath");
      } catch (e) {
        print("⚠️ Could not delete temporary file: $e");
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
      MaterialPageRoute(builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage,)),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
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
                // Header Card
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
                        _EnhancedMetaRow(label: S.of(context).villageNameMap, value: widget.villageName),
                        _EnhancedMetaRow(label: S.of(context).brand, value: widget.brand),
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
                    errorBuilder: (context, error, stackTrace) {
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

  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;
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

    String fullPrintNumber = '$printNumber1$printNumber2';

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
      bool isNetworkAvailable = await _checkNetworkConnectivity();
      String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Store images (NO re-compression - already compressed)
      for (var i = 0; i < images.length; i++) {
        if (images[i].imagePath != null) {
          final storedPath = await _storeImageInInternalDocuments(images[i].imagePath!);
          images[i].imagePath = storedPath;
        }
      }

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

      await ExecutionImageUploadHiveRepository().saveMetadata(metadata);
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
          print(" Successfully marked locateId ${widget.locateId} as captured");
        } catch (e) {
          print(" Failed to mark locate as captured: $e");
          // Don't fail the submission if marking fails
          // Log the error but continue with the submission
          await CrashReportManager.storeLogMessage(
              "event=mark_captured_failed | "
                  "locateId=${widget.locateId} | "
                  "error=$e | "
                  "timestamp=${DateTime.now().toIso8601String()}"
          );
        }
      } else {
        print("ℹ️ No locateId to mark as captured (locateId: ${widget.locateId})");
      }

      String uploadDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await UploadCountRepository().incrementUploadCount(uploadDate);

      await _clearSavedState();

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
              builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage)
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
}

// ImageData class
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

// Enhanced Meta Row Components
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

// Colors
const Color primaryColor = Color(0xFF2196F3);
const Color primaryLightColor = Color(0xFF64B5F6);
const Color accentColor = Color(0xFF03DAC6);
const Color neutralDarkColor = Color(0xFF212121);

// ============================================================
// CAMERA SCREEN
// ============================================================
class CameraScreen extends StatefulWidget {
  final Function(String, double, double) onImageCaptured;
  final int imageIndex;
  final double? targetLatitude;
  final double? targetLongitude;
  final double? referenceLatitude;
  final double? referenceLongitude;
  final String imageLabel;
  final String requirementText;
  final VoidCallback? onRefreshLocation;

  const CameraScreen({
    super.key,
    required this.onImageCaptured,
    required this.imageIndex,
    this.targetLatitude,
    this.targetLongitude,
    this.referenceLatitude,
    this.referenceLongitude,
    required this.imageLabel,
    required this.requirementText,
    this.onRefreshLocation,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  Position? _currentPosition;
  bool _isLocationValid = false;
  String _locationError = '';

  // Camera toggle
  int _cameraIndex = 0; // 0 = back, 1 = front
  List<CameraDescription> _availableCameras = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameras();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cameraController?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController?.resumePreview();
    }
  }

  Future<void> _initializeCameras() async {
    try {
      if (cameras == null || cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      _availableCameras = cameras!;

      // Start with back camera
      _cameraIndex = 0;
      for (int i = 0; i < _availableCameras.length; i++) {
        if (_availableCameras[i].lensDirection == CameraLensDirection.back) {
          _cameraIndex = i;
          break;
        }
      }

      await _initializeCamera(_cameraIndex);

    } catch (e) {
      print(" Camera initialization error: $e");
      Fluttertoast.showToast(
        msg: "Failed to initialize camera: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _initializeCamera(int index) async {
    try {
      if (_availableCameras.isEmpty) {
        throw Exception('No cameras available');
      }

      if (index >= _availableCameras.length) {
        index = 0;
      }

      // Dispose old controller if exists
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      final cameraDescription = _availableCameras[index];

      _cameraController = CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });

      print(" Camera initialized: ${cameraDescription.name} (${cameraDescription.lensDirection})");

    } catch (e) {
      print(" Camera initialization error: $e");
      setState(() {
        _isCameraInitialized = false;
      });
      Fluttertoast.showToast(
        msg: "Failed to switch camera: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras.length < 2) {
      Fluttertoast.showToast(
        msg: "Only one camera available",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isCameraInitialized = false;
    });

    // Switch to next camera
    _cameraIndex = (_cameraIndex + 1) % _availableCameras.length;

    await _initializeCamera(_cameraIndex);
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocationValid = false;
        _locationError = '';
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLocationValid = true;
        _locationError = '';
      });

      if (widget.targetLatitude != null && widget.targetLongitude != null) {
        double distance = _calculateDistance(
          position.latitude,
          position.longitude,
          widget.targetLatitude!,
          widget.targetLongitude!,
        );

        if (distance > 50) {
          setState(() {
            _isLocationValid = false;
            _locationError = 'You are ${distance.toStringAsFixed(0)}m away. Must be within 50m.';
          });
          Fluttertoast.showToast(
            msg: " ${_locationError}",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }

      if (widget.referenceLatitude != null && widget.referenceLongitude != null) {
        double distanceFromReference = _calculateDistance(
          position.latitude,
          position.longitude,
          widget.referenceLatitude!,
          widget.referenceLongitude!,
        );

        if (distanceFromReference > 50) {
          setState(() {
            _isLocationValid = false;
            _locationError = 'You are ${distanceFromReference.toStringAsFixed(0)}m away from reference image. Must be within 50m.';
          });
          Fluttertoast.showToast(
            msg: " ${_locationError}",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }

    } catch (e) {
      setState(() {
        _isLocationValid = false;
        _locationError = 'Unable to get location. Please enable GPS.';
      });
      Fluttertoast.showToast(
        msg: "⚠️ Please enable GPS",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// ============================================================
  /// COMPRESS IMAGE ON CAPTURE (Camera Screen)
  /// ============================================================
  /// Uses the SAME logic as the main screen.
  /// Min height = 1024, auto width, target size under 200 KB.
  /// ============================================================
  /// COMPRESS IMAGE ON CAPTURE (Camera Screen)
  /// ============================================================
  /// Uses the SAME logic as the main screen.
  /// Min height = 1024, auto width, target 100-200 KB.
  Future<File?> _compressImageOnCapture(File imageFile) async {
    const int minTargetKB = 100;
    const int maxTargetKB = 200;
    const int minHeight = 1024;

    Future<File?> _compress(String srcPath, String dstPath, int quality) async {
      final result = await FlutterImageCompress.compressAndGetFile(
        srcPath,
        dstPath,
        quality: quality,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );
      if (result == null) return null;
      final f = File(result.path);
      return await f.exists() ? f : null;
    }

    try {
      if (!await imageFile.exists()) return null;

      final originalSizeKB = await imageFile.length() / 1024;
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;

      // HIGHER quality values to avoid over-compression
      final int quality = originalSizeKB <= 300
          ? 95
          : originalSizeKB <= 600
          ? 90
          : originalSizeKB <= 1000
          ? 85
          : originalSizeKB <= 2000
          ? 75
          : originalSizeKB <= 3000
          ? 65
          : originalSizeKB <= 5000
          ? 55
          : 45;

      File? out = await _compress(imageFile.path, "${dir.path}/IMG_$ts.jpg", quality);
      if (out == null) return null;

      double sizeKB = await out.length() / 1024;

      // If below 100 KB, increase quality
      if (sizeKB < minTargetKB) {
        final int higherQuality = (quality * (minTargetKB / sizeKB)).ceil().clamp(quality + 5, 98);
        final File? retry = await _compress(
          imageFile.path,
          "${dir.path}/IMG_${ts}_h.jpg",
          higherQuality,
        );
        if (retry != null) {
          try { await out!.delete(); } catch (_) {}
          out = retry;
          sizeKB = await out.length() / 1024;
        }
      }
      // If over 200 KB, reduce quality
      else if (sizeKB > maxTargetKB) {
        final int lowerQuality = (quality * (maxTargetKB / sizeKB)).floor().clamp(15, quality - 5);
        final File? retry = await _compress(
          imageFile.path,
          "${dir.path}/IMG_${ts}_l.jpg",
          lowerQuality,
        );
        if (retry != null) {
          try { await out!.delete(); } catch (_) {}
          out = retry;
          sizeKB = await out.length() / 1024;
        }
      }

      // Cleanup original
      try { await imageFile.delete(); } catch (_) {}

      print("📸 Image ${widget.imageIndex + 1}: ${originalSizeKB.toStringAsFixed(0)}KB → ${sizeKB.toStringAsFixed(0)}KB");

      // ========== SHOW TOAST WITH SIZE ==========
      String sizeDisplay;
      if (sizeKB >= 1024) {
        sizeDisplay = "${(sizeKB / 1024).toStringAsFixed(1)} MB";
      } else {
        sizeDisplay = "${sizeKB.toStringAsFixed(0)} KB";
      }

      Color toastColor;
      String statusIcon;
      if (sizeKB >= minTargetKB && sizeKB <= maxTargetKB) {
        toastColor = Colors.green;
        statusIcon = "✅";
      } else if (sizeKB < minTargetKB) {
        toastColor = Colors.orange;
        statusIcon = "⚠️";
      } else {
        toastColor = Colors.orange;
        statusIcon = "⚠️";
      }

      Fluttertoast.showToast(
        msg: "$statusIcon Image ${widget.imageIndex + 1}:"" "
           // "$sizeDisplay (Target: $minTargetKB-$maxTargetKB KB)",
            "$sizeDisplay",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: toastColor,
        textColor: Colors.white,
      );

      return out;

    } catch (e, st) {
      print("❌ Compression error: $e");
      return null;
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing || _isProcessing || !_isCameraInitialized || _cameraController == null) {
      return;
    }

    if (!_isLocationValid) {
      Fluttertoast.showToast(
        msg: "",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile picture = await _cameraController!.takePicture();
      print("📸 Picture captured: ${picture.path}");

      setState(() {
        _isProcessing = true;
      });

      final File imageFile = File(picture.path);
      File? compressedFile = await _compressImageOnCapture(imageFile);

      String finalImagePath;
      if (compressedFile != null) {
        finalImagePath = compressedFile.path;
      } else {
        finalImagePath = picture.path;
      }

      widget.onImageCaptured(
        finalImagePath,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Double toast for success (compression toast already shown)
      Fluttertoast.showToast(
        msg: "✅ Image ${widget.imageIndex + 1} captured",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      print("❌ Capture error: $e");
      Fluttertoast.showToast(
        msg: "Failed to capture image: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );

      setState(() {
        _isCapturing = false;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isCameraInitialized && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),

            // Capture Button
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: _isCapturing || _isProcessing
                            ? Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Cancel Button (Left)
            Positioned(
              bottom: 50,
              left: 30,
              child: GestureDetector(
                onTap: () {
                  _cameraController?.dispose();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Flip Camera Button (Right)
            Positioned(
              bottom: 50,
              right: 30,
              child: GestureDetector(
                onTap: _toggleCamera,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
