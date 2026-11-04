//
//  ImGuiDrawView.h
//  ImGuiTest
//
//  Created by yiming on 2021/6/2.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ImGuiDrawView : UIViewController

@property(nonatomic, copy) void (^onCallChange)(BOOL open);

+ (instancetype)sharedInstance;
+ (void)showChange:(BOOL)open;

- (void)activeHack:(NSString *)title
           message:(NSString *)message
              font:(UIFont *)font
          duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
