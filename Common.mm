//
//  Common.mm
//
//
//  Created by Le Tien Dat on 3/4/26.
//

#include "Common.h"

NS_ASSUME_NONNULL_BEGIN

#define UD [NSUserDefaults standardUserDefaults]

@implementation Common

const char *frameworkName = NULL;
Common *common = [Common new];

- (void)setFrameworkName:(const char *)name_ {
    frameworkName = name_;
}
- (const char *)getFrameworkName {
    return frameworkName;
}

- (UIWindow *)getKeyWindow {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication]
                 .connectedScenes) {
            if (scene.activationState ==
                UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    } else {
        return [UIApplication sharedApplication].keyWindow;
    }

    return nil;
}

- (UIViewController *)getRootViewController:(UIWindow *)keyWindow {
    if (!keyWindow)
        keyWindow = [self getKeyWindow];
    if (!keyWindow) {
        return nil;
    }
    return keyWindow.rootViewController;
}

- (UIViewController *)getTopViewController:(UIWindow *)window {
    if (!window) {
        window = [self getKeyWindow];
    }
    if (!window) {
        return nil;
    }

    UIViewController *top = window.rootViewController;
    if (!top) {
        return nil;
    }

    while (true) {
        if (top.presentedViewController) {
            top = top.presentedViewController;
            continue;
        }

        if ([top isKindOfClass:[UINavigationController class]]) {
            UIViewController *visible =
                ((UINavigationController *)top).visibleViewController;
            if (visible) {
                top = visible;
                continue;
            }
        }

        if ([top isKindOfClass:[UITabBarController class]]) {
            UIViewController *selected =
                ((UITabBarController *)top).selectedViewController;
            if (selected) {
                top = selected;
                continue;
            }
        }

        break;
    }

    return top;
}

- (void)setInt:(int)value forKey:(NSString *)key {
    [UD setInteger:value forKey:key];
    [UD synchronize];
}

- (int)integerForKey:(NSString *)key defaultValue:(int)defaultValue {
    if ([UD objectForKey:key]) {
        return (int)[UD integerForKey:key];
    }
    return defaultValue;
}

- (void)setBool:(bool)value forKey:(NSString *)key {
    [UD setBool:value forKey:key];
    [UD synchronize];
}

- (bool)boolForKey:(NSString *)key defaultValue:(bool)defaultValue {
    if ([UD objectForKey:key]) {
        return [UD boolForKey:key];
    }
    return defaultValue;
}

- (void)setFloat:(float)value forKey:(NSString *)key {
    [UD setFloat:value forKey:key];
    [UD synchronize];
}

- (float)floatForKey:(NSString *)key defaultValue:(float)defaultValue {
    if ([UD objectForKey:key]) {
        return [UD floatForKey:key];
    }
    return defaultValue;
}

- (void)setString:(NSString *)value forKey:(NSString *)key {
    [UD setObject:value forKey:key];
    [UD synchronize];
}

- (NSString *)stringForKey:(NSString *)key
              defaultValue:(NSString *)defaultValue {
    if ([UD objectForKey:key]) {
        return [UD stringForKey:key];
    }
    return defaultValue;
}

@end

NS_ASSUME_NONNULL_END
