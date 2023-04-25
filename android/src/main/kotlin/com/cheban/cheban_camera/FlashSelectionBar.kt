package com.cheban.cheban_camera

import android.content.Context
import android.util.AttributeSet
import android.view.View
import android.view.View.OnClickListener
import android.widget.ImageView
import android.widget.LinearLayout

class FlashSelectionBar(context: Context, attributeSet: AttributeSet): LinearLayout(context, attributeSet), OnClickListener {
    /// 回调
    var mOnFlashSelectionListener: OnFlashSelectionListener? = null
    /// 关闭闪光灯
    private lateinit var mFlashOffImageView: ImageView
    /// 自动闪光灯
    private lateinit var mFlashAutoImageView: ImageView
    /// 开启闪光灯
    private lateinit var mFlashOnImageView: ImageView
    /// FlashBar启动器按钮
    private lateinit var mFlashBarLauncherBtnImageView: ImageView

    fun setListener(flashSelectionListener: OnFlashSelectionListener) {
        mOnFlashSelectionListener = flashSelectionListener
    }

    init {
        inflate(context, R.layout.view_flash_modes, this)
        bindLayoutView()
        bindOnClickListener()
    }

    private fun bindLayoutView() {
        mFlashOffImageView = findViewById(R.id.iv_flash_off)
        mFlashAutoImageView = findViewById(R.id.iv_flash_auto)
        mFlashOnImageView = findViewById(R.id.iv_flash_on)
        mFlashBarLauncherBtnImageView = findViewById(R.id.iv_flash_switch)
    }

    private fun bindOnClickListener() {
        mFlashOffImageView.setOnClickListener(this)
        mFlashAutoImageView.setOnClickListener(this)
        mFlashOnImageView.setOnClickListener(this)
        mFlashBarLauncherBtnImageView.setOnClickListener(this)
    }

    override fun onClick(p0: View?) {
        when (p0?.id) {
            mFlashOffImageView.id -> {
                mFlashBarLauncherBtnImageView.setImageDrawable(resources.getDrawable(R.mipmap.flash_off))
                mOnFlashSelectionListener?.callback(0)
            }
            mFlashAutoImageView.id -> {
                mFlashBarLauncherBtnImageView.setImageDrawable(resources.getDrawable(R.mipmap.flash_auto))
                mOnFlashSelectionListener?.callback(1)
            }
            mFlashOnImageView.id -> {
                mFlashBarLauncherBtnImageView.setImageDrawable(resources.getDrawable(R.mipmap.flash_on))
                mOnFlashSelectionListener?.callback(2)
            }
            mFlashBarLauncherBtnImageView.id -> {
                mOnFlashSelectionListener?.callback(3)
            }
        }
    }

}