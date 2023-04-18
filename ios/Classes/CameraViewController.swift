//
//  CameraViewController.swift
//  custom_camera
//
//  Created by 吴文炜 on 2022/10/28.
//

import UIKit
import AVKit
import Flutter

class CameraViewController: UIViewController, CameraManagerDelegate, ImageViewBackDelegate, VideoViewBackDelegate {
    
    var flutterResult : FlutterResult?
    var sourceType : Int = 3
    var faceType: Int = 1
    
    let cameraManager = CameraManager()
    var cameraTabBar: CameraTabBar?
    var isRecording = false
    
    var countTimer : Timer?
    var totalCount : Int = 0
    
    var device = AVCaptureDevice.default(for: .video)
    
    /// 预览视图
    lazy var previewLayer: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview($0)
        return $0
    }(UIView())
    
    /// 闪光灯模式
    lazy var flashModeBar: FlashModeBar = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.alpha = 0
        $0.selectFlashModeHandler = { [weak self] (flashMode) -> Void in
            guard let self = self else { return }
            if let device = self.device {
                try? device.lockForConfiguration()
                if (device.hasTorch) {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            }

            switch flashMode {
            case .off:
                self.cameraManager.flashMode = CameraFlashMode.off
                self.flashButton.setImage(sourceImage(name: "flash_off"), for: .normal)
            case .on:
                self.cameraManager.flashMode = CameraFlashMode.on
                self.flashButton.setImage(sourceImage(name: "flash_on"), for: .normal)
            case .auto:
                self.cameraManager.flashMode = CameraFlashMode.auto
                self.flashButton.setImage(sourceImage(name: "flash_auto"), for: .normal)
            case .open:
                if let device = self.device {
                    try? device.lockForConfiguration()
                    if (device.hasTorch) {
                        device.torchMode = .on
                    }
                    device.unlockForConfiguration()
                }
            }
            self.switchFlashMode()
        }
        self.view.addSubview($0)
        return $0
    }(FlashModeBar())
    
    /// 闪光灯按钮
    lazy var flashButton: UIButton = {
        $0.setImage(sourceImage(name: "ic_camera_flash"), for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = cameraManager.hasFlash;
        $0.addTarget(self, action: #selector(switchFlashMode), for: .touchUpInside)
        self.view.addSubview($0)
        return $0
    }(UIButton(type: .custom))
    
    /// 切换摄像头按钮
    lazy var switchCameraButton: UIButton = {
        $0.setImage(sourceImage(name: "switch_camera"), for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(changeCameraDevice), for: .touchUpInside)
        self.view.addSubview($0)
        return $0
    }(UIButton(type: .custom))
    
    /// 关闭按钮
    lazy var closeButton: UIButton = {
        $0.setImage(sourceImage(name: "ic_close"), for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        self.view.addSubview($0)
        return $0
    }(UIButton(type: .custom))
    
    /// 拍照按钮
    lazy var takeshotButton: TakeshotButton = {
        $0.addTarget(self, action: #selector(recordButtonTapped))
        $0.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview($0)
        return $0
    }(TakeshotButton())
    
    /// 中间提示雨（包括录像时间提示）
    lazy var behaviorLabel: UILabel = {
        $0.text = "轻触拍照，按住摄像"
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .white
        $0.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview($0)
        return $0
    }(UILabel())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        setupConstraints()
        setupCamera()
        startAnimatedBehaviorHidden()
    }
    
    /// 初始化布局
    func setupConstraints() {
        NSLayoutConstraint.activate([
            previewLayer.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            flashModeBar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            flashModeBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 4.fixed),
            flashModeBar.heightAnchor.constraint(equalToConstant: 48.fixed),
            flashModeBar.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20.fixed),
            flashModeBar.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20.fixed),
            previewLayer.heightAnchor.constraint(equalTo: self.view.heightAnchor),
            flashButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 14.fixed),
            flashButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -34.fixed),
            flashButton.widthAnchor.constraint(equalToConstant: 28.fixed),
            flashButton.heightAnchor.constraint(equalToConstant: 28.fixed),
            takeshotButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -32.fixed),
            takeshotButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            takeshotButton.widthAnchor.constraint(equalToConstant: 72.fixed),
            takeshotButton.heightAnchor.constraint(equalToConstant: 72.fixed),
            closeButton.centerYAnchor.constraint(equalTo: takeshotButton.centerYAnchor),
            closeButton.rightAnchor.constraint(equalTo: takeshotButton.leftAnchor, constant: -48.fixed),
            switchCameraButton.leftAnchor.constraint(equalTo: takeshotButton.rightAnchor, constant: 48.fixed),
            switchCameraButton.centerYAnchor.constraint(equalTo: takeshotButton.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 48.fixed),
            closeButton.heightAnchor.constraint(equalToConstant: 48.fixed),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 48.fixed),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 48.fixed),
            behaviorLabel.bottomAnchor.constraint(equalTo: takeshotButton.topAnchor, constant: -42.fixed),
            behaviorLabel.centerXAnchor.constraint(equalTo: takeshotButton.centerXAnchor),
        ])
//        //切换拍照/录像
//        if (sourceType == 3) {
//            cameraTabBar = CameraTabBar.init(frame: CGRect(x: (SCREEN_WIDE - 100*RATE) / 2, y: cameraView!.frame.size.height + cameraView!.frame.origin.y - 50*RATE, width: 100*RATE, height: 50*RATE))
//            self.view.addSubview(cameraTabBar!)
//            cameraTabBar!.cameraTabBarBlock = { index in
//                self.outputModeButtonTapped(index: index)
//            }
//        }
        
    }
    
    /// 初始化相机
    func setupCamera() {
        cameraManager.cameraDelegate = self
        //cameraManager.shouldEnableExposure = true
        cameraManager.shouldKeepViewAtOrientationChanges = true
        cameraManager.writeFilesToPhoneLibrary = false
        cameraManager.animateShutter = true
        if (faceType == 1) {
            cameraManager.cameraDevice = .back
        } else {
            cameraManager.cameraDevice = .front
        }
        if (sourceType != 2) {
            cameraManager.cameraOutputMode = .stillImage
        } else {
            cameraManager.cameraOutputMode = .videoWithMic
        }
        cameraManager.cameraOutputQuality = .high
        cameraManager.shouldFlipFrontCameraImage = true
        cameraManager.videoStabilisationMode = .standard
        cameraManager.showAccessPermissionPopupAutomatically = false
        
        cameraManager.askUserForCameraPermission { [weak self] permissionGranted in
            guard let self = self else { return }
            if permissionGranted {
                self.cameraManager.addPreviewLayerToView(self.previewLayer, newCameraOutputMode: self.cameraManager.cameraOutputMode)
                self.cameraManager.showErrorBlock = { (erTitle: String, erMessage: String) -> Void in
                    let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (_) -> Void in }))
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
    /// 隐藏提示文本
    func startAnimatedBehaviorHidden() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: { () -> Void in
            UIView.animate(withDuration: 0.25) {
                self.behaviorLabel.alpha = 0.0;
            }
        })
    }
    
    /// 点击切换闪光灯
    @objc func switchFlashMode() {
        UIView.animate(withDuration: 0.25) {
            self.flashModeBar.alpha = self.flashModeBar.alpha == 1 ? 0 : 1;
        }
    }
    
    
    //切换输出类型 拍照/录像
    @objc func outputModeButtonTapped(index: Int) {
        if (cameraManager.cameraOutputMode == CameraOutputMode.stillImage && index == 1) {
            return
        }
        if (cameraManager.cameraOutputMode == CameraOutputMode.videoWithMic &&  index == 2) {
            return
        }
        if (cameraManager.cameraOutputMode == CameraOutputMode.videoOnly &&  index == 2) {
            return
        }
        cameraManager.cameraOutputMode = cameraManager.cameraOutputMode == CameraOutputMode.videoWithMic ? CameraOutputMode.stillImage : CameraOutputMode.videoWithMic
        switch cameraManager.cameraOutputMode {
            case .stillImage:
            cameraTabBar?.pictureBtn?.setTitleColor(hexColor(hex: 0xFFE06A), for: .normal)
            cameraTabBar?.videoBtn?.setTitleColor(hexColor(hex: 0x90FFFFFF), for: .normal)
            updateTakeView(color: UIColor.white, width: 34*RATE, radius: 17*RATE)
            case .videoWithMic, .videoOnly:
            cameraTabBar?.pictureBtn?.setTitleColor(hexColor(hex: 0x90FFFFFF), for: .normal)
            cameraTabBar?.videoBtn?.setTitleColor(hexColor(hex: 0xFFE06A), for: .normal)
            updateTakeView(color: hexColor(hex: 0xFF4747), width: 34*RATE, radius: 17*RATE)
        }
    }
    
    //切换前后摄像头
    @objc func changeCameraDevice(sender: UITapGestureRecognizer) {
        cameraManager.cameraDevice = cameraManager.cameraDevice == CameraDevice.front ? CameraDevice.back : CameraDevice.front
    }
    
    //拍照/录像
    @objc func recordButtonTapped(sender: UIButton) {
        switch cameraManager.cameraOutputMode {
        case .stillImage:
            cameraManager.capturePictureDataWithCompletion { result in
                switch result {
                    case .failure:  self.cameraManager.showErrorBlock("Error occurred", "Cannot save picture.")
                    case .success(let content):
                    guard let image = content.asImage else {
                        return
                    }
                    if (image.imageOrientation != .up) {
                        UIGraphicsBeginImageContext(image.size)
                        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
                        var drawImg = UIGraphicsGetImageFromCurrentImageContext()!
                        UIGraphicsEndImageContext()
                        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
                        do {
                            try drawImg.pngData()?.write(to: URL(fileURLWithPath: path))
                            self.flutterResult!([
                                    "width": Int(image.size.width),
                                    "height": Int(image.size.height),
                                    "type": 1,
                                    "origin_file_path": path,
                                    "thumbnail_file_path": "",
                                ])
                        } catch {
                            print("写入文件失败")
                        }
                    } else {
                        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
                        do {
                            try image.pngData()?.write(to: URL(fileURLWithPath: path))
                            self.flutterResult!([
                                    "width": Int(image.size.width),
                                    "height": Int(image.size.height),
                                    "type": 1,
                                    "origin_file_path": path,
                                    "thumbnail_file_path": "",
                                ])
                        } catch {
                            print("写入文件失败")
                        }
                    }
                    self.dismiss(animated: false)
//                    let validVC = ImageViewController.init()
//                    let capturedData = content.asData
//                    let capturedImage = UIImage(data: capturedData!)!
//                    validVC.image = capturedImage
//                    validVC.flutterResult = self.flutterResult
//                    validVC.modalPresentationStyle = .fullScreen
//                    validVC.imageViewBackDelegate = self
//                    self.present(validVC, animated: true)
                }
            }
            break
        case .videoWithMic, .videoOnly:
            if !isRecording {
                updateTakeView(color: hexColor(hex: 0xFF4747), width: 20*RATE, radius: 4*RATE)
                isRecording = true
                createTimer()
                cameraManager.startRecordingVideo()
            } else {
                closeTimer()
                cameraManager.stopVideoRecording { [self] (videoURL, error) -> Void in
                    updateTakeView(color: hexColor(hex: 0xFF4747), width: 34*RATE, radius: 17*RATE)
                    isRecording = false
                    if error != nil {
                        self.cameraManager.showErrorBlock("Error occurred", "Cannot save video.")
                    } else {
                        jumpToVideo(outputFileURL: videoURL!)
                    }
                }
            }
            break
        }
    }
    
    func isRecordEndTime(outputFileURL: URL) {
        updateTakeView(color: hexColor(hex: 0xFF4747), width: 34*RATE, radius: 17*RATE)
        isRecording = false
        jumpToVideo(outputFileURL: outputFileURL)
    }
    
    func jumpToVideo(outputFileURL: URL) {
        let videoVC = VideoViewController.init()
        videoVC.videoViewBackDelegate = self
        videoVC.videoURL = outputFileURL
        videoVC.flutterResult = flutterResult
        videoVC.modalPresentationStyle = .fullScreen
        self.present(videoVC, animated: true)
    }
    
    func createTimer() {
        closeTimer()
        totalCount = 0
        countTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.countDownAction), userInfo: nil, repeats: true)
        countTimer!.fire()
    }
    
    @objc func countDownAction(sender: Timer) {

    }
    
    func closeTimer() {
        countTimer?.invalidate()
        countTimer = nil
    }
    
    func updateTakeView(color: UIColor, width: CGFloat, radius: CGFloat) {
        
    }
    
    func imageViewCallBack() {
        cameraManager.destroy()
        self.dismiss(animated: true)
    }
    
    func videoViewCallBack() {
        cameraManager.destroy()
        self.dismiss(animated: true)
    }
    
    @objc func backAction(sender: UIButton) {
        closeTimer()
        cameraManager.destroy()
        self.dismiss(animated: true)
    }
    
    deinit {
        closeTimer()
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
