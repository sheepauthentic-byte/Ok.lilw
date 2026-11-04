//
//  Common.h
//
//
//  Created by Le Tien Dat on 3/4/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Common : NSObject

- (void)setFrameworkName:(const char *)name_;
- (const char *)getFrameworkName;

- (UIWindow *)getKeyWindow;
- (UIViewController *)getRootViewController:(UIWindow *)keyWindow;
- (UIViewController *)getTopViewController:(UIWindow *)keyWindow;

// UserDefaults
- (void)setInt:(int)value forKey:(NSString *)key;
- (int)integerForKey:(NSString *)key defaultValue:(int)defaultValue;
- (void)setBool:(bool)value forKey:(NSString *)key;
- (bool)boolForKey:(NSString *)key defaultValue:(bool)defaultValue;
- (void)setFloat:(float)value forKey:(NSString *)key;
- (float)floatForKey:(NSString *)key defaultValue:(float)defaultValue;
- (void)setString:(NSString *)value forKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key
              defaultValue:(NSString *)defaultValue;

@end

extern Common *common;

NS_ASSUME_NONNULL_END
