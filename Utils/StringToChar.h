//
//  StringToChar.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 6/7/26.
//

#ifndef StringToChar_h
#define StringToChar_h

#include <cstddef>
#include <cstring>

static void LoadStringToCharBuffer(const char *src, char *dst, size_t dstSize) {
    if (dst == nullptr || dstSize == 0) {
        return;
    }

    dst[0] = '\0';

    if (src == nullptr) {
        return;
    }

    std::strncpy(dst, src, dstSize - 1);
    dst[dstSize - 1] = '\0';
}

#endif /* StringToChar_h */
