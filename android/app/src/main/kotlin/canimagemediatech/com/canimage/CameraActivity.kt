package com.canimagemediatech.canimage

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File

class CameraActivity : Activity() {

    private val CAMERA_REQUEST_CODE = 101
    private var photoFile: File? = null
    private val TAG = "CameraActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate called")

        if (savedInstanceState == null) {
            Log.d(TAG, "First time creation - opening camera")
            openCamera()
        } else {
            Log.d(TAG, "Restored from saved state")
            val filePath = savedInstanceState.getString("photo_file_path")
            if (filePath != null) {
                photoFile = File(filePath)
                Log.d(TAG, "Restored file path: $filePath")
            }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        photoFile?.let {
            outState.putString("photo_file_path", it.absolutePath)
            Log.d(TAG, "Saved file path to bundle: ${it.absolutePath}")
        }
    }

    private fun openCamera() {
        Log.d(TAG, "openCamera() called")

        val filePath = intent.getStringExtra("filePath")
        Log.d(TAG, "Received file path: $filePath")

        if (filePath.isNullOrEmpty()) {
            Log.e(TAG, "File path is null or empty")
            setResult(RESULT_CANCELED)
            finish()
            return
        }

        try {
            val file = File(filePath)
            photoFile = file

            Log.d(TAG, "Creating directories for: ${file.parentFile?.absolutePath}")
            val dirsCreated = file.parentFile?.mkdirs() ?: false
            Log.d(TAG, "Directories created: $dirsCreated")

            val photoURI: Uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )
            Log.d(TAG, "Generated photo URI: $photoURI")

            val takePictureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
            takePictureIntent.flags = Intent.FLAG_GRANT_WRITE_URI_PERMISSION

            val cameraApps = takePictureIntent.resolveActivity(packageManager)
            Log.d(TAG, "Available camera apps: $cameraApps")

            if (cameraApps != null) {
                Log.d(TAG, "Starting camera activity")
                startActivityForResult(takePictureIntent, CAMERA_REQUEST_CODE)
            } else {
                Log.e(TAG, "No camera app available")
                setResult(RESULT_CANCELED)
                finish()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in openCamera: ${e.message}", e)
            setResult(RESULT_CANCELED)
            finish()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        Log.d(TAG, "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")

        when (requestCode) {
            CAMERA_REQUEST_CODE -> {
                Log.d(TAG, "Camera result received")

                // Check if file was created
                photoFile?.let { file ->
                    val exists = file.exists()
                    val size = if (exists) file.length() else 0
                    Log.d(TAG, "Photo file exists: $exists, size: $size bytes")
                }

                setResult(resultCode)
                Log.d(TAG, "Setting result and finishing")
                finish()
            }
            else -> {
                Log.w(TAG, "Unexpected request code: $requestCode")
                setResult(RESULT_CANCELED)
                finish()
            }
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy called")
        super.onDestroy()
    }
}