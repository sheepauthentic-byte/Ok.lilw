//
//  Macros.h
//  ModMenu
//
//  Created by Joey on 4/2/19.
//  Copyright © 2019 Joey. All rights reserved.
//

#pragma once

#import "AntiHook/AntiHook.h"
#import "Config.h"
#import "Foundation/Foundation.h"
#import "GioVoTinh/PatchAPI.h"
#import "GioVoTinh/il2cpp.h"
#import "Il2cppResolver/IL2CPP_Resolver.hpp"
#import "KittyMemory/KittyUtils.hpp"
#import "KittyMemory/MemoryPatch.hpp"
#import "KittyMemory/writeData.hpp"
#import "Security/oxorany/oxorany_include.h"
#import "Utils/EntityManager.h"
#import "Utils/Esp.h"
#import "Utils/HookUtils.h"
#import "Utils/Quaternion.h"
#import "Utils/RuntimeMacros.h"
#import "Utils/json.hpp"
#import "Utils/monoString.h"
#import "lib/MonoString.h"

#include <algorithm>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <set>
#include <substrate.h>

#define HOOK(offset, ptr, orig)                                                \
    MSHookFunction((void *)getRealOffset(offset), (void *)ptr, (void **)&orig)
#define HOOK_NO_ORIG(offset, ptr)                                              \
    MSHookFunction((void *)getRealOffset(offset), (void *)ptr, NULL)
#define HOOK_V2(offset, ptr, orig)                                             \
    do {                                                                       \
        NSString *result_##__COUNTER__ = StaticInlineHookPatch(                \
            (char *)[common getFrameworkName], offset, nullptr);               \
        if (result_##__COUNTER__) {                                            \
            LOG(@"Hook result: %s", result_##__COUNTER__.UTF8String);          \
            void *result = StaticInlineHookFunction(                           \
                (char *)[common getFrameworkName], offset, (void *)ptr);       \
            LOG(@"Hook result %p", result);                                    \
            *(void **)(&orig) = (void *)result;                                \
        }                                                                      \
    } while (0);

// Fix issue it always patch inline => Check is hooked? => If it don't hooked to
// patch inline function orig goto function hook in __HOOK_TEXT
#define HOOK_V3(offset, ptr, orig)                                             \
    do {                                                                       \
        @autoreleasepool {                                                     \
            void *result = StaticInlineHookFunction(                           \
                (char *)[common getFrameworkName], offset, (void *)ptr);       \
            if (result) {                                                      \
                *(void **)(&orig) = result;                                    \
            } else {                                                           \
                NSString *result_##__COUNTER__ = StaticInlineHookPatch(        \
                    (char *)[common getFrameworkName], offset, nullptr);       \
                if (result_##__COUNTER__) {                                    \
                    LOG(@"Hook result: %s", result_##__COUNTER__.UTF8String);  \
                    result = StaticInlineHookFunction(                         \
                        (char *)[common getFrameworkName], offset,             \
                        (void *)ptr);                                          \
                    LOG(@"Hook result %p", result);                            \
                    if (result)                                                \
                        *(void **)(&orig) = result;                            \
                }                                                              \
            }                                                                  \
        }                                                                      \
    } while (0)

// Note to not prepend an underscore to the symbol. See Notes on the Apple
// manpage
// (https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dlsym.3.html)
#define HOOKSYM(sym, ptr, org)                                                 \
    MSHookFunction((void *)dlsym((void *)RTLD_DEFAULT, sym), (void *)ptr,      \
                   (void **)&org)
#define HOOKSYM_NO_ORIG(sym, ptr)                                              \
    MSHookFunction((void *)dlsym((void *)RTLD_DEFAULT, sym), (void *)ptr, NULL)
#define getSym(symName) dlsym((void *)RTLD_DEFAULT, symName)

// Helper
#define appPath [[NSBundle mainBundle] bundlePath]
#define binaryPath(name) [appPath stringByAppendingPathComponent:name]
#define ARRAY_LENGTH(arr) std::size(arr)
