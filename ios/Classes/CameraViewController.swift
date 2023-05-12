//
//  CameraViewController.swift
//  custom_camera
//
//  Created by 吴文炜 on 2022/10/28.
//

import UIKit
import AVKit
import Flutter

class CameraViewController: UIViewController, CameraManagerDelegate {
    
    var flutterResult : FlutterResult?
    var sourceType : Int = 3
    var faceType: Int = 1
    
    var delayDismissTime: Double = 0.25
    
    let cameraManager = CameraManager()
    var cameraTabBar: CameraTabBar?
    
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
            self.onSwitchFlashPressed()
        }
        self.view.addSubview($0)
        return $0
    }(FlashModeBar())
    
    /// 闪光灯按钮
    lazy var flashButton: UIButton = {
        $0.setImage(sourceImage(name: "flash_off"), for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = cameraManager.hasFlash;
        $0.addTarget(self, action: #selector(onSwitchFlashPressed), for: .touchUpInside)
        self.view.addSubview($0)
        return $0
    }(UIButton(type: .custom))
    
    /// 切换摄像头按钮
    lazy var switchCameraButton: UIButton = {
        $0.setImage(sourceImage(name: "switch_camera"), for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(onSwitchCameraPressed), for: .touchUpInside)
        self.view.addSubview($0)
        return $0
    }(UIButton(type: .custom))
    
    /// 关闭按钮
    lazy var closeButton: UIButton = {
        $0.setImage(sourceImage(name: "ic_close"), for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(onBackPressed), for: .touchUpInside)
        self.view.addSubview($0)
        return $0
    }(UIButton(type: .custom))
    
    /// 拍照按钮
    lazy var takeshotButton: TakeshotButton = {
        $0.takeshotShouldCapture = { [weak self] in
            guard let self = self else { return }
            if self.cameraManager.cameraIsSetup == false {
                return
            }
            if (self.sourceType == 1 || self.sourceType == 3) {
                self.capturePicture()
            }
        }
        $0.takeshotShouldRecordMovie = { [weak self] isStart in
            guard let self = self else { return }
            if self.cameraManager.cameraIsSetup == false {
                return
            }
            if (self.sourceType == 2 || self.sourceType == 3) {
                self.recordMovie(isStart)
            }
        }
        $0.takeshotUpdateRecordMovie = { [weak self] countdown in
            guard let self = self else { return }
            if self.cameraManager.cameraIsSetup == false {
                return
            }
            if (self.sourceType == 2 || self.sourceType == 3) {
                if (countdown < 10) {
                    self.tipLabel.text = "00:00:0" + String(countdown)
                } else {
                    self.tipLabel.text = "00:00:" + String(countdown)
                }
            }
        }
        $0.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview($0)
        return $0
    }(TakeshotButton(frame: .zero, sourceType: sourceType))
    
    /// 中间提示（包括录像时间提示）
    lazy var tipLabel: UILabel = {
        $0.text = "轻触拍照，按住摄像"
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .white
        $0.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview($0)
        return $0
    }(UILabel())
        
    lazy var backdropView: UIVisualEffectView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview($0)
        return $0
    }(UIVisualEffectView(effect: UIBlurEffect(style: .dark)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        setupConstraints()
        setupCamera()
        performHideTip(true, true)
    }
    
    /// 初始化布局
    func setupConstraints() {
        NSLayoutConstraint.activate([
            previewLayer.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            flashModeBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 4.fixed),
            flashModeBar.heightAnchor.constraint(equalToConstant: 48.fixed),
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
            tipLabel.bottomAnchor.constraint(equalTo: takeshotButton.topAnchor, constant: -42.fixed),
            tipLabel.centerXAnchor.constraint(equalTo: takeshotButton.centerXAnchor),
            backdropView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            backdropView.heightAnchor.constraint(equalTo: self.view.heightAnchor),
        ])
    }
    
    /// 初始化相机
    func setupCamera() {
        cameraManager.cameraDelegate = self
        cameraManager.shouldKeepViewAtOrientationChanges = true
        cameraManager.writeFilesToPhoneLibrary = false
        cameraManager.animateShutter = true
        if (faceType == 1) {
            cameraManager.cameraDevice = .back
        } else {
            cameraManager.cameraDevice = .front
        }
        ///  默认必须是视频
        cameraManager.cameraOutputMode = .videoWithMic
        if (sourceType == 1) {
            tipLabel.text = "点击拍照"
        }
        cameraManager.cameraOutputQuality = .high
        cameraManager.shouldFlipFrontCameraImage = true
        cameraManager.videoStabilisationMode = .standard
        cameraManager.showAccessPermissionPopupAutomatically = false
        cameraManager.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            guard let self = self else { return }
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (_) -> Void in }))
            self.present(alertController, animated: true, completion: nil)
        }

        cameraManager.askUserForCameraPermission { [weak self] permissionGranted in
            guard let self = self else { return }
            if permissionGranted {
                self.cameraManager.addPreviewLayerToView(self.previewLayer, newCameraOutputMode: self.cameraManager.cameraOutputMode)
                var snapshotView: UIView? = nil
                if let v = self.previewLayer.snapshotView(afterScreenUpdates: true) {
                    snapshotView = v
                    self.view.insertSubview(v, belowSubview: self.takeshotButton)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                    UIView.animate(withDuration: 0.25) {
                        self.backdropView.alpha = 0
                        snapshotView?.alpha = 0
                    } completion: { result in
                        snapshotView?.removeFromSuperview()
                        self.backdropView.removeFromSuperview()
                    }
                })
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
    func performHideTip(_ hidden: Bool, _ delay: Bool) {
        if (delay) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                if (self.takeshotButton.timer != nil || self.takeshotButton.countdown != 0) {
                    return
                }
                self.hideTip(hidden)
            })
        } else {
            hideTip(hidden)
        }
    }
    
    @objc func hideTip(_ hidden: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.tipLabel.alpha = hidden ? 0 : 1;
        }
    }
    
    /// 点击切换闪光灯
    @objc func onSwitchFlashPressed() {
        UIView.animate(withDuration: 0.25) {
            self.flashModeBar.alpha = self.flashModeBar.alpha == 1 ? 0 : 1;
        }
    }
    
    //切换前后摄像头
    @objc func onSwitchCameraPressed(sender: UITapGestureRecognizer) {
        cameraManager.cameraDevice = cameraManager.cameraDevice == CameraDevice.front ? CameraDevice.back : CameraDevice.front
    }
    
    @objc func onBackPressed(sender: UIButton) {
        takeshotButton.invalidTimer()
        cameraManager.destroy()
        self.flutterResult!(nil)
        self.dismiss(animated: true)
    }
    
    func capturePicture() {
        if (cameraManager.captureLock) {
            return
        }
        cameraManager.captureLock = true
        var snapshotView: UIView? = nil
        if let v = self.previewLayer.snapshotView(afterScreenUpdates: true) {
            snapshotView = v
            self.view.insertSubview(v, belowSubview: self.flashButton)
        }
        if (self.cameraManager.cameraOutputMode != CameraOutputMode.stillImage) {
            self.cameraManager.cameraOutputMode = CameraOutputMode.stillImage;
        }
        /// 需要跳过一下动画时间，不然获取照片会黑掉
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
            self.cameraManager.capturePictureDataWithCompletion { [weak self] result in
                self?.cameraManager.captureLock = false
                guard let self = self else { return }
                switch result {
                case .failure:
                    snapshotView?.removeFromSuperview()
                    self.cameraManager.showErrorBlock("Error occurred", "Cannot save picture.")
                case .success(let content):
                    guard let image = content.asImage else {
                        snapshotView?.removeFromSuperview()
                        return
                    }
                    if (image.imageOrientation != .up) {
                        UIGraphicsBeginImageContext(image.size)
                        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
                        let drawImg = UIGraphicsGetImageFromCurrentImageContext()!
                        UIGraphicsEndImageContext()
                        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
                        do {
                            // 1024 * 1024 = 1kb * 500 = 500k max = 500kb
                            let compressData = self.compressImage(image: drawImg, maxLength: 1024 * 1024 * 500)
                            let compressImg = UIImage(data: compressData)
                            // 压缩失败用原来的
                            try (compressImg ?? drawImg).pngData()?.write(to: URL(fileURLWithPath: path))
                            self.flutterResult!([
                                "width": Int(compressImg?.size.width ?? drawImg.size.width),
                                "height": Int(compressImg?.size.height ?? drawImg.size.height),
                                "type": 1,
                                "origin_file_path": path,
                                "thumbnail_file_path": "",
                            ])
                            DispatchQueue.main.asyncAfter(deadline: .now() + self.delayDismissTime, execute: {
                                self.dismiss(animated: false)
                            })
                        } catch {
                            snapshotView?.removeFromSuperview()
                            print("写入文件失败")
                        }
                    } else {
                        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
                        do {
                            // 1024 * 1024 = 1kb * 500 = 500k max = 500kb
                            let compressData = self.compressImage(image: image, maxLength: 1024 * 1024 * 500)
                            let compressImg = UIImage(data: compressData)
                            // 压缩失败用原来的
                            try (compressImg ?? image).pngData()?.write(to: URL(fileURLWithPath: path))
                            self.flutterResult!([
                                "width": Int(compressImg?.size.width ?? image.size.width),
                                "height": Int(compressImg?.size.height ?? image.size.height),
                                "type": 1,
                                "origin_file_path": path,
                                "thumbnail_file_path": "",
                            ])
                            DispatchQueue.main.asyncAfter(deadline: .now() + self.delayDismissTime, execute: {
                                self.dismiss(animated: false)
                            })
                        } catch {
                            snapshotView?.removeFromSuperview()
                            print("写入文件失败")
                        }
                    }
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
        })
    }
    
    func compressImage(image: UIImage ,maxLength: Int) -> Data {
        // let tempMaxLength: Int = maxLength / 8
        let tempMaxLength: Int = maxLength
        var compression: CGFloat = 1
        guard var data = image.jpegData(compressionQuality: compression), data.count > tempMaxLength else { return image.jpegData(compressionQuality: compression)! }

        // 压缩大小
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _ in 0..<6 {
            compression = (max + min) / 2
            data = image.jpegData(compressionQuality: compression)!
            if CGFloat(data.count) < CGFloat(tempMaxLength) * 0.9 {
                min = compression
            } else if data.count > tempMaxLength {
                max = compression
            } else {
                break
            }
        }
        var resultImage: UIImage = UIImage(data: data)!
        if data.count < tempMaxLength { return data }

        // 压缩大小
        var lastDataLength: Int = 0
        while data.count > tempMaxLength && data.count != lastDataLength {
            lastDataLength = data.count
            let ratio: CGFloat = CGFloat(tempMaxLength) / CGFloat(data.count)
            print("Ratio =", ratio)
            let size: CGSize = CGSize(width: resultImage.size.width * ratio, height: resultImage.size.height * ratio)
            UIGraphicsBeginImageContext(size)
            resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            resultImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            data = resultImage.jpegData(compressionQuality: 0.1)!
        }
        return data
    }
    
    func recordMovie(_ isStart: Bool) {
        if isStart {
            if (self.cameraManager.cameraOutputMode != CameraOutputMode.videoWithMic) {
                self.cameraManager.cameraOutputMode = CameraOutputMode.videoWithMic
            }
            performHideTip(false, false)
            cameraManager.startRecordingVideo()
        } else {
            performHideTip(true, false)
            cameraManager.stopVideoRecording { [weak self] (videoURL, error) -> Void in
                guard let self = self else { return }
                if error != nil {
                    self.cameraManager.showErrorBlock("Error occurred", "Cannot save video.")
                } else {
                    let image = self.thumbnailImageForVideo(videoURL: videoURL!)
                    if (image != nil) {
                        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
                        let duration = self.totalSecondForVideo(videoURL: videoURL!)
                        if (duration == 0) {
                            return
                        }
                        do {
                            try image!.pngData()?.write(to: URL(fileURLWithPath: path))
                            self.flutterResult!([
                                "width": Int(image!.size.width),
                                "height": Int(image!.size.height),
                                "type": 2,
                                "origin_file_path": videoURL!.path,
                                "thumbnail_file_path": path,
                                "duration": duration,
                            ])
                            DispatchQueue.main.asyncAfter(deadline: .now() + self.delayDismissTime, execute: {
                                self.dismiss(animated: false)
                            })
                        } catch {
                            print("写入文件失败")
                        }
                    }
                }
            }
        }
    }
    
    func totalSecondForVideo(videoURL: URL) -> Int {
        let aset = AVURLAsset(url: videoURL, options: nil)
        let time : CMTime = aset.duration
        return Int(floor(CMTimeGetSeconds(time)))
    }
    
    //获取视频封面
    func thumbnailImageForVideo(videoURL: URL) -> UIImage? {
        let aset = AVURLAsset(url: videoURL, options: nil)
        let assetImg = AVAssetImageGenerator(asset: aset)
        assetImg.appliesPreferredTrackTransform = true
        assetImg.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
        do{
            let cgimgref = try assetImg.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 50), actualTime: nil)
            let cover = UIImage(cgImage: cgimgref)
            /// 视频封面压缩了
            let compressData = compressImage(image: cover, maxLength: 1024 * 1024 * 500)
            return UIImage(data: compressData)
        }catch{
            return nil
        }
    }
    
//    func jumpToVideo(outputFileURL: URL) {
//        let videoVC = VideoViewController.init()
//        videoVC.videoViewBackDelegate = self
//        videoVC.videoURL = outputFileURL
//        videoVC.flutterResult = flutterResult
//        videoVC.modalPresentationStyle = .fullScreen
//        self.present(videoVC, animated: true)
//    }
    
    // MARK: - Delegate
    
    func isRecordEndTime(outputFileURL: URL) {
        print(outputFileURL)
    }
    
    deinit {
        print("如果这行没有执行的话，要注意看下CameraManager.destory有没有执行，更重要的是要去关心是哪里被内存引用问题，否则cameraManager只是被移除，依然占用内存")
        print("CameraViewController deinit")
        cameraManager.destroy()
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
