import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/crash_manager.dart' show CrashReportManager;
import '../utils/inactivity_detector.dart';
import '../utils/shared_preference.dart';
import '../utils/token_manager.dart';
import 'auth/login_screen.dart';
import 'landing/landing_screen.dart';

final splashScreenProvider = StateProvider<bool>((ref) => true);

class SplashScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const SplashScreen({super.key, required this.changeLanguage});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String? uid;
  late AnimationController _animationController;
  late Animation<double> _boomerangAnimation;
  bool _permissionsRequested = false;
  String _statusMessage = "Initializing...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CrashReportManager.storeLogMessage("Splash Screen Started");

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _boomerangAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.7)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_animationController);

    _startBoomerangAnimation();
    _requestAllPermissions();
  }

  void _startBoomerangAnimation() {
    _animationController.forward().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _animationController.reset();
          _animationController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted && _permissionsRequested) {
          // Removed security recheck
        }
      });
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _statusMessage = "Requesting permissions...";
    });

    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      int androidVersion = 0;
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        androidVersion = androidInfo.version.sdkInt;
      }

      List<Permission> essentialPermissions = [
        Permission.camera,
        Permission.microphone,
        Permission.location,
        Permission.phone,
        Permission.contacts,
        Permission.sms,
        Permission.notification,
      ];

      if (androidVersion >= 33) {
        essentialPermissions.addAll([
          Permission.videos,
          Permission.audio,
        ]);
      }

      if (androidVersion >= 31) {
        essentialPermissions.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]);
      }

      if (androidVersion < 30) {
        essentialPermissions.add(Permission.storage);
      }

      Map<Permission, PermissionStatus> finalStatuses = {};

      for (Permission permission in essentialPermissions) {
        setState(() {
          _statusMessage = "Requesting ${_getPermissionName(permission)} permission...";
        });

        await Future.delayed(Duration(milliseconds: 300));

        PermissionStatus currentStatus = await permission.status;
        if (currentStatus.isGranted) {
          finalStatuses[permission] = currentStatus;
          continue;
        }

        PermissionStatus status = await permission.request();
        finalStatuses[permission] = status;

        await Future.delayed(Duration(milliseconds: 200));
      }

      int grantedCount = finalStatuses.values.where((status) => status.isGranted).length;
      int totalCount = finalStatuses.length;

      setState(() {
        if (grantedCount == totalCount) {
          _statusMessage = "All permissions granted! ($grantedCount/$totalCount)";
        } else {
          _statusMessage = "Permissions granted: $grantedCount/$totalCount";
        }
      });

      _permissionsRequested = true;
      _initializeFolderStructure();

    } catch (e) {
      setState(() {
        _statusMessage = "Error requesting permissions";
      });

      _permissionsRequested = true;
      _initializeFolderStructure();
    }
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return "Storage";
      case Permission.camera:
        return "Camera";
      case Permission.location:
        return "Location";
      case Permission.phone:
        return "Phone";
      case Permission.notification:
        return "Notification";
      case Permission.bluetoothScan:
        return "Bluetooth Scan";
      case Permission.bluetoothConnect:
        return "Bluetooth Connect";
      case Permission.bluetoothAdvertise:
        return "Bluetooth Advertise";
      default:
        return permission.toString().split('.').last;
    }
  }

  // Initialize folder structure for both Pastor and Supervisor
  Future<void> _initializeFolderStructure() async {
    setState(() {
      _statusMessage = "Setting up application...";
    });

    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw 'Unable to access external storage directory';
      }

      // Create folders for Pastor: /CIMTDWP
      await _createRoleFolderWithUID(externalDir.path, 'CIMTDWP', 'Pastor');

      // Create folders for Supervisor: /CIMTDWPSUP
      await _createRoleFolderWithUID(externalDir.path, 'CIMTDWPSUP', 'Supervisor');

      // print(' Both Pastor and Supervisor folders initialized');

    } catch (e) {
      // print(' Error initializing folder structure: $e');
    }

    setState(() {
      _statusMessage = "Ready to launch...";
    });

    Future.delayed(Duration(seconds: 1), () async {
      final accessToken = await getAuthToken();
      final isValid = await TokenManager().isTokenValid();

      if (accessToken != null && accessToken.isNotEmpty && isValid) {
        await TokenManager().initializeTokenMonitoring(accessToken);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InactivityDetector(
              child: LandingScreen(changeLanguage: widget.changeLanguage),
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LoginScreen(
                changeLanguage: widget.changeLanguage,
              )),
        );
      }
    });
  }

  // Create role-specific folder and check/create UID
  Future<void> _createRoleFolderWithUID(
      String basePath,
      String folderName,
      String role,
      ) async {
    try {
      Directory roleDir = Directory('$basePath/$folderName/Appfiles');

      if (!await roleDir.exists()) {
        await roleDir.create(recursive: true);
      }

      File uidFile = File('${roleDir.path}/UID.txt');

      if (!await uidFile.exists()) {
        final androidId = await _getAndroidId();
        await uidFile.writeAsString(androidId);
        print('$role Android ID saved: $androidId');
      } else {
        final lines = await uidFile.readAsLines();

        if (lines.isNotEmpty) {
          print('$role Android ID: ${lines.first}');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  Future<String> _getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Android ID
    }

    return "UNKNOWN_DEVICE";
  }



  Future<String> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceInfoValue = '';

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceInfoValue = androidInfo.id ?? 'Unknown Device Info';
    } else {
      deviceInfoValue = 'Unknown Device';
    }

    return deviceInfoValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _boomerangAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _boomerangAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 80,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}