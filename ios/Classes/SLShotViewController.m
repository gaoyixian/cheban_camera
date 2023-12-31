//
//  SLShotViewController.m
//  DarkMode
//
//  Created by wsl on 2019/9/18.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLShotViewController.h"
#import "SLBlurView.h"
#import "SLAvCaptureTool.h"
#import "SLShotFocusView.h"
#import "SLDelayPerform.h"
#import "SLToolMacro.h"
#import "UIView+SLFrame.h"
#import "SLAvCaptureFlashBar.h"

// TODO: 编辑暂时不考虑用原生做，否则Android一套iOS一套
//#import "SLEditVideoController.h"
//#import "SLEditImageController.h"

#define KMaxDurationOfVideo  30.0 //录制最大时长 s

@interface SLShotViewController ()<SLAvCaptureToolDelegate>
{
    dispatch_source_t _gcdTimer; //计时器
    NSTimeInterval _durationOfVideo;  //录制视频的时长
}


@property (nonatomic, strong) SLAvCaptureTool *avCaptureTool; //摄像头采集工具
@property (nonatomic, strong) UIImageView *captureView; // 捕获预览视图

@property (nonatomic, strong) UIButton *switchCameraBtn; // 切换前后摄像头
@property (nonatomic, strong) UIButton *backBtn;

@property (nonatomic, strong) SLBlurView *shotBtn; //拍摄按钮
@property (nonatomic, strong) UIView *whiteView; //白色圆心
@property (nonatomic, strong) CAShapeLayer *progressLayer; //环形进度条
@property (nonatomic, strong) CAShapeLayer *traceLayer; //环形进度条
@property (nonatomic, strong) UILabel *tipsLabel; //拍摄提示语  轻触拍照 长按拍摄
@property (nonatomic, strong) UILabel *timeLabel; //倒计时文本
@property (nonatomic, strong) UIButton *flashButton; //闪光灯按钮
@property (nonatomic, strong) SLAvCaptureFlashBar *flashBar;//闪光灯选择条

@property (nonatomic, assign) CGFloat currentZoomFactor; //当前焦距比例系数
@property (nonatomic, strong) SLShotFocusView *focusView;   //当前聚焦视图
@property (nonatomic, strong) UIVisualEffectView *backdropView;

@end

@implementation SLShotViewController

#pragma mark - OverWrite
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self.avCaptureTool startRunning];
    [self focusAtPoint:CGPointMake(SL_kScreenWidth/2.0, SL_kScreenHeight/2.0)];
    //监听设备方向，旋转切换摄像头按钮
    [self.avCaptureTool addObserver:self forKeyPath:@"shootingOrientation" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_gcdTimer) {
        dispatch_source_cancel(_gcdTimer);
        _gcdTimer = nil;
    }
    [_avCaptureTool stopRunning];
    [_avCaptureTool removeObserver:self forKeyPath:@"shootingOrientation"];
    [SLDelayPerform sl_cancelDelayPerform];
}
//- (void)viewSafeAreaInsetsDidChange {
//    [super viewSafeAreaInsetsDidChange];
//    UIEdgeInsets insets = self.view.safeAreaInsets;
//}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (BOOL)shouldAutorotate {
    return NO;
}
- (void)dealloc {
    _avCaptureTool.delegate = nil;
    _avCaptureTool = nil;
    NSLog(@"拍摄视图释放");
}
#pragma mark - UI
- (void)setupUI {
    self.title = @"拍摄";
    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:self.captureView];
    
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.shotBtn];
    [self.shotBtn.layer addSublayer:self.traceLayer];
    [self.view addSubview:self.switchCameraBtn];
    [self.view addSubview:self.flashButton];
    [self.view addSubview:self.backdropView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.45 animations:^{
            self.backdropView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.backdropView removeFromSuperview];
        }];
    });
    [self.view addSubview:self.tipsLabel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tipsLabel removeFromSuperview];
    });
}

#pragma mark - Getter
- (UIVisualEffectView *)backdropView {
    if (_backdropView == nil) {
        _backdropView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        _backdropView.frame = self.view.bounds;
    }
    return _backdropView;
}
- (SLAvCaptureTool *)avCaptureTool {
    if (_avCaptureTool == nil) {
        _avCaptureTool = [[SLAvCaptureTool alloc] init];
        _avCaptureTool.preview = self.captureView;
        _avCaptureTool.delegate = self;
        _avCaptureTool.videoSize = CGSizeMake(SL_kScreenWidth*0.8, SL_kScreenHeight*0.8);
        if (self.faceType == 1) {
            [_avCaptureTool switchsCamera:AVCaptureDevicePositionBack];
        } else {
            [_avCaptureTool switchsCamera:AVCaptureDevicePositionFront];
        }
    }
    return _avCaptureTool;
}
- (UIView *)captureView {
    if (_captureView == nil) {
        _captureView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _captureView.contentMode = UIViewContentModeScaleAspectFit;
        _captureView.backgroundColor = [UIColor blackColor];
        _captureView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFocusing:)];
        [_captureView addGestureRecognizer:tap];
        
        UIPinchGestureRecognizer  *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchFocalLength:)];
        [_captureView addGestureRecognizer:pinch];
    }
    return _captureView;
}
- (UIButton *)backBtn {
    if (_backBtn == nil) {
        _backBtn = [[UIButton alloc] init];
        _backBtn.frame = CGRectMake(0, 0, 48, 48);
        _backBtn.center = CGPointMake((self.view.sl_width/2 - 72/2.0)/2.0, self.view.sl_height - 80);
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        [_backBtn setImage:[UIImage imageNamed:@"ic_close" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}
- (UIView *)shotBtn {
    if (_shotBtn == nil) {
        _shotBtn = [[SLBlurView alloc] init];
        _shotBtn.userInteractionEnabled = YES;
        _shotBtn.frame = CGRectMake(0, 0, 72, 72);
        if (self.sourceType == 1) {
            _shotBtn.backgroundColor = [UIColor whiteColor];
        } else {
            _shotBtn.backgroundColor = [UIColor clearColor];
        }
        _shotBtn.center = CGPointMake(self.view.sl_width/2.0, self.view.sl_height - 80);
        _shotBtn.clipsToBounds = YES;
        _shotBtn.layer.cornerRadius = _shotBtn.sl_width/2.0;
        //轻触拍照，长按摄像
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takePicture:)];
        [_shotBtn addGestureRecognizer:tap];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(recordVideo:)];
        longPress.minimumPressDuration = 0.3;
        [_shotBtn addGestureRecognizer:longPress];
        //中心白色
        self.whiteView.frame = CGRectMake(0, 0, 60, 60);
        self.whiteView.center = CGPointMake(_shotBtn.sl_width/2.0, _shotBtn.sl_height/2.0);
        self.whiteView.layer.cornerRadius = self.whiteView.frame.size.width/2.0;
        [_shotBtn addSubview:self.whiteView];
    }
    return _shotBtn;
}
- (UIButton *)switchCameraBtn {
    if (_switchCameraBtn == nil) {
        _switchCameraBtn = [[UIButton alloc] init];
        _switchCameraBtn.frame = CGRectMake(0, 0, 48, 48);
        _switchCameraBtn.center = CGPointMake((self.view.sl_width/2 + 72/2.0) + ((self.view.sl_width/2 - 72/2.0) / 2), self.view.sl_height - 80);
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        [_switchCameraBtn setImage:[UIImage imageNamed:@"switch_camera" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
        [_switchCameraBtn addTarget:self action:@selector(switchCameraClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraBtn;
}
- (UIView *)whiteView {
    if (_whiteView == nil) {
        _whiteView = [UIView new];
        _whiteView.backgroundColor = [UIColor whiteColor];
    }
    return _whiteView;
}
- (CAShapeLayer *)traceLayer {
    if (_traceLayer == nil) {
        //设置画笔路径
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.shotBtn.frame.size.width/2.0, self.shotBtn.frame.size.height/2.0) radius:self.shotBtn.frame.size.width/2.0 startAngle:- M_PI_2 endAngle:-M_PI_2 + M_PI * 2 clockwise:YES];
        //按照路径绘制圆环
        _traceLayer = [CAShapeLayer layer];
        _traceLayer.frame = _shotBtn.bounds;
        _traceLayer.fillColor = [UIColor clearColor].CGColor;
        _traceLayer.lineWidth = 12;
        //线头的样式
        _traceLayer.lineCap = kCALineCapButt;
        //圆环颜色
        _traceLayer.strokeColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16].CGColor;
        _traceLayer.strokeStart = 0;
        _traceLayer.strokeEnd = 1;
        //path 决定layer将被渲染成何种形状
        _traceLayer.path = path.CGPath;
    }
    return _traceLayer;

}
- (CAShapeLayer *)progressLayer {
    if (_progressLayer == nil) {
        //设置画笔路径
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.shotBtn.frame.size.width/2.0, self.shotBtn.frame.size.height/2.0) radius:self.shotBtn.frame.size.width/2.0 startAngle:- M_PI_2 endAngle:-M_PI_2 + M_PI * 2 clockwise:YES];
        //按照路径绘制圆环
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = _shotBtn.bounds;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.lineWidth = 12;
        //线头的样式
        _progressLayer.lineCap = kCALineCapButt;
        //圆环颜色
        if (self.appType == 0) {
            _progressLayer.strokeColor = [UIColor colorWithRed:245.0/255.0 green:51.0/255.0 blue:87.0/255.0 alpha:1.0].CGColor;
        } else {
            _progressLayer.strokeColor = [UIColor colorWithRed:32.0/255.0 green:188.0/255.0 blue:154.0/255.0 alpha:1.0].CGColor;
        }
        _progressLayer.strokeStart = 0;
        _progressLayer.strokeEnd = 0;
        //path 决定layer将被渲染成何种形状
        _progressLayer.path = path.CGPath;
    }
    return _progressLayer;
}
- (SLShotFocusView *)focusView {
    if (_focusView == nil) {
        _focusView= [[SLShotFocusView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    }
    return _focusView;
}
- (UILabel *)tipsLabel {
    if (_tipsLabel == nil) {
        _tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.sl_width - 140)/2.0, self.shotBtn.sl_y - 20 - 30, 140, 20)];
        _tipsLabel.textColor = [UIColor whiteColor];
        _tipsLabel.font = [UIFont systemFontOfSize:14];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        if (self.sourceType == 1) {
            _tipsLabel.text = @"Click to Take Photo";
        } else if (self.sourceType == 2) {
            _tipsLabel.text = @"按住摄像";
        } else {
            _tipsLabel.text = @"轻触拍照，按住摄像";
        }
    }
    return  _tipsLabel;
}
- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.sl_width - 140)/2.0, self.shotBtn.sl_y - 20 - 30, 140, 20)];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.font = [UIFont systemFontOfSize:14];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.text = @"00:00";
        _timeLabel.hidden = YES;
        [self.view addSubview:_timeLabel];
    }
    return _timeLabel;
}
- (UIButton *)flashButton {
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashButton addTarget:self action:@selector(flashChange:) forControlEvents:UIControlEventTouchUpInside];
        _flashButton.frame = CGRectMake(self.view.sl_width - 34 - 28, [[UIApplication sharedApplication] statusBarFrame].size.height + 14, 28, 28);
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        [_flashButton setImage:[UIImage imageNamed:@"flash_off" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
        [self.view addSubview:_flashButton];
    }
    return _flashButton;
}
- (SLAvCaptureFlashBar *)flashBar {
    if (!_flashBar) {
        CGFloat width = 28 * 4 + 36 * 3 + 12 * 2 + 18;
        _flashBar = [[SLAvCaptureFlashBar alloc] initWithFrame:CGRectMake(self.view.sl_width - width - 22, [[UIApplication sharedApplication] statusBarFrame].size.height + (48 - 28 - 14), width, 48) type:self.avCaptureTool.flashMode];
        __weak SLShotViewController *weakSelf = self;
        _flashBar.onChooseFlashCompleted = ^(NSInteger type) {
            weakSelf.flashButton.hidden = NO;
            weakSelf.avCaptureTool.flashMode = type;
            switch (weakSelf.avCaptureTool.flashMode) {
                case AVCaptureFlashModeOff: {
                    NSBundle *bundle = [NSBundle bundleForClass:weakSelf.class];
                    [weakSelf.flashButton setImage:[UIImage imageNamed:@"flash_off" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
                    break;
                }
                case AVCaptureFlashModeAuto: {
                    NSBundle *bundle = [NSBundle bundleForClass:weakSelf.class];
                    [weakSelf.flashButton setImage:[UIImage imageNamed:@"flash_auto" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
                    break;
                }
                case AVCaptureFlashModeOn: {
                    NSBundle *bundle = [NSBundle bundleForClass:weakSelf.class];
                    [weakSelf.flashButton setImage:[UIImage imageNamed:@"flash_on" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
                    break;
                }
            }

        };
        _flashBar.layer.zPosition = 100;
        _flashBar.hidden = YES;
        [self.view addSubview:_flashBar];
    }
    return _flashBar;
}

#pragma mark - HelpMethods
//开始计时录制
- (void)startTimer{
    [self.tipsLabel removeFromSuperview];
    /** 创建定时器对象
     * para1: DISPATCH_SOURCE_TYPE_TIMER 为定时器类型
     * para2-3: 中间两个参数对定时器无用
     * para4: 最后为在什么调度队列中使用
     */
    _gcdTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    /** 设置定时器
     * para2: 任务开始时间
     * para3: 任务的间隔
     * para4: 可接受的误差时间，设置0即不允许出现误差
     * Tips: 单位均为纳秒
     */
    //定时器延迟时间
    NSTimeInterval delayTime = 0.f;
    //定时器间隔时间
    NSTimeInterval timeInterval = 0.1f;
    //设置开始时间
    dispatch_time_t startDelayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC));
    dispatch_source_set_timer(_gcdTimer, startDelayTime, timeInterval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    /** 设置定时器任务
     * 可以通过block方式
     * 也可以通过C函数方式
     */
    //    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_gcdTimer, ^{
        self->_durationOfVideo+= timeInterval;
        SL_DISPATCH_ON_MAIN_THREAD((^{
            self.timeLabel.hidden = NO;
            //主线程更新UI
            self.progressLayer.strokeEnd = self->_durationOfVideo/KMaxDurationOfVideo;
            int duration = ceil(self->_durationOfVideo);
            self.timeLabel.text = [NSString stringWithFormat:@"00:%02d", duration - 1];
        }));
        
        if(self->_durationOfVideo > KMaxDurationOfVideo) {
            NSLog(@"时长 %f", self->_durationOfVideo);
            SL_DISPATCH_ON_MAIN_THREAD(^{
                self.progressLayer.strokeEnd = 1;
                //暂停定时器
                // dispatch_suspend(_gcdTimer);
                //取消计时器
                dispatch_source_cancel(self->_gcdTimer);
                self->_durationOfVideo = 0;
                [self.progressLayer removeFromSuperlayer];
                //停止录制
                [self.avCaptureTool stopRecordVideo];
                [self.avCaptureTool stopRunning];
                self.timeLabel.hidden = YES;
            });
        }
    });
    // 启动任务，GCD计时器创建后需要手动启动
    dispatch_resume(_gcdTimer);
}

#pragma mark - EventsHandle
//返回
- (void)backBtn:(UIButton *)btn {
    [self dismissViewControllerAnimated:YES completion:nil];
}
//闪光灯
- (void)flashChange:(UIButton *)btn {
    btn.hidden = YES;
    self.flashBar.hidden = NO;
}
//聚焦手势
- (void)tapFocusing:(UITapGestureRecognizer *)tap {
    //如果没在运行，取消聚焦
    if(!self.avCaptureTool.isRunning) {
        return;
    }
    CGPoint point = [tap locationInView:self.captureView];
//    if(point.y > self.shotBtn.sl_y || point.y < self.switchCameraBtn.sl_y + self.switchCameraBtn.sl_height) {
//        return;
//    }
    [self focusAtPoint:point];
}
//设置焦点视图位置
- (void)focusAtPoint:(CGPoint)point {
    self.focusView.center = point;
    [self.focusView removeFromSuperview];
    [self.view addSubview:self.focusView];
    self.focusView.transform = CGAffineTransformMakeScale(1.3, 1.3);
    [UIView animateWithDuration:0.5 animations:^{
        self.focusView.transform = CGAffineTransformIdentity;
    }];
    [self.avCaptureTool focusAtPoint:point];
    SL_WeakSelf;
    [SLDelayPerform sl_startDelayPerform:^{
        [weakSelf.focusView removeFromSuperview];
    } afterDelay:1.0];
}
//调节焦距 手势
- (void)pinchFocalLength:(UIPinchGestureRecognizer *)pinch {
    if(pinch.state == UIGestureRecognizerStateBegan) {
        self.currentZoomFactor = self.avCaptureTool.videoZoomFactor;
    }
    if (pinch.state == UIGestureRecognizerStateChanged) {
        self.avCaptureTool.videoZoomFactor = self.currentZoomFactor * pinch.scale;
    }
}
//切换前/后摄像头
- (void)switchCameraClicked:(id)sender {
    if (self.avCaptureTool.devicePosition == AVCaptureDevicePositionFront) {
        [self.avCaptureTool switchsCamera:AVCaptureDevicePositionBack];
    } else if(self.avCaptureTool.devicePosition == AVCaptureDevicePositionBack) {
        [self.avCaptureTool switchsCamera:AVCaptureDevicePositionFront];
    }
}
//轻触拍照
- (void)takePicture:(UITapGestureRecognizer *)tap {
    if (self.sourceType == 2) {
        return;
    }
    [self.avCaptureTool outputPhoto];
    NSLog(@"拍照");
}
//长按摄像 小视频
- (void)recordVideo:(UILongPressGestureRecognizer *)longPress {
    if (self.sourceType == 1) {
        return;
    }
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:{
            self.whiteView.sl_size = CGSizeMake(24, 24);
            self.whiteView.center = CGPointMake(self.shotBtn.sl_width/2.0, self.shotBtn.sl_height/2.0);
            self.whiteView.layer.cornerRadius = self.whiteView.sl_width/2.0;
            //开始计时
            [self startTimer];
            //添加进度条
            [self.shotBtn.layer addSublayer:self.progressLayer];
            self.progressLayer.strokeEnd = 0;
            NSString *outputVideoFielPath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"cheban_camera_video_%.0f.mp4", [[NSDate date] timeIntervalSince1970]]];
            //开始录制视频
            [self.avCaptureTool startRecordVideoToOutputFileAtPath:outputVideoFielPath recordType:SLAvCaptureTypeAv];
        }
            NSLog(@"开始摄像");
            break;
        case UIGestureRecognizerStateChanged:{
        }
            //            NSLog(@"正在摄像");
            break;
        case UIGestureRecognizerStateEnded:{
            self.whiteView.sl_size = CGSizeMake(60, 60);
            self.whiteView.center = CGPointMake(self.shotBtn.sl_width/2.0, self.shotBtn.sl_height/2.0);
            self.whiteView.layer.cornerRadius = self.whiteView.sl_width/2.0;
            //取消计时器
            dispatch_source_cancel(self->_gcdTimer);
            self->_durationOfVideo = 0;
            self.progressLayer.strokeEnd = 0;
            [self.progressLayer removeFromSuperlayer];
            //    结束录制视频
            [self.avCaptureTool stopRunning];
            [self.avCaptureTool stopRecordVideo];
        }
            break;
        default:
            break;
    }
}
// KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"shootingOrientation"]) {
        UIDeviceOrientation deviceOrientation = [change[@"new"] intValue];
        [UIView animateWithDuration:0.3 animations:^{
            switch (deviceOrientation) {
                case UIDeviceOrientationPortrait:
                    self.switchCameraBtn.transform = CGAffineTransformMakeRotation(0);
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    self.switchCameraBtn.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    break;
                case UIDeviceOrientationLandscapeRight:
                    self.switchCameraBtn.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    self.switchCameraBtn.transform = CGAffineTransformMakeRotation(-M_PI);
                    break;
                default:
                    break;
            }
        }];
    }
}

#pragma mark - SLAvCaptureToolDelegate  图片、音视频输出代理
//图片输出完成
- (void)captureTool:(SLAvCaptureTool *)captureTool didOutputPhoto:(UIImage *)image error:(NSError *)error {
    [self.avCaptureTool stopRunning];
    NSLog(@"拍照结束");
    if (self.flutterResult == nil) {
        return;
    }
    NSString *prefixPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [NSString stringWithFormat:@"%@/cheban_camera_image_%.0f.jpg", prefixPath, [[NSDate date] timeIntervalSince1970]];
    NSData *data = [self compressImage:image maxLen:1024 * 500];
    if ([data writeToURL:[NSURL fileURLWithPath:path] atomically:YES]) {
        NSDictionary *result = @{
            @"width": [NSNumber numberWithInt:image.size.width],
            @"height": [NSNumber numberWithInt:image.size.height],
            @"type": @1,
            @"origin_file_path": path,
            @"thumbnail_file_path": @"",
        };
        self.flutterResult(result);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:nil];
        });

    }

    // TODO: 编辑暂时不考虑用原生做，否则Android一套iOS一套
//    SLEditImageController * editViewController = [[SLEditImageController alloc] init];
//    editViewController.image = image;
//    editViewController.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:editViewController animated:NO completion:nil];
}
//音视频输出完成
- (void)captureTool:(SLAvCaptureTool *)captureTool didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    
    [self.avCaptureTool stopRunning];
    NSLog(@"结束录制");
    // TODO: 编辑暂时不考虑用原生做，否则Android一套iOS一套
//    SLEditVideoController * editViewController = [[SLEditVideoController alloc] init];
//    editViewController.videoPath = outputFileURL;
//    editViewController.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:editViewController animated:NO completion:^{
//        NSString *result = error ? @"录制失败" : @"录制成功";
//        NSLog(@"%@ %@", result , error.localizedDescription);
//        [SLAlertView showAlertViewWithText:result delayHid:1];
//    }];
    UIImage *image = [self thumbnailImageForVideo:outputFileURL];
    if (image != nil) {
        NSString *prefixPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *path = [NSString stringWithFormat:@"%@/cheban_camera_image_%.0f.jpg", prefixPath, [[NSDate date] timeIntervalSince1970]];
        NSInteger duration = [self totalSecondForVideo:outputFileURL];
        NSData *data = [self compressImage:image maxLen:1024 * 500];
        if ([data writeToURL:[NSURL fileURLWithPath:path] atomically:YES]) {
            NSDictionary *result = @{
                @"width": [NSNumber numberWithInteger:image.size.width],
                @"height": [NSNumber numberWithInteger:image.size.height],
                @"type": @2,
                @"origin_file_path": outputFileURL.path,
                @"thumbnail_file_path": path,
                @"duration": [NSNumber numberWithInteger:duration]
            };
            self.flutterResult(result);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:NO completion:nil];
            });
        }

    }
    NSInteger fileSize = (NSInteger)[[NSFileManager defaultManager] attributesOfItemAtPath:outputFileURL.path error:nil].fileSize;
    NSLog(@"视频文件大小 === %.2fM",fileSize/(1024.0*1024.0));
}

//let image = self.thumbnailImageForVideo(videoURL: videoURL!)
//let compressData = self.compressImage(image: image!, maxLength: 1024 * 500)
//if (image != nil) {
//    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/image_\(Int(Date().timeIntervalSince1970)).jpg"
//    let duration = self.totalSecondForVideo(videoURL: videoURL!)
//    if (duration == 0) {
//        return
//    }
//    do {
//        try compressData.write(to: URL(fileURLWithPath: path))
//        self.flutterResult!([
//            "width": Int(image!.size.width),
//            "height": Int(image!.size.height),
//            "type": 2,
//            "origin_file_path": videoURL!.path,
//            "thumbnail_file_path": path,
//            "duration": duration,
//        ])
//        DispatchQueue.main.asyncAfter(deadline: .now() + self.delayDismissTime, execute: {
//            self.dismiss(animated: false)
//        })
//    } catch {
//        print("写入文件失败")
//    }
//}


- (NSData *)compressImage:(UIImage *)image maxLen:(NSInteger)maxLength {
    NSInteger tempMaxLength = maxLength;
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    if (data.length < tempMaxLength) {
        return data;
    }
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; i++) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(image, compression);
        if (data.length < tempMaxLength * 0.9) {
            min = compression;
        } else if (data.length > tempMaxLength) {
            max = compression;
        } else {
            break;
        }
    }
    UIImage *resultImage = [UIImage imageWithData:data];
    if (data.length < tempMaxLength) {
        return data;
    }
    NSInteger lastDataLength = 0;
    while (data.length > tempMaxLength && data.length != lastDataLength) {
        lastDataLength = data.length;
        CGFloat ratio = tempMaxLength / data.length;
        CGSize size = CGSizeMake(resultImage.size.width * ratio, resultImage.size.height * ratio);
        UIGraphicsBeginImageContext(size);
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        data = UIImageJPEGRepresentation(image, 0.1);
    }
    return data;
}

- (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    AVAssetImageGenerator *assetImage = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    assetImage.appliesPreferredTrackTransform = YES;
    assetImage.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    CGImageRef imageRef = [assetImage copyCGImageAtTime:CMTimeMake(0, 50) actualTime:nil error:nil];
    return [UIImage imageWithCGImage:imageRef];
}

- (NSInteger)totalSecondForVideo:(NSURL *)videoURL {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    CMTime time = asset.duration;
    CGFloat sec = CMTimeGetSeconds(time);
    return ceil(sec);
}

@end
