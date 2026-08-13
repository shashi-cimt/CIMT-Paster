


import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/image_orientation_utils.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  static Future<String?> capture(BuildContext context) async {
    // Unlock all orientations while camera is open
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    try {
      return await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const CameraCaptureScreen(),
          fullscreenDialog: true,
        ),
      );
    } finally {
      // Restore app to portrait only
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCapturing = false;
  bool _isSwitchingCamera = false;
  String? _initError;

  List<CameraDescription> _availableCameras = [];
  int _cameraIndex = 0;

  // Set when the app is backgrounded mid-capture and cleared once that
  // teardown finishes. _initCamera awaits it before opening a new session —
  // starting a new CameraController while the old one's native camera
  // session is still being released is what produced native SIGABRT crashes
  // on resume (two concurrent camera sessions racing at the platform level).
  Future<void>? _pendingDispose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  // ============================================================
  // LOAD AVAILABLE CAMERAS
  // ============================================================
  Future<void> _initCameras() async {
    try {
      _availableCameras = await availableCameras();

      if (_availableCameras.isEmpty) {
        if (mounted) {
          setState(() => _initError = 'No camera found on this device.');
        }
        return;
      }

      // Prefer BACK camera
      _cameraIndex = 0;
      for (int i = 0; i < _availableCameras.length; i++) {
        if (_availableCameras[i].lensDirection == CameraLensDirection.back) {
          _cameraIndex = i;
          break;
        }
      }

      await _initCamera(_cameraIndex);
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = 'Unable to start camera: $e');
    }
  }

  // ============================================================
  // INITIALIZE CAMERA
  // ============================================================
  Future<void> _initCamera(int index) async {
    if (_availableCameras.isEmpty) return;

    try {
      if (index < 0 || index >= _availableCameras.length) index = 0;

      if (_pendingDispose != null) {
        try {
          await _pendingDispose;
        } catch (_) {}
        _pendingDispose = null;
      }

      final CameraController? oldController = _controller;
      _controller = null;

      if (mounted) setState(() {});

      if (oldController != null) {
        try {
          await oldController.dispose();
        } catch (_) {}
      }

      final CameraController controller = CameraController(
        _availableCameras[index],
        ResolutionPreset.high, // change to veryHigh if needed
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _cameraIndex = index;
        _initError = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = 'Camera error: ${e.description ?? e.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = 'Unable to start camera: $e');
    }
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================
  Future<void> _toggleCamera() async {
    if (_availableCameras.length < 2 || _isCapturing || _isSwitchingCamera) {
      return;
    }

    setState(() => _isSwitchingCamera = true);

    try {
      final int nextIndex = (_cameraIndex + 1) % _availableCameras.length;
      await _initCamera(nextIndex);
    } finally {
      if (mounted) setState(() => _isSwitchingCamera = false);
    }
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (controller != null) {
        _controller = null;
        _pendingDispose = controller.dispose();
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_availableCameras.isNotEmpty) {
        _initCamera(_cameraIndex);
      } else {
        _initCameras();
      }
    }
  }

  // ============================================================
  // CAPTURE
  // ============================================================
  Future<void> _capture() async {
    final CameraController? controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing ||
        _isSwitchingCamera) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Pin the photo's EXIF rotation to the orientation the plugin has
      // detected right now. Without this the shot can be tagged with a
      // stale orientation reading, saving landscape photos as portrait.
      final DeviceOrientation captureOrientation =
          controller.value.deviceOrientation;
      try {
        await controller.lockCaptureOrientation(captureOrientation);
      } catch (_) {
        // Not fatal — falls back to the plugin's own auto-detection.
      }

      final XFile shot = await controller.takePicture();

      try {
        await controller.unlockCaptureOrientation();
      } catch (_) {}

      final Directory tempDirectory = await getTemporaryDirectory();
      final String destinationPath =
          '${tempDirectory.path}/capture_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Flutter's Image widget ignores JPEG EXIF orientation tags, so a
      // photo whose pixels are stored sideways with an EXIF "rotate 90"
      // instruction still renders sideways/portrait everywhere in the app.
      // Bake the rotation into the pixel data itself so the file is
      // physically upright on disk. Done via compute() since decode/encode
      // of a full-resolution photo is CPU-heavy enough to freeze the UI
      // thread if run inline, which is what made the shot feel slow to
      // appear after the shutter fired.
      final Uint8List rawBytes = await File(shot.path).readAsBytes();
      final Uint8List? uprightBytes = await compute(bakeJpegOrientation, rawBytes);
      if (uprightBytes != null) {
        await File(destinationPath).writeAsBytes(uprightBytes);
      } else {
        await File(shot.path).copy(destinationPath);
      }

      if (!mounted) return;

      Navigator.pop(context, destinationPath);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: ${e.description ?? e.code}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e')),
      );
    }
  }

  void _closeCamera() {
    if (_isCapturing) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final CameraController? controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isCapturing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildCameraView(),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_initError != null) {
      return _buildErrorView();
    }

    final CameraController? controller = _controller;
    final bool isReady =
        controller != null && controller.value.isInitialized;

    return OrientationBuilder(
      builder: (context, orientation) {
        final bool isLandscape = orientation == Orientation.landscape;
        final EdgeInsets safePadding = MediaQuery.paddingOf(context);

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

            // ==================== LANDSCAPE ====================
            if (isLandscape) ...[
              // Close - Top Right
              Positioned(
                top: safePadding.top + 16,
                right: safePadding.right + 20,
                child: _buildCancelButton(),
              ),

              // Capture - Center Right
              Positioned(
                top: 0,
                bottom: 0,
                right: safePadding.right + 18,
                child: Center(child: _buildCaptureButton(isReady)),
              ),

              // Flip - Bottom Right
              if (_availableCameras.length > 1)
                Positioned(
                  bottom: safePadding.bottom + 16,
                  right: safePadding.right + 20,
                  child: _buildFlipCameraButton(),
                ),
            ],

            // ==================== PORTRAIT ====================
            if (!isLandscape) ...[
              // Close - Bottom Left
              Positioned(
                bottom: safePadding.bottom + 30,
                left: safePadding.left + 24,
                child: _buildCancelButton(),
              ),

              // Capture - Bottom Center
              Positioned(
                bottom: safePadding.bottom + 18,
                left: 0,
                right: 0,
                child: Center(child: _buildCaptureButton(isReady)),
              ),

              // Flip - Bottom Right
              if (_availableCameras.length > 1)
                Positioned(
                  bottom: safePadding.bottom + 26,
                  right: safePadding.right + 24,
                  child: _buildFlipCameraButton(),
                ),
            ],
          ],
        );
      },
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================
  Widget _buildCaptureButton(bool isReady) {
    final bool disabled = !isReady || _isCapturing || _isSwitchingCamera;

    return GestureDetector(
      onTap: disabled ? null : _capture,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled && !_isCapturing ? 0.6 : 1,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
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
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: _isCapturing
                  ? const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isCapturing ? null : _closeCamera,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1,
            ),
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _buildFlipCameraButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (_isSwitchingCamera || _isCapturing) ? null : _toggleCamera,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1,
            ),
          ),
          child: _isSwitchingCamera
              ? const Padding(
            padding: EdgeInsets.all(15),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(
            Icons.flip_camera_ios,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================
  Widget _buildErrorView() {
    return OrientationBuilder(
      builder: (context, orientation) {
        final bool isLandscape = orientation == Orientation.landscape;
        final EdgeInsets safePadding = MediaQuery.paddingOf(context);

        return Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _initError ?? 'Unable to start camera.',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() => _initError = null);
                          await _initCameras();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: isLandscape ? 8 : safePadding.top + 8,
              right: isLandscape
                  ? safePadding.right + 8
                  : safePadding.right + 12,
              child: _buildCancelButton(),
            ),
          ],
        );
      },
    );
  }
}