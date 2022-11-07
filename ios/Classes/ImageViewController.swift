//
//  ImageViewController.swift
//  custom_camera
//
//  Created by 吴文炜 on 2022/10/28.
//

import UIKit
import Flutter

protocol ImageViewBackDelegate {
    func imageViewCallBack()
}

class ImageViewController: UIViewController {

    var image : UIImage?
    
    var imageView : UIImageView?
    
    var imageViewBackDelegate : ImageViewBackDelegate?
    
    var flutterResult : FlutterResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
    }
    
    func initViews() {
        
        self.view.backgroundColor = UIColor.black
        
        imageView = UIImageView.init(frame: CGRect(x: 0, y: safeAreaTop(), width: SCREEN_WIDE, height: SCREEN_HEIGHT - safeAreaBottom() - 50*RATE - safeAreaTop()))
        imageView?.contentMode = .scaleAspectFit
        imageView?.layer.masksToBounds = true
        self.view.addSubview(imageView!)
        
        guard let validImage = image else {
            return
        }
        imageView?.image = validImage
        
        let closeBtn = UIButton.init(type: .custom)
        closeBtn.frame = CGRect(x: 16*RATE, y: SCREEN_HEIGHT - 50*RATE - safeAreaBottom(), width: 60*RATE, height: 30*RATE)
        closeBtn.setTitle("重拍", for: .normal)
        closeBtn.setTitleColor(UIColor.white, for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17*RATE)
        closeBtn.contentHorizontalAlignment = .left
        closeBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        self.view.addSubview(closeBtn)
        
        let useBtn = UIButton.init(type: .custom)
        useBtn.frame = CGRect(x: SCREEN_WIDE - 96*RATE, y: SCREEN_HEIGHT - 50*RATE - safeAreaBottom(), width: 80*RATE, height: 30*RATE)
        useBtn.setTitle("使用照片", for: .normal)
        useBtn.setTitleColor(UIColor.white, for: .normal)
        useBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17*RATE)
        useBtn.contentHorizontalAlignment = .right
        useBtn.addTarget(self, action: #selector(useAction), for: .touchUpInside)
        self.view.addSubview(useBtn)
        
    }
    
    @objc func closeAction(sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @objc func useAction(sender: UIButton) {
        if (image!.imageOrientation != .up) {
            UIGraphicsBeginImageContext(image!.size)
            image!.draw(in: CGRect(x: 0, y: 0, width: image!.size.width, height: image!.size.height))
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
        do {
            try image!.pngData()?.write(to: URL(fileURLWithPath: path))
                flutterResult!([
                    "width": Int(image!.size.width),
                    "height": Int(image!.size.height),
                    "type": 1,
                    "origin_file_path": path,
                    "thumbnail_file_path": "",
                ])
        } catch {
            print("写入文件失败")
        }
        UIImageWriteToSavedPhotosAlbum(image!, self, #selector(save(image:didFinishSavingWithError:contextInfo:)), nil)
        self.dismiss(animated: false)
        self.imageViewBackDelegate?.imageViewCallBack()
    }
    
    @objc func save(image:UIImage, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
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
