package com.cheban.cheban_camera

import android.annotation.SuppressLint
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.hardware.display.DisplayManager
import android.media.ExifInterface
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
import kotlinx.coroutines.delay
import java.io.*
import java.nio.ByteBuffer
import java.util.Arrays
import java.util.concurrent.TimeUnit

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class CameraManager(context: AppCompatActivity, previewView: PreviewView) {

    private var context: AppCompatActivity
    private var previewView: PreviewView

    private var mImageCapture: ImageCapture? = null
    private var mVideoCapture: VideoCapture<Recorder>? = null
    /// 录制
    private var mRecording: Recording? = null
    private var mPendingRecording: PendingRecording? = null

    private var cameraProvider: ProcessCameraProvider? = null
    /// 相机
    private var mCamera: Camera? = null

    var lock: Boolean = false;

    /// 录制
    private var mOnRecordListener: OnRecordListener? = null
    /// 照片
    private var mOnCaptureListener: OnCaptureListener? = null

    val orientationEventListener by lazy {
        object : OrientationEventListener(context) {
            @SuppressLint("RestrictedApi")
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
                mVideoCapture?.targetRotation = rotation
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
            if (hasFlashUnit()) {
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
        }

    init {
        this.context = context
        this.previewView = previewView
    }

    fun setRecordListener(onRecordListener: OnRecordListener) {
        mOnRecordListener = onRecordListener
    }

    fun setCaptureListener(onCaptureListener: OnCaptureListener) {
        mOnCaptureListener = onCaptureListener
    }

    fun switchFacing() {
        facing = when (facing) {
            CameraFacing.BACK -> {
                /// 前摄像头没有闪光灯
                CameraFacing.FRONT

            }
            CameraFacing.FRONT -> {
                CameraFacing.BACK
            }
        }
    }

    fun hasFlashUnit(): Boolean {
        return true == mCamera?.cameraInfo?.hasFlashUnit()
    }

    /// 捕捉图片
    fun capturePicture() {
        // Get a stable reference of the modifiable image capture use case
        val imageCapture = mImageCapture ?: return
        if (lock) {
            return
        }
        lock = true;

        val destFile = File(context.filesDir, "picture_${System.currentTimeMillis()}.jpg")

        // Create output options object which contains file + metadata
        var metadata = Metadata()
        metadata.isReversedHorizontal = facing == CameraFacing.FRONT
        val outputOptions = OutputFileOptions
            .Builder(destFile)
            .setMetadata(metadata)
            .build()
        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(context),
            object : OnImageSavedCallback {
                override fun onError(exc: ImageCaptureException) {
                    lock = false
                    Log.e("capture picture", "Photo capture failed: ${exc.message}", exc)
                }

                override fun
                        onImageSaved(output: OutputFileResults){
                    val msg = "Photo capture succeeded: ${output.savedUri}"
                    Log.d("capture picture", msg)
                    if (output.savedUri != null) {
                        val saveUri = output.savedUri!!
                        println(">>>>>>>>>>>> compress ${saveUri.toFile().length()}")
                        val bmp: Bitmap? = compressImg(saveUri)
                       val originPath = saveUri.path
                        val thumbnailPath = ""
                        var width = bmp?.width
                        if (width == null) {
                            width = 0
                        }
                        var height = bmp?.height
                        if (height == null) {
                            height = 0
                        }
                        val dict: MutableMap<String, Any> = mutableMapOf(
                            "width" to width,
                            "height" to height,
                            "type" to 1,
                            "duration" to 0,
                        )
                        if (originPath != null) {
                            dict["origin_file_path"] = originPath
                        }
                        dict["thumbnail_file_path"] = thumbnailPath
                        mOnCaptureListener?.takePhoto(dict)
                    }
                    lock = false
                }
            }
        )
    }

    /// 新增压缩图片
    private fun compressImg(uri: Uri): Bitmap? {
        //将图片转换为bitmap
        val bitmapImg = BitmapFactory.decodeStream(context.contentResolver.openInputStream(uri))

        val baos = ByteArrayOutputStream()
        bitmapImg.compress(Bitmap.CompressFormat.JPEG, 100, baos)
        println("bitmap factory bytes size ---------------${baos.toByteArray().size}" )
        if (baos.toByteArray().size / 1024 > 512) { //判断如果图片大于500k,进行压缩避免在生成图片（BitmapFactory.decodeStream）时溢出
            baos.reset() //重置baos即清空baos
            bitmapImg.compress(Bitmap.CompressFormat.JPEG, 50, baos) //这里压缩50%，把压缩后的数据存放到baos中
        }
        var isBm: ByteArrayInputStream? = ByteArrayInputStream(baos.toByteArray())
        val newOpts = BitmapFactory.Options()
        //开始读入图片，此时把options.inJustDecodeBounds 设回true了
        newOpts.inJustDecodeBounds = true
        var bitmap = BitmapFactory.decodeStream(isBm, null, newOpts)
        newOpts.inJustDecodeBounds = false
        val w = newOpts.outWidth
        val h = newOpts.outHeight

        val hh = 1920 //这里设置高度为800f
        val ww = 1080 //这里设置宽度为480f
        //缩放比。由于是固定比例缩放，只用高或者宽其中一个数据进行计算即可
        var be = 1 //be=1表示不缩放
        if (w > h && w > ww) { //如果宽度大的话根据宽度固定大小缩放
            be = (newOpts.outWidth / ww).toInt()
        } else if (w < h && h > hh) { //如果高度高的话根据宽度固定大小缩放
            be = (newOpts.outHeight / hh).toInt()
        }
        if (be <= 0) be = 1
        newOpts.inSampleSize = be //设置缩放比例
        //重新读入图片，注意此时已经把options.inJustDecodeBounds 设回false了
        isBm = ByteArrayInputStream(baos.toByteArray())
        bitmap = BitmapFactory.decodeStream(isBm, null, newOpts)
        if (bitmap != null) {
            val f: File? =  getFileFromMediaUri(uri)
            if (f != null) {
                val bb = rotateBitmapByDegree(bitmap, getBitmapDegree(f.absolutePath))
                uri.toFile().writeBytes(baos.toByteArray())
                println("========compress -------- ${uri.toFile().length()}")
                if (bb != null) {
                    return bb
                }
            }
        }
        var byteCount = bitmap?.byteCount
        if (byteCount == null) {
            byteCount = 0
        }
        val buffer = ByteBuffer.allocate(byteCount)
        bitmap?.copyPixelsToBuffer(buffer)
        uri.toFile().delete()
        uri.toFile().writeBytes(buffer.array())
        println("+++++++++compress -------- ${uri.toFile().length()}")
        return bitmap//压缩好比例大小后再进行质量压缩
    }

    private fun getFileFromMediaUri(uri: Uri): File? {
        if (uri.scheme.toString().compareTo("content") == 0) {
            //val cr: ContentResolver = this.getContentResolver()
            val cursor: Cursor = context.contentResolver.query(uri, null, null, null, null) ?: return null
            // 根据Uri从数据库中找
            cursor.moveToFirst()
            cursor.getColumnIndex("_data")
            val  cursorRange = cursor.getColumnIndex("_data");
            if (cursorRange >= 0) {
                val filePath: String = cursor.getString(cursorRange) // 获取图片路径
                cursor.close()
                return File(filePath)
            }
        } else if (uri.scheme.toString().compareTo("file") == 0) {
            return File(uri.toString().replace("file://", ""))
        }
        return null
    }

    private fun getBitmapDegree(path: String): Int {
        var degree = 0
        try {
            // 从指定路径下读取图片，并获取其EXIF信息
            val exifInterface = ExifInterface(path)

            // 获取图片的旋转信息
            val orientation: Int = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL)
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> degree = 90
                ExifInterface.ORIENTATION_ROTATE_180 -> degree = 180
                ExifInterface.ORIENTATION_ROTATE_270 -> degree = 270
            }
        } catch (e: IOException) {
            e.printStackTrace()
        }
        return degree
    }

    private fun rotateBitmapByDegree(bm: Bitmap, degree: Int): Bitmap? {
        var returnBm: Bitmap? = null
        // 根据旋转角度，生成旋转矩阵
        val matrix = Matrix()
        matrix.postRotate(degree.toFloat())
        try {
            // 将原始图片按照旋转矩阵进行旋转，并得到新的图片
            returnBm = Bitmap.createBitmap(bm, 0, 0, bm.width, bm.height, matrix, true)
        } catch (e: OutOfMemoryError) {
        }
        if (returnBm == null) {
            returnBm = bm
        }
        if (bm != returnBm) {
            bm.recycle()
        }
        return returnBm
    }

    /// 开始录制视频
    fun startVideoRecord() {
        if (mVideoCapture == null || mPendingRecording == null) {
            return
        }
        if (lock) {
            return
        }
        lock = true
        /// 启动录制并且得到录制对象
        mRecording = mPendingRecording?.start(ContextCompat.getMainExecutor(context)) { recordEvent ->
            /// 获取录制状态
            when (recordEvent) {
                is VideoRecordEvent.Start -> {
                    /// 开启录制
                    Log.w("RECODING STATUS", "start recoding")
                    mOnRecordListener?.start(recordEvent)
                }
                is VideoRecordEvent.Finalize -> {
                    Log.w("RECODING STATUS", "finalize recoding")
                    mOnRecordListener?.stop(recordEvent)
                    /// 再做一次关闭录制，安全第一
                    closeVideoRecord()
                    /// 判断视频文件是否存在
                    if (recordEvent.outputResults.outputUri.toString().isNotEmpty() && recordEvent.outputResults.outputUri.toFile().exists()) {
                        takeVideo(recordEvent.outputResults.outputUri)
                    } else {
//                        Toast.makeText(context, "视频文件不存在", Toast.LENGTH_SHORT).show()
                    }
                    lock = false
                }
                is VideoRecordEvent.Pause -> {

                }
                is VideoRecordEvent.Resume -> {

                }
            }

        }
    }

    /// 关闭录制
    fun closeVideoRecord() {
        mRecording?.close()
    }

    /// 完成视频录制
    private fun takeVideo(videoUri: Uri) {
        /// 获取第一帧 存入本地当作缩略图
        val mMMR = MediaMetadataRetriever()
        mMMR.setDataSource(context, videoUri)
        var mDuration =
            mMMR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toInt()?.div(1000)
        if (mDuration == null || mDuration == 0) {
            return
        }
        var videoRotation = mMMR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
        if (videoRotation == null) {
            videoRotation = "0"
            Log.d("CameraManager", videoRotation)
        }
        var videoWidth = mMMR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt()
        if (videoWidth == null) {
            videoWidth = 0
        }
        var videoHeight = mMMR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt()
        if (videoHeight == null) {
            videoHeight = 0
        }
        when (videoRotation) {
            "90", "270" -> {
                val tmp = videoWidth
                videoWidth = videoHeight
                videoHeight = tmp
            }
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
            mOnRecordListener?.takeVideo(dict)
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
        if (mCamera == null || mCamera?.cameraInfo == null) {
            return
        }
        if (lock) {
            return
        }
        lock = true
        mCamera?.cameraControl?.cancelFocusAndMetering()
        val createPoint: MeteringPoint = if (auto) {

            val meteringPointFactory = DisplayOrientedMeteringPointFactory(
                previewView.display,
                mCamera?.cameraInfo!!,
                previewView.width.toFloat(),
                previewView.height.toFloat()
            )
            meteringPointFactory.createPoint(x, y)
        } else {
            val meteringPointFactory = previewView.meteringPointFactory
            meteringPointFactory.createPoint(x, y)
        }


        val build = FocusMeteringAction.Builder(createPoint, FLAG_AF)
            .setAutoCancelDuration(3, TimeUnit.SECONDS)
            .build()

        val future = mCamera?.cameraControl?.startFocusAndMetering(build)

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
            lock = false
        }, ContextCompat.getMainExecutor(context))
    }

    /// 绑定图片捕捉、视频捕捉
    fun bindCameraUseCases() {
        if (lock) {
            return
        }
        lock = true
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            val resources = context.resources
            val displayMetrics = resources.displayMetrics
            val viewSize = Size(displayMetrics.widthPixels, displayMetrics.heightPixels)

            // Used to bind the lifecycle of cameras to the lifecycle owner
            cameraProvider = cameraProviderFuture.get()

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
                cameraProvider?.unbindAll()
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
                        mCamera = cameraProvider?.bindToLifecycle(context, cameraSelector, mImageCapture!!, preview)
                    }
                    CameraCaptureMode.MOVIE -> {
                        val recorder = Recorder.Builder().setQualitySelector(QualitySelector.from(Quality.FHD, FallbackStrategy.lowerQualityThan(
                            Quality.FHD))).build()
                        mVideoCapture = VideoCapture.withOutput(recorder)
                        /// 构建视频文件路径
                        val videoFile = File(context.filesDir, "video_${System.currentTimeMillis()}.mp4")
                        /// 构建文件输出路径
                        val outputOptions = FileOutputOptions
                            .Builder(videoFile)
                            .build()
                        mPendingRecording = mVideoCapture!!.output.prepareRecording(context, outputOptions).apply {
                            /// 启用音频
                            withAudioEnabled()
                        }
                        mCamera = cameraProvider?.bindToLifecycle(context, cameraSelector, mVideoCapture!!, preview)
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
                        val recorder = Recorder.Builder().setQualitySelector(QualitySelector.from(Quality.FHD, FallbackStrategy.lowerQualityThan(
                            Quality.FHD))).build()
                        mVideoCapture = VideoCapture.withOutput(recorder)
                        /// 构建视频文件路径
                        val videoFile = File(context.filesDir, "video_${System.currentTimeMillis()}.mp4")
                        /// 构建文件输出路径
                        val outputOptions = FileOutputOptions
                            .Builder(videoFile)
                            .build()
                        mPendingRecording = mVideoCapture!!.output.prepareRecording(context, outputOptions).apply {
                            /// 启用音频
                            withAudioEnabled()
                        }
                        mCamera = cameraProvider?.bindToLifecycle(context, cameraSelector, mImageCapture!!, mVideoCapture!!, preview)
                    }
                }
            } catch(exc: Exception) {
                Log.w("Bind Camera use case", exc.message.let { "$it" })
            }
            lock = false
        }, ContextCompat.getMainExecutor(context))
    }

    fun destroy() {
        Log.d("CameraManager", "Destory")
        closeVideoRecord()
        previewView.removeAllViews()
        cameraProvider?.unbindAll()
        mImageCapture = null
        mVideoCapture = null
        mRecording = null
        mPendingRecording = null
        mCamera = null
        cameraProvider = null
    }

}