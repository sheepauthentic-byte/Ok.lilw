//
//  AntiHook.m
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/11/26.
//

#import "AntiHook.h"
#import "../Utils/RuntimeMacros.h"
#import "../lib/fishhook.h"

NS_ASSUME_NONNULL_BEGIN

@interface AntiHook ()
@property(nonatomic, weak) NSTimer *timer;
@end

BOOL AntiHookEnable = NO;

static ssize_t (*orig_send)(int, const void *, size_t, int);
ssize_t hook_send(int a, const void *b, size_t c, int d) {
    if (AntiHookEnable) {
        return 0;
    } else {
        return orig_send(a, b, c, d);
    }
}

@implementation AntiHook

+ (void)load {
    timer(5) {
        AntiHook *view = [AntiHook Timer];
        [view start];
        [[[[UIApplication sharedApplication] windows] lastObject]
            addSubview:view];
    });
}

+ (instancetype)Timer {
    return [[AntiHook alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)hook {
    AntiHookEnable = YES;
    rebind_symbols(
        (struct rebinding[1]){{"send", (void *)hook_send, (void **)&orig_send}},
        1);
}

- (void)start {
    self.timer.fireDate = [NSDate distantPast];
}

- (NSTimer *_Nullable)timer {
    if (!_timer) {
        _timer =
            [NSTimer scheduledTimerWithTimeInterval:3
                                            repeats:YES
                                              block:^(NSTimer *_Nonnull timer) {
                                                if (AntiHookEnable) {
                                                    [self hook];
                                                }
                                              }];
    }
    return _timer;
}

@end

NS_ASSUME_NONNULL_END
