#include "KittyScanner.hpp"
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <sys/stat.h>

#include "KittyUtils.hpp"

// refs
// https://github.com/learn-more/findpattern-bench

namespace KittyScanner
{

    bool compare(const char *data, const char *pattern, const char *mask)
    {
        for (; *mask; ++mask, ++data, ++pattern)
        {
            if (*mask == 'x' && *data != *pattern)
                return false;
        }
        return !*mask;
    }

    uintptr_t findInRange(const uintptr_t start, const uintptr_t end, const char *pattern, const std::string &mask)
    {
        const size_t scan_size = mask.length();

        if (scan_size < 1 || ((start + scan_size) > end))
            return 0;

        const size_t length = end - start;

        for (size_t i = 0; i < length; ++i)
        {
            const uintptr_t current_end = start + i + scan_size;
            if (current_end > end)
                break;

            if (!compare(reinterpret_cast<const char *>(start + i), pattern, mask.c_str()))
                continue;

            return start + i;
        }
        return 0;
    }

    std::vector<uintptr_t> findBytesAll(const uintptr_t start, const uintptr_t end, const char *bytes,
                                        const std::string &mask)
    {
        std::vector<uintptr_t> list;

        if (start >= end || !bytes || mask.empty())
            return list;

        uintptr_t curr_search_address = start;
        const size_t scan_size = mask.length();
        do
        {
            if (!list.empty())
                curr_search_address = list.back() + scan_size;

            uintptr_t found = findInRange(curr_search_address, end, bytes, mask);
            if (!found)
                break;

            list.push_back(found);
        } while (true);

        return list;
    }

    uintptr_t findBytesFirst(const uintptr_t start, const uintptr_t end, const char *bytes, const std::string &mask)
    {
        if (start >= end || !bytes || mask.empty())
            return 0;

        return findInRange(start, end, bytes, mask);
    }

    std::vector<uintptr_t> findHexAll(const uintptr_t start, const uintptr_t end, std::string hex,
                                      const std::string &mask)
    {
        std::vector<uintptr_t> list;

        if (start >= end || mask.empty() || !KittyUtils::String::ValidateHex(hex))
            return list;

        const size_t scan_size = mask.length();
        if ((hex.length() / 2) != scan_size)
            return list;

        std::vector<char> pattern(scan_size);
        KittyUtils::dataFromHex(hex, &pattern[0]);

        list = findBytesAll(start, end, pattern.data(), mask);
        return list;
    }

    uintptr_t findHexFirst(const uintptr_t start, const uintptr_t end, std::string hex, const std::string &mask)
    {
        if (start >= end || mask.empty() || !KittyUtils::String::ValidateHex(hex))
            return 0;

        const size_t scan_size = mask.length();
        if ((hex.length() / 2) != scan_size)
            return 0;

        std::vector<char> pattern(scan_size);
        KittyUtils::dataFromHex(hex, &pattern[0]);

        return findBytesFirst(start, end, pattern.data(), mask);
    }

    std::vector<uintptr_t> findIdaPatternAll(const uintptr_t start, const uintptr_t end, const std::string &pattern)
    {
        std::vector<uintptr_t> list;

        if (start >= end)
            return list;

        std::string mask;
        std::vector<char> bytes;

        const size_t pattren_len = pattern.length();
        for (std::size_t i = 0; i < pattren_len; i++)
        {
            if (pattern[i] == ' ')
                continue;

            if (pattern[i] == '?')
            {
                bytes.push_back(0);
                mask += '?';
            }
            else if (pattren_len > i + 1 && std::isxdigit(pattern[i]) && std::isxdigit(pattern[i + 1]))
            {
                bytes.push_back(std::stoi(pattern.substr(i++, 2), nullptr, 16));
                mask += 'x';
            }
        }

        if (bytes.empty() || mask.empty() || bytes.size() != mask.size())
            return list;

        list = findBytesAll(start, end, bytes.data(), mask);
        return list;
    }

    uintptr_t findIdaPatternFirst(const uintptr_t start, const uintptr_t end, const std::string &pattern)
    {
        if (start >= end)
            return 0;

        std::string mask;
        std::vector<char> bytes;

        const size_t pattren_len = pattern.length();
        for (std::size_t i = 0; i < pattren_len; i++)
        {
            if (pattern[i] == ' ')
                continue;

            if (pattern[i] == '?')
            {
                bytes.push_back(0);
                mask += '?';
            }
            else if (pattren_len > i + 1 && std::isxdigit(pattern[i]) && std::isxdigit(pattern[i + 1]))
            {
                bytes.push_back(std::stoi(pattern.substr(i++, 2), nullptr, 16));
                mask += 'x';
            }
        }

        if (bytes.empty() || mask.empty() || bytes.size() != mask.size())
            return 0;

        return findBytesFirst(start, end, bytes.data(), mask);
    }

    std::vector<uintptr_t> findDataAll(const uintptr_t start, const uintptr_t end, const void *data, size_t size)
    {
        std::vector<uintptr_t> list;

        if (start >= end || !data || size < 1)
            return list;

        std::string mask(size, 'x');

        list = findBytesAll(start, end, (const char *)data, mask);
        return list;
    }

    uintptr_t findDataFirst(const uintptr_t start, const uintptr_t end, const void *data, size_t size)
    {
        if (start >= end || !data || size < 1)
            return 0;

        std::string mask(size, 'x');

        return findBytesFirst(start, end, (const char *)data, mask);
    }

} // namespace KittyScanner
