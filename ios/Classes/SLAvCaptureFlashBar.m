//
//  SLAvCaptureFlashBar.m
//  cheban_camera
//
//  Created by melody on 2023/5/22.
//

#import "SLAvCaptureFlashBar.h"
#import "SLShotViewController.h"

@interface SLAvCaptureFlashBar ()

@property (strong, nonatomic) UIStackView *stackView;
@property (strong, nonatomic) UIView *separatorView;
@property (strong, nonatomic) UIButton *flashButton;

@end

@implementation SLAvCaptureFlashBar

- (UIStackView *)stackView {
    if (!_stackView) {
        _stackView = [[UIStackView alloc] init];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.distribution = UIStackViewDistributionFillEqually;
        _stackView.spacing = 36;
        self.stackView.frame = CGRectMake(12, 0, 28 * 3 + 36 * 2, self.bounds.size.height);
        [self addSubview:_stackView];
    }
    return _stackView;
}

- (UIView *)separatorView {
    if (!_separatorView) {
        _separatorView = [[UIView alloc] initWithFrame:CGRectMake(12 + 28 * 3 + 36 * 3, 10, 0.5, self.bounds.size.height - 20)];
        _separatorView.backgroundColor = [UIColor colorWithRed:216.0/255.0 green:216.0/255.0 blue:216.0/255.0 alpha:1.0];
    }
    return _separatorView;
}

- (UIButton *)flashButton {
    if (!_flashButton) {
        _flashButton = [[UIButton alloc] initWithFrame:CGRectMake(12 + 28 * 3 + 36 * 3 + 0.5 + 18, 0, 28, self.bounds.size.height)];
        _flashButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_flashButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_flashButton];
    }
    return _flashButton;
}

- (instancetype)initWithFrame:(CGRect)frame type:(NSInteger)type {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 26;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.65];
        for (int i = 0; i < 3; i++) {
            UIView *itemView = [self createStackOfRowForType:i];
            [self.stackView addArrangedSubview:itemView];
        }
        [self addSubview:self.separatorView];
        self.flashButton.tag = type;
        NSBundle *bundle = [NSBundle bundleForClass:[SLShotViewController class]];
        switch (type) {
            case 0:
                [self.flashButton setImage:[UIImage imageNamed:@"flash_off" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
                break;
            case 1:
                [self.flashButton setImage:[UIImage imageNamed:@"flash_on" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
                break;
            case 2:
                [self.flashButton setImage:[UIImage imageNamed:@"flash_auto" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
                break;
        }

    }
    return self;
}

- (UIView *)createStackOfRowForType:(NSInteger)type {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 28, 28);
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    NSBundle *bundle = [NSBundle bundleForClass:[SLShotViewController class]];
    switch (type) {
        case 0:
            button.tag = 0;
            [button setImage:[UIImage imageNamed:@"flash_off" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
            break;
        case 1:
            button.tag = 2;
            [button setImage:[UIImage imageNamed:@"flash_auto" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
            break;
        case 2:
            button.tag = 1;
            [button setImage:[UIImage imageNamed:@"flash_on" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
            break;
    }
    [button addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)onButtonClick:(UIButton *)sender {
    self.hidden = YES;
    self.onChooseFlashCompleted(sender.tag);
    NSBundle *bundle = [NSBundle bundleForClass:[SLShotViewController class]];
    switch (sender.tag) {
        case 0:
            [self.flashButton setImage:[UIImage imageNamed:@"flash_off" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
            break;
        case 1:
            [self.flashButton setImage:[UIImage imageNamed:@"flash_on" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
            break;
        case 2:
            [self.flashButton setImage:[UIImage imageNamed:@"flash_auto" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
            break;
    }
}

@end
