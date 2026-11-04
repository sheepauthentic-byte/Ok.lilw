#pragma once

#import "Common.h"
#import "Foundation/Foundation.h"
#import "GioVoTinh/PatchAPI.h"

#ifdef __cplusplus
#import "Security/Obfuscate.h"
#define GVT_LOG_PREFIX NSSENCRYPT("GioVoTinh Mod >>>")
#else
#define GVT_LOG_PREFIX @"GioVoTinh Mod >>>"
#endif

#define LOG(...)                                                               \
    NSLog(@"%@ %@", GVT_LOG_PREFIX, [NSString stringWithFormat:__VA_ARGS__])

#define timer(sec) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sec * NSEC_PER_SEC), dispatch_get_main_queue(), ^
#define timer_background(sec) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sec * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
#define onMain(block) dispatch_async(dispatch_get_main_queue(), block)
