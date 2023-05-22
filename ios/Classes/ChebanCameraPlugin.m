#import "ChebanCameraPlugin.h"
#if __has_include(<cheban_camera/cheban_camera-Swift.h>)
#import <cheban_camera/cheban_camera-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cheban_camera-Swift.h"
#endif
#import "SLShotViewController.h"

@implementation ChebanCameraPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"cheban_camera" binaryMessenger:registrar.messenger];
    [registrar addMethodCallDelegate:registrar channel:channel];

  [SwiftChebanCameraPlugin registerWithRegistrar:registrar];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"takePhotoAndVideo"]) {
        if ([call.arguments isKindOfClass:NSDictionary.class]) {
            NSDictionary *dict = call.arguments;
            int sourceType = [dict objectForKey:@"source_type"];
            int faceType = [dict objectForKey:@"face_type"];
            int animated = [dict objectForKey:@"animated"];
            SLShotViewController *vc = [[SLShotViewController alloc] init];
            [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:vc animated:YES completion:nil];
        } else if ([call.method isEqualToString:@"destory"]) {
            if ([[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentedViewController] isKindOfClass:SLShotViewController.class]) {
                [[UIApplication.sharedApplication.keyWindow rootViewController].presentedViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }
}


@end
