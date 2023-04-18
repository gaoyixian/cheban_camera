//
//  NomalTools.swift
//  custom_camera
//
//  Created by 吴文炜 on 2022/10/28.
//

import Foundation

import UIKit

let SCREEN_WIDE : CGFloat = UIScreen.main.bounds.width

let SCREEN_HEIGHT : CGFloat = UIScreen.main.bounds.height

let RATE : CGFloat = SCREEN_WIDE / 375.0

var bundleName = ""

func safeAreaTop() -> CGFloat {
    var statusBarHeight: CGFloat = 0
    if #available(iOS 13.0, *) {
        let scene = UIApplication.shared.connectedScenes.first
        guard let windowScene = scene as? UIWindowScene else { return 0 }
        guard let statusBarManager = windowScene.statusBarManager else { return 0 }
        statusBarHeight = statusBarManager.statusBarFrame.height
    } else {
        statusBarHeight = UIApplication.shared.statusBarFrame.height
    }
    return statusBarHeight
}

func safeAreaBottom() -> CGFloat {
    if #available(iOS 13.0, *) {
        let scene = UIApplication.shared.connectedScenes.first
        guard let windowScene = scene as? UIWindowScene else { return 0 }
        guard let window = windowScene.windows.first else { return 0 }
        return window.safeAreaInsets.bottom
    } else if #available(iOS 11.0, *) {
        guard let window = UIApplication.shared.windows.first else { return 0 }
        return window.safeAreaInsets.bottom
    }
    return 0;
}

/// 根据色值获取颜色
/// - Parameter hex: 色值
/// - Returns: 颜色
func hexColor(hex: NSInteger) -> UIColor {
    let red: CGFloat = ((CGFloat)((hex >> 16) & 0xFF)) / ((CGFloat)(0xFF))
    let green: CGFloat = ((CGFloat)((hex >> 8) & 0xFF)) / ((CGFloat)(0xFF))
    let blue: CGFloat = ((CGFloat)((hex >> 0) & 0xFF)) / ((CGFloat)(0xFF))
    let alpha: CGFloat = hex > 0xFFFFFF ? ((CGFloat)((hex >> 24) & 0xFF)) / ((CGFloat)(0xFF)) : 1
    return UIColor.init(red: red, green: green, blue: blue, alpha: alpha);
}

func sourceImage(name: String) ->  UIImage{
    let bundle = Bundle(for: CameraViewController.self)
    return UIImage.init(named: name, in: bundle, compatibleWith: nil)!
}

extension Double {
    var fixed: Double {
        return self * RATE;
    }
}

extension Int {
    var fixed: Double {
        return Double(self) * RATE;
    }
}
