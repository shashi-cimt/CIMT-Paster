
// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
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
//       case AppLifecycleState.resumed:
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             FocusScope.of(context).unfocus();
//             _restoreStateIfNeeded();
//           }
//         });
//         break;
//       case AppLifecycleState.detached:
//         _saveCurrentState();
//         break;
//       case AppLifecycleState.inactive:
//       case AppLifecycleState.hidden:
//         break;
//     }
//   }
//
//   Future<void> _saveCurrentState() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     if (_currentImageIndex != null && isPickingImage) {
//       await prefs.setBool('su_is_picking_image', true);
//       await prefs.setInt('su_current_image_index', _currentImageIndex!);
//
//       final currentImage = images[_currentImageIndex!];
//       if (currentImage.imagePath != null) {
//         await prefs.setString('su_current_image_path', currentImage.imagePath!);
//         await prefs.setDouble('su_current_image_lat', currentImage.lat);
//         await prefs.setDouble('su_current_image_long', currentImage.long);
//       }
//     }
//   }
//
//   Future<void> _clearSavedState() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('su_is_picking_image');
//     await prefs.remove('su_current_image_index');
//     await prefs.remove('su_current_image_path');
//     await prefs.remove('su_current_image_lat');
//     await prefs.remove('su_current_image_long');
//   }
//
//   Future<void> _restoreStateIfNeeded() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final savedIndex = prefs.getInt('su_current_image_index');
//     final savedImagePath = prefs.getString('su_current_image_path');
//
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
//       // Process the captured image
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
//             builder: (context) => SUSeePlanScreen(changeLanguage: widget.changeLanguage),
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
//   // ========== IMPROVED COMPRESSION METHOD (150-200 KB) ==========
//   Future<String> _storeImageInInternalDocuments(String imagePath) async {
//     try {
//       print(' Storing image with compression...');
//
//       // Get external storage directory
//       Directory? externalDir = await getExternalStorageDirectory();
//       if (externalDir == null) {
//         throw 'Unable to access external storage directory';
//       }
//
//       Directory appDocDir = Directory('${externalDir.path}/CIMTDWP');
//       if (!await appDocDir.exists()) {
//         await appDocDir.create(recursive: true);
//         print(' CIMTDWP folder created at: ${appDocDir.path}');
//       }
//       print(' Using external storage: ${appDocDir.path}');
//
//       // Create the nested folder structure for PostRecca/Supervisor
//       Directory dwPaintingDir = Directory('${appDocDir.path}/PostRecca/Supervisor/${widget.projectID}/${widget.planCode}/${widget.villageCode}/${widget.printId}/Images');
//
//       if (!await dwPaintingDir.exists()) {
//         await dwPaintingDir.create(recursive: true);
//         print(' Nested folders created: ${dwPaintingDir.path}');
//       }
//
//       File imageFile = File(imagePath);
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
//       debugPrint('📸 IMAGE COMPRESSION STARTED (Post Recca)');
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
//       // Define the image name
//       String imageName = 'Img_${DateTime.now().millisecondsSinceEpoch}.jpg';
//
//       // Define the full path where the image will be stored
//       String imagePathInStorage = '${dwPaintingDir.path}/$imageName';
//
//       // Save compressed image
//       File compressedImage = File(imagePathInStorage);
//       await compressedImage.writeAsBytes(bestCompressedBytes);
//
//       if (!await compressedImage.exists()) {
//         throw 'Failed to write compressed image to storage';
//       }
//
//       int diskSize = await compressedImage.length();
//       double diskSizeKB = diskSize / 1024;
//       debugPrint('💾 Disk Size: ${diskSizeKB.toStringAsFixed(2)} KB');
//       debugPrint('==================================================');
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
//       debugPrint('==================================================');
//       debugPrint('📸 SUBMITTING POST RECCA IMAGES - SIZE CHECK');
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
//       String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//
//       // Create metadata object
//       SUImageUploaddata metadata = SUImageUploaddata(
//         printId: widget.printId.toString(),
//         planCode: widget.planCode.toString(),
//         nearImagePath: images[0].imagePath,
//         nearLatitude: images[0].lat.toString(),
//         nearLongitude: images[0].long.toString(),
//         farImagePath: images[1].imagePath,
//         farLatitude: images[1].lat.toString(),
//         farLongitude: images[1].long.toString(),
//         villageCode: widget.villageCode.toString(),
//         remark: remarksIds.join(", "),
//         executionDate: currentDate,
//         uploadDate: '',
//         villageName: widget.villageName.toString(),
//         tensil: widget.tensil.toString(),
//         printNo: widget.printNo.toString(),
//         createdAt: DateTime.now(),
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
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:canimage/Repository/remarks_repository.dart';
import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:canimage/Screens/printSync/execution_print_sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../APIService/auth_service.dart';
import '../../Hive_Database/post_recca_image_upload_db.dart';
import '../../Hive_Database/execution_image_upload_db.dart';
import '../../Hive_Database/remarks_db.dart';
import '../../Model/recca_remarks_model.dart';
import '../../Repository/completed_upload_repository.dart';
import '../../Repository/postRecca_balance_count_change_repository.dart';
import '../../Repository/post_recca_image_upload_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/crash_manager.dart';
import '../../utils/fonts.dart';
import '../../utils/print_crash_manager.dart';
import '../printSync/post_recca_print_sync_screen.dart';
import 'post_recca_see_plans.dart';
import '../../main.dart';

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

  static bool get isCameraActive => _SUUploadSeePlanScreenState.isCameraOpen;

  @override
  State<SUUploadSeePlanScreen> createState() => _SUUploadSeePlanScreenState();
}

class _SUUploadSeePlanScreenState extends State<SUUploadSeePlanScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {

  static bool isCameraOpen = false;

  List<ImageData> images = List.generate(2, (index) => ImageData());
  List<ReccaRemarksModel>? plans;
  List<Remarks> dataRemarks = [];
  bool loader = true;
  bool isRefreshing = false;
  List<bool> _isPickerActiveList = List.generate(2, (index) => false);
  bool isPickingImage = false;
  bool _isProcessingRecoveredImage = false;

  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  int? _currentImageIndex;
  int _timeoutRetryCount = 0;
  DateTime? _lastTimeoutTime;

  final FocusNode _focusNode = FocusNode();
  final Set<String> _selectedRemarks = {};
  final TextEditingController _remarksDisplayCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize cameras
    _initCameras();

    fetchRemarks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRestoreState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _remarksDisplayCtrl.dispose();
    _clearSavedState();
    isCameraOpen = false;
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

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
      ResolutionPreset.medium,
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
    final wasPicking = prefs.getBool('su_is_picking_image') ?? false;

    if (wasPicking) {
      await _restoreStateIfNeeded();
      await prefs.setBool('su_is_picking_image', false);
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

      await _saveCurrentState();

      // ========== OPEN CAMERA SCREEN ==========
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SUPostReccaCameraScreen(
            imageIndex: index,
            imageLabel: index == 0 ? 'Near View' : 'Road View',
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
      print("🧹 Cleaning up camera picker state for index $index");
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

  // ========== COMPRESS IMAGE ON CAPTURE ==========
  Future<File?> _compressImageOnCapture(File imageFile, int imageIndex) async {
    const int minTargetKB = 150;
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
      } else if (sizeKB > maxTargetKB) {
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

      try { await imageFile.delete(); } catch (_) {}

      print("📸 Image ${imageIndex + 1}: ${originalSizeKB.toStringAsFixed(0)}KB → ${sizeKB.toStringAsFixed(0)}KB");

      if (mounted) {
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
          msg: "$statusIcon Image ${imageIndex + 1}: $sizeDisplay",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: toastColor,
          textColor: Colors.white,
        );
      }

      return out;

    } catch (e, st) {
      print("❌ Compression error: $e");
      await CrashReportManager.storeCrashReport(
        error: "Compression error: $e",
        stackTrace: st.toString(),
      );
      return null;
    }
  }

  // ========== STORE IMAGE IN INTERNAL DOCUMENTS ==========
  Future<String> _storeImageInInternalDocuments(String imagePath) async {
    try {
      print(' Storing image with compression...');

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

      Directory dwPaintingDir = Directory('${appDocDir.path}/PostRecca/Supervisor/${widget.projectID}/${widget.planCode}/${widget.villageCode}/${widget.printId}/Images');

      if (!await dwPaintingDir.exists()) {
        await dwPaintingDir.create(recursive: true);
        print(' Nested folders created: ${dwPaintingDir.path}');
      }

      File sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        throw 'Source image file does not exist: $imagePath';
      }

      String imageName = 'Img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String imagePathInStorage = '${dwPaintingDir.path}/$imageName';

      await sourceFile.copy(imagePathInStorage);

      File copiedFile = File(imagePathInStorage);
      if (!await copiedFile.exists()) {
        throw 'Failed to copy image to storage';
      }

      try {
        await sourceFile.delete();
        print("🗑️ Temporary file deleted: $imagePath");
      } catch (e) {
        print("⚠️ Could not delete temporary file: $e");
      }

      print('🎉 SUCCESS! Image stored at: $imagePathInStorage');
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

      await PostReccaImageUploadHiveRepository().saveSUImageMetadata(metadata);
      await CompletedUploadRepository().markAsCompleted(widget.printId.toString());
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

// ============================================================
// POST RECCA CAMERA SCREEN
// ============================================================
class SUPostReccaCameraScreen extends StatefulWidget {
  final Function(String, double, double) onImageCaptured;
  final int imageIndex;
  final String imageLabel;

  const SUPostReccaCameraScreen({
    super.key,
    required this.onImageCaptured,
    required this.imageIndex,
    required this.imageLabel,
  });

  @override
  State<SUPostReccaCameraScreen> createState() => _SUPostReccaCameraScreenState();
}

class _SUPostReccaCameraScreenState extends State<SUPostReccaCameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  Position? _currentPosition;

  // Camera toggle
  int _cameraIndex = 0;
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

      _cameraIndex = 0;
      for (int i = 0; i < _availableCameras.length; i++) {
        if (_availableCameras[i].lensDirection == CameraLensDirection.back) {
          _cameraIndex = i;
          break;
        }
      }

      await _initializeCamera(_cameraIndex);

    } catch (e) {
      print("Camera initialization error: $e");
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

      print("Camera initialized: ${cameraDescription.name} (${cameraDescription.lensDirection})");

    } catch (e) {
      print("Camera initialization error: $e");
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

    _cameraIndex = (_cameraIndex + 1) % _availableCameras.length;
    await _initializeCamera(_cameraIndex);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
      });

    } catch (e) {
      Fluttertoast.showToast(
        msg: "⚠️ Please enable GPS",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<File?> _compressImageOnCapture(File imageFile) async {
    const int minTargetKB = 150;
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
      } else if (sizeKB > maxTargetKB) {
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

      try { await imageFile.delete(); } catch (_) {}

      print("📸 Image ${widget.imageIndex + 1}: ${originalSizeKB.toStringAsFixed(0)}KB → ${sizeKB.toStringAsFixed(0)}KB");

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
        msg: "$statusIcon Image ${widget.imageIndex + 1}: $sizeDisplay",
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

    if (_currentPosition == null) {
      Fluttertoast.showToast(
        msg: "⚠️ Location not available. Please enable GPS.",
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

      Fluttertoast.showToast(
        msg: "✅ ${widget.imageLabel} captured",
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