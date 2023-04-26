package com.cheban.cheban_camera

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.util.Log
import android.util.Size
import android.view.OrientationEventListener
import android.view.Surface
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.*
import androidx.camera.core.AspectRatio.RATIO_16_9
import androidx.camera.core.AspectRatio.RATIO_4_3
import androidx.camera.core.FocusMeteringAction.FLAG_AF
import androidx.camera.core.ImageCapture.*
import androidx.camera.core.impl.PreviewConfig
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.*
import androidx.camera.video.VideoCapture
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.core.net.toFile
import java.io.*
import java.util.concurrent.TimeUnit

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class CameraManager(context: AppCompatActivity, previewView: PreviewView) {

    private var context: AppCompatActivity
    private var previewView: PreviewView

    private var mImageCapture: ImageCapture? = null
    private var mVideoCapture: VideoCapture<Recorder>? = null
    /// 录制
    private var mRecording: Recording? = null
    /// 相机
    private var camera: Camera? = null

    /// 监听回调
    private var mOnCameraEventListener: OnCameraEventListener? = null

    val orientationEventListener by lazy {
        object : OrientationEventListener(context) {
            override fun onOrientationChanged(orientation: Int) {
                if (orientation == ORIENTATION_UNKNOWN) {
                    return
                }

                val rotation = when (orientation) {
                    in 45 until 135 -> Surface.ROTATION_270
                    in 135 until 225 -> Surface.ROTATION_180
                    in 225 until 315 -> Surface.ROTATION_90
                    else -> Surface.ROTATION_0
                }

                mImageCapture?.targetRotation = rotation
            }
        }
    }

    /// 摄像头方向
    var facing: CameraFacing = CameraFacing.BACK
        set(value) {
            field = value
            bindCameraUseCases()
        }

    /// 捕捉模式 --- 只是切换绑定的useCases
    var captureMode: CameraCaptureMode = CameraCaptureMode.ALL
        set(value) {
            field = value
            bindCameraUseCases()
        }

    var flashMode: CameraFlashMode = CameraFlashMode.OFF
        set(value) {
            field = value
            if (mImageCapture != null) {
                when (field) {
                    CameraFlashMode.OFF -> {
                        mImageCapture?.flashMode = FLASH_MODE_OFF
                    }
                    CameraFlashMode.AUTO -> {
                        mImageCapture?.flashMode = FLASH_MODE_AUTO
                    }
                    CameraFlashMode.OPEN -> {
                        mImageCapture?.flashMode = FLASH_MODE_ON
                    }
                }
            }
        }

    init {
        this.context = context
        this.previewView = previewView
    }

    /// 设置监听
    fun setListener(onCameraEventListener: OnCameraEventListener) {
        mOnCameraEventListener = onCameraEventListener
    }

    fun switchFacing() {
        facing = when (facing) {
            CameraFacing.BACK -> {
                CameraFacing.FRONT

            }
            CameraFacing.FRONT -> {
                CameraFacing.BACK
            }
        }
    }

    /// 捕捉图片
    fun capturePicture() {
        // Get a stable reference of the modifiable image capture use case
        val imageCapture = mImageCapture ?: return
        val destFile = File(context.filesDir, "picture_${System.currentTimeMillis()}.jpg")

        // Create output options object which contains file + metadata
        val outputOptions = OutputFileOptions
            .Builder(destFile)
            .build()
        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(context),
            object : OnImageSavedCallback {
                override fun onError(exc: ImageCaptureException) {
                    Log.e("capture picture", "Photo capture failed: ${exc.message}", exc)
                }

                override fun
                        onImageSaved(output: OutputFileResults){
                    val msg = "Photo capture succeeded: ${output.savedUri}"
                    Log.d("capture picture", msg)
                    if (output.savedUri != null) {
                        val originPath = output.savedUri!!.path
                        val thumbnailPath = ""
                        val options = BitmapFactory.Options()
                        options.inJustDecodeBounds = true
                        val bitmap = BitmapFactory.decodeFile(originPath, options)
                        val dict: MutableMap<String, Any> = mutableMapOf(
                            "width" to options.outWidth,
                            "height" to options.outHeight,
                            "type" to 1,
                            "duration" to 0,
                        )
                        if (originPath != null) {
                            dict["origin_file_path"] = originPath
                        }
                        dict["thumbnail_file_path"] = thumbnailPath
                        mOnCameraEventListener?.finish(dict)
                    }
                }
            }
        )
    }

    /// 开始录制视频
    fun startVideoRecord() {
        if (mVideoCapture == null) {
            return
        }
        /// 构建视频文件路径
        val videoFile = File(context.filesDir, "video_${System.currentTimeMillis()}.mp4")
        /// 构建文件输出路径
        val outputOptions = FileOutputOptions
            .Builder(videoFile)
            .build()
        /// 启动录制并且得到录制对象
        mRecording = mVideoCapture!!.output.prepareRecording(context, outputOptions).apply {
            /// 启用音频
            withAudioEnabled()
        }.start(ContextCompat.getMainExecutor(context)) { recordEvent ->
            /// 获取录制状态
            when (recordEvent) {
                is VideoRecordEvent.Start -> {
                    /// 开启录制
                    Log.w("RECODING STATUS", "start recoding")
                    mOnCameraEventListener?.videoRecordingStart(recordEvent)
                }
                is VideoRecordEvent.Finalize -> {
                    Log.w("RECODING STATUS", "finalize recoding")
                    mOnCameraEventListener?.videoRecordingEnd(recordEvent)
                    /// 再做一次关闭录制，安全第一
                    closeVideoRecord()
                    /// 判断视频文件是否存在
                    if (recordEvent.outputResults.outputUri.toString().isNotEmpty() && recordEvent.outputResults.outputUri.toFile().exists()) {
                        finishRecordVideo(recordEvent.outputResults.outputUri)
                    } else {
//                        Toast.makeText(context, "视频文件不存在", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }
    }

    /// 关闭录制
    fun closeVideoRecord() {
        mRecording?.close()
    }

    /// 完成视频录制
    private fun finishRecordVideo(videoUri: Uri) {
        /// 获取第一帧 存入本地当作缩略图
        val mMMR = MediaMetadataRetriever()
        mMMR.setDataSource(context, videoUri)
        var mDuration =
            mMMR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toInt()?.div(1000)
        if (mDuration == null) {
            mDuration = 0
        }
        var videoWidth = mMMR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt()
        if (videoWidth == null) {
            videoWidth = 0
        }
        var videoHeight = mMMR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt()
        if (videoHeight == null) {
            videoHeight = 0
        }
        val bmp = mMMR.frameAtTime ?: return
        val byteArrayOutputStream = ByteArrayOutputStream()
        /// 压缩下
        bmp.compress(Bitmap.CompressFormat.JPEG, 10, byteArrayOutputStream)
        val cupBytes: ByteArray = byteArrayOutputStream.toByteArray()
        val destFile = File(context.filesDir, "cover_${System.currentTimeMillis()}.jpg")
        /// 写入到本地
        val file = writeDataToFile(cupBytes, destFile)
        if (file != null) {
            val originPath = videoUri.toFile().path
            val thumbnailPath = file.path
            val dict: MutableMap<String, Any> = mutableMapOf(
                "width" to videoWidth,
                "height" to videoHeight,
                "type" to 2,
                "duration" to mDuration,
            )
            dict["origin_file_path"] = originPath
            dict["thumbnail_file_path"] = thumbnailPath
            mOnCameraEventListener?.finish(dict)
        } else {
            Toast.makeText(context, "录像失败，请重试", Toast.LENGTH_SHORT).show()
        }
    }

    /// 写入文件到本地
    private fun writeDataToFile(data: ByteArray, file: File): File? {
        if (file.exists() && !file.delete()) return null
        try {
            BufferedOutputStream(FileOutputStream(file)).use { stream ->
                stream.write(data)
                stream.flush()
                return file
            }
        } catch (e: IOException) {
            if (e.message != null) {
                Log.e("Write Data to file err", e.message!!)
            }
            return null
        }
    }

    fun focus(x: Float, y: Float, auto: Boolean) {
        camera?.cameraControl?.cancelFocusAndMetering()
        val createPoint: MeteringPoint = if (auto) {

            val meteringPointFactory = DisplayOrientedMeteringPointFactory(
                previewView.display,
                camera?.cameraInfo!!,
                previewView.width.toFloat()!!,
                previewView.height.toFloat()!!
            )
            meteringPointFactory.createPoint(x, y)
        } else {
            val meteringPointFactory = previewView.meteringPointFactory
            meteringPointFactory.createPoint(x, y)!!
        }


        val build = FocusMeteringAction.Builder(createPoint, FLAG_AF)
            .setAutoCancelDuration(3, TimeUnit.SECONDS)
            .build()

        val future = camera?.cameraControl?.startFocusAndMetering(build)


        future?.addListener({
            try {

                if (future.get().isFocusSuccessful) {
                    //聚焦成功
                    Log.e("camera focus", "聚焦成功")
                } else {
                    //聚焦失败
                    Log.e("camera focus", "聚焦失败")
                }
            } catch (e: Exception) {
                Log.e("camera focus", "异常" + e.message)
            }

        }, ContextCompat.getMainExecutor(context))
    }

    /// 绑定图片捕捉、视频捕捉
    fun bindCameraUseCases() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            val resources = context.resources
            val displayMetrics = resources.displayMetrics
            val viewSize = Size(displayMetrics.widthPixels, displayMetrics.heightPixels)

            // Used to bind the lifecycle of cameras to the lifecycle owner
            val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()

            // Preview
            val preview = Preview.Builder()
                .setTargetResolution(viewSize)
                .build()
                .also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

            try {
                var cameraSelector = when (facing) {
                    CameraFacing.BACK -> {
                        CameraSelector.DEFAULT_BACK_CAMERA
                    }
                    CameraFacing.FRONT -> {
                        CameraSelector.DEFAULT_FRONT_CAMERA
                    }
                }
                // Unbind use cases before rebinding
                cameraProvider.unbindAll()
                when (captureMode) {
                    CameraCaptureMode.PICTURE -> {
                        mImageCapture = Builder()
                            .setTargetResolution(viewSize)
                            .build()
                        when (flashMode) {
                            CameraFlashMode.OFF -> {
                                mImageCapture?.flashMode = FLASH_MODE_OFF
                            }
                            CameraFlashMode.AUTO -> {
                                mImageCapture?.flashMode = FLASH_MODE_AUTO
                            }
                            CameraFlashMode.OPEN -> {
                                mImageCapture?.flashMode = FLASH_MODE_ON
                            }
                        }
                        camera = cameraProvider.bindToLifecycle(context, cameraSelector, mImageCapture!!, preview)
                    }
                    CameraCaptureMode.MOVIE -> {
                        val recorder = Recorder.Builder().setQualitySelector(QualitySelector.from(Quality.HIGHEST)).build()
                        mVideoCapture = VideoCapture.withOutput(recorder)
                        camera = cameraProvider.bindToLifecycle(context, cameraSelector, mVideoCapture!!, preview)
                    }
                    CameraCaptureMode.ALL -> {
                        mImageCapture = Builder()
                            .setTargetResolution(viewSize)
                            .build()
                        when (flashMode) {
                            CameraFlashMode.OFF -> {
                                mImageCapture?.flashMode = FLASH_MODE_OFF
                            }
                            CameraFlashMode.AUTO -> {
                                mImageCapture?.flashMode = FLASH_MODE_AUTO
                            }
                            CameraFlashMode.OPEN -> {
                                mImageCapture?.flashMode = FLASH_MODE_ON
                            }
                        }
                        val recorder = Recorder.Builder().setQualitySelector(QualitySelector.from(Quality.HIGHEST)).build()
                        mVideoCapture = VideoCapture.withOutput(recorder)
                        camera = cameraProvider.bindToLifecycle(context, cameraSelector, mImageCapture!!, mVideoCapture!!, preview)
                    }
                }
            } catch(exc: Exception) {
                Log.w("Bind Camera use case", exc.message.let { "$it" })
            }

        }, ContextCompat.getMainExecutor(context))
    }

    fun destroy() {
        Log.d("CameraManager", "Destory")
        camera = null
        mImageCapture = null
        mVideoCapture = null
        mRecording = null
    }

}