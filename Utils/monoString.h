//
//  ESP
//
//  Created by Ngọc Bằng on 2/6/2022.
//
//  Updated by Le Tien Dat (16/6/2026)

typedef struct _monoString {
    void *klass;   // 0x0 (8 bytes)
    int length;    // 0x8 (4 bytes)
    char chars[1]; // 0xC

    int getLength() { return length; }

    char *getChars() { return chars; }

    NSString *toNSString() {
        return [[NSString alloc]
            initWithBytes:(const void *)(chars)
                   length:(NSUInteger)(length * 2)
                 encoding:(NSStringEncoding)NSUTF16LittleEndianStringEncoding];
    }

    char *toCString() {
        NSString *v1 = toNSString();
        return (char *)([v1 UTF8String]);
    }

    std::string toCPPString() { return std::string(toCString()); }
} monoString;
