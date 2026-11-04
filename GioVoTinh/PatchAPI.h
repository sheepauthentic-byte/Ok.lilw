#pragma once

#import <Foundation/Foundation.h>
#include <stdint.h>

struct mach_header_64;

uint64_t va2rva(struct mach_header_64 *header, uint64_t va);
void *rva2data(struct mach_header_64 *header, uint64_t rva);
NSMutableData *load_macho_data(NSString *path);
NSMutableData *add_hook_section(NSMutableData *macho);
bool hex2bytes(char *bytes, unsigned char *buffer);
uint64_t calc_patch_hash(uint64_t vaddr, char *patch);
NSString *StaticInlineHookPatch(char *machoPath, uint64_t vaddr, char *patch);
void *find_module_by_path(char *machoPath);
void *StaticInlineHookFunction(char *machoPath, uint64_t vaddr,
                               void *replace);
BOOL ActiveCodePatch(char *machoPath, uint64_t vaddr, char *patch);
BOOL DeactiveCodePatch(char *machoPath, uint64_t vaddr, char *patch);
