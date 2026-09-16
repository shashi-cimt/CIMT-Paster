import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart' show appInitializationFuture;
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


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CrashReportManager.storeLogMessage("Splash Screen Started");

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _boomerangAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
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

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // 1. Start boomerang animation
    final animFuture = _animationController.forward();

    // 2. Initialize folder structure
    final folderFuture = _initializeFolderStructure();

    // 3. Wait for the full animation to complete AND all background initialization to finish
    await Future.wait([
      animFuture,
      folderFuture,
      if (appInitializationFuture != null) appInitializationFuture!,
    ]);

    // Small graceful pause with logo fully settled at 1.0
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    final accessToken = await getAuthToken();
    final isValid = await TokenManager().isTokenValid();

    if (!mounted) return;

    if (accessToken.isNotEmpty && isValid) {
      await TokenManager().initializeTokenMonitoring(accessToken);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InactivityDetector(
            child: LandingScreen(changeLanguage: widget.changeLanguage),
          ),
        ),
      );
    } else {
      await clearUserSession();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(changeLanguage: widget.changeLanguage),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  // Initialize folder structure for both Pastor and Supervisor
  Future<void> _initializeFolderStructure() async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw 'Unable to access external storage directory';
      }

      // Create folders for Pastor: /CIMTDWP
      await _createRoleFolderWithUID(externalDir.path, 'CIMTDWP', 'Pastor');

      // Create folders for Supervisor: /CIMTDWPSUP
      await _createRoleFolderWithUID(
        externalDir.path,
        'CIMTDWPSUP',
        'Supervisor',
      );
    } catch (e) {
      // Error initializing folder structure
    }
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
    if (Platform.isAndroid) {
      try {
        const androidIdPlugin = AndroidId();
        final id = await androidIdPlugin.getId();
        return id ?? "UNKNOWN_DEVICE";
      } catch (e) {
        print('Error getting Android ID: $e');
        return "UNKNOWN_DEVICE";
      }
    }

    return "UNKNOWN_DEVICE";
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
                    child: Image.asset('assets/logo.png', height: 80),
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
