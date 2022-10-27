package com.cheban.cheban_camera

import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PointF
import android.media.FaceDetector.Face
import android.opengl.Visibility
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import com.google.android.material.tabs.TabLayout
import com.otaliastudios.cameraview.*
import com.otaliastudios.cameraview.controls.Facing
import com.otaliastudios.cameraview.controls.Flash
import com.otaliastudios.cameraview.filter.Filters
import com.otaliastudios.cameraview.markers.DefaultAutoFocusMarker
import java.io.File
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.*


class CameraActivity : AppCompatActivity(), View.OnClickListener, TabLayout.OnTabSelectedListener {

    companion object {
        var result: io.flutter.plugin.common.MethodChannel.Result? = null
        var sourceType: Int = 3
        var faceType: Int = 1
    }

    private lateinit var cameraView: CameraView
    private lateinit var chooseTab: TabLayout
    private lateinit var flashIV: ImageView
    private lateinit var beautyIV: ImageView
    private lateinit var timeTV: TextView
    private lateinit var backIV: ImageView
    private lateinit var switchIV: ImageView
    private lateinit var captureCL: ConstraintLayout
    private lateinit var endV: View
    private lateinit var captureV: View

    //拍照时间
    private var captureTime: Long = 0
    //录像时间
    private var videoTime: Long = 0
    private var timer: Timer? = null

    //当前选择的是拍照还是录像 0.拍照 1.录像
    private var currentChoose = 0;

    //相机风格设置
    private var currentFilter = 0
    private val allFilters = Filters.values()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_camera)
        cameraView = findViewById<CameraView>(R.id.camera)
        chooseTab = findViewById(R.id.tl_choose)
        flashIV = findViewById(R.id.iv_flash)
        beautyIV = findViewById(R.id.iv_beauty)
        timeTV = findViewById(R.id.tv_time)
        backIV = findViewById(R.id.iv_back)
        switchIV = findViewById(R.id.iv_switch)
        captureCL = findViewById(R.id.cl_capture)
        endV = findViewById(R.id.v_end)
        captureV = findViewById(R.id.v_capture)

        if (sourceType == 1) {
            chooseTab.visibility = View.INVISIBLE
            chooseTab.addTab(chooseTab.newTab().setText(R.string.picture))
        } else if (sourceType == 2) {
            currentChoose = 1
            chooseTab.visibility = View.INVISIBLE
            captureV.setBackgroundResource(R.drawable.shape_27_corner_bg_red)
            chooseTab.addTab(chooseTab.newTab().setText(R.string.video))
        } else {
            chooseTab.addTab(chooseTab.newTab().setText(R.string.picture))
            chooseTab.addTab(chooseTab.newTab().setText(R.string.video))
            chooseTab.addOnTabSelectedListener(this)
        }

        if (faceType == 2) {
            cameraView.facing = Facing.FRONT
        }

        cameraView.setAutoFocusMarker(DefaultAutoFocusMarker())

        CameraLogger.setLogLevel(CameraLogger.LEVEL_VERBOSE)
        cameraView.setLifecycleOwner(this)
        cameraView.addCameraListener(Listener())

        flashIV.setOnClickListener(this)
        beautyIV.setOnClickListener(this)
        backIV.setOnClickListener(this)
        switchIV.setOnClickListener(this)
        captureCL.setOnClickListener(this)
    }



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
            PicturePreviewActivity.pictureResult = result
            val intent = Intent(this@CameraActivity, PicturePreviewActivity::class.java)
            intent.putExtra("delay", callbackTime - captureTime)
            startActivityForResult(intent, 300)
            captureTime = 0
        }

        override fun onVideoTaken(result: VideoResult) {
            super.onVideoTaken(result)
            Log.w("CameraException","onVideoTaken called! Launching activity.")
            VideoPreviewActivity.videoResult = result
            val intent = Intent(this@CameraActivity, VideoPreviewActivity::class.java)
            startActivityForResult(intent, 300)
        }

        override fun onVideoRecordingStart() {
            super.onVideoRecordingStart()
            endV.visibility = View.VISIBLE
            captureV.visibility = View.GONE
            timeTV.visibility = View.VISIBLE
            startTimer()
            Log.w("CameraException","onVideoRecordingStart!")
        }

        override fun onVideoRecordingEnd() {
            super.onVideoRecordingEnd()
            endV.visibility = View.GONE
            captureV.visibility = View.VISIBLE
            timeTV.visibility = View.GONE
            stopTimer()
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

    override fun onClick(v: View?) {
        when (v!!.id) {
            R.id.iv_flash -> {
                when (cameraView.flash) {
                    Flash.OFF -> {
                        flashIV.setImageResource(R.mipmap.flash_auto)
                        cameraView.flash = Flash.AUTO
                    }
                    Flash.AUTO -> {
                        flashIV.setImageResource(R.mipmap.flash_on)
                        cameraView.flash = Flash.TORCH
                    }
                    else -> {
                        flashIV.setImageResource(R.mipmap.flash_off)
                        cameraView.flash = Flash.OFF
                    }
                }
            }
            R.id.iv_beauty -> {
                if (currentFilter < allFilters.size - 1) {
                    currentFilter++
                } else {
                    currentFilter = 0
                }
                val filter = allFilters[currentFilter]
                cameraView.filter = filter.newInstance()
            }
            R.id.iv_back -> {
                finish()
            }
            R.id.iv_switch -> {
                if (cameraView.isTakingPicture || cameraView.isTakingVideo) return
                cameraView.toggleFacing()
            }
            R.id.cl_capture -> {
                if (currentChoose == 0) {
                    if (cameraView.isTakingPicture) return
                    captureTime = System.currentTimeMillis()
                    cameraView.takePictureSnapshot()
                } else {
                    if (cameraView.isTakingVideo) {
                        cameraView.stopVideo()
                    } else {
                        cameraView.takeVideoSnapshot(File(filesDir, "video_${System.currentTimeMillis()}.mp4"), 15000)
                    }

                }
            }
        }
    }

    override fun onTabSelected(tab: TabLayout.Tab?) {
        if (cameraView.isTakingPicture || cameraView.isTakingVideo) {
            chooseTab.selectTab(chooseTab.getTabAt(currentChoose))
            return
        }
        currentChoose = chooseTab.selectedTabPosition
        if (currentChoose == 0) {
            captureV.setBackgroundResource(R.drawable.shape_27_corner_bg_white)
        } else {
            captureV.setBackgroundResource(R.drawable.shape_27_corner_bg_red)
        }
    }

    override fun onTabUnselected(tab: TabLayout.Tab?) {

    }

    override fun onTabReselected(tab: TabLayout.Tab?) {

    }

    fun startTimer() {
        videoTime = -1
        timer = Timer()
        timer!!.schedule(object : TimerTask() {
            override fun run() {
                videoTime ++
                runOnUiThread {
                    if (videoTime < 10) {
                        timeTV.text = "00:00:0${videoTime}"
                    } else if (videoTime < 16) {
                        timeTV.text = "00:00:${videoTime}"
                    }
                }


            }
        },  15,1000)

    }

    fun stopTimer() {
        videoTime = -1
        timer?.cancel()
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
        timer?.cancel()
        cameraView.destroy()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 300 && resultCode == 10001 && data != null) {
            if (result != null) {
                val originPath = data.getStringExtra("origin_file_path")
                val thumbnailPath = data.getStringExtra("thumbnail_file_path")
                val dict: MutableMap<String, Any> = mutableMapOf<String, Any>(
                    "width" to data.getIntExtra("width", 0),
                    "height" to data.getIntExtra("height", 0),
                    "type" to data.getIntExtra("type", 0),
                )
                if (originPath != null) {
                    dict["origin_file_path"] = originPath
                }
                if (thumbnailPath != null) {
                    dict["thumbnail_file_path"] = thumbnailPath
                }
                result!!.success(dict)
                finish()
            }
        }
    }
}