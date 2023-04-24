package com.cheban.cheban_camera

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** ChebanCameraPlugin */
class ChebanCameraPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private var context: Context? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "cheban_camera")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "takePhotoAndVideo") {
      CameraActivity.result = result
      val dict: Map<*, *> = call.arguments as Map<*, *>
      CameraActivity.sourceType =  (dict["source_type"] as Int)
      CameraActivity.faceType = (dict["face_type"] as Int)
      val intent = Intent(context, CameraActivity::class.java)
      context!!.startActivity(intent)
    } else if (call.method == "destory") {
      if (context != null) {
        val activity = findActivity(context!!)
        if (activity != null) {
          activity.finish()
        } else {
          Toast.makeText(context, "未发现相机", Toast.LENGTH_SHORT).show()
        }
      } else {
      }
    } else {
      result.notImplemented()
    }
  }

  private fun findActivity(context: Context): Activity? {
    return when (context) {
        is Activity -> {
          context
        }
      is ContextWrapper -> {
        findActivity((context).baseContext)
      }
      else -> {
        null
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    context = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {

  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

  }

  override fun onDetachedFromActivity() {

  }


}
