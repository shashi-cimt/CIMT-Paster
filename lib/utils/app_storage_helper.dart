import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central helper for managing image storage inside the public
/// `/storage/emulated/0/CIMT/` directory structure with role-based folders
/// (e.g. `CIMT/Paster/...` or `CIMT/Supervisor/...`).
class AppStorageHelper {
  AppStorageHelper._();

  /// Checks and requests "All Files Access" (MANAGE_EXTERNAL_STORAGE)
  /// on Android 11+ (API 30+), or standard storage permission on older Android.
  static Future<bool> ensureStoragePermission({BuildContext? context}) async {
    if (!Platform.isAndroid) return true;

    try {
      // Check MANAGE_EXTERNAL_STORAGE status first (for Android 11+)
      PermissionStatus manageStatus =
          await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) {
        return true;
      }

      // If context provided, show explanation dialog before system settings redirect
      if (context != null && context.mounted) {
        bool proceed =
            await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => Dialog(
                backgroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Icon Badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF264386).withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF264386).withOpacity(0.18),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.folder_shared_rounded,
                            size: 32,
                            color: Color(0xFF264386),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      const Text(
                        'Storage Permission',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          fontFamily: "Roboto",
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        'To store and organize captured photos in your phone\'s File Manager (Internal Storage > CIMT), please allow "All files access".',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.grey.shade600,
                          fontFamily: "Roboto",
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Info Box with key points
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Location: Internal Storage/CIMT',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                      fontFamily: "Roboto",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.touch_app_rounded,
                                  size: 16,
                                  color: Color(0xFF264386),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Next screen par "Allow access to manage all files" switch on karein.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade700,
                                      fontFamily: "Roboto",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                foregroundColor: const Color(0xFF64748B),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Allow Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                backgroundColor: const Color(0xFF264386),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Allow',
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
                    ],
                  ),
                ),
              ),
            ) ??
            false;

        if (!proceed) return false;
      }

      // Request manageExternalStorage
      manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        return true;
      }

      // Fallback to standard storage permission (e.g. Android 9/10)
      PermissionStatus storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } catch (_) {
      // If permission check fails, attempt fallback
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  /// Resolves the public `/storage/emulated/0/CIMT` directory.
  static Future<Directory> getPublicCimtDirectory() async {
    String basePath = '/storage/emulated/0/CIMT';

    if (Platform.isAndroid) {
      try {
        final Directory? extDir = await getExternalStorageDirectory();
        if (extDir != null && extDir.path.contains('/Android/data')) {
          final root = extDir.path.split('/Android/data').first;
          basePath = '$root/CIMT';
        }
      } catch (_) {}
    } else {
      basePath = '${Directory.systemTemp.path}/CIMT';
    }

    final Directory dir = Directory(basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Resolves the public `/storage/emulated/0/CIMT/Logs/{Role}/{subFolder}`
  /// Automatically segments logs by role ('Paster' or 'Supervisor').
  /// If [rootOnly] is true, resolves directly under `/storage/emulated/0/CIMT/Logs`.
  static Future<Directory> getPublicLogsDirectory({
    String? subFolder,
    String? roleFolder,
    bool rootOnly = false,
  }) async {
    final Directory cimtDir = await getPublicCimtDirectory();
    if (rootOnly) {
      final String targetPath = (subFolder != null && subFolder.trim().isNotEmpty)
          ? '${cimtDir.path}/Logs/${sanitizePathComponent(subFolder)}'
          : '${cimtDir.path}/Logs';
      final Directory dir = Directory(targetPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    final String safeRole = await resolveRoleFolder(roleFolder);
    final String basePath = '${cimtDir.path}/Logs/$safeRole';
    final String targetPath = (subFolder != null && subFolder.trim().isNotEmpty)
        ? '$basePath/${sanitizePathComponent(subFolder)}'
        : basePath;
    final Directory dir = Directory(targetPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Sanitizes folder/file names to ensure they are valid on the Android filesystem.
  static String sanitizePathComponent(String input) {
    if (input.trim().isEmpty) return 'Unknown';
    // Replace characters forbidden in Android / Linux filenames
    return input.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// Resolves the role folder name ('Paster' or 'Supervisor').
  /// Checks explicit role parameter first, then SharedPreferences 'roleFlag' (6 -> Paster, 7 -> Supervisor)
  /// and 'roleName'. Defaults to 'Paster' if undetermined.
  static Future<String> resolveRoleFolder([String? explicitRole]) async {
    if (explicitRole != null && explicitRole.trim().isNotEmpty) {
      final String r = explicitRole.trim().toLowerCase();
      if (r.contains('sup') || r == '7') return 'Supervisor';
      if (r.contains('past') || r == '6') return 'Paster';
      return sanitizePathComponent(explicitRole);
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String roleFlag = (prefs.getString('roleFlag') ?? '').trim();
      if (roleFlag == '7') return 'Supervisor';
      if (roleFlag == '6') return 'Paster';

      final String roleName = (prefs.getString('roleName') ?? '')
          .trim()
          .toLowerCase();
      if (roleName.contains('sup')) return 'Supervisor';
      if (roleName.contains('past')) return 'Paster';
    } catch (_) {}

    return 'Paster';
  }

  /// Builds and creates the nested folder for a print:
  /// `/storage/emulated/0/CIMT/{RoleFolder}/{ProjectId}/{PlanServerID}/{PlanId}/{VillageCode}/{PrintName}`
  /// Example:
  /// CIMT/Paster/101/55/P101/V09/A1
  /// CIMT/Supervisor/101/55/P101/V09/A1
  static Future<Directory> getPrintFolder({
    String? roleFolder,
    String? projectId,
    String? planServerId,
    String? planId,
    String? villageCode,
    String? printName,
    String? villageName,
    String? printNo,
    String? subfolder,
  }) async {
    final Directory cimtDir = await getPublicCimtDirectory();

    final String safeRole = await resolveRoleFolder(roleFolder ?? subfolder);
    final String safeProject = sanitizePathComponent(
      projectId ?? 'UnknownProject',
    );
    final String safePlanId = sanitizePathComponent(
      (planId != null && planId.trim().isNotEmpty)
          ? planId
          : (planServerId ?? 'UnknownPlanId'),
    );
    final String safeVillage = sanitizePathComponent(
      villageCode ?? villageName ?? 'UnknownVillage',
    );
    final String safePrint = sanitizePathComponent(
      printName ?? printNo ?? 'Print',
    );

    // final String folderPath = '${cimtDir.path}/$safeRole/$safeProject/$safePlanId/$safeVillage/$safePlanServerId/$safePrint';
    final String folderPath =
        '${cimtDir.path}/$safeRole/$safeProject/$safePlanId/$safeVillage/$safePrint';
    final Directory folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  /// Returns the full target file path for a photo slot:
  /// e.g. `/storage/emulated/0/CIMT/Paster/ProjectId/PlanId/VillageCode/PrintName/Image1_09092026142540.jpeg`
  /// or   `/storage/emulated/0/CIMT/Supervisor/ProjectId/PlanId/VillageCode/PrintName/Image1_09092026142540.jpeg`
  static Future<String> getPhotoFilePath({
    String? roleFolder,
    String? projectId,
    String? planServerId,
    String? planId,
    String? villageCode,
    String? printName,
    required int photoNumber,
    String? villageName,
    String? printNo,
    String? subfolder,
  }) async {
    final Directory folder = await getPrintFolder(
      roleFolder: roleFolder,
      projectId: projectId,
      planServerId: planServerId,
      planId: planId,
      villageCode: villageCode,
      printName: printName,
      villageName: villageName,
      printNo: printNo,
      subfolder: subfolder,
    );

    // Clean any prior file for this slot number so retakes don't leave orphaned duplicates
    await cleanPreviousSlotFiles(folder, photoNumber);

    final String timestamp = DateFormat(
      'ddMMyyyyHHmmss',
    ).format(DateTime.now());
    return '${folder.path}/Image${photoNumber}_$timestamp.jpeg';
  }

  /// Cleans any previous photo file for this slot number in the folder
  static Future<void> cleanPreviousSlotFiles(
    Directory folder,
    int photoNumber,
  ) async {
    try {
      if (!await folder.exists()) return;
      final entities = folder.listSync();
      final prefix = 'Image${photoNumber}_';
      final legacyPrefix = 'Photo_$photoNumber.';
      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.uri.pathSegments.last;
          if (fileName.startsWith(prefix) ||
              fileName.startsWith(legacyPrefix)) {
            await cleanFileIfExists(entity.path);
          }
        }
      }
    } catch (_) {}
  }

  /// If photos were captured before printName was entered or changed,
  /// relocates them to the new print folder and returns the new path.
  static Future<String> relocatePhotoIfPrintNameChanged({
    required String currentPath,
    String? roleFolder,
    required String projectId,
    String? planServerId,
    String? planId,
    required String villageCode,
    required String printName,
    required int photoNumber,
    String? subfolder,
  }) async {
    try {
      final File currentFile = File(currentPath);
      if (!await currentFile.exists()) return currentPath;

      final Directory targetFolder = await getPrintFolder(
        roleFolder: roleFolder,
        projectId: projectId,
        planServerId: planServerId,
        planId: planId,
        villageCode: villageCode,
        printName: printName,
        subfolder: subfolder,
      );

      if (currentFile.parent.path == targetFolder.path) {
        return currentPath;
      }

      final fileName = currentFile.uri.pathSegments.last;
      String newFileName = fileName;
      if (!fileName.startsWith('Image$photoNumber') ||
          !fileName.endsWith('.jpeg')) {
        final timestamp = DateFormat('ddMMyyyyHHmmss').format(DateTime.now());
        newFileName = 'Image${photoNumber}_$timestamp.jpeg';
      }

      final String newPath = '${targetFolder.path}/$newFileName';
      await currentFile.copy(newPath);
      await cleanFileIfExists(currentPath);
      return newPath;
    } catch (_) {
      return currentPath;
    }
  }

  /// Safely evicts an image from memory cache and deletes its file if it exists.
  static Future<void> cleanFileIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      await FileImage(file).evict();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
