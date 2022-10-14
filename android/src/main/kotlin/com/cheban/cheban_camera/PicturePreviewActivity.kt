package com.cheban.cheban_camera

import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.otaliastudios.cameraview.CameraUtils
import com.otaliastudios.cameraview.PictureResult
import java.io.File

class PicturePreviewActivity : AppCompatActivity(), View.OnClickListener {

    companion object {
        var pictureResult: PictureResult? = null
    }

    private lateinit var pictureView: ImageView

    private lateinit var remarkTV: TextView

    private lateinit var usePhotoTV: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_picture_preview)
        val result = pictureResult ?: run {
            Toast.makeText(this, "拍照失败，请重试", Toast.LENGTH_SHORT).show()
            finish()
            return
        }
        pictureView = findViewById(R.id.iv_picture)
        remarkTV = findViewById(R.id.tv_remake)
        usePhotoTV = findViewById(R.id.tv_use_photo)

        remarkTV.setOnClickListener(this)
        usePhotoTV.setOnClickListener(this)

        try {
            result.toBitmap(2048, 2048) {
                bitmap ->
                saveBitmapGallery(bitmap!!)
                pictureView.setImageBitmap(bitmap)
            }
        } catch (e: UnsupportedOperationException) {
            Toast.makeText(this, "拍照失败，请重试", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        pictureResult = null
    }

    override fun onClick(v: View?) {
        if (v!!.id == R.id.tv_remake) {
            finish()
        } else {

            val destFile = File(filesDir, "picture_${System.currentTimeMillis()}.jpg")
            CameraUtils.writeToFile(requireNotNull(pictureResult?.data), destFile) { file ->
                if (file != null) {
                    val intent = Intent()
                    intent.putExtra("width", pictureResult!!.size.width)
                    intent.putExtra("height", pictureResult!!.size.height)
                    intent.putExtra("type", 1)
                    intent.putExtra("origin_file_path", file.path)
                    intent.putExtra("thumbnail_file_path", "")
                    setResult(10001, intent)
                    finish()
                } else {
                    Toast.makeText(this, "拍照失败，请重试", Toast.LENGTH_SHORT).show()
                    finish()
                }
            }
        }
    }

    fun saveBitmapGallery( bitmap: Bitmap): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            //返回出一个URI
            val insert = contentResolver.insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                /*
                这里如果不写的话 默认是保存在 /sdCard/DCIM/Pictures
                 */
                ContentValues()//这里可以啥也不设置 保存图片默认就好了
            ) ?: return false //为空的话 直接失败返回了

            //这个打开了输出流  直接保存图片就好了
            contentResolver.openOutputStream(insert).use {
                it ?: return false
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, it)
            }
            return true
        } else {
            MediaStore.Images.Media.insertImage(contentResolver, bitmap, "title", "desc")
            return true
        }
    }


}