// import 'dart:async';
// import 'dart:io';
//
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
//
// /// Full-screen in-app camera shared by every "capture image" flow (execution,
// /// rework, and post-recca upload screens) instead of launching the OS camera
// /// app via image_picker. Staying inside the app's own CameraController (no
// /// external activity hand-off) also avoids the class of "camera closed but
// /// the photo never came back" crashes that only affected the image_picker
// /// native-camera intent on some Android builds.
// ///
// /// Push it with [CameraCaptureScreen.capture]; it resolves to the captured
// /// JPEG's file path once the user accepts a photo, or `null` if they back
// /// out without accepting one.
// class CameraCaptureScreen extends StatefulWidget {
//   const CameraCaptureScreen({super.key});
//
//   static Future<String?> capture(BuildContext context) {
//     return Navigator.push<String>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const CameraCaptureScreen(),
//         fullscreenDialog: true,
//       ),
//     );
//   }
//
//   @override
//   State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
// }
//
// class _CameraCaptureScreenState extends State<CameraCaptureScreen>
//     with WidgetsBindingObserver {
//   CameraController? _controller;
//   FlashMode _flashMode = FlashMode.off;
//   String? _capturedPath;
//   bool _isCapturing = false;
//   String? _initError;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initCamera();
//   }
//
//   Future<void> _initCamera() async {
//     try {
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         if (mounted) setState(() => _initError = 'No camera found on this device.');
//         return;
//       }
//       final rearCamera = cameras.firstWhere(
//         (c) => c.lensDirection == CameraLensDirection.back,
//         orElse: () => cameras.first,
//       );
//       final controller = CameraController(
//         rearCamera,
//         ResolutionPreset.high,
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.jpeg,
//       );
//       await controller.initialize();
//       try {
//         await controller.setFlashMode(_flashMode);
//       } catch (_) {
//         // Not all devices support flash; capture still works without it.
//       }
//
//       if (!mounted) {
//         await controller.dispose();
//         return;
//       }
//       setState(() {
//         _controller = controller;
//         _initError = null;
//       });
//     } catch (e) {
//       if (mounted) {
//         setState(() => _initError = 'Unable to start the camera: $e');
//       }
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     final controller = _controller;
//     if (controller == null || !controller.value.isInitialized) return;
//
//     if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
//       _controller = null;
//       controller.dispose();
//     } else if (state == AppLifecycleState.resumed) {
//       _initCamera();
//     }
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   Future<void> _toggleFlash() async {
//     final controller = _controller;
//     if (controller == null) return;
//     final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
//     try {
//       await controller.setFlashMode(next);
//       if (mounted) setState(() => _flashMode = next);
//     } catch (_) {
//       // Ignore devices that reject the flash mode change.
//     }
//   }
//
//   Future<void> _capture() async {
//     final controller = _controller;
//     if (controller == null || !controller.value.isInitialized || _isCapturing) {
//       return;
//     }
//     setState(() => _isCapturing = true);
//     try {
//       final shot = await controller.takePicture();
//
//       // Copy out of the camera plugin's own cache into a path we own, so it
//       // isn't at risk of being reused/cleared by the plugin later.
//       final tempDir = await getTemporaryDirectory();
//       final destPath =
//           '${tempDir.path}/capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       await File(shot.path).copy(destPath);
//
//       if (mounted) {
//         setState(() => _capturedPath = destPath);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to capture photo: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isCapturing = false);
//     }
//   }
//
//   void _retake() {
//     setState(() => _capturedPath = null);
//   }
//
//   void _usePhoto() {
//     Navigator.pop(context, _capturedPath);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: true,
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: SafeArea(
//           child: _capturedPath != null ? _buildPreview() : _buildCameraView(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCameraView() {
//     if (_initError != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.error_outline, color: Colors.white, size: 48),
//               const SizedBox(height: 12),
//               Text(
//                 _initError!,
//                 style: const TextStyle(color: Colors.white),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Close'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     final controller = _controller;
//     if (controller == null || !controller.value.isInitialized) {
//       return const Center(child: CircularProgressIndicator(color: Colors.white));
//     }
//
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         Center(child: CameraPreview(controller)),
//         Positioned(
//           top: 8,
//           left: 8,
//           child: IconButton(
//             icon: const Icon(Icons.close, color: Colors.white, size: 28),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         Positioned(
//           top: 8,
//           right: 8,
//           child: IconButton(
//             icon: Icon(
//               _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
//               color: Colors.white,
//               size: 28,
//             ),
//             onPressed: _toggleFlash,
//           ),
//         ),
//         Positioned(
//           bottom: 24,
//           left: 0,
//           right: 0,
//           child: Center(
//             child: GestureDetector(
//               onTap: _isCapturing ? null : _capture,
//               child: Container(
//                 width: 72,
//                 height: 72,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white,
//                   border: Border.all(color: Colors.white54, width: 4),
//                 ),
//                 child: _isCapturing
//                     ? const Padding(
//                         padding: EdgeInsets.all(20),
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : null,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPreview() {
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         Image.file(File(_capturedPath!), fit: BoxFit.contain),
//         Positioned(
//           bottom: 24,
//           left: 24,
//           right: 24,
//           child: Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: _retake,
//                   icon: const Icon(Icons.refresh, color: Colors.white),
//                   label: const Text('Retake', style: TextStyle(color: Colors.white)),
//                   style: OutlinedButton.styleFrom(
//                     side: const BorderSide(color: Colors.white),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: _usePhoto,
//                   icon: const Icon(Icons.check),
//                   label: const Text('Use Photo'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
//
//
//
//


import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Full-screen in-app camera shared by every "capture image" flow (execution,
/// rework, and post-recca upload screens) instead of launching the OS camera
/// app via image_picker. Staying inside the app's own CameraController (no
/// external activity hand-off) also avoids the class of "camera closed but
/// the photo never came back" crashes that only affected the image_picker
/// native-camera intent on some Android builds.
///
/// Push it with [CameraCaptureScreen.capture]; it resolves to the captured
/// JPEG's file path as soon as a photo is taken, or `null` if the user backs
/// out without taking one.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  static Future<String?> capture(BuildContext context) {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraCaptureScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  FlashMode _flashMode = FlashMode.off;
  bool _isCapturing = false;
  String? _initError;

  // Camera toggle
  List<CameraDescription> _availableCameras = [];
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  /// Loads the camera list once, then initializes starting with the back
  /// camera (falls back to the first available one).
  Future<void> _initCameras() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        if (mounted) {
          setState(() => _initError = 'No camera found on this device.');
        }
        return;
      }

      _cameraIndex = 0;
      for (int i = 0; i < _availableCameras.length; i++) {
        if (_availableCameras[i].lensDirection == CameraLensDirection.back) {
          _cameraIndex = i;
          break;
        }
      }

      await _initCamera(_cameraIndex);
    } catch (e) {
      if (mounted) {
        setState(() => _initError = 'Unable to start the camera: $e');
      }
    }
  }

  Future<void> _initCamera(int index) async {
    try {
      if (index >= _availableCameras.length) index = 0;

      // Dispose the old controller before creating a new one.
      final old = _controller;
      _controller = null;
      await old?.dispose();

      final controller = CameraController(
        _availableCameras[index],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      try {
        await controller.setFlashMode(_flashMode);
      } catch (_) {
        // Not all cameras support flash (e.g. front camera); capture still
        // works without it.
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _initError = 'Unable to start the camera: $e');
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras.length < 2 || _isCapturing) return;
    setState(() {
      // Clearing the controller shows the loading spinner while switching.
      _initError = null;
    });
    _cameraIndex = (_cameraIndex + 1) % _availableCameras.length;
    await _initCamera(_cameraIndex);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_cameraIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {
      // Ignore devices that reject the flash mode change.
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final shot = await controller.takePicture();

      // Copy out of the camera plugin's own cache into a path we own, so it
      // isn't at risk of being reused/cleared by the plugin later.
      final tempDir = await getTemporaryDirectory();
      final destPath =
          '${tempDir.path}/capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(shot.path).copy(destPath);

      // No preview/confirm step: return the photo immediately.
      if (mounted) {
        Navigator.pop(context, destPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _buildCameraView(),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                _initError!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview
        if (isReady)
          Positioned.fill(child: CameraPreview(controller))
        else
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),

        // Flash Button (Top Right)
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: _toggleFlash,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                _flashMode == FlashMode.off
                    ? Icons.flash_off
                    : Icons.flash_on,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),

        // Capture Button (Center Bottom)
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: (_isCapturing || !isReady) ? null : _capture,
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
                      offset: const Offset(0, 4),
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
                    child: _isCapturing
                        ? const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue),
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

        // Cancel Button (Bottom Left)
        Positioned(
          bottom: 50,
          left: 30,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),

        // Flip Camera Button (Bottom Right)
        if (_availableCameras.length > 1)
          Positioned(
            bottom: 50,
            right: 30,
            child: GestureDetector(
              onTap: _toggleCamera,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
      ],
    );
  }

}
