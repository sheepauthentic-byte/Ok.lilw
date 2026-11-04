//
//  AntiHook.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/11/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AntiHook : UIView

extern BOOL AntiHookEnable;

+ (instancetype)Timer;
- (void)start;

@end

NS_ASSUME_NONNULL_END
