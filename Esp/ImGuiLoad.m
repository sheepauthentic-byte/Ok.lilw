//
//  ImGuiLoad.m
//  ImGuiTest
//
//  Created by yiming on 2021/6/2.
//

#import "ImGuiLoad.h"
#import "../Common.h"
#import "../Utils/RuntimeMacros.h"
#import "ImGuiDrawView.h"
#import "JHPP.h"

@interface ImGuiLoad ()
@property(nonatomic, strong) ImGuiDrawView *imGUI;
@end

static UIWindow *mainWindow;

@implementation ImGuiLoad

static ImGuiLoad *extraInfo;

+ (void)load {
    [super load];

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetLocalCenter(), NULL, &didFinishLaunching,
        (CFStringRef)UIApplicationDidFinishLaunchingNotification, NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
}

static void didFinishLaunching(CFNotificationCenterRef center, void *observer,
                               CFStringRef name, const void *object,
                               CFDictionaryRef userInfo) {
    timer(1) {
        mainWindow = [common getKeyWindow];
        extraInfo = [ImGuiLoad new];
        [extraInfo initTapGes];
        [extraInfo initTapGesHide];
        [extraInfo show];
        [extraInfo hide];
    });
}

- (void)initTapGes {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.numberOfTapsRequired = 2;    // 点击次数
    tap.numberOfTouchesRequired = 3; // 手指数
    [[JHPP currentViewController].view addGestureRecognizer:tap];
    [tap addTarget:self action:@selector(show)];
}

- (void)initTapGesHide {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.numberOfTapsRequired = 2;    // 点击次数
    tap.numberOfTouchesRequired = 2; // 手指数
    [[JHPP currentViewController].view addGestureRecognizer:tap];
    [tap addTarget:self action:@selector(hide)];
}

- (void)show {
    mainWindow = [common getKeyWindow];

    if (!_imGUI) {
        ImGuiDrawView *vc = [ImGuiDrawView sharedInstance];
        vc.onCallChange = ^(BOOL open) {
          if (open) {
              [extraInfo show];
          } else {
              [extraInfo hide];
          }
        };
        _imGUI = vc;
    }

    [ImGuiDrawView showChange:YES];
    if (!_imGUI.view.superview) {
        UIViewController *topVC = [common getTopViewController:mainWindow];
        if (!topVC) {
            return;
        }

        [_imGUI willMoveToParentViewController:nil];
        [_imGUI removeFromParentViewController];

        [topVC addChildViewController:_imGUI];
        _imGUI.view.frame = topVC.view.bounds;
        [topVC.view addSubview:_imGUI.view];
        [_imGUI didMoveToParentViewController:topVC];
    }
    _imGUI.view.hidden = NO;
    _imGUI.view.userInteractionEnabled = YES;
}

- (void)hide {
    if (_imGUI) {
        [ImGuiDrawView showChange:NO];
        _imGUI.view.userInteractionEnabled = NO;
    }
}

@end
