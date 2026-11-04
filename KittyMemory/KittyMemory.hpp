//
//  KittyMemory.hpp
//
//  Created by MJ (Ruit) on 1/1/19.
//

#pragma once

#include <inttypes.h>
#include <cstdio>
#include <string>
#include <unistd.h>
#include <sys/mman.h>
#include <vector>

#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/getsect.h>
#include <libkern/OSCacheControl.h>

#include "KittyUtils.hpp"

namespace KittyMemory
{
    /*
     * Reads an address content into a buffer
     */
    bool memRead(const void *address, void *buffer, size_t len);

    enum Memory_Status
    {
        KMS_FAILED = 0,
        KMS_SUCCESS,
        KMS_INV_ADDR,
        KMS_INV_LEN,
        KMS_INV_BUF,
        KMS_ERR_PROT,
        KMS_ERR_GET_PAGEINFO,
        KMS_ERR_VMWRITE,
    };

    struct seg_data_t
    {
        uintptr_t start, end;
        unsigned long size;
        seg_data_t() : start(0), end(0), size(0)
        {
        }
    };

    class MemoryFileInfo
    {
    public:
        uint32_t index;
#ifdef __LP64__
        const mach_header_64 *header;
#else
        const mach_header *header;
#endif
        const char *name;
        intptr_t address;

        MemoryFileInfo() : index(0), header(nullptr), name(nullptr), address(0)
        {
        }

        inline seg_data_t getSegment(const char *seg_name) const
        {
            seg_data_t data{};
            if (!header || !seg_name)
                return data;
            data.start = uintptr_t(getsegmentdata(header, seg_name, &data.size));
            data.end = data.start + data.size;
            return data;
        }

        inline seg_data_t getSection(const char *seg_name, const char *sect_name) const
        {
            seg_data_t data{};
            if (!header || !seg_name || !sect_name)
                return data;
            data.start = uintptr_t(getsectiondata(header, seg_name, sect_name, &data.size));
            data.end = data.start + data.size;
            return data;
        }
    };

    /*
     * Writes buffer content to an address
     */
    Memory_Status memWrite(void *address, const void *buffer, size_t len);

    /*
     * vm_region_recurse_64 wrapper
     */
    kern_return_t getPageInfo(vm_address_t region, vm_region_submap_short_info_64 *info_out);

    /*
     * returns base executable info
     */
    MemoryFileInfo getBaseInfo();

    /*
     * find in memory file info by checking if target loaded object file ends with @fileName
     */
    MemoryFileInfo getMemoryFileInfo(const std::string &fileName);

    /*
     * returns the absolue address of a relative offset of a file in memory or NULL as
     * fileName for base executable
     */
    uintptr_t getAbsoluteAddress(const char *fileName, uintptr_t address);

} // namespace KittyMemory

namespace KittyScanner
{
    uintptr_t findSymbol(const KittyMemory::MemoryFileInfo &info, const std::string &symbol);
    uintptr_t findSymbol(const std::string &lib, const std::string &symbol);
} // namespace KittyScanner
