package com.cheban.cheban_camera

import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PointF
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.os.Environment
import android.provider.MediaStore
import android.text.TextUtils
import android.util.Log
import android.util.TypedValue
import android.view.MotionEvent
import android.view.View
import android.view.animation.AlphaAnimation
import android.view.animation.Animation
import android.view.animation.Animation.AnimationListener
import android.view.animation.ScaleAnimation
import android.webkit.MimeTypeMap
import android.widget.ImageView
import android.widget.RelativeLayout
import android.widget.TextView
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.progressindicator.CircularProgressIndicator
import com.google.android.material.tabs.TabLayout
import com.otaliastudios.cameraview.*
import com.otaliastudios.cameraview.controls.Facing
import com.otaliastudios.cameraview.controls.Flash
import com.otaliastudios.cameraview.filter.Filters
import com.otaliastudios.cameraview.markers.DefaultAutoFocusMarker
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.util.*


class CameraActivity : AppCompatActivity(), View.OnClickListener, View.OnLongClickListener, View.OnTouchListener, AnimationListener, SelectFlashModeHandler {

    companion object {
        var result: io.flutter.plugin.common.MethodChannel.Result? = null
        var sourceType: Int = 3
        var faceType: Int = 1
    }

    private lateinit var cameraView: CameraView
    private lateinit var flashIV: ImageView
    private lateinit var timeTV: TextView
    private lateinit var backIV: ImageView
    private lateinit var switchIV: ImageView
    private lateinit var captureCL: RelativeLayout
    private lateinit var captureV: View
    private lateinit var tipTV: TextView
    private lateinit var progressCircular: CircularProgressIndicator
    private lateinit var flashModesView: FlashModesView

    //拍照时间
    private var captureTime: Long = 0
    private var isTapped = false

    private val alphaAnimation = AlphaAnimation(1f, 0f)

    private val recordTimer: RecordTimer = RecordTimer()

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_camera)
        cameraView = findViewById<CameraView>(R.id.camera)
        flashIV = findViewById(R.id.iv_flash)
        timeTV = findViewById(R.id.tv_time)
        backIV = findViewById(R.id.iv_back)
        switchIV = findViewById(R.id.iv_switch)
        captureCL = findViewById(R.id.cl_capture)
        captureV = findViewById(R.id.v_capture)
        tipTV = findViewById(R.id.tv_tip)
        flashModesView = findViewById(R.id.view_flash_modes)
        flashModesView.handler = this
        progressCircular = findViewById(R.id.progress_circular)
//        progressCircular.trackThickness = TypedValue.applyDimension(
//            TypedValue.COMPLEX_UNIT_DIP,
//            6f,
//            applicationContext.resources.displayMetrics
//        ).toInt()
//        progressCircular.trackCornerRadius = TypedValue.applyDimension(
//            TypedValue.COMPLEX_UNIT_DIP,
//            8f,
//            applicationContext.resources.displayMetrics
//        ).toInt()
        alphaAnimation.duration = 800
        alphaAnimation.setAnimationListener(this)
        GlobalScope.launch {
            delay(5000)
            runOnUiThread {
                tipTV.startAnimation(alphaAnimation)
            }
        }

        if (faceType == 2) {
            cameraView.facing = Facing.FRONT
        }

        if (sourceType == 1) {
            progressCircular.trackColor = Color.WHITE
            tipTV.text = "轻点拍照"
        }

        cameraView.setAutoFocusMarker(DefaultAutoFocusMarker())

        CameraLogger.setLogLevel(CameraLogger.LEVEL_VERBOSE)
        cameraView.setLifecycleOwner(this)
        cameraView.addCameraListener(Listener())

        flashIV.setOnClickListener(this)
        backIV.setOnClickListener(this)
        switchIV.setOnClickListener(this)
        captureCL.setOnClickListener(this)
        captureCL.setOnLongClickListener(this)
        captureCL.setOnTouchListener(this)
    }

    override fun onResume() {
        super.onResume()
        cameraView.open()
    }

    override fun onPause() {
        super.onPause()

        cameraView.close()
    }

    override fun onDestroy() {
        super.onDestroy()
        recordTimer.cancel()
        cameraView.destroy()
    }

    /// Camera监听类
    private inner class Listener : CameraListener() {
        override fun onCameraOpened(options: CameraOptions) {
            Log.w("CameraException", options.toString())
        }

        override fun onCameraError(exception: CameraException) {
            super.onCameraError(exception)
            Log.w("CameraException", "Got CameraException #" + exception.reason)
        }

        override fun onPictureTaken(result: PictureResult) {
            super.onPictureTaken(result)
            if (cameraView.isTakingVideo) {
                Log.w("CameraException", "Captured while taking video. Size=" + result.size)
                return
            }
            // This can happen if picture was taken with a gesture.
            val callbackTime = System.currentTimeMillis()
            if (captureTime == 0L) captureTime = callbackTime - 300
            Log.w("CameraException", "onPictureTaken called! Launching activity. Delay: ${callbackTime - captureTime}")

            takePicture(result)
//            PicturePreviewActivity.pictureResult = result
//            val intent = Intent(this@CameraActivity, PicturePreviewActivity::class.java)
//            intent.putExtra("delay", callbackTime - captureTime)
//            startActivityForResult(intent, 300)
            captureTime = 0
        }

        override fun onVideoTaken(result: VideoResult) {
            super.onVideoTaken(result)
            Log.w("CameraException","onVideoTaken called! Launching activity.")
            takeVideo(result)
//            VideoPreviewActivity.videoResult = result
//            val intent = Intent(this@CameraActivity, VideoPreviewActivity::class.java)
//            startActivityForResult(intent, 300)
        }

        override fun onVideoRecordingStart() {
            super.onVideoRecordingStart()
            videoDidStartRecording()
            Log.w("CameraException","onVideoRecordingStart!")
        }

        override fun onVideoRecordingEnd() {
            super.onVideoRecordingEnd()
            videoDidStopRecording()
            Log.w("CameraException","onVideoRecordingEnd!")
        }

        override fun onExposureCorrectionChanged(newValue: Float, bounds: FloatArray, fingers: Array<PointF>?) {
            super.onExposureCorrectionChanged(newValue, bounds, fingers)
            Log.w("CameraException","Exposure correction:$newValue")
        }

        override fun onZoomChanged(newValue: Float, bounds: FloatArray, fingers: Array<PointF>?) {
            super.onZoomChanged(newValue, bounds, fingers)
            Log.w("CameraException","Zoom:$newValue")
        }
    }

    private inner class RecordTimer: CountDownTimer(20000, 1000) {

        @RequiresApi(Build.VERSION_CODES.N)
        override fun onTick(p0: Long) {
            val value = 20 - (p0 / 1000)
            Log.w("RecordTimer", "计时器运行中 ------- $value")
            runOnUiThread {
                if (value >= 0) {
                    if (value < 10) {
                        timeTV.text = "00:0${value}"
                    } else {
                        timeTV.text = "00:${value}"
                    }
                    progressCircular.setProgress((value / 20f * 100).toInt(), true)
                }
            }
        }

        @RequiresApi(Build.VERSION_CODES.N)
        override fun onFinish() {
            timeTV.text = "00:20"
            progressCircular.setProgress((100).toInt(), true)
        }

    }

    fun takePicture(picture: PictureResult) {
        val destFile = File(filesDir, "picture_${System.currentTimeMillis()}.jpg")
        CameraUtils.writeToFile(requireNotNull(picture.data), destFile) { file ->
            if (file != null) {
                val originPath = file.path
                val thumbnailPath = ""
                val dict: MutableMap<String, Any> = mutableMapOf<String, Any>(
                    "width" to picture.size.width,
                    "height" to picture.size.height,
                    "type" to 1,
                    "duration" to 0,
                )
                if (originPath != null) {
                    dict["origin_file_path"] = originPath
                }
                if (thumbnailPath != null) {
                    dict["thumbnail_file_path"] = thumbnailPath
                }
                result!!.success(dict)
                finish()
            } else {
                Toast.makeText(this@CameraActivity, "拍照失败，请重试", Toast.LENGTH_SHORT).show()
            }
        }
    }

    fun takeVideo(video: VideoResult) {
        saveFileToGallery(video.file.path, null)
        //saveVideoToSystemAlbum(videoResult!!.file.path)
        val mMMR = MediaMetadataRetriever()
        mMMR.setDataSource(this, Uri.fromFile(video.file))
        val mDuration = mMMR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toInt()?.div(1000)
        val bmp = mMMR.frameAtTime
        if (bmp != null) {
            val byteArrayOutputStream = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.JPEG, 10, byteArrayOutputStream)
            val cupBytes: ByteArray = byteArrayOutputStream.toByteArray()
            val destFile = File(filesDir, "cover_${System.currentTimeMillis()}.jpg")
            CameraUtils.writeToFile(cupBytes, destFile) { file ->
                if (file != null) {
                    val originPath = video.file.path
                    val thumbnailPath = file.path
                    val dict: MutableMap<String, Any> = mutableMapOf<String, Any>(
                        "width" to video.size.width,
                        "height" to video.size.height,
                        "type" to 2,
                        "duration" to mDuration.let { 0 },
                    )
                    if (originPath != null) {
                        dict["origin_file_path"] = originPath
                    }
                    if (thumbnailPath != null) {
                        dict["thumbnail_file_path"] = thumbnailPath
                    }
                    result!!.success(dict)
                    finish()
                } else {
                    Toast.makeText(this, "录像失败，请重试", Toast.LENGTH_SHORT).show()
                }
            }
        } else {
            Toast.makeText(this, "录像失败，请重试", Toast.LENGTH_SHORT).show()
        }
    }

    private fun saveFileToGallery(filePath: String, name: String?): Boolean {
        val context = applicationContext
        return try {
            val originalFile = File(filePath)
            val fileUri = generateUri(originalFile.extension, name)

            val outputStream = context?.contentResolver?.openOutputStream(fileUri)!!
            val fileInputStream = FileInputStream(originalFile)

            val buffer = ByteArray(10240)
            var count = 0
            while (fileInputStream.read(buffer).also { count = it } > 0) {
                outputStream.write(buffer, 0, count)
            }

            outputStream.flush()
            outputStream.close()
            fileInputStream.close()

            context!!.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, fileUri))
            true
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }

    private fun generateUri(extension: String = "", name: String? = null): Uri {
        var fileName = name ?: System.currentTimeMillis().toString()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

            val values = ContentValues()
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
            val mimeType = getMIMEType(extension)
            if (!TextUtils.isEmpty(mimeType)) {
                values.put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                if (mimeType!!.startsWith("video")) {
                    uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_MOVIES)
                }
            }
            return applicationContext?.contentResolver?.insert(uri, values)!!
        } else {
            val storePath = Environment.getExternalStorageDirectory().absolutePath + File.separator + Environment.DIRECTORY_PICTURES
            val appDir = File(storePath)
            if (!appDir.exists()) {
                appDir.mkdir()
            }
            if (extension.isNotEmpty()) {
                fileName += (".$extension")
            }
            return Uri.fromFile(File(appDir, fileName))
        }
    }

    private fun getMIMEType(extension: String): String? {
        var type: String? = null;
        if (!TextUtils.isEmpty(extension)) {
            type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.toLowerCase())
        }
        return type
    }

    /// 开始录制
    private fun startRecord() {
        if (!cameraView.isTakingVideo) {
            cameraView.takeVideoSnapshot(File(filesDir, "video_${System.currentTimeMillis()}.mp4"), 20000)
        }
    }

    /// 停止录制
    private fun stopRecord() {
        if (cameraView.isTakingVideo) {
            // 应该去执行结束录制了
            cameraView.stopVideo()
        }
    }

    /// 已经开始录制
    private fun videoDidStartRecording() {
        updateCapatureSize(24f)
        recordTimer.start()
        runOnUiThread {
            timeTV.visibility = View.VISIBLE
            tipTV.visibility = View.INVISIBLE
            alphaAnimation.cancel()
            progressCircular.progress = 0
        }
    }

    /// 已经停止录制
    private fun videoDidStopRecording() {
        updateCapatureSize(60f)
        recordTimer.cancel()
        runOnUiThread {
            timeTV.visibility = View.INVISIBLE
            timeTV.text = "00:00"
            progressCircular.progress = 0
        }
    }

    /// 更新录制按钮的大小
    private fun updateCapatureSize(value: Float) {
        runOnUiThread {
            val layoutParams = captureV.layoutParams
            layoutParams.width = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, applicationContext.resources.displayMetrics).toInt()
            layoutParams.height = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, applicationContext.resources.displayMetrics).toInt()
            captureV.layoutParams = layoutParams
        }
    }


    ///////////////////////////////////// ----------  代理  --------------- ///////////////////////////////////

    /// 点击事件代理
    override fun onClick(v: View?) {
        when (v!!.id) {
            R.id.iv_flash -> {
                when (flashModesView.visibility) {
                    View.INVISIBLE -> {
                        flashModesView.visibility = View.VISIBLE
                        flashIV.visibility = View.INVISIBLE
                    }
                    View.VISIBLE -> {
                        flashModesView.visibility = View.INVISIBLE
                        flashIV.visibility = View.VISIBLE
                    }
                }
            }
            R.id.iv_back -> {
                cameraView.destroy()
                finish()
            }
            R.id.iv_switch -> {
                if (cameraView.isTakingPicture || cameraView.isTakingVideo) return
                cameraView.toggleFacing()
            }
            R.id.cl_capture -> {
                if (cameraView.isTakingPicture) return
                captureTime = System.currentTimeMillis()
                cameraView.takePictureSnapshot()
            }
        }
    }

    /// 长按事件代理
    override fun onLongClick(p0: View?): Boolean {
        if (sourceType == 1) {
            return false
        }
        startRecord()
        return true
    }

    /// 触碰事件获取代理
    override fun onTouch(p0: View?, p1: MotionEvent?): Boolean {
        when (p1?.action) {
            MotionEvent.ACTION_UP -> {
                if (!isTapped) {
                    stopRecord()
                }
            }
        }
        return false
    }


    /// 动画代理

    override fun onAnimationStart(p0: Animation?) {

    }

    override fun onAnimationEnd(p0: Animation?) {
        tipTV.visibility = View.INVISIBLE
    }

    override fun onAnimationRepeat(p0: Animation?) {

    }

    override fun invoked(value: Int) {
        when (value) {
            0 -> {
                flashIV.setImageDrawable(applicationContext.resources.getDrawable(R.mipmap.flash_off))
                cameraView.flash = Flash.OFF
            }
            1 -> {
                flashIV.setImageDrawable(applicationContext.resources.getDrawable(R.mipmap.flash_auto))
                cameraView.flash = Flash.AUTO
            }
            2 -> {
                flashIV.setImageDrawable(applicationContext.resources.getDrawable(R.mipmap.flash_on))
                cameraView.flash = Flash.TORCH
            }
            3 -> {
            }
        }
        flashModesView.visibility = View.INVISIBLE
        flashIV.visibility = View.VISIBLE
    }
}