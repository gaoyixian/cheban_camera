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
    var flashModeImageView: UIImageView?
    var cameraTabBar: CameraTabBar?
    var cameraView: UIView?
    var askForPermissionsLabel: UILabel?
    var takeBarView: UIView?
    var takeView : UIView?
    var isRecording = false
    
    var countDownLbl: UILabel?
    var countTimer : Timer?
    var totalCount : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraManager()
        initViews()
    }
    
    func initViews() {
        self.view.backgroundColor = UIColor.black
        //顶部区域
        let headerView = UIView.init(frame: CGRect(x: 0, y: safeAreaTop(), width: SCREEN_WIDE, height: 30*RATE))
        self.view.addSubview(headerView)
        
        flashModeImageView = UIImageView.init(frame: CGRect(x: 15*RATE, y: 0, width: 24*RATE, height: headerView.frame.size.height))
        flashModeImageView?.image = sourceImage(name: "flash_off")
        flashModeImageView?.isUserInteractionEnabled = true
        flashModeImageView?.contentMode = .scaleAspectFit
        headerView.addSubview(flashModeImageView!)
        
        countDownLbl = UILabel.init(frame: CGRect(x: SCREEN_WIDE - 95*RATE, y: 0, width: 80*RATE, height: 24*RATE))
        countDownLbl?.textColor = UIColor.white
        countDownLbl?.font = UIFont.systemFont(ofSize: 15*RATE)
        countDownLbl?.text = "00:00:00"
        countDownLbl?.isHidden = true
        countDownLbl?.textAlignment = .center
        countDownLbl?.backgroundColor = hexColor(hex: 0xFF7474)
        countDownLbl?.layer.cornerRadius = 4*RATE
        countDownLbl?.layer.masksToBounds = true
        headerView.addSubview(countDownLbl!)
        
        if cameraManager.hasFlash {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changeFlashMode))
            flashModeImageView?.addGestureRecognizer(tapGesture)
        }
        
//        outputImageView = UIImageView.init(frame: CGRect(x: flashModeImageView!.frame.origin.x + 60, y: 0, width: 30, height: 60))
//        outputImageView?.image = UIImage(named: "output_video")
//        outputImageView?.isUserInteractionEnabled = true
//        outputImageView?.contentMode = .scaleAspectFit
//        headerView.addSubview(outputImageView!)
//        let outputGesture = UITapGestureRecognizer(target: self, action: #selector(outputModeButtonTapped))
//        outputImageView?.addGestureRecognizer(outputGesture)
        
        //底部区域
        let footerView = UIView.init(frame: CGRect(x: 0, y: SCREEN_HEIGHT - safeAreaBottom() - 100*RATE, width: SCREEN_WIDE, height: 100*RATE))
        self.view.addSubview(footerView)
        
        //拍照/录像按钮
        takeBarView = UIView.init(frame: CGRect(x: (SCREEN_WIDE - 60*RATE)/2, y: 20*RATE, width: 60*RATE, height: 60*RATE))
        takeBarView?.layer.borderWidth = 6*RATE
        takeBarView?.layer.borderColor = UIColor.white.cgColor
        takeBarView?.layer.cornerRadius = 30*RATE
        takeBarView?.layer.masksToBounds = true
        footerView.addSubview(takeBarView!)
        
        takeView = UIView.init(frame: CGRect(x: 0, y: 0, width: 34*RATE, height: 34*RATE))
        takeView?.center = CGPoint(x: takeBarView!.frame.size.width/2, y: takeBarView!.frame.size.height/2)
        if (sourceType == 2) {
            takeView?.backgroundColor = hexColor(hex: 0xFF4747)
        } else {
            takeView?.backgroundColor = UIColor.white
        }
        takeView?.layer.cornerRadius = 17*RATE
        takeView?.layer.masksToBounds = true
        takeBarView?.addSubview(takeView!)
        
        let cameraButton = UIButton.init(type: .custom)
        cameraButton.frame = CGRect(x: 0, y: 0, width: takeBarView!.frame.size.width, height: takeBarView!.frame.size.height)
        cameraButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        takeBarView?.addSubview(cameraButton)
        
        
        //取消按钮
        let cancelImageView = UIImageView.init(frame: CGRect(x: (SCREEN_WIDE / 2 - 30*RATE) / 2 - 25*RATE, y: 25*RATE, width: 50*RATE, height: 50*RATE))
        cancelImageView.image = sourceImage(name: "ic_close")
        cancelImageView.isUserInteractionEnabled = true
        footerView.addSubview(cancelImageView)
        let backGesture = UITapGestureRecognizer(target: self, action: #selector(backAction))
        cancelImageView.addGestureRecognizer(backGesture)
        
        //切换前后摄像头按钮
        let switchImageView = UIImageView.init(frame: CGRect(x: (SCREEN_WIDE / 2 - 30*RATE) / 2 + 5*RATE + SCREEN_WIDE / 2, y: 25*RATE, width: 50*RATE, height: 50*RATE))
        switchImageView.image = sourceImage(name: "switch_camera")
        switchImageView.isUserInteractionEnabled = true
        footerView.addSubview(switchImageView)
        let switchGesture = UITapGestureRecognizer(target: self, action: #selector(changeCameraDevice))
        switchImageView.addGestureRecognizer(switchGesture)
        
        //预览界面
        cameraView = UIView.init(frame: CGRect(x: 0, y: headerView.frame.origin.y+headerView.frame.size.height, width: SCREEN_WIDE, height: SCREEN_HEIGHT - headerView.frame.origin.y - headerView.frame.size.height - footerView.frame.size.height - safeAreaBottom()))
        cameraView?.backgroundColor = UIColor.black
        self.view.addSubview(cameraView!)
        
        //切换拍照/录像
        if (sourceType == 3) {
            cameraTabBar = CameraTabBar.init(frame: CGRect(x: (SCREEN_WIDE - 100*RATE) / 2, y: cameraView!.frame.size.height + cameraView!.frame.origin.y - 50*RATE, width: 100*RATE, height: 50*RATE))
            self.view.addSubview(cameraTabBar!)
            cameraTabBar!.cameraTabBarBlock = { index in
                self.outputModeButtonTapped(index: index)
            }
        }
        askForPermissionsLabel = UILabel.init(frame: CGRect(x: cameraView!.frame.origin.x, y: cameraView!.frame.origin.y, width: cameraView!.frame.size.width, height: cameraView!.frame.size.height))
        askForPermissionsLabel?.text = "点击此处打开相机"
        askForPermissionsLabel?.textColor = UIColor.white
        askForPermissionsLabel?.textAlignment = .center
        askForPermissionsLabel?.isHidden = true
        askForPermissionsLabel?.isUserInteractionEnabled = true
        askForPermissionsLabel?.font = UIFont.systemFont(ofSize: 20)
        self.view.addSubview(askForPermissionsLabel!)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(askForCameraPermissions))
        askForPermissionsLabel?.addGestureRecognizer(tapGesture)
        
        let currentCameraState = cameraManager.currentCameraStatus()
        if currentCameraState == .notDetermined {
            askForPermissionsLabel?.isHidden = false
        } else if currentCameraState == .ready {
            addCameraToView()
        } else {
            askForPermissionsLabel?.isHidden = false
        }
    }
    
    //相机配置设置
    func setupCameraManager()  {
        cameraManager.cameraDelegate = self
        cameraManager.shouldEnableExposure = true
        cameraManager.animateCameraDeviceChange = true
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
    }
    
    //相机添加到view
    func addCameraToView() {
        cameraManager.addPreviewLayerToView(cameraView!, newCameraOutputMode: cameraManager.cameraOutputMode)
        cameraManager.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (_) -> Void in }))
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    //权限申请
    @objc func askForCameraPermissions(sender: UITapGestureRecognizer) {
        cameraManager.askUserForCameraPermission { permissionGranted in
            if permissionGranted {
                self.askForPermissionsLabel?.isHidden = true
                self.addCameraToView()
            } else {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
    //切换闪光灯
    @objc func changeFlashMode(sender: UITapGestureRecognizer) {
        switch cameraManager.changeFlashMode() {
            case .off:
                flashModeImageView?.image = sourceImage(name: "flash_off")
            case .on:
                flashModeImageView?.image = sourceImage(name: "flash_on")
            case .auto:
                flashModeImageView?.image = sourceImage(name: "flash_auto")
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
            cameraTabBar?.pictureBtn?.setTitleColor(UIColor.white, for: .normal)
            cameraTabBar?.videoBtn?.setTitleColor(hexColor(hex: 0x90FFFFFF), for: .normal)
            updateTakeView(color: UIColor.white, width: 34*RATE, radius: 17*RATE)
            case .videoWithMic, .videoOnly:
            cameraTabBar?.pictureBtn?.setTitleColor(hexColor(hex: 0x90FFFFFF), for: .normal)
            cameraTabBar?.videoBtn?.setTitleColor(UIColor.white, for: .normal)
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
                    let validVC = ImageViewController.init()
                    let capturedData = content.asData
                    let capturedImage = UIImage(data: capturedData!)!
                    validVC.image = capturedImage
                    validVC.flutterResult = self.flutterResult
                    validVC.modalPresentationStyle = .fullScreen
                    validVC.imageViewBackDelegate = self
                    self.present(validVC, animated: true)
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
                    countDownLbl?.isHidden = true
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
        countDownLbl?.isHidden = true
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
        countDownLbl?.isHidden = false
        totalCount = 0
        countTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.countDownAction), userInfo: nil, repeats: true)
        countTimer!.fire()
    }
    
    @objc func countDownAction(sender: Timer) {
        if totalCount == 15 {
            countDownLbl?.text = "00:00:15"
        } else {
            totalCount += 1
            if (totalCount < 10) {
                countDownLbl?.text = "00:00:0" + String(totalCount)
            } else {
                countDownLbl?.text = "00:00:" + String(totalCount)
            }
        }
    }
    
    func closeTimer() {
        countTimer?.invalidate()
        countTimer = nil
    }
    
    func updateTakeView(color: UIColor, width: CGFloat, radius: CGFloat) {
        takeView?.backgroundColor = color
        takeView?.frame.size = CGSize(width: width, height: width)
        takeView?.center = CGPoint(x: takeBarView!.frame.size.width/2, y: takeBarView!.frame.size.height/2)
        takeView?.layer.cornerRadius = radius
        takeView?.layer.masksToBounds = true
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
