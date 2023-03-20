//
//  VideoViewController.swift
//  custom_camera
//
//  Created by 吴文炜 on 2022/11/7.
//

import UIKit
import AVKit

protocol VideoViewBackDelegate {
    func videoViewCallBack()
}

class VideoViewController: UIViewController {

    var playBtn: UIButton?
    
    var videoURL : URL?
    
    var avplayer : AVPlayer?
    
    var videoViewBackDelegate : VideoViewBackDelegate?
    
    var flutterResult : FlutterResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        initPlayer()
        
        let closeBtn = UIButton.init(type: .custom)
        closeBtn.frame = CGRect(x: 16*RATE, y: SCREEN_HEIGHT - 50*RATE - safeAreaBottom(), width: 60*RATE, height: 30*RATE)
        closeBtn.setTitle("重拍", for: .normal)
        closeBtn.setTitleColor(UIColor.white, for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17*RATE)
        closeBtn.contentHorizontalAlignment = .left
        closeBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        self.view.addSubview(closeBtn)
        
        playBtn = UIButton.init(type: .custom)
        playBtn?.frame = CGRect(x: (SCREEN_WIDE - 30*RATE)/2, y:  SCREEN_HEIGHT - 50*RATE - safeAreaBottom(), width: 30*RATE, height: 30*RATE)
        playBtn?.setImage(sourceImage(name: "ic_play"), for: .normal)
        playBtn?.isSelected = false
        playBtn?.addTarget(self, action: #selector(playerAction), for: .touchUpInside)
        self.view.addSubview(playBtn!)
        
        let useBtn = UIButton.init(type: .custom)
        useBtn.frame = CGRect(x: SCREEN_WIDE - 96*RATE, y: SCREEN_HEIGHT - 50*RATE - safeAreaBottom(), width: 80*RATE, height: 30*RATE)
        useBtn.setTitle("使用视频", for: .normal)
        useBtn.setTitleColor(UIColor.white, for: .normal)
        useBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17*RATE)
        useBtn.contentHorizontalAlignment = .right
        useBtn.addTarget(self, action: #selector(useAction), for: .touchUpInside)
        self.view.addSubview(useBtn)
        
        avplayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: DispatchQueue.main) { [weak self](time) in
            //当前正在播放的时间
            let loadTime = CMTimeGetSeconds(time)
            //视频总时间
            if (self != nil) {
                if (self!.avplayer!.currentItem != nil) {
                    let totalTime = CMTimeGetSeconds((self?.avplayer?.currentItem?.duration)!)
                    if (loadTime >= totalTime) {
                        self!.avplayer?.seek(to: CMTime(seconds: 0.0, preferredTimescale: 1000000))
                        self!.avplayer?.pause()
                        self!.playBtn?.setImage(sourceImage(name: "ic_play"), for: .normal)
                        self!.playBtn?.isSelected = false
                    }
                }
            }
        }
    }
    
    func initPlayer() {
        guard let validVideoUrl = videoURL else {
            return
        }
        //创建媒体资源管理对象
        let playerItem = AVPlayerItem(url: validVideoUrl)
        //创建ACplayer：负责视频播放
        avplayer = AVPlayer(playerItem: playerItem)
        avplayer?.rate = 1.0
        //创建显示视频的图层
        let playerLayer = AVPlayerLayer.init(player: avplayer)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.masksToBounds = true
        playerLayer.frame = CGRect(x: 0, y: safeAreaTop(), width: SCREEN_WIDE, height: SCREEN_HEIGHT - safeAreaBottom() - 50*RATE - safeAreaTop())
        self.view.layer.addSublayer(playerLayer)
        
        avplayer?.pause()
    }
    
    @objc func closeAction(sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @objc func playerAction(sender: UIButton) {
        if (sender.isSelected) {
            avplayer?.pause()
            sender.setImage(sourceImage(name: "ic_play"), for: .normal)
        } else {
            avplayer?.play()
            sender.setImage(sourceImage(name: "ic_stop"), for: .normal)
        }
        sender.isSelected = !sender.isSelected
    }
    
    @objc func useAction(sender: UIButton) {
        let image = thumbnailImageForVideo(videoURL: videoURL!)
        if (image != nil) {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
            let duration = totalSecondForVideo(videoURL: videoURL!)
            do {
                try image!.pngData()?.write(to: URL(fileURLWithPath: path))
                    flutterResult!([
                        "width": Int(image!.size.width),
                        "height": Int(image!.size.height),
                        "type": 2,
                        "origin_file_path": videoURL!.path,
                        "thumbnail_file_path": path,
                        "duration": duration,
                    ])
            } catch {
                print("写入文件失败")
            }
        }
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoURL!.path)) {
            UISaveVideoAtPathToSavedPhotosAlbum(videoURL!.path, self, #selector(save(path:didFinishSavingWithError:contextInfo:)), nil);//保存视频到相簿
        }
        self.dismiss(animated: false)
        self.videoViewBackDelegate?.videoViewCallBack()
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
                return UIImage(cgImage: cgimgref)
            }catch{
                return nil
            }
        }
    
    @objc func save(path: String, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
        if (didFinishSavingWithError != nil) {
            print("保存相册失败")
        }
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

