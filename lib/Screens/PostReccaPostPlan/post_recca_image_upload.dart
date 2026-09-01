// import 'dart:async';
// import 'dart:convert';
// import 'package:image/image.dart' as img;
// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:canimage/Repository/remarks_repository.dart';
// import 'package:canimage/Screens/landing/landing_screen.dart';
// import 'package:canimage/Screens/printSync/execution_print_sync_screen.dart';
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
// import '../../APIService/auth_service.dart';
// import '../../Hive_Database/post_recca_image_upload_db.dart';
// import '../../Hive_Database/execution_image_upload_db.dart';
// import '../../Hive_Database/remarks_db.dart';
// import '../../Model/recca_remarks_model.dart';
// import '../../Repository/completed_upload_repository.dart';
// import '../../Repository/postRecca_balance_count_change_repository.dart';
// import '../../Repository/post_recca_image_upload_repository.dart';
//
// import '../../generated/l10n.dart';
// import '../../utils/crash_manager.dart';
// import '../../utils/fonts.dart';
// import '../../utils/print_crash_manager.dart';
// import '../printSync/post_recca_print_sync_screen.dart';
// import 'post_recca_see_plans.dart';
//
// class SUUploadSeePlanScreen extends StatefulWidget {
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
//   final Function(String) changeLanguage;
//
//   SUUploadSeePlanScreen({
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
//     required this.changeLanguage
//   });
//
//   @override
//   State<SUUploadSeePlanScreen> createState() => _SUUploadSeePlanScreenState();
// }
//
// class _SUUploadSeePlanScreenState extends State<SUUploadSeePlanScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
//   List<ImageData> images = List.generate(2, (index) => ImageData());
//   List<ReccaRemarksModel>? plans;
//   List<Remarks> dataRemarks = [];
//   bool loader = true;
//   bool isRefreshing = false;
//   List<bool> _isPickerActiveList = List.generate(2, (index) => false);
//   bool isPickingImage = false;
//   bool _isProcessingRecoveredImage = false;
//
//   // Camera integration variables
//   final ImagePicker _picker = ImagePicker();
//   int? _currentImageIndex;
//
//   final FocusNode _focusNode = FocusNode();
//   final Set<String> _selectedRemarks = {};
//   final TextEditingController _remarksDisplayCtrl = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     fetchRemarks();
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _focusNode.dispose();
//     _remarksDisplayCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   bool get wantKeepAlive => true; // Keeps state alive
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//
//     switch (state) {
//       case AppLifecycleState.paused:
//       // App minimized - save critical state
//         _saveCurrentState();
//         break;
//       case AppLifecycleState.resumed:
//       // App restored - restore state if needed
//         _restoreStateIfNeeded();
//         break;
//       case AppLifecycleState.detached:
//       // App being killed
//         _saveCurrentState();
//         break;
//       case AppLifecycleState.inactive:
//       case AppLifecycleState.hidden:
//       // Handle other states if needed
//         break;
//     }
//   }
//
//   // Future<void> _saveCurrentState() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //
//   //   // Save current operation state
//   //   await prefs.setBool('su_is_picking_image', isPickingImage);
//   //   await prefs.setInt('su_current_image_index', _currentImageIndex ?? -1);
//   //
//   //   // Save image paths
//   //   for (int i = 0; i < images.length; i++) {
//   //     if (images[i].imagePath != null) {
//   //       await prefs.setString('su_image_path_$i', images[i].imagePath!);
//   //       await prefs.setDouble('su_image_lat_$i', images[i].lat);
//   //       await prefs.setDouble('su_image_long_$i', images[i].long);
//   //     }
//   //   }
//   //
//   //   // Save selected remarks
//   //   await prefs.setStringList('su_selected_remarks', _selectedRemarks.toList());
//   //   await prefs.setString('su_remarks_display', _remarksDisplayCtrl.text);
//   // }
//   //
//   // Future<void> _restoreStateIfNeeded() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //
//   //   // Restore images
//   //   for (int i = 0; i < images.length; i++) {
//   //     final imagePath = prefs.getString('su_image_path_$i');
//   //     if (imagePath != null && await File(imagePath).exists()) {
//   //       setState(() {
//   //         images[i].imagePath = imagePath;
//   //         images[i].lat = prefs.getDouble('su_image_lat_$i') ?? 0.0;
//   //         images[i].long = prefs.getDouble('su_image_long_$i') ?? 0.0;
//   //       });
//   //     }
//   //   }
//   //
//   //   // Restore remarks
//   //   final savedRemarks = prefs.getStringList('su_selected_remarks');
//   //   if (savedRemarks != null) {
//   //     setState(() {
//   //       _selectedRemarks.clear();
//   //       _selectedRemarks.addAll(savedRemarks);
//   //       _remarksDisplayCtrl.text = prefs.getString('su_remarks_display') ?? '';
//   //     });
//   //   }
//   // }
//
//
//   // Enhanced image picker with camera plugin support
//   // Future<void> _pickImage(int index) async {
//   //   if (isPickingImage) {
//   //     print("Image picking already in progress");
//   //     return;
//   //   }
//   //
//   //   try {
//   //     setState(() {
//   //       isPickingImage = true;
//   //       _isPickerActiveList[index] = true;
//   //       _currentImageIndex = index;
//   //     });
//   //
//   //     // Request permissions
//   //     await _requestCameraPermissions();
//   //
//   //     // Show source selection dialog
//   //     final ImageSource? source = await ImageSource.camera;
//   //     if (source == null) {
//   //       return;
//   //     }
//   //
//   //     String? imagePath;
//   //
//   //     if (source == ImageSource.camera) {
//   //       // Use embedded camera for stability
//   //       imagePath = await _openEmbeddedCamera();
//   //     } else {
//   //       // Use image_picker for gallery
//   //       final XFile? pickedFile = await _picker.pickImage(
//   //         source: ImageSource.gallery,
//   //         imageQuality: 90,
//   //         maxWidth: 1920,
//   //         maxHeight: 1920,
//   //       );
//   //       imagePath = pickedFile?.path;
//   //     }
//   //
//   //     if (imagePath != null) {
//   //       await _processImageFromPath(imagePath, index);
//   //       Fluttertoast.showToast(
//   //         msg: source == ImageSource.camera
//   //             ? S.of(context).imageCaptured
//   //             : S.of(context).imageSelected,
//   //         toastLength: Toast.LENGTH_SHORT,
//   //         gravity: ToastGravity.BOTTOM,
//   //       );
//   //     }
//   //
//   //   } catch (e) {
//   //     // print("Error in _pickImage: $e");
//   //     // _handleImagePickerError(e);
//   //     await CrashReportManager.storeCrashReport(
//   //       error: "Camera error: $e",
//   //       stackTrace: StackTrace.current.toString(),
//   //     );
//   //   } finally {
//   //     if (mounted) {
//   //       setState(() {
//   //         isPickingImage = false;
//   //         _isPickerActiveList[index] = false;
//   //       });
//   //     }
//   //   }
//   // }
//
//
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
//       // Get current location first
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
//       // ========== REQUEST CAMERA PERMISSIONS ==========
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
//       // ========== OPEN CAMERA USING IMAGE_PICKER WITH TIMEOUT ==========
//       XFile? pickedFile;
//
//       try {
//         // Add timeout to prevent indefinite hanging
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
//         // Handle specific platform exceptions
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
//         // Catch any other unexpected errors
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
//       // Process the captured image
//       if (pickedFile != null) {
//         try {
//           // Verify file exists
//           final file = File(pickedFile.path);
//           if (!await file.exists()) {
//             throw Exception('Captured image file not found');
//           }
//
//           // Verify file is readable
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
//         // User cancelled
//         await _clearSavedState();
//       }
//
//     } catch (e) {
//       // Final catch-all for any unexpected errors
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
// // Add this new method for error dialog with retry option
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
//       // Go back to previous screen
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => SUSeePlanScreen(changeLanguage: widget.changeLanguage),
//           ),
//         );
//       }
//     } else if (shouldRetry == true) {
//       // Retry capturing the image
//       await Future.delayed(Duration(milliseconds: 300));
//       if (mounted) {
//         _pickImage(imageIndex);
//       }
//     }
//   }
//
// // Update _clearSavedState method
//   Future<void> _clearSavedState() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('su_is_picking_image');
//     await prefs.remove('su_current_image_index');
//
//     // Clear image paths for both images
//     for (int i = 0; i < 2; i++) {
//       await prefs.remove('su_image_path_$i');
//       await prefs.remove('su_image_lat_$i');
//       await prefs.remove('su_image_long_$i');
//     }
//   }
//
// // Update _saveCurrentState method
//   Future<void> _saveCurrentState() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     // Only save if we're actively picking an image
//     if (_currentImageIndex != null && isPickingImage) {
//       await prefs.setBool('su_is_picking_image', true);
//       await prefs.setInt('su_current_image_index', _currentImageIndex!);
//
//       // ONLY save the current image being captured (not all images)
//       final currentImage = images[_currentImageIndex!];
//       if (currentImage.imagePath != null) {
//         await prefs.setString('su_current_image_path', currentImage.imagePath!);
//         await prefs.setDouble('su_current_image_lat', currentImage.lat);
//         await prefs.setDouble('su_current_image_long', currentImage.long);
//       }
//     }
//   }
//
// // Update _restoreStateIfNeeded method
//   Future<void> _restoreStateIfNeeded() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final savedIndex = prefs.getInt('su_current_image_index');
//     final savedImagePath = prefs.getString('su_current_image_path');
//
//     // Only restore if we have a saved index and path
//     if (savedIndex != null && savedImagePath != null && savedIndex < 2) {
//       if (await File(savedImagePath).exists()) {
//         setState(() {
//           images[savedIndex].imagePath = savedImagePath;
//           images[savedIndex].lat = prefs.getDouble('su_current_image_lat') ?? 0.0;
//           images[savedIndex].long = prefs.getDouble('su_current_image_long') ?? 0.0;
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
//
//     await _clearSavedState();
//   }
//
// // Update _requestCameraPermissions method
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
//
//
//
//   // Request camera permissions
//   // Future<void> _requestCameraPermissions() async {
//   //   final permissions = await [
//   //     Permission.camera,
//   //     Permission.storage,
//   //     Permission.photos,
//   //   ].request();
//   //
//   //   if (permissions[Permission.camera] != PermissionStatus.granted) {
//   //     throw PlatformException(
//   //       code: "CAMERA_PERMISSION_DENIED",
//   //       message: "Camera permission is required",
//   //     );
//   //   }
//   // }
//
//   // Process image from file path
//   Future<void> _processImageFromPath(String imagePath, int index) async {
//     if (index < 0 || index >= images.length) {
//       print("Invalid image index: $index");
//       return;
//     }
//
//     try {
//       final imageFile = File(imagePath);
//       if (!await imageFile.exists()) {
//         throw Exception("Image file not found: $imagePath");
//       }
//
//       final fileSize = await imageFile.length();
//       if (fileSize == 0) {
//         throw Exception("Image file is empty");
//       }
//
//       print("Processing image for index $index: $imagePath (${fileSize} bytes)");
//
//       Position? position;
//       try {
//         position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.medium,
//           timeLimit: Duration(seconds: 5),
//         );
//       } catch (e) {
//         print("Using fallback location: $e");
//         position = Position(
//           latitude: 0.0,
//           longitude: 0.0,
//           timestamp: DateTime.now(),
//           accuracy: 0.0,
//           altitude: 0.0,
//           heading: 0.0,
//           speed: 0.0,
//           speedAccuracy: 0.0,
//           altitudeAccuracy: 0.0,
//           headingAccuracy: 0.0,
//         );
//       }
//
//       if (mounted) {
//         setState(() {
//           images[index].imagePath = imagePath;
//           images[index].lat = position?.latitude ?? 0.0;
//           images[index].long = position?.longitude ?? 0.0;
//         });
//         print("Successfully updated image data for index $index");
//       }
//     } catch (e) {
//       print("Error processing image: $e");
//       // if (mounted) {
//       //   Fluttertoast.showToast(
//       //     msg: "Error processing image: $e",
//       //     toastLength: Toast.LENGTH_SHORT,
//       //     gravity: ToastGravity.BOTTOM,
//       //   );
//       // }
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
//   bool get _isAnyPickerActive =>
//       _isPickerActiveList.any((isActive) => isActive) ||
//           _isProcessingRecoveredImage;
//
//   void fetchRemarks() async {
//     setState(() {
//       loader = true;
//     });
//
//     try {
//       final remarksData = await RemarksHiveRepository().loadRemarks();
//
//       if (remarksData.isNotEmpty) {
//         dataRemarks = remarksData;
//         print('Remarks loaded from Hive: $dataRemarks');
//       } else {
//         print('No remarks found in Hive.');
//       }
//     } catch (e) {
//       print('Error loading remarks: $e');
//       Fluttertoast.showToast(msg: S.of(context).failedLoadRemarks);
//     } finally {
//       setState(() {
//         loader = false;
//       });
//     }
//   }
//
//   // Future<String> _storeImageInInternalDocuments(String imagePath) async {
//   //   // First, check current permission status
//   //   PermissionStatus status = await Permission.manageExternalStorage.status;
//   //   print('📋 Current permission status: $status');
//   //
//   //   if (!status.isGranted) {
//   //     print('❌ MANAGE_EXTERNAL_STORAGE permission not granted');
//   //     print('🔧 Requesting permission...');
//   //
//   //     // Request permission
//   //     PermissionStatus newStatus = await Permission.manageExternalStorage.request();
//   //     print('📋 New permission status: $newStatus');
//   //
//   //     if (!newStatus.isGranted) {
//   //       print('⚠️ Permission denied. Opening app settings...');
//   //       print('📱 Please go to: Settings → Apps → Can Image → Permissions → Files and media → Allow management of all files');
//   //
//   //       // Open app settings
//   //       await openAppSettings();
//   //       throw 'Storage permission denied. Please enable "All files access" in app settings.';
//   //     }
//   //   }
//   //
//   //   try {
//   //     print('✅ Permission granted! Storing image...');
//   //
//   //     Directory appDocDir;
//   //
//   //     // Try primary storage path first
//   //     Directory primaryDir = Directory('/storage/emulated/0/CIMTDWP');
//   //
//   //     try {
//   //       // Test if we can create/access the primary directory
//   //       if (!await primaryDir.exists()) {
//   //         await primaryDir.create(recursive: true);
//   //         print('📁 Primary CIMTDWP folder created at: ${primaryDir.path}');
//   //       }
//   //
//   //       // Test write permission by creating a temporary test file
//   //       File testFile = File('${primaryDir.path}/test_write.tmp');
//   //       await testFile.writeAsString('test');
//   //       await testFile.delete();
//   //
//   //       appDocDir = primaryDir;
//   //       print('✅ Using primary storage: ${primaryDir.path}');
//   //
//   //     } catch (e) {
//   //       print('⚠️ Primary storage not accessible: $e');
//   //       print('🔄 Falling back to external storage...');
//   //
//   //       // Fallback to external storage directory
//   //       Directory? externalDir = await getExternalStorageDirectory();
//   //       if (externalDir == null) {
//   //         throw 'Unable to access both primary and external storage';
//   //       }
//   //
//   //       appDocDir = Directory('${externalDir.path}/CIMTDWP');
//   //       if (!await appDocDir.exists()) {
//   //         await appDocDir.create(recursive: true);
//   //         print('📁 Fallback CIMTDWP folder created at: ${appDocDir.path}');
//   //       }
//   //       print('✅ Using external storage: ${appDocDir.path}');
//   //     }
//   //
//   //     // Create the nested folder structure for PostRecca/Supervisor
//   //     Directory dwPaintingDir = Directory('${appDocDir.path}/PostRecca/Supervisor/${widget.projectID}/${widget.planCode}/${widget.villageCode}/${widget.printId}/Images');
//   //
//   //     // Create the folder if it does not exist
//   //     if (!await dwPaintingDir.exists()) {
//   //       await dwPaintingDir.create(recursive: true);
//   //       print('📁 Nested folders created: ${dwPaintingDir.path}');
//   //     }
//   //
//   //     // Read the image file into bytes
//   //     File imageFile = File(imagePath);
//   //     if (!await imageFile.exists()) {
//   //       throw 'Source image file does not exist: $imagePath';
//   //     }
//   //
//   //     var imageBytes = await imageFile.readAsBytes();
//   //
//   //     // Compress the image bytes to reduce size
//   //     int targetWidth = 800;
//   //     int targetHeight = 800;
//   //
//   //     var result = await FlutterImageCompress.compressWithList(
//   //       imageBytes,
//   //       minWidth: targetWidth,
//   //       minHeight: targetHeight,
//   //       quality: 90,
//   //       format: CompressFormat.png,
//   //     );
//   //
//   //     // Check if the image is compressed
//   //     if (result == null) {
//   //       throw 'Image compression failed';
//   //     }
//   //
//   //     // Define the image name
//   //     String imageName = 'Img_${DateTime.now().toIso8601String().replaceAll(RegExp('[^0-9]'), '')}.png';
//   //
//   //     // Define the full path where the image will be stored
//   //     String imagePathInStorage = '${dwPaintingDir.path}/$imageName';
//   //
//   //     // Create a new file from the compressed result and save it
//   //     File compressedImage = File(imagePathInStorage);
//   //     await compressedImage.writeAsBytes(result);
//   //
//   //     // Verify the file was written successfully
//   //     if (!await compressedImage.exists()) {
//   //       throw 'Failed to write compressed image to storage';
//   //     }
//   //
//   //     print('🎉 SUCCESS! Image stored at: $imagePathInStorage');
//   //     print('📱 Storage location: ${appDocDir.path}');
//   //     print('📂 Full path: PostRecca → Supervisor → ${widget.projectID} → ${widget.planCode} → ${widget.villageCode} → ${widget.printId} → Images');
//   //
//   //     return imagePathInStorage;
//   //
//   //   } catch (e) {
//   //     print('❌ Error storing image: $e');
//   //     throw 'Failed to store image: $e';
//   //   }
//   // }
//
//   Future<String> _storeImageInInternalDocuments(String imagePath) async {
//     try {
//       print('✅ Storing image in external storage...');
//
//       // Get external storage directory (app-specific, no permission needed)
//       Directory? externalDir = await getExternalStorageDirectory();
//       if (externalDir == null) {
//         throw 'Unable to access external storage directory';
//       }
//
//       // Create app-specific folder structure in external storage
//       Directory appDocDir = Directory('${externalDir.path}/CIMTDWP');
//       if (!await appDocDir.exists()) {
//         await appDocDir.create(recursive: true);
//         print('📁 CIMTDWP folder created at: ${appDocDir.path}');
//       }
//       print('✅ Using external storage: ${appDocDir.path}');
//
//       // Create the nested folder structure for PostRecca/Supervisor
//       Directory dwPaintingDir = Directory('${appDocDir.path}/PostRecca/Supervisor/${widget.projectID}/${widget.planCode}/${widget.villageCode}/${widget.printId}/Images');
//
//       // Create the folder if it does not exist
//       if (!await dwPaintingDir.exists()) {
//         await dwPaintingDir.create(recursive: true);
//         print('📁 Nested folders created: ${dwPaintingDir.path}');
//       }
//
//       // Read the image file into bytes
//       File imageFile = File(imagePath);
//       if (!await imageFile.exists()) {
//         throw 'Source image file does not exist: $imagePath';
//       }
//
//       var imageBytes = await imageFile.readAsBytes();
//
//       // Compress the image bytes to reduce size
//       int targetWidth = 800;
//       int targetHeight = 800;
//
//       var result = await FlutterImageCompress.compressWithList(
//         imageBytes,
//         minWidth: targetWidth,
//         minHeight: targetHeight,
//         quality: 90,
//         format: CompressFormat.png,
//       );
//
//       // Check if the image is compressed
//       if (result == null) {
//         throw 'Image compression failed';
//       }
//
//       // Define the image name
//       String imageName = 'Img_${DateTime.now().toIso8601String().replaceAll(RegExp('[^0-9]'), '')}.png';
//
//       // Define the full path where the image will be stored
//       String imagePathInStorage = '${dwPaintingDir.path}/$imageName';
//
//       // Create a new file from the compressed result and save it
//       File compressedImage = File(imagePathInStorage);
//       await compressedImage.writeAsBytes(result);
//
//       // Verify the file was written successfully
//       if (!await compressedImage.exists()) {
//         throw 'Failed to write compressed image to storage';
//       }
//
//       print('🎉 SUCCESS! Image stored at: $imagePathInStorage');
//       print('📱 Storage location: ${appDocDir.path}');
//       print('📂 Full path: PostRecca → Supervisor → ${widget.projectID} → ${widget.planCode} → ${widget.villageCode} → ${widget.printId} → Images');
//
//       return imagePathInStorage;
//
//     } catch (e) {
//       print('❌ Error storing image: $e');
//       throw 'Failed to store image: $e';
//     }
//   }
//
//   void _openRemarksDialog() async {
//     final temp = Set<String>.from(_selectedRemarks);
//
//     await showDialog<void>(
//       context: context,
//       builder: (ctx) {
//         return StatefulBuilder(
//           builder: (ctx, setLocal) {
//             return AlertDialog(
//               title: Text(S.of(context).pleaseSelect, style: TextStyle(fontFamily: "Roboto", fontSize: 14)),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: dataRemarks.map((opt) {
//                       final checked = temp.contains(opt.remarks);
//                       return CheckboxListTile(
//                         controlAffinity: ListTileControlAffinity.leading,
//                         value: checked,
//                         dense: true,
//                         title: Text(opt.remarks, style: TextStyle(fontFamily: "Roboto")),
//                         onChanged: (v) {
//                           setLocal(() {
//                             if (v == true) {
//                               temp.add(opt.remarks);
//                             } else {
//                               temp.remove(opt.remarks);
//                             }
//                           });
//                         },
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(ctx),
//                   child: Text(S.of(context).cancel, style: TextStyle(fontFamily: "Roboto")),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     setState(() {
//                       _selectedRemarks
//                         ..clear()
//                         ..addAll(temp);
//                       _remarksDisplayCtrl.text = _selectedRemarks.join(', ');
//                     });
//                     Navigator.pop(ctx);
//                   },
//                   child: Text(S.of(context).submit, style: TextStyle(fontFamily: "Roboto")),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<bool> _onWillPop() async {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => SUSeePlanScreen(changeLanguage: widget.changeLanguage,)),
//     );
//     return false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
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
//           body: loader == true ? Center(child: CircularProgressIndicator(color: Colors.blue,)) : SingleChildScrollView(
//             child: Column(
//               children: [
//                 // Enhanced Header Card
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
//                         _EnhancedMetaRow(label: S.of(context).villageNameMap, value: widget.villageName.toString()),
//                         _EnhancedMetaRow(label: S.of(context).brand, value: widget.brand.toString()),
//                         _EnhancedMetaRowWithInputs(
//                           label: S.of(context).size,
//                           value: widget.width.toString(),
//                           secondValue: widget.height.toString(),
//                         ),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 S.of(context).printNo,
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                   color: Font.neutralDarkColor,
//                                   fontFamily: "Roboto",
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 55,),
//                             Center(
//                               child: Text(
//                                 widget.printNo.toString(),
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                   color: Font.neutralDarkColor,
//                                   fontFamily: "Roboto",
//                                 ),
//                               ),
//                             ),
//
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//
//                         // REMARKS SECTION
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Label
//                             Expanded(
//                               flex: 2,
//                               child: Padding(
//                                 padding: EdgeInsets.only(top: 14),
//                                 child: Text(
//                                   S.of(context).remarks,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                     color: Color(0xFF2D2D2D),
//                                     fontFamily: "Roboto",
//                                   ),
//                                 ),
//                               ),
//                             ),
//
//                             // Display + open picker
//                             Expanded(
//                               flex: 4,
//                               child: GestureDetector(
//                                 onTap: _openRemarksDialog,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey[50],
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: Border.all(color: Colors.grey),
//                                   ),
//                                   child: _selectedRemarks.isEmpty
//                                       ? Row(
//                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Text(
//                                         S.of(context).pleaseSelect,
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.grey,
//                                           fontFamily: "Roboto",
//                                         ),
//                                       ),
//                                       Icon(Icons.expand_more, size: 18, color: Colors.grey),
//                                     ],
//                                   )
//                                       : Text(
//                                     _selectedRemarks.join(', '),
//                                     style: const TextStyle(
//                                       fontSize: 12,
//                                       color: Color(0xFF2D2D2D),
//                                       fontFamily: "Roboto",
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // Images Section - Modified for 2 images
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Padding(
//                         padding: EdgeInsets.only(left: 4, bottom: 12),
//                         child: Row(
//                           children: [
//                             Icon(Icons.photo_library, color: Font.primaryColor, size: 20),
//                             SizedBox(width: 8),
//                             Text(
//                               S.of(context).uploadImages,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Font.neutralDarkColor,
//                                 fontFamily: "Roboto",
//                               ),
//                             ),
//                             Spacer(),
//                             Container(
//                               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: Font.accentColor.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 '${images.where((img) => img.imagePath != null).length}/2',
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
//                       // Modified to show 2 images in a row layout
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildEnhancedImageCard(0, S.of(context).nearView),
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: _buildEnhancedImageCard(1, S.of(context).roadView),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 SizedBox(height: 20),
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
//                             _isAnyPickerActive ? "Camera Active..." :
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
//   Widget _buildEnhancedImageCard(int index, String imageTitle) {
//     final hasImage = images[index].imagePath != null;
//     final isThisCardActive = _isPickerActiveList[index];
//
//     return Container(
//       height: 280,
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
//           // Image area
//           Expanded(
//             child: GestureDetector(
//               onTap: (_isAnyPickerActive || isRefreshing || loader) ? null : () => _pickImage(index),
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
//           // Image title and status
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: hasImage ? Font.primaryColor.withOpacity(0.1) :
//               isThisCardActive ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(16),
//                 bottomRight: Radius.circular(16),
//               ),
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   imageTitle,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Font.neutralDarkColor,
//                     fontFamily: "Roboto",
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: hasImage ? Font.primaryColor :
//                         isThisCardActive ? Colors.blue : Colors.grey[400],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         '${index + 1}',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     if (isThisCardActive)
//                       SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//                         ),
//                       )
//                     else
//                       Icon(
//                         hasImage ? Icons.check_circle : Icons.radio_button_unchecked,
//                         color: hasImage ? Colors.green : Colors.grey[400],
//                         size: 16,
//                       ),
//                   ],
//                 ),
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
//           child: FutureBuilder<bool>(
//             future: File(images[index].imagePath!).exists(),
//             builder: (context, snapshot) {
//               if (snapshot.data == true) {
//                 return Image.file(
//                   File(images[index].imagePath!),
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   height: double.infinity,
//                   errorBuilder: (context, error, stackTrace) {
//                     print("Image display error: $error");
//                     return Container(
//                       color: Colors.grey[300],
//                       child: Icon(Icons.error, color: Colors.red),
//                     );
//                   },
//                 );
//               }
//               return Container(
//                 color: Colors.grey[300],
//                 child: Center(child: CircularProgressIndicator()),
//               );
//             },
//           ),
//         ),
//         // Remove button
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
//         // Edit overlay
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
//             (isThisCardActive ? Colors.blue : Font.accentColor).withOpacity(0.1),
//             (isThisCardActive ? Colors.blue : Font.primaryLightColor).withOpacity(0.1),
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
//               color: (isThisCardActive ? Colors.blue : Font.primaryColor).withOpacity(0.1),
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
//             isThisCardActive ? "Opening Camera..." : S.of(context).addPhoto,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: isThisCardActive ? Colors.blue : Font.primaryColor,
//               fontFamily: "Roboto",
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _submitDetails() async {
//     setState(() {
//       isRefreshing = true;
//     });
//
//     try {
//       final remarksIds = dataRemarks
//           .where((remark) => _selectedRemarks.contains(remark.remarks))
//           .map((remark) => remark.id)
//           .toList();
//
//       String remarksString = remarksIds.join(", ");
//       print(remarksString);
//       print("remarksIds:");
//
//       // Validate remarks selection
//       if (_selectedRemarks.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content: Text(S.of(context).selectRemarks),
//                 backgroundColor: Colors.red
//             )
//         );
//         setState(() {
//           isRefreshing = false;
//         });
//         return;
//       }
//
//       // Validate all images are uploaded
//       final uploadedCount = images.where((img) => img.imagePath != null).length;
//       if (uploadedCount != 2) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content: Text(S.of(context).pleaseUploadAllImages),
//                 backgroundColor: Colors.red
//             )
//         );
//         setState(() {
//           isRefreshing = false;
//         });
//         return;
//       }
//
//       // Store images in internal storage and update paths
//       for (var i = 0; i < images.length; i++) {
//         if (images[i].imagePath != null) {
//           final compressedImagePath = await _storeImageInInternalDocuments(images[i].imagePath!);
//           images[i].imagePath = compressedImagePath;
//         }
//       }
//
//       String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//
//       // Create metadata object
//       SUImageUploaddata metadata = SUImageUploaddata(
//           printId: widget.printId.toString(),
//           planCode: widget.planCode.toString(),
//           nearImagePath: images[0].imagePath,
//           nearLatitude: images[0].lat.toString(),
//           nearLongitude: images[0].long.toString(),
//           farImagePath: images[1].imagePath,
//           farLatitude: images[1].lat.toString(),
//           farLongitude: images[1].long.toString(),
//           villageCode: widget.villageCode.toString(),
//           remark: remarksIds.join(", "),
//           executionDate: currentDate,
//           uploadDate: '',
//           villageName: widget.villageName.toString(),
//           tensil: widget.tensil.toString(),
//           printNo: widget.printNo.toString(),
//         createdAt: DateTime.now(),  // ADD THIS LINE
//       );
//
//       // Save metadata to Hive
//       await PostReccaImageUploadHiveRepository().saveSUImageMetadata(metadata);
//
//       await CompletedUploadRepository().markAsCompleted(widget.printId.toString());
//
//       // Increment offline count
//       await CountChangeHiveRepository().incrementOfflineCount(
//         widget.planCode.toString(),
//         widget.villageCode.toString(),
//         widget.villageName.toString(),
//         widget.tensil.toString(),
//       );
//
//       String metadataJson = jsonEncode(metadata);
//
//       await PrintCrashReportManager.storeCrashReport(
//         error: "Post Recca Upload Data: $metadataJson",
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {
//           'phase': 'Post Recca Upload Data',
//           'timestamp': DateTime.now().toIso8601String(),
//         },
//       );
//
//       // Show success message and navigate
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(S.of(context).submitPlan),
//             backgroundColor: Colors.green,
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
//               builder: (context) => SUSeePlanScreen(changeLanguage: widget.changeLanguage)
//           )
//       );
//
//     } catch (e) {
//       print('Error in _submitDetails: $e');
//       await CrashReportManager.storeCrashReport(
//         error: "Submit details error: $e",
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {
//           'printId': widget.printId.toString(),
//           'imageCount': images.where((img) => img.imagePath != null).length,
//         },
//       );
//
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //     SnackBar(
//       //         content: Text('An error occurred while submitting. Please try again.'),
//       //         backgroundColor: Colors.red
//       //     )
//       // );
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
//                 color: Font.neutralDarkColor,
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
//                 color: Font.neutralDarkColor,
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
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: Font.neutralDarkColor,
//                 fontFamily: "Roboto",
//               ),
//             ),
//           ),
//           SizedBox(width: 83),
//           Center(
//             child: Text(
//               "${value}W",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Font.neutralDarkColor,
//                 fontFamily: "Roboto",
//               ),
//             ),
//           ),
//
//           SizedBox(width: 4),
//           Text('×', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
//           SizedBox(width: 4),
//           Center(
//             child: Text(
//               "${secondValue}H",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Font.neutralDarkColor,
//                 fontFamily: "Roboto",
//               ),
//             ),
//           ),
//
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:canimage/Repository/remarks_repository.dart';
import '../Common/camera_capture_screen.dart';
import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:canimage/Screens/printSync/execution_print_sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/image_compression_helper.dart';
import '../../utils/persistent_capture_store.dart';
import '../../APIService/auth_service.dart';
import '../../Hive_Database/post_recca_image_upload_db.dart';
import '../../Hive_Database/execution_image_upload_db.dart';
import '../../Hive_Database/post_recca_image_draft_db.dart';
import '../../Hive_Database/remarks_db.dart';
import '../../Model/recca_remarks_model.dart';
import '../../Repository/completed_upload_repository.dart';
import '../../Repository/postRecca_balance_count_change_repository.dart';
import '../../Repository/post_recca_image_upload_repository.dart';
import '../../Repository/post_recca_image_draft_repository.dart';

import '../../generated/l10n.dart';
import '../../utils/crash_manager.dart';
import '../../utils/fonts.dart';
import '../../utils/print_crash_manager.dart';
import '../../utils/uid_file_helper.dart';
import '../printSync/post_recca_print_sync_screen.dart';
import 'post_recca_see_plans.dart';

class SUUploadSeePlanScreen extends StatefulWidget {
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
  final Function(String) changeLanguage;

  SUUploadSeePlanScreen({
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
    required this.changeLanguage
  });

  @override
  State<SUUploadSeePlanScreen> createState() => _SUUploadSeePlanScreenState();
}

class _SUUploadSeePlanScreenState extends State<SUUploadSeePlanScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<ImageData> images = List.generate(2, (index) => ImageData());
  List<ReccaRemarksModel>? plans;
  List<Remarks> dataRemarks = [];
  bool loader = true;
  bool isRefreshing = false;
  List<bool> _isPickerActiveList = List.generate(2, (index) => false);
  bool isPickingImage = false;
  bool _isProcessingRecoveredImage = false;

  // Camera integration variables
  final ImagePicker _picker = ImagePicker();
  int? _currentImageIndex;

  final FocusNode _focusNode = FocusNode();
  final Set<String> _selectedRemarks = {};
  final TextEditingController _remarksDisplayCtrl = TextEditingController();

  // Persists already-captured images to Hive as soon as each one is taken,
  // keyed per print item, so closing this screen (or a camera crash) before
  // Submit does not lose captures already made.
  final PostReccaImageDraftHiveRepository _draftRepository =
      PostReccaImageDraftHiveRepository();
  late final String _draftKey;

  String _buildDraftKey() {
    return "POSTRECCA_${widget.printId}_${widget.planCode}_${widget.villageCode}";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _draftKey = _buildDraftKey();
    _recoverAfterRestart();

    fetchRemarks();
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
      final savedIndex = prefs.getInt('su_current_image_index');
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
        subfolder: 'PostRecca',
      );

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
          images[savedIndex].imagePath = permanentPath;
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
    _focusNode.dispose();
    _remarksDisplayCtrl.dispose();
    super.dispose();
  }

  /// Restores any images captured on a previous visit to this screen that
  /// were never submitted, so re-opening it (or recovering from a crash)
  /// does not show a blank form. Slot 0 = near, slot 1 = far.
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

  /// Persists the current in-memory capture state (near/far images) to
  /// Hive so it survives the screen being closed or a crash.
  Future<void> _saveDraftToHive() async {
    final draft = PostReccaImageDraft(
      draftKey: _draftKey,
      planCode: widget.planCode,
      villageCode: widget.villageCode,
      printId: widget.printId,
    );
    for (var i = 0; i < images.length; i++) {
      draft.setSlot(i, images[i].imagePath, images[i].lat, images[i].long);
    }
    await _draftRepository.saveDraft(draft);
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
        break;
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FocusScope.of(context).unfocus();
            _restoreStateIfNeeded();
          }
        });
        break;
      case AppLifecycleState.detached:
        _saveCurrentState();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentImageIndex != null && isPickingImage) {
      await prefs.setBool('su_is_picking_image', true);
      await prefs.setInt('su_current_image_index', _currentImageIndex!);

      final currentImage = images[_currentImageIndex!];
      if (currentImage.imagePath != null) {
        await prefs.setString('su_current_image_path', currentImage.imagePath!);
        await prefs.setDouble('su_current_image_lat', currentImage.lat);
        await prefs.setDouble('su_current_image_long', currentImage.long);
      }
    }
  }

  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('su_is_picking_image');
    await prefs.remove('su_current_image_index');
    await prefs.remove('su_current_image_path');
    await prefs.remove('su_current_image_lat');
    await prefs.remove('su_current_image_long');
  }

  Future<void> _restoreStateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    final savedIndex = prefs.getInt('su_current_image_index');
    final savedImagePath = prefs.getString('su_current_image_path');

    if (savedIndex != null && savedImagePath != null && savedIndex < 2) {
      if (await File(savedImagePath).exists()) {
        setState(() {
          images[savedIndex].imagePath = savedImagePath;
          images[savedIndex].lat = prefs.getDouble('su_current_image_lat') ?? 0.0;
          images[savedIndex].long = prefs.getDouble('su_current_image_long') ?? 0.0;
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

    await _clearSavedState();
  }

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
      return UidFileHelper.canonicalize(await UidFileHelper.readRawUidContent(uidFile));
    } catch (e) {
      return null;
    }
  }

  Future<bool> _hasRealInternetForLog() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
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
      XFile? pickedFile;

      try {
        pickedFile = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        ).timeout(
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
      if (pickedFile  != null) {
        try {
          final file = File(pickedFile.path);
          if (!await file.exists()) {
            throw Exception('Captured image file not found');
          }

          await file.length();

          // Move out of the camera screen's temp dir into permanent storage
          // immediately — leaving it in temp until Submit risks the OS
          // reclaiming it (and crashing the app) under low memory before the
          // user ever gets there.
          final String permanentPath = await PersistentCaptureStore.persist(
            pickedFile.path,
            subfolder: 'PostRecca',
          );

          if (mounted) {
            setState(() {
              images[index].imagePath = permanentPath;
              images[index].lat = currentPosition!.latitude;
              images[index].long = currentPosition.longitude;
            });
          }

          await _clearSavedState();

          // Persist immediately so this capture is not lost if the user
          // closes the screen (or the camera crashes) before submitting.
          await _saveDraftToHive();

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
            builder: (context) => SUSeePlanScreen(changeLanguage: widget.changeLanguage),
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

  void _removeImage(int index) {
    if (_isPickerActiveList[index]) return;
    setState(() {
      images[index].imagePath = null;
      images[index].lat = 0.0;
      images[index].long = 0.0;
    });
    _saveDraftToHive();
  }

  bool get _isAnyPickerActive =>
      _isPickerActiveList.any((isActive) => isActive) ||
          _isProcessingRecoveredImage;

  void fetchRemarks() async {
    setState(() {
      loader = true;
    });

    try {
      final remarksData = await RemarksHiveRepository().loadRemarks();

      if (remarksData.isNotEmpty) {
        dataRemarks = remarksData;
        print('Remarks loaded from Hive: $dataRemarks');
      } else {
        print('No remarks found in Hive.');
      }
    } catch (e) {
      print('Error loading remarks: $e');
      Fluttertoast.showToast(msg: S.of(context).failedLoadRemarks);
    } finally {
      setState(() {
        loader = false;
      });
    }
  }

  // ========== IMPROVED COMPRESSION METHOD (100-150 KB) ==========
  Future<String> _storeImageInInternalDocuments(String imagePath) async {
    try {
      print(' Storing image with compression...');

      // Get external storage directory
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw 'Unable to access external storage directory';
      }

      Directory appDocDir = Directory('${externalDir.path}/CIMTDWP');
      if (!await appDocDir.exists()) {
        await appDocDir.create(recursive: true);
        print(' CIMTDWP folder created at: ${appDocDir.path}');
      }
      print(' Using external storage: ${appDocDir.path}');

      // Create the nested folder structure for PostRecca/Supervisor
      Directory dwPaintingDir = Directory('${appDocDir.path}/PostRecca/Supervisor/${widget.projectID}/${widget.planCode}/${widget.villageCode}/${widget.printId}/Images');

      if (!await dwPaintingDir.exists()) {
        await dwPaintingDir.create(recursive: true);
        print(' Nested folders created: ${dwPaintingDir.path}');
      }

      File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw 'Source image file does not exist: $imagePath';
      }

      // Read original image bytes as Uint8List
      List<int> imageBytesList = await imageFile.readAsBytes();
      Uint8List imageBytes = Uint8List.fromList(imageBytesList);
      double originalSizeKB = imageBytes.length / 1024;

      const int targetMinKB = 100;
      const int targetMaxKB = 150;

      debugPrint('==================================================');
      debugPrint('📸 IMAGE COMPRESSION STARTED (Post Recca)');
      debugPrint('📁 Original Size: ${originalSizeKB.toStringAsFixed(2)} KB');
      debugPrint('🎯 Target Range: $targetMinKB - $targetMaxKB KB');
      debugPrint('==================================================');

      final bestCompressedBytes = await ImageCompressionHelper.compressToTargetSize(
        imageBytes,
        targetMinKB: targetMinKB,
        targetMaxKB: targetMaxKB,
      );
      final bestSize = bestCompressedBytes.length;

      // Final size check
      double finalSizeKB = bestSize / 1024;

      debugPrint('==================================================');
      debugPrint('📊 COMPRESSION SUMMARY');
      debugPrint('📁 Original Size: ${originalSizeKB.toStringAsFixed(2)} KB');
      debugPrint('📁 Final Size: ${finalSizeKB.toStringAsFixed(2)} KB');
      debugPrint('📉 Space Saved: ${(originalSizeKB - finalSizeKB).toStringAsFixed(2)} KB');
      debugPrint('📊 Compression Ratio: ${((originalSizeKB - finalSizeKB) / originalSizeKB * 100).toStringAsFixed(1)}%');

      if (bestSize >= targetMinKB * 1024 && bestSize <= targetMaxKB * 1024) {
        debugPrint('✅ STATUS: WITHIN TARGET RANGE ($targetMinKB-$targetMaxKB KB) ✅');
      } else if (bestSize < targetMinKB * 1024) {
        debugPrint('⚠️ STATUS: BELOW TARGET (${finalSizeKB.toStringAsFixed(2)} KB < $targetMinKB KB)');
      } else {
        debugPrint('⚠️ STATUS: ABOVE TARGET (${finalSizeKB.toStringAsFixed(2)} KB > $targetMaxKB KB)');
      }
      debugPrint('==================================================');

      // Define the image name
      String imageName = 'Img_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Define the full path where the image will be stored
      String imagePathInStorage = '${dwPaintingDir.path}/$imageName';

      // Save compressed image
      File compressedImage = File(imagePathInStorage);
      await compressedImage.writeAsBytes(bestCompressedBytes);

      if (!await compressedImage.exists()) {
        throw 'Failed to write compressed image to storage';
      }

      int diskSize = await compressedImage.length();
      double diskSizeKB = diskSize / 1024;
      debugPrint('💾 Disk Size: ${diskSizeKB.toStringAsFixed(2)} KB');
      debugPrint('==================================================');

      print('🎉 SUCCESS! Image stored at: $imagePathInStorage');
      print('📱 Storage location: ${appDocDir.path}');
      print('📂 Full path: PostRecca → Supervisor → ${widget.projectID} → ${widget.planCode} → ${widget.villageCode} → ${widget.printId} → Images');

      return imagePathInStorage;

    } catch (e) {
      print('❌ Error storing image: $e');
      throw 'Failed to store image: $e';
    }
  }

  void _openRemarksDialog() async {
    final temp = Set<String>.from(_selectedRemarks);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(S.of(context).pleaseSelect, style: TextStyle(fontFamily: "Roboto", fontSize: 14)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: dataRemarks.map((opt) {
                      final checked = temp.contains(opt.remarks);
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: checked,
                        dense: true,
                        title: Text(opt.remarks, style: TextStyle(fontFamily: "Roboto")),
                        onChanged: (v) {
                          setLocal(() {
                            if (v == true) {
                              temp.add(opt.remarks);
                            } else {
                              temp.remove(opt.remarks);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(S.of(context).cancel, style: TextStyle(fontFamily: "Roboto")),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedRemarks
                        ..clear()
                        ..addAll(temp);
                      _remarksDisplayCtrl.text = _selectedRemarks.join(', ');
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(S.of(context).submit, style: TextStyle(fontFamily: "Roboto")),
                ),
              ],
            );
          },
        );
      },
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
    super.build(context);
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
          body: loader == true ? Center(child: CircularProgressIndicator(color: Colors.blue,)) : SingleChildScrollView(
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
                        _EnhancedMetaRow(label: S.of(context).villageNameMap, value: widget.villageName.toString()),
                        _EnhancedMetaRow(label: S.of(context).brand, value: widget.brand.toString()),
                        _EnhancedMetaRowWithInputs(
                          label: S.of(context).size,
                          value: widget.width.toString(),
                          secondValue: widget.height.toString(),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                S.of(context).printNo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Font.neutralDarkColor,
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ),
                            SizedBox(width: 55,),
                            Center(
                              child: Text(
                                widget.printNo.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Font.neutralDarkColor,
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // REMARKS SECTION
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.only(top: 14),
                                child: Text(
                                  S.of(context).remarks,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2D2D2D),
                                    fontFamily: "Roboto",
                                  ),
                                ),
                              ),
                            ),

                            // Display + open picker
                            Expanded(
                              flex: 4,
                              child: GestureDetector(
                                onTap: _openRemarksDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: _selectedRemarks.isEmpty
                                      ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        S.of(context).pleaseSelect,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontFamily: "Roboto",
                                        ),
                                      ),
                                      Icon(Icons.expand_more, size: 18, color: Colors.grey),
                                    ],
                                  )
                                      : Text(
                                    _selectedRemarks.join(', '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2D2D2D),
                                      fontFamily: "Roboto",
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Images Section - Modified for 2 images
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library, color: Font.primaryColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              S.of(context).uploadImages,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Font.neutralDarkColor,
                                fontFamily: "Roboto",
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Font.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${images.where((img) => img.imagePath != null).length}/2',
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
                      // Modified to show 2 images in a row layout
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedImageCard(0, S.of(context).nearView),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildEnhancedImageCard(1, S.of(context).roadView),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

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
                            _isAnyPickerActive ? "Camera Active..." :
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

  Widget _buildEnhancedImageCard(int index, String imageTitle) {
    final hasImage = images[index].imagePath != null;
    final isThisCardActive = _isPickerActiveList[index];

    return Container(
      height: 280,
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
          // Image area
          Expanded(
            child: GestureDetector(
              onTap: (_isAnyPickerActive || isRefreshing || loader) ? null : () => _pickImage(index),
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

          // Image title and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasImage ? Font.primaryColor.withOpacity(0.1) :
              isThisCardActive ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Text(
                  imageTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Font.neutralDarkColor,
                    fontFamily: "Roboto",
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasImage ? Font.primaryColor :
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
                    print("Image display error: $error");
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
            (isThisCardActive ? Colors.blue : Font.accentColor).withOpacity(0.1),
            (isThisCardActive ? Colors.blue : Font.primaryLightColor).withOpacity(0.1),
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
              color: (isThisCardActive ? Colors.blue : Font.primaryColor).withOpacity(0.1),
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
            isThisCardActive ? "Opening Camera..." : S.of(context).addPhoto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isThisCardActive ? Colors.blue : Font.primaryColor,
              fontFamily: "Roboto",
            ),
          ),
        ],
      ),
    );
  }

  void _submitDetails() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      final remarksIds = dataRemarks
          .where((remark) => _selectedRemarks.contains(remark.remarks))
          .map((remark) => remark.id)
          .toList();

      String remarksString = remarksIds.join(", ");
      print(remarksString);
      print("remarksIds:");

      // Validate remarks selection
      if (_selectedRemarks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(S.of(context).selectRemarks),
                backgroundColor: Colors.red
            )
        );
        setState(() {
          isRefreshing = false;
        });
        return;
      }

      // Validate all images are uploaded
      final uploadedCount = images.where((img) => img.imagePath != null).length;
      if (uploadedCount != 2) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(S.of(context).pleaseUploadAllImages),
                backgroundColor: Colors.red
            )
        );
        setState(() {
          isRefreshing = false;
        });
        return;
      }

      debugPrint('==================================================');
      debugPrint('📸 SUBMITTING POST RECCA IMAGES - SIZE CHECK');
      debugPrint('==================================================');

      // Store images with compression and log each size
      List<double> imageSizes = [];
      for (var i = 0; i < images.length; i++) {
        if (images[i].imagePath != null) {
          File originalFile = File(images[i].imagePath!);
          int originalSize = await originalFile.length();
          double originalSizeKB = originalSize / 1024;

          debugPrint('📷 Image ${i+1} Original Size: ${originalSizeKB.toStringAsFixed(2)} KB');

          final compressedImagePath = await _storeImageInInternalDocuments(images[i].imagePath!);
          images[i].imagePath = compressedImagePath;

          File compressedFile = File(compressedImagePath);
          int compressedSize = await compressedFile.length();
          double compressedSizeKB = compressedSize / 1024;
          imageSizes.add(compressedSizeKB);

          debugPrint('📷 Image ${i+1} Compressed Size: ${compressedSizeKB.toStringAsFixed(2)} KB');
          debugPrint('---');
        }
      }

      // Log summary of all images
      debugPrint('==================================================');
      debugPrint('📊 ALL IMAGES SIZE SUMMARY');
      debugPrint('==================================================');
      for (var i = 0; i < imageSizes.length; i++) {
        String status = '';
        if (imageSizes[i] >= 150 && imageSizes[i] <= 200) {
          status = '✅ IN RANGE';
        } else if (imageSizes[i] < 150) {
          status = '⚠️ BELOW RANGE';
        } else {
          status = '⚠️ ABOVE RANGE';
        }
        debugPrint('Image ${i+1}: ${imageSizes[i].toStringAsFixed(2)} KB - $status');
      }

      double totalSize = imageSizes.fold(0, (sum, size) => sum + size);
      double averageSize = imageSizes.isNotEmpty ? totalSize / imageSizes.length : 0;
      debugPrint('----------------------------------------');
      debugPrint('📊 Total Size: ${totalSize.toStringAsFixed(2)} KB');
      debugPrint('📊 Average Size: ${averageSize.toStringAsFixed(2)} KB');
      debugPrint('==================================================');

      String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Create metadata object
      SUImageUploaddata metadata = SUImageUploaddata(
        printId: widget.printId.toString(),
        planCode: widget.planCode.toString(),
        nearImagePath: images[0].imagePath,
        nearLatitude: images[0].lat.toString(),
        nearLongitude: images[0].long.toString(),
        farImagePath: images[1].imagePath,
        farLatitude: images[1].lat.toString(),
        farLongitude: images[1].long.toString(),
        villageCode: widget.villageCode.toString(),
        remark: remarksIds.join(", "),
        executionDate: currentDate,
        uploadDate: '',
        villageName: widget.villageName.toString(),
        tensil: widget.tensil.toString(),
        printNo: widget.printNo.toString(),
        createdAt: DateTime.now(),
      );

      // Save metadata to Hive
      await PostReccaImageUploadHiveRepository().saveSUImageMetadata(metadata);

      // Submission succeeded, so the in-progress draft is no longer needed.
      await _draftRepository.deleteDraft(_draftKey);

      // ========== ACTIVITY LOG: record what was submitted ==========
      final rawUid = await _getRawUidForLog();
      final isNetworkAvailable = await _hasRealInternetForLog();
      await CrashReportManager.storePrintSubmissionLog({
        'printId': metadata.printId,
        'PlanCode': metadata.planCode,
        'PrintNo': metadata.printNo,
        'VillageCode': metadata.villageCode,
        'ExecutionDate': metadata.executionDate,
        'UploadDate': metadata.uploadDate,
        'NearImage': metadata.nearImagePath,
        'FarImage': metadata.farImagePath,
        'Near_Latitude': metadata.nearLatitude,
        'Near_Longitude': metadata.nearLongitude,
        'Far_Latitude': metadata.farLatitude,
        'Far_Longitude': metadata.farLongitude,
        'remark': metadata.remark,
        'NetworkStatus': isNetworkAvailable ? 'online' : 'offline',
        'UID': rawUid,
      });

      await CompletedUploadRepository().markAsCompleted(widget.printId.toString());

      // Increment offline count
      await CountChangeHiveRepository().incrementOfflineCount(
        widget.planCode.toString(),
        widget.villageCode.toString(),
        widget.villageName.toString(),
        widget.tensil.toString(),
      );

      String metadataJson = jsonEncode(metadata);

      await PrintCrashReportManager.storeCrashReport(
        error: "Post Recca Upload Data: $metadataJson",
        stackTrace: StackTrace.current.toString(),
        additionalInfo: {
          'phase': 'Post Recca Upload Data',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).submitPlan),
            backgroundColor: Colors.green,
          )
      );

      setState(() {
        isRefreshing = false;
      });

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => SUSeePlanScreen(changeLanguage: widget.changeLanguage)
          )
      );

    } catch (e) {
      print('Error in _submitDetails: $e');
      await CrashReportManager.storeCrashReport(
        error: "Submit details error: $e",
        stackTrace: StackTrace.current.toString(),
        additionalInfo: {
          'printId': widget.printId.toString(),
          'imageCount': images.where((img) => img.imagePath != null).length,
        },
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
                color: Font.neutralDarkColor,
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
                color: Font.neutralDarkColor,
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Font.neutralDarkColor,
                fontFamily: "Roboto",
              ),
            ),
          ),
          SizedBox(width: 83),
          Center(
            child: Text(
              "${value}W",
              style: TextStyle(
                fontSize: 12,
                color: Font.neutralDarkColor,
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
                color: Font.neutralDarkColor,
                fontFamily: "Roboto",
              ),
            ),
          ),
        ],
      ),
    );
  }
}