import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'utils/fonts.dart';
import 'widgets/app_snack_bar.dart';

class UpdateProvider extends ChangeNotifier {
  double _progress = 0.0;
  bool _isDownloading = false;
  String _downloadStatus = '';
  String? latestVersion;
  String? downloadUrl;
  String? desc;

  BuildContext? _dialogContext;
  bool _isDialogOpen = false;

  double get progress => _progress;
  bool get isDownloading => _isDownloading;
  String get downloadStatus => _downloadStatus;

  // Firestore Collection Name: 'app_updates'
  // Document ID: 'latest'
  Future<void> checkForUpdate(BuildContext context) async {
    if (_isDownloading || _isDialogOpen) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('app_updates')
          .doc('latest')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();

        latestVersion = data?['version']?.toString().trim();
        downloadUrl = data?['link']?.toString().trim() ?? '';
        desc = data?['desc']?.toString().trim() ?? '';

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version.trim();

        debugPrint('Data: $data');
        debugPrint('Current Version: $currentVersion');
        debugPrint('Latest Version: $latestVersion');
        debugPrint('Download URL: $downloadUrl');

        if (latestVersion != null &&
            downloadUrl!.isNotEmpty &&
            latestVersion != currentVersion) {
          if (context.mounted) {
            showUpdateDialog(context, desc ?? '');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching update data: $e');
    }
  }

  void showUpdateDialog(BuildContext context, String desc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Font.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.system_update_rounded,
                          color: Font.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New Update Available',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Roboto',
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              latestVersion != null && latestVersion!.isNotEmpty
                                  ? 'Version $latestVersion'
                                  : 'New version ready to install',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w600,
                                color: Font.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        desc.isNotEmpty
                            ? desc
                            : 'Get the latest version now for a better experience, bug fixes, and new features!',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Roboto',
                          color: Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        downloadUpdate(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Font.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shadowColor: Font.primaryColor.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'UPDATE NOW',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> downloadUpdate(BuildContext context) async {
    // Only request install packages permission, no storage permission needed
    // if we save to our own app directory.
    if (Platform.isAndroid) {
      if (!await Permission.requestInstallPackages.request().isGranted) {
        if (context.mounted) {
          showPermissionSnackbar(context);
        }
        return;
      }
    }

    if (!context.mounted) return;
    showProgressDialog(context);

    _isDownloading = true;
    _progress = 0.0;
    _downloadStatus = 'Initializing Download...';
    notifyListeners();

    String url = downloadUrl ?? '';
    // Fix Google Drive View Link to Download Link
    if (url.contains('drive.google.com')) {
      final idRegExp = RegExp(r'\/d\/([a-zA-Z0-9_-]+)');
      final match = idRegExp.firstMatch(url);
      if (match != null) {
        final id = match.group(1);
        url = 'https://drive.google.com/uc?export=download&id=$id';
      }
    }

    final dio = Dio();
    try {
      // Use app's external files dir (no permission needed)
      // On Android this is typically: /storage/emulated/0/Android/data/com.example.app/files
      final directory = await getExternalStorageDirectory();

      if (directory == null) {
        throw 'Could not access storage directory';
      }

      final v = latestVersion ?? 'latest';
      final filePath = '${directory.path}/CanImage_$v.apk';

      // Delete existing file if present
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _progress = received / total;
            _downloadStatus =
                'Downloading... ${(_progress * 100).toStringAsFixed(0)}%';
            notifyListeners();
          }
        },
      );

      _downloadStatus = 'Download Complete. Installing...';
      notifyListeners();

      if (context.mounted) {
        await installApk(context, filePath);
      }
    } catch (e) {
      _closeProgressDialog();
      if (context.mounted) {
        handleDownloadError(context, e.toString());
      }
    } finally {
      _isDownloading = false;
      _progress = 0.0;
      if (_downloadStatus.contains('Complete')) {
        // If installation started, we can close dialog
        _closeProgressDialog();
      }
      notifyListeners();
    }
  }

  void showProgressDialog(BuildContext context) {
    _isDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        _dialogContext = dialogContext;
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Font.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_download_rounded,
                          color: Font.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Downloading Update',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Roboto',
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Please keep the app open',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Roboto',
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: this,
                    builder: (context, child) {
                      final percent = (_progress * 100).clamp(0, 100).toInt();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progress > 0 ? _progress : null,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Font.primaryColor,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _downloadStatus,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontFamily: 'Roboto',
                                  color: Font.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_progress > 0)
                                Text(
                                  '$percent%',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontFamily: 'Roboto',
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogOpen = false;
      _dialogContext = null;
    });
  }

  void _closeProgressDialog() {
    if (_isDialogOpen && _dialogContext != null && _dialogContext!.mounted) {
      Navigator.of(_dialogContext!).pop();
      _isDialogOpen = false;
      _dialogContext = null;
    }
  }

  void showPermissionSnackbar(BuildContext context) {
    if (!context.mounted) return;
    final mediaQuery = MediaQuery.of(context);
    final double topPadding = mediaQuery.padding.top;
    final double screenHeight = mediaQuery.size.height;
    final double bottomMargin = (screenHeight - topPadding - 80).clamp(
      16.0,
      screenHeight - 40,
    );

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(left: 16, right: 16, bottom: bottomMargin),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 5),
        padding: EdgeInsets.zero,
        content: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Allow installation from unknown sources to update',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    openAppSettings();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
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

  Future<void> installApk(BuildContext context, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (context.mounted) {
        handleDownloadError(context, 'APK file not found.');
      }
      return;
    }

    // Open the APK for installation
    try {
      final result = await OpenFilex.open(filePath);
      debugPrint('Result: ${result.message}');
      if (result.type != ResultType.done) {
        if (context.mounted) {
          handleDownloadError(context, result.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        handleDownloadError(context, e.toString());
      }
    }
  }

  void handleDownloadError(BuildContext context, String error) {
    if (!context.mounted) return;
    AppSnackBar.showError(context, 'Update Failed: $error');
  }
}

// Backward-compatibility alias
typedef UpdateController = UpdateProvider;

// Riverpod ChangeNotifierProvider
final updateProvider = ChangeNotifierProvider<UpdateProvider>((ref) {
  return UpdateProvider();
});

// Check for updates example:
// With Riverpod:
// WidgetsBinding.instance.addPostFrameCallback((_) {
//   ref.read(updateProvider).checkForUpdate(context);
// });
// Or with direct ChangeNotifier:
// WidgetsBinding.instance.addPostFrameCallback((_) {
//   UpdateProvider().checkForUpdate(context);
// });
