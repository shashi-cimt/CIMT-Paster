package canimagemediatech.com.canimage

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.annotation.NonNull
import java.io.File
import java.io.IOException
import android.Manifest
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private val CAMERA_CHANNEL = "com.canimagemediatech.camera_channel"
    private val CHANNEL_POLICIES = "com.canimage/device_policies"
    private val CAMERA_REQUEST_CODE = 102
    private val PERMISSION_REQUEST_CODE = 103
    private val TAG = "MainActivity"
    private val CHANNEL = "auto_rotate_checker"

    private var currentCameraResult: MethodChannel.Result? = null
    private var currentPhotoFile: File? = null
    private var pendingFilePath: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Device policies channel (unchanged)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_POLICIES)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDeveloperModeEnabled" -> {
                        try {
                            val dev = Settings.Global.getInt(
                                contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
                            ) == 1
                            val adb = Settings.Global.getInt(
                                contentResolver, Settings.Global.ADB_ENABLED, 0
                            ) == 1
                            result.success(dev || adb)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error checking developer mode", e)
                            result.success(false)
                        }
                    }

                    "isMockLocationAllowed" -> {
                        try {
                            val mockAllowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                Settings.Secure.getString(
                                    contentResolver, "mock_location"
                                ) != "0"
                            } else {
                                Settings.Secure.getString(
                                    contentResolver, Settings.Secure.ALLOW_MOCK_LOCATION
                                ) != "0"
                            }
                            result.success(mockAllowed)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error checking mock location", e)
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAutoRotateEnabled" -> {
                    val autoRotateEnabled = isAutoRotateEnabled()
                    result.success(autoRotateEnabled)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAutoRotateEnabled(): Boolean {
        return try {
            val rotationSetting = Settings.System.getInt(
                contentResolver,
                Settings.System.ACCELEROMETER_ROTATION,
                0
            )
            rotationSetting == 1
        } catch (e: Exception) {
            // Default to enabled if we can't check
            true
        }
    }
}