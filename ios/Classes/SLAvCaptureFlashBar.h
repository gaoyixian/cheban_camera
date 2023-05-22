//
//  SLAvCaptureFlashBar.h
//  cheban_camera
//
//  Created by melody on 2023/5/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLAvCaptureFlashBar : UIView

- (instancetype)initWithFrame:(CGRect)frame type:(NSInteger)type;

@property (copy, nonatomic) void (^onChooseFlashCompleted)(NSInteger type);

@end

NS_ASSUME_NONNULL_END
