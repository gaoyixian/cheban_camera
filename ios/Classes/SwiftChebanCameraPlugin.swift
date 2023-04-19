import Flutter
import UIKit
import AVFoundation

//UIImagePickerControllerDelegate, UINavigationControllerDelegate
public class SwiftChebanCameraPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cheban_camera", binaryMessenger: registrar.messenger())
    let instance = SwiftChebanCameraPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if (call.method == "takePhotoAndVideo") {
          let dict = call.arguments as! NSDictionary
          let sourceType = dict["source_type"] as! Int
          let faceType = dict["face_type"] as! Int
          
          var cameraVC = CameraViewController.init()
          cameraVC.flutterResult = result
          cameraVC.sourceType = sourceType
          cameraVC.faceType = faceType
          cameraVC.modalPresentationStyle = .fullScreen
          UIApplication.shared.keyWindow!.rootViewController!.present(cameraVC, animated: true)
//
//
//          if (isAvailable()) {
//              let mediaTypeArr: [String]? = UIImagePickerController.availableMediaTypes(for: .camera)
//              if (mediaTypeArr != nil) {
//                  let sourceArray = NSMutableArray.init()
//                  for item in mediaTypeArr! {
//                      if (item == "public.image" && sourceType != 2) {
//                          sourceArray.add(item)
//                      } else if (item == "public.movie" && sourceType != 1) {
//                          sourceArray.add(item)
//                      }
//                  }
//                  if (sourceArray.count > 0) {
//                      let pickerControl = UIImagePickerController()
//                      pickerControl.sourceType = .camera
//                      pickerControl.mediaTypes = sourceArray as! [String]
//                      if (faceType == 2) {
//                          pickerControl.cameraDevice = .front
//                      }
//                      pickerControl.delegate = self
//                      pickerControl.videoMaximumDuration = 15
//                      pickerControl.videoQuality = .typeHigh
//                      UIApplication.shared.keyWindow!.rootViewController!.present(pickerControl, animated: true)
//                  }
//              }
//          }
      }
  }
    
//    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        print("拿到数据")
//        let mediaType = info[.mediaType] as! String
//        if (mediaType  == "public.image") {
//            var image = info[.originalImage] as! UIImage
//            if (image.imageOrientation != .up) {
//                UIGraphicsBeginImageContext(image.size)
//                image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
//                image = UIGraphicsGetImageFromCurrentImageContext()!
//                UIGraphicsEndImageContext()
//            }
//            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
//            do {
//                try image.pngData()?.write(to: URL(fileURLWithPath: path))
////                flutterResult!([
////                    "width": Int(image.size.width),
////                    "height": Int(image.size.height),
////                    "type": 1,
////                    "origin_file_path": path,
////                    "thumbnail_file_path": "",
////                ])
//            } catch {
//                print("写入文件失败")
//            }
//            UIImageWriteToSavedPhotosAlbum(image, self, #selector(save(image:didFinishSavingWithError:contextInfo:)), nil)
//        } else {
//            let videoUrl = info[.mediaURL] as! URL
//            let image = thumbnailImageForVideo(videoURL: videoUrl)
//            if (image != nil) {
//                let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
//                do {
//                    try image!.pngData()?.write(to: URL(fileURLWithPath: path))
////                    flutterResult!([
////                        "width": Int(image!.size.width),
////                        "height": Int(image!.size.height),
////                        "type": 2,
////                        "origin_file_path": videoUrl.path,
////                        "thumbnail_file_path": path,
////                    ])
//                } catch {
//                    print("写入文件失败")
//                }
//            }
//
//            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoUrl.path)) {
//                UISaveVideoAtPathToSavedPhotosAlbum(videoUrl.path, self, #selector(save(path:didFinishSavingWithError:contextInfo:)), nil);//保存视频到相簿
//            }
//        }
//        picker.dismiss(animated: true)
//    }
//
//    @objc func save(image:UIImage, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
//        if (didFinishSavingWithError != nil) {
//            print("保存相册失败")
//        }
//    }
//
//    @objc func save(path: String, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
//        if (didFinishSavingWithError != nil) {
//            print("保存相册失败")
//        }
//    }
//
//    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        picker.dismiss(animated: true)
//    }
//
//    //当前相机是否可用
//    func isAvailable() -> Bool {
//        return UIImagePickerController.isSourceTypeAvailable(.camera)
//    }
//
//    //获取视频封面
//    func thumbnailImageForVideo(videoURL: URL) -> UIImage? {
//            let aset = AVURLAsset(url: videoURL, options: nil)
//            let assetImg = AVAssetImageGenerator(asset: aset)
//            assetImg.appliesPreferredTrackTransform = true
//            assetImg.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
//            do{
//                let cgimgref = try assetImg.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 50), actualTime: nil)
//                return UIImage(cgImage: cgimgref)
//            }catch{
//                return nil
//            }
//        }
//
//
  
    
    
    
    
    
//    - (UIViewController *)topViewController {
//    #pragma clang diagnostic push
//    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
//      // TODO(stuartmorgan) Provide a non-deprecated codepath. See
//      // https://github.com/flutter/flutter/issues/104117
//      return [self topViewControllerFromViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
//    #pragma clang diagnostic pop
//    }
//
//    /**
//     * This method recursively iterate through the view hierarchy
//     * to return the top most view controller.
//     *
//     * It supports the following scenarios:
//     *
//     * - The view controller is presenting another view.
//     * - The view controller is a UINavigationController.
//     * - The view controller is a UITabBarController.
//     *
//     * @return The top most view controller.
//     */
//    - (UIViewController *)topViewControllerFromViewController:(UIViewController *)viewController {
//      if ([viewController isKindOfClass:[UINavigationController class]]) {
//        UINavigationController *navigationController = (UINavigationController *)viewController;
//        return [self
//            topViewControllerFromViewController:[navigationController.viewControllers lastObject]];
//      }
//      if ([viewController isKindOfClass:[UITabBarController class]]) {
//        UITabBarController *tabController = (UITabBarController *)viewController;
//        return [self topViewControllerFromViewController:tabController.selectedViewController];
//      }
//      if (viewController.presentedViewController) {
//        return [self topViewControllerFromViewController:viewController.presentedViewController];
//      }
//      return viewController;
//    }
    
    
    
}
