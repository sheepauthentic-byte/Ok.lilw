#import "HookUtils.h"

#import "../GioVoTinh/PatchAPI.h"
#import "../KittyMemory/KittyUtils.hpp"
#import "../KittyMemory/MemoryPatch.hpp"
#import "RuntimeMacros.h"

uint64_t getRealOffset(uint64_t offset) {
    return KittyMemory::getAbsoluteAddress([common getFrameworkName], offset);
}

uint64_t getRealOffset(const char *binaryName, uint64_t offset) {
    return KittyMemory::getAbsoluteAddress(binaryName, offset);
}

uint64_t getOffset(uintptr_t address) {
    return address - KittyMemory::getAbsoluteAddress([common getFrameworkName],
                                                     ENCRYPTOFFSET("0x0"));
}

uint64_t getOffset(const char *binaryName, uintptr_t address) {
    return address -
           KittyMemory::getAbsoluteAddress(binaryName, ENCRYPTOFFSET("0x0"));
}

void patchOffsetKitty(uint64_t offset, std::string hexBytes) {
    MemoryPatch patch =
        MemoryPatch::createWithHex([common getFrameworkName], offset, hexBytes);
    if (!patch.isValid()) {
        LOG(@"Invalid patch, failing offset: 0x%llX, please re-check the hex "
            @"you entered.",
            offset);
        return;
    }
    if (!patch.Modify()) {
        LOG(@"Something went wrong while patching this offset: 0x%llX", offset);
    }
}

void patchOffset(uint64_t vaddr, std::string hexBytes) {
    char *frameworkName = (char *)[common getFrameworkName];
    const uint64_t imageBase = 0x100000000;
    if (vaddr > imageBase)
        vaddr = vaddr - imageBase;

    if (!KittyUtils::String::ValidateHex(hexBytes)) {
        LOG(@"Invalid hex string: %s, please re-check the hex you entered.",
            hexBytes.c_str());
        return;
    }

    ActiveCodePatch(frameworkName, vaddr, const_cast<char *>(hexBytes.data()));

    NSString *msg = StaticInlineHookPatch(frameworkName, vaddr,
                                          const_cast<char *>(hexBytes.data()));

    LOG(@"Patch result: %@", msg);
}

void restorePatchOffset(uint64_t vaddr, std::string hexBytes) {
    char *frameworkName = (char *)[common getFrameworkName];
    const uint64_t imageBase = 0x100000000;
    if (vaddr > imageBase)
        vaddr = vaddr - imageBase;

    if (!KittyUtils::String::ValidateHex(hexBytes)) {
        LOG(@"Invalid hex string: %s, please re-check the hex you entered.",
            hexBytes.c_str());
        return;
    }

    DeactiveCodePatch(frameworkName, vaddr,
                      const_cast<char *>(hexBytes.data()));
}
