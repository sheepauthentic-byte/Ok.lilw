#pragma once

#include <stdint.h>
#include <string>

uint64_t getRealOffset(uint64_t offset);
uint64_t getRealOffset(const char *binaryName, uint64_t offset);
uint64_t getOffset(uintptr_t address);
uint64_t getOffset(const char *binaryName, uintptr_t address);
void patchOffsetKitty(uint64_t offset, std::string hexBytes);
void patchOffset(uint64_t vaddr, std::string hexBytes);
void restorePatchOffset(uint64_t vaddr, std::string hexBytes);
