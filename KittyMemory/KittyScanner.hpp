#pragma once

#include <string>
#include <cstdint>
#include <vector>
#include <utility>

#include "KittyMemory.hpp"

namespace KittyScanner
{
    /**
     * Search for bytes within a memory range and return all results
     *
     * @start: search start address
     * @end: search end address
     * @bytes: bytes to search
     * @mask: bytes mask x/?
     *
     * @return vector list of all found bytes addresses
     */
    std::vector<uintptr_t> findBytesAll(const uintptr_t start, const uintptr_t end, const char *bytes,
                                        const std::string &mask);

    /**
     * Search for bytes within a memory range and return first result
     *
     * @start: search start address
     * @end: search end address
     * @bytes: bytes to search
     * @mask: bytes mask x/?
     *
     * @return first found bytes address
     */
    uintptr_t findBytesFirst(const uintptr_t start, const uintptr_t end, const char *bytes, const std::string &mask);

    /**
     * Search for hex within a memory range and return all results
     *
     * @start: search start address
     * @end: search end address
     * @hex: hex to search
     * @mask: hex mask x/?
     *
     * @return vector list of all found hex addresses
     */
    std::vector<uintptr_t> findHexAll(const uintptr_t start, const uintptr_t end, std::string hex,
                                      const std::string &mask);

    /**
     * Search for hex within a memory range and return first result
     *
     * @start: search start address
     * @end: search end address
     * @hex: hex to search
     * @mask: hex mask x/?
     *
     * @return first found hex address
     */
    uintptr_t findHexFirst(const uintptr_t start, const uintptr_t end, std::string hex, const std::string &mask);

    /**
     * Search for ida pattern within a memory range and return all results
     *
     * @param start: search start address
     * @param end: search end address
     * @param pattern: hex bytes and wildcard "?" ( FF DD ? 99 CC ? 00 )
     *
     * @return vector list of all found pattern addresses
     */
    std::vector<uintptr_t> findIdaPatternAll(const uintptr_t start, const uintptr_t end, const std::string &pattern);

    /**
     * Search for ida pattern within a memory range and return first result
     *
     * @param start: search start address
     * @param end: search end address
     * @param pattern: hex bytes and wildcard "?" ( FF DD ? 99 CC ? 00 )
     *
     * @return first found pattern address
     */
    uintptr_t findIdaPatternFirst(const uintptr_t start, const uintptr_t end, const std::string &pattern);

    /**
     * Search for data within a memory range and return all results
     *
     * @start: search start address
     * @end: search end address
     * @data: data to search
     * @size: data size
     *
     * @return vector list of all found data addresses
     */
    std::vector<uintptr_t> findDataAll(const uintptr_t start, const uintptr_t end, const void *data, size_t size);

    /**
     * Search for data within a memory range and return first result
     *
     * @start: search start address
     * @end: search end address
     * @data: data to search
     * @size: data size
     *
     * @return first found data address
     */
    uintptr_t findDataFirst(const uintptr_t start, const uintptr_t end, const void *data, size_t size);

} // namespace KittyScanner
