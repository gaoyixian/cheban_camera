package com.cheban.cheban_camera

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Color
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.util.Log
import android.util.TypedValue
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.animation.AlphaAnimation
import android.view.animation.Animation
import android.view.animation.Animation.AnimationListener
import android.widget.ImageView
import android.widget.RelativeLayout
import android.widget.RelativeLayout.LayoutParams
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.*
import androidx.camera.core.ImageCapture.*
import androidx.camera.video.*
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.core.view.drawToBitmap
import com.google.android.material.progressindicator.CircularProgressIndicator
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.*
import java.util.*


class CameraActivity : ComponentActivity() {

    companion object {
        var result: MethodChannel.Result? = null
        var sourceType: Int = 3
        var faceType: Int = 1
        var appType: Int = 0
        @JvmStatic
        var cameraActivity: CameraActivity? = null
    }

    private inner class RecordTimer: CountDownTimer(30400, 1000) {

        @RequiresApi(Build.VERSION_CODES.N)
        override fun onTick(p0: Long) {
            runOnUiThread {
                if (countdownTimer <= 30) {
                    if (countdownTimer < 10) {
                        mTimeTextView.text = "00:0${countdownTimer}"
                    } else {
                        mTimeTextView.text = "00:${countdownTimer}"
                    }
                    mProgressCircular.setProgress((countdownTimer / 30f * 100).toInt(), true)
                }
                countdownTimer++
            }
        }

        @RequiresApi(Build.VERSION_CODES.N)
        override fun onFinish() {
            mTimeTextView.text = "00:30"
            mProgressCircular.setProgress((100).toInt(), true)
            mCameraManager.closeVideoRecord()
            countdownTimer = 0
        }
    }

    private val animationDurationMillis: Long = 300

    private lateinit var mFlashImageView: ImageView
    private lateinit var mTimeTextView: TextView
    private lateinit var mBackImageView: ImageView
    private lateinit var mSwitchImageView: ImageView
    private lateinit var mCaptureButton: RelativeLayout
    private lateinit var mCaptureView: View
    private lateinit var mTipTextView: TextView
    private lateinit var mProgressCircular: CircularProgressIndicator
    private lateinit var mFlashSelectionBar: FlashSelectionBar
    private lateinit var mRecordImageView: ImageView
    private lateinit var mBackdropView: View
    private lateinit var mFocusImageView: ImageView
    private lateinit var mScreenshotRelativeLayout: RelativeLayout
    private lateinit var mScreenshotImageView: ImageView

    private var countdownTimer: Int = 0

    /// 相机预览视图
    private lateinit var mPreviewView: PreviewView

    private lateinit var mCameraManager: CameraManager

    private val recordTimer: RecordTimer = RecordTimer()

    private var callResult: Boolean = false

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_camera)
        cameraActivity = this
        mPreviewView = findViewById(R.id.view_finder)
        mBackdropView = findViewById(R.id.backdrop)
        mFlashImageView = findViewById(R.id.iv_flash)
        mTimeTextView = findViewById(R.id.tv_time)
        mBackImageView = findViewById(R.id.iv_back)
        mSwitchImageView = findViewById(R.id.iv_switch)
        mCaptureButton = findViewById(R.id.cl_capture)
        mCaptureView = findViewById(R.id.v_capture)
        mTipTextView = findViewById(R.id.tv_tip)
        mProgressCircular = findViewById(R.id.progress_circular)
        mRecordImageView = findViewById(R.id.iv_recording)
        mFlashSelectionBar = findViewById(R.id.view_flash_modes)
        mFocusImageView = findViewById(R.id.focus)
        mScreenshotRelativeLayout = findViewById(R.id.rl_screenshot)
        mScreenshotImageView = findViewById(R.id.iv_screenshot)
        mPreviewView.scaleType = PreviewView.ScaleType.FIT_CENTER
        mPreviewView.implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        if (appType == 1) {
            mProgressCircular.setIndicatorColor(Color.parseColor("#20BC9A"))
        }

        mFlashSelectionBar.setListener(object : OnFlashSelectionListener {
            override fun callback(value: Int) {
                when (value) {
                    0 -> {
                        mFlashImageView.setImageDrawable(applicationContext.resources.getDrawable(R.mipmap.flash_off))
                        mCameraManager.flashMode = CameraFlashMode.OFF
                    }
                    1 -> {
                        mFlashImageView.setImageDrawable(applicationContext.resources.getDrawable(R.mipmap.flash_auto))
                        mCameraManager.flashMode = CameraFlashMode.AUTO
                    }
                    2 -> {
                        mFlashImageView.setImageDrawable(applicationContext.resources.getDrawable(R.mipmap.flash_on))
                        mCameraManager.flashMode = CameraFlashMode.OPEN
                    }
                    3 -> {
                        updateFlashSelectionBarVisibility()
                    }
                }
                mFlashSelectionBar.visibility = View.INVISIBLE
                mFlashImageView.visibility = View.VISIBLE
            }
        })

        mBackdropView.setOnTouchListener { _, p1 ->
            mCameraManager.focus(p1.x, p1.y, true)
            /// 布局是用relativeLayout
            val layoutParams = mFocusImageView.layoutParams as RelativeLayout.LayoutParams
            layoutParams.leftMargin = (p1.x - TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 30f, resources.displayMetrics)).toInt()
            layoutParams.topMargin = (p1.y - TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 30f, resources.displayMetrics)).toInt()
            mFocusImageView.layoutParams = layoutParams
            val alphaOutAnim = AlphaAnimation(0f, 1f)
            val alphaInAnim = AlphaAnimation(1f, 0f)
            alphaOutAnim.duration = animationDurationMillis
            alphaInAnim.duration = animationDurationMillis
            alphaOutAnim.setAnimationListener(object : AnimationListener {
                override fun onAnimationStart(p0: Animation?) {
                    mFocusImageView.visibility = View.VISIBLE
                    mFocusImageView.animate().scaleX(1.2f)
                    mFocusImageView.animate().scaleY(1.2f)
                }

                override fun onAnimationRepeat(p0: Animation?) {

                }

                override fun onAnimationEnd(p0: Animation?) {
                    mFocusImageView.startAnimation(alphaInAnim)
                }
            })
            alphaInAnim.setAnimationListener(object : AnimationListener {
                override fun onAnimationStart(p0: Animation?) {
                    mFocusImageView.animate().scaleX(1f)
                    mFocusImageView.animate().scaleY(1f)
                }

                override fun onAnimationRepeat(p0: Animation?) {

                }

                override fun onAnimationEnd(p0: Animation?) {
                    mFocusImageView.visibility = View.GONE
                }
            })
            mFocusImageView.startAnimation(alphaOutAnim)
            false
        }

        mCameraManager = CameraManager(this, mPreviewView)

        /// 模式设置
        if (sourceType == 1) {
            mProgressCircular.trackColor = Color.WHITE
            mTipTextView.text = "点击拍照"
            mCameraManager.captureMode = CameraCaptureMode.PICTURE
        } else {
            mCameraManager.captureMode = CameraCaptureMode.ALL
        }

        mCameraManager.setRecordListener(object : OnRecordListener {
            override fun start(event: VideoRecordEvent) {
                recordingVideoStart()
            }

            override fun stop(event: VideoRecordEvent) {
                recodingVideoEnd()
            }

            override fun takeVideo(result: Map<String, Any>) {
                if (!callResult) {
                    callResult = true
                    CameraActivity.result?.success(result)
                }
                CoroutineScope(Dispatchers.IO).launch {
                    delay(250)
                    runOnUiThread {
                        finish()
                    }
                }
            }
        })
        mCameraManager.setCaptureListener(object : OnCaptureListener {
            override fun takePhoto(result: Map<String, Any>) {
                if (!callResult) {
                    callResult = true
                    CameraActivity.result?.success(result)
                }
                CoroutineScope(Dispatchers.IO).launch {
                    delay(250)
                    runOnUiThread {
                        finish()
                    }
                }
            }
        })

        /// 配置视图的
        mFlashImageView.setOnClickListener { updateFlashSelectionBarVisibility() }
        mBackImageView.setOnClickListener {
            if (!mCameraManager.lock) {
                finish()
            }
        }
        mSwitchImageView.setOnClickListener {
            mScreenshotRelativeLayout.visibility = View.VISIBLE
            if (mPreviewView.bitmap == null) {
                println("bitmap is null")
            }
            mScreenshotImageView.setImageBitmap(mPreviewView.bitmap)
            CoroutineScope(Dispatchers.IO).launch {
                mCameraManager.flashMode = CameraFlashMode.OFF
                mFlashImageView.setImageDrawable(applicationContext.resources.getDrawable(R.mipmap.flash_off))
                mCameraManager.switchFacing()
                CoroutineScope(Dispatchers.IO).launch {
                    delay(800)
                    runOnUiThread {
                        mScreenshotRelativeLayout.visibility = View.INVISIBLE
                    }
                }
            }
        }
        mCaptureButton.setOnClickListener {
            mCameraManager.capturePicture()
        }
        mCaptureButton.setOnLongClickListener {
            mCameraManager.startVideoRecord()
            true
        }
        mCaptureButton.setOnTouchListener { p0, p1 ->
            when (p1?.action) {
                MotionEvent.ACTION_UP -> {
                    /// 手势抬起时 就调用一起关闭录制，能关闭的话
                    mCameraManager.closeVideoRecord()
                    recordTimer.cancel()
                }
            }
        false
    }

    /// UI后续的业务判断的
    if (ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_DENIED) {
            mRecordImageView.visibility = View.VISIBLE
        }

        mCameraManager.facing = when (faceType) {
            2 -> {
                CameraFacing.FRONT
            }
            else -> {
                CameraFacing.BACK
            }
        }
        mCameraManager.bindCameraUseCases()
        /// 延迟处理的
        CoroutineScope(Dispatchers.IO).launch {
            delay(5000)
            runOnUiThread {
                if (mTimeTextView.visibility == View.INVISIBLE) {
                    val alphaAnim = AlphaAnimation(1f, 0f)
                    alphaAnim.duration = animationDurationMillis
                    alphaAnim.setAnimationListener(object : AnimationListener {
                        override fun onAnimationEnd(p0: Animation?) {
                            mTipTextView.visibility = View.GONE
                        }

                        override fun onAnimationRepeat(p0: Animation?) {
                        }

                        override fun onAnimationStart(p0: Animation?) {
                        }
                    })
                    mTipTextView.startAnimation(alphaAnim)
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onStart() {
        super.onStart()
        mCameraManager.orientationEventListener.enable()
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onStop() {
        super.onStop()
        mCameraManager.orientationEventListener.disable()
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onDestroy() {
        super.onDestroy()
        Log.d("CameraActivity", "Destory")
        mCameraManager.destroy()
        cameraActivity = null
        result = null
        recordTimer.cancel()
    }

    private fun recordingVideoStart() {
        recordTimer.start()
        runOnUiThread {
            val layoutParams = mCaptureView.layoutParams
            layoutParams.width = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 24f, resources.displayMetrics).toInt()
            layoutParams.height = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 24f, resources.displayMetrics).toInt()
            mCaptureView.layoutParams = layoutParams
            mTimeTextView.visibility = View.VISIBLE
            mTipTextView.visibility = View.GONE
            mProgressCircular.progress = 0
        }
    }

    private fun recodingVideoEnd() {
        recordTimer.cancel()
        countdownTimer = 0
        runOnUiThread {
            val layoutParams = mCaptureView.layoutParams
            layoutParams.width = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 60f, resources.displayMetrics).toInt()
            layoutParams.height = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 60f, resources.displayMetrics).toInt()
            mCaptureView.layoutParams = layoutParams
            mTimeTextView.visibility = View.INVISIBLE
            mTimeTextView.text = "00:00"
            mProgressCircular.progress = 0
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun updateFlashSelectionBarVisibility() {
        if (mCameraManager.lock) {
            return
        }
        when (mFlashSelectionBar.visibility) {
            View.INVISIBLE -> {
                val alphaAnim = AlphaAnimation(0f, 1f)
                alphaAnim.duration = animationDurationMillis
                alphaAnim.setAnimationListener(object : AnimationListener{
                    override fun onAnimationStart(p0: Animation?) {
                    }

                    override fun onAnimationRepeat(p0: Animation?) {
                    }

                    override fun onAnimationEnd(p0: Animation?) {
                        mFlashSelectionBar.visibility = View.VISIBLE
                        mFlashImageView.visibility = View.INVISIBLE
                    }
                })
                mFlashSelectionBar.startAnimation(alphaAnim)
            }
            View.VISIBLE -> {
                val alphaAnim = AlphaAnimation(1f, 0f)
                alphaAnim.duration = animationDurationMillis
                alphaAnim.setAnimationListener(object : AnimationListener{
                    override fun onAnimationStart(p0: Animation?) {
                        mFlashImageView.visibility = View.VISIBLE
                    }

                    override fun onAnimationRepeat(p0: Animation?) {
                    }

                    override fun onAnimationEnd(p0: Animation?) {
                        mFlashSelectionBar.visibility = View.INVISIBLE
                    }
                })
                mFlashSelectionBar.startAnimation(alphaAnim)
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun finish() {
        super.finish()
        overridePendingTransition(0,0)
        /// 手势返回需要判断下是否有callback
        if (!callResult) {
            callResult = true
            result?.success(null)
        }
        mCameraManager.destroy()
    }

}