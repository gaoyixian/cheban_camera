package com.cheban.cheban_camera

import android.content.Context
import android.util.AttributeSet
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout

interface SelectFlashModeHandler {
    fun invoked(value: Int)
}

class FlashModesView(context: Context, attributeSet: AttributeSet): LinearLayout(context, attributeSet), View.OnClickListener{

    var handler: SelectFlashModeHandler? = null

    private var ivFlashOff: ImageView
    private var ivFlashAuto: ImageView
    private var ivFlashOn: ImageView
    private var ivFlashSwitch: ImageView

    init {
        inflate(context, R.layout.view_flash_modes, this)
        ivFlashOff = findViewById(R.id.iv_flash_off)
        ivFlashAuto = findViewById(R.id.iv_flash_auto)
        ivFlashOn = findViewById(R.id.iv_flash_on)
        ivFlashSwitch = findViewById(R.id.iv_flash_switch)

        ivFlashOff.setOnClickListener(this)
        ivFlashAuto.setOnClickListener(this)
        ivFlashOn.setOnClickListener(this)
        ivFlashSwitch.setOnClickListener(this)
    }

    override fun onClick(p0: View?) {
        when (p0?.id) {
            ivFlashOff.id -> {
                ivFlashSwitch.setImageDrawable(resources.getDrawable(R.mipmap.flash_off))
                handler?.invoked(0)
            }
            ivFlashAuto.id -> {
                ivFlashSwitch.setImageDrawable(resources.getDrawable(R.mipmap.flash_auto))
                handler?.invoked(1)
            }
            ivFlashOn.id -> {
                ivFlashSwitch.setImageDrawable(resources.getDrawable(R.mipmap.flash_on))
                handler?.invoked(2)
            }
            ivFlashSwitch.id -> {
                handler?.invoked(3)
            }
        }
    }
}