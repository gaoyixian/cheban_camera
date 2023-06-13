//
//  SLShotViewController.h
//  DarkMode
//
//  Created by wsl on 2019/9/18.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/// 拍摄视图控制器
@interface SLShotViewController : UIViewController

@property (assign, nonatomic) NSInteger faceType;
@property (assign, nonatomic) NSInteger sourceType;
@property (assign, nonatomic) NSInteger appType;

@property (copy, nonatomic) FlutterResult flutterResult;

@end

NS_ASSUME_NONNULL_END
