package com.cheban.cheban_camera

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import android.widget.VideoView
import androidx.appcompat.app.AppCompatActivity
import com.otaliastudios.cameraview.CameraUtils
import com.otaliastudios.cameraview.VideoResult
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream


class VideoPreviewActivity : AppCompatActivity(), View.OnClickListener {
    companion object {
        var videoResult: VideoResult? = null
    }

    private val videoView: VideoView by lazy { findViewById<VideoView>(R.id.view_video) }

    private lateinit var playerImageView: ImageView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_video_preview)

        val result = videoResult ?: run {
            Toast.makeText(this, "录像失败，请重试", Toast.LENGTH_SHORT).show()
            finish()
            return
        }
        playerImageView = findViewById(R.id.iv_play)
        playerImageView.setOnClickListener(this)
        findViewById<TextView>(R.id.tv_remake).setOnClickListener(this)
        findViewById<TextView>(R.id.tv_use_video).setOnClickListener(this)

        videoView.setVideoURI(Uri.fromFile(result.file))
        videoView.setOnPreparedListener { mp ->
            val lp = videoView.layoutParams
            val videoWidth = mp.videoWidth.toFloat()
            val videoHeight = mp.videoHeight.toFloat()
            val viewWidth = videoView.width.toFloat()
            lp.height = (viewWidth * (videoHeight / videoWidth)).toInt()
            videoView.layoutParams = lp
            playVideo()
            playVideo()
        }
        videoView.setOnCompletionListener {
            playerImageView.setImageResource(R.mipmap.play)
        }
    }

    override fun onClick(v: View?) {
        when (v!!.id) {
            R.id.iv_play -> {
                playVideo()
            }
            R.id.tv_remake -> {
                finish()
            }
            R.id.tv_use_video -> {
                saveVideoToSystemAlbum(videoResult!!.file.path)
                val mMMR = MediaMetadataRetriever()
                mMMR.setDataSource(this, Uri.fromFile(videoResult!!.file))
                val bmp = mMMR.frameAtTime
                if (bmp != null) {
                    val byteArrayOutputStream = ByteArrayOutputStream()
                    bmp.compress(Bitmap.CompressFormat.JPEG, 10, byteArrayOutputStream)
                    val cupBytes: ByteArray = byteArrayOutputStream.toByteArray()
                    val destFile = File(filesDir, "cover_${System.currentTimeMillis()}.jpg")
                    CameraUtils.writeToFile(cupBytes, destFile) { file ->
                        if (file != null) {
                            val intent = Intent()
                            intent.putExtra("width", videoResult!!.size.width)
                            intent.putExtra("height", videoResult!!.size.height)
                            intent.putExtra("type", 2)
                            intent.putExtra("origin_file_path", videoResult!!.file.path)
                            intent.putExtra("thumbnail_file_path", file.path)
                            setResult(10001, intent)
                            finish()
                        } else {
                            Toast.makeText(this, "录像失败，请重试", Toast.LENGTH_SHORT).show()
                            finish()
                        }
                    }
                } else {
                    Toast.makeText(this, "录像失败，请重试", Toast.LENGTH_SHORT).show()
                    finish()
                }
            }
        }
    }

    private fun playVideo() {
        if (videoView.isPlaying) {
            playerImageView.setImageResource(R.mipmap.play)
            videoView.pause()
        } else {
            playerImageView.setImageResource(R.mipmap.stop)
            videoView.start()
        }
    }

    fun saveVideoToSystemAlbum(videoPath: String): Boolean {
        return try {
            val localContentResolver: ContentResolver = contentResolver
            val localContentValues: ContentValues = getVideoContentValues(File(videoPath), System.currentTimeMillis())
            val localUri = localContentResolver.insert(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                localContentValues
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && applicationInfo.targetSdkVersion >= Build.VERSION_CODES.Q) {
                // 拷贝到指定uri,如果没有这步操作，android11不会在相册显示
                try {
                    val out: OutputStream? = contentResolver.openOutputStream(localUri!!)
                    copyFile(videoPath, out!!)
                } catch (e: IOException) {
                    e.printStackTrace()
                }
            }
            sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, localUri))
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun getVideoContentValues(paramFile: File, paramLong: Long): ContentValues {
        val localContentValues = ContentValues()
        localContentValues.put("title", paramFile.name)
        localContentValues.put("_display_name", paramFile.name)
        localContentValues.put("mime_type", "video/mp4")
        localContentValues.put("datetaken", java.lang.Long.valueOf(paramLong))
        localContentValues.put("date_modified", java.lang.Long.valueOf(paramLong))
        localContentValues.put("date_added", java.lang.Long.valueOf(paramLong))
        localContentValues.put("_data", paramFile.absolutePath)
        localContentValues.put("_size", java.lang.Long.valueOf(paramFile.length()))
        return localContentValues
    }

    fun copyFile(oldPath: String, out: OutputStream): Boolean {
        try {
            var bytesum = 0
            var byteread = 0
            val oldfile = File(oldPath)
            if (oldfile.exists()) {
                // 读入原文件
                val inStream: InputStream = FileInputStream(oldPath)
                val buffer = ByteArray(1444)
                while (inStream.read(buffer).also { byteread = it } != -1) {
                    bytesum += byteread //字节数 文件大小
                    println(bytesum)
                    out.write(buffer, 0, byteread)
                }
                inStream.close()
                out.close()
                return true
            } else {
                Log.w("CameraException", String.format("文件(%s)不存在。", oldPath))
            }
        } catch (e: java.lang.Exception) {
            Log.e("CameraException", "复制单个文件操作出错")
            e.printStackTrace()
        }
        return false
    }
}