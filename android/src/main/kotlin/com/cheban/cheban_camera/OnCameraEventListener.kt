package com.cheban.cheban_camera

import androidx.camera.video.VideoRecordEvent

interface OnCameraEventListener {
    /// 开始录制
    fun videoRecordingStart(videoRecordEvent: VideoRecordEvent)
    /// 结束录制
    fun videoRecordingEnd(videoRecordEvent: VideoRecordEvent)
    /// 完成结果
    fun finish(result: Map<String, Any>)

}