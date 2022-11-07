//
//  CameraTabBar.swift
//  custom_camera
//
//  Created by 吴文炜 on 2022/11/4.
//

import UIKit

typealias CameraTabBarBlock = (_ index: Int) -> Void

class CameraTabBar: UIView {
    
    var pictureBtn : UIButton?
    
    var videoBtn : UIButton?
    
    var cameraTabBarBlock : CameraTabBarBlock?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        pictureBtn = UIButton.init(type: .custom)
        pictureBtn?.frame = CGRect(x: 0, y: 0, width: frame.size.width/2, height: frame.size.height)
        pictureBtn?.setTitle("图片", for: .normal)
        pictureBtn?.setTitleColor(hexColor(hex: 0xFFE06A), for: .normal)
        pictureBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 15*RATE)
        pictureBtn?.addTarget(self, action: #selector(pictureAction), for: .touchUpInside)
        self.addSubview(pictureBtn!)
        
        videoBtn = UIButton.init(type: .custom)
        videoBtn?.frame = CGRect(x: frame.size.width/2, y: 0, width: frame.size.width/2, height: frame.size.height)
        videoBtn?.setTitle("视频", for: .normal)
        videoBtn?.setTitleColor(hexColor(hex: 0x90FFFFFF), for: .normal)
        videoBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 15*RATE)
        videoBtn?.addTarget(self, action: #selector(videoAction), for: .touchUpInside)
        self.addSubview(videoBtn!)
        
    }
    
    @objc func pictureAction() {
        cameraTabBarBlock!(1)
    }
    
    @objc func videoAction() {
        cameraTabBarBlock!(2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
