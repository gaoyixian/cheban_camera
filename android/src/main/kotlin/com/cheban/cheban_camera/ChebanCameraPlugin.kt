package com.cheban.cheban_camera

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
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

  @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "takePhotoAndVideo") {
      CameraActivity.result = result
      val dict: Map<*, *> = call.arguments as Map<*, *>
      CameraActivity.sourceType =  (dict["source_type"] as Int)
      CameraActivity.faceType = (dict["face_type"] as Int)
      CameraActivity.channel = channel
      val intent = Intent(context, CameraActivity::class.java)
      context!!.startActivity(intent)
    } else if (call.method == "destory") {
//      val activityManager = context!!.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
//      var list = activityManager.getRunningTasks(1)
//      if (list != null && list.size > 0) {
//
//        val componentName = list[0].topActivity
//        componentName?.className.let {
//          if (it.equals("CameraActivity")) {
//            只获取到了Name，没有获取到activity
//          }
//        }
//      }
      if (CameraActivity.cameraActivity != null) {
        CameraActivity.cameraActivity!!.finish()
      }
    } else {
      result.notImplemented()
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
