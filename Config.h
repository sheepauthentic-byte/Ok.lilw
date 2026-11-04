//
//  Config.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 6/5/26.
//

#import "Utils/RuntimeMacros.h"
#include <string>

#ifndef Config_h
#define Config_h

static inline const char *BaseURL() {
    static std::string url = ENCRYPT("https://raw.githubusercontent.com/"
                                     "letienndat/Data-Mod/refs/heads/master");
    return url.c_str();
}

#endif /* Config_h */
