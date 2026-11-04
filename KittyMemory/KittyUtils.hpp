#pragma once

#include <string>
#include <cstdint>
#include <algorithm>
#include <sstream>
#include <iomanip>
#include <cstdarg>
#include <vector>
#include <utility>
#include <random>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <errno.h>
#include <inttypes.h>
#include <dirent.h>
#include <mutex>
#include <functional>

#define KT_PAGE_SIZE (sysconf(_SC_PAGE_SIZE))

#define KT_PAGE_START(x) (uintptr_t(x) & ~(KT_PAGE_SIZE - 1))
#define KT_PAGE_END(x) (KT_PAGE_START(uintptr_t(x) + KT_PAGE_SIZE - 1))
#define KT_PAGE_OFFSET(x) (uintptr_t(x) - KT_PAGE_START(x))
#define KT_PAGE_LEN(x) (size_t(KT_PAGE_SIZE - KT_PAGE_OFFSET(x)))

#define KT_PAGE_END2(x, len) (KT_PAGE_START((uintptr_t(x) + len) + KT_PAGE_SIZE - 1))
#define KT_PAGE_LEN2(x, len) (KT_PAGE_END2(x, len) - KT_PAGE_START(x))

#define KT_PROT_RWX (PROT_READ | PROT_WRITE | PROT_EXEC)
#define KT_PROT_RX (PROT_READ | PROT_EXEC)
#define KT_PROT_RW (PROT_READ | PROT_WRITE)

#define KITTY_LOG_TAG "KittyMemory"

#include <os/log.h>

#ifdef kITTYMEMORY_DEBUG
#define KITTY_LOGD(fmt, ...) os_log(OS_LOG_DEFAULT, "D " KITTY_LOG_TAG ": " fmt, ##__VA_ARGS__)
#else
#define KITTY_LOGD(fmt, ...)                                                                                           \
    do                                                                                                                 \
    {                                                                                                                  \
    } while (0)
#endif

#define KITTY_LOGI(fmt, ...) os_log(OS_LOG_DEFAULT, "I " KITTY_LOG_TAG ": " fmt, ##__VA_ARGS__)
#define KITTY_LOGE(fmt, ...) os_log_error(OS_LOG_DEFAULT, "E " KITTY_LOG_TAG ": " fmt, ##__VA_ARGS__)

#define KT_EINTR_RETRY(exp)                                                                                            \
    ({                                                                                                                 \
        __typeof__(exp) _rc;                                                                                           \
        do                                                                                                             \
        {                                                                                                              \
            _rc = (exp);                                                                                               \
        } while (_rc == -1 && errno == EINTR);                                                                         \
        _rc;                                                                                                           \
    })

namespace KittyUtils
{

    inline uintptr_t untagHeepPtr(uintptr_t p)
    {
        return p;
    }

    inline void *untagHeepPtr(void *p)
    {
        return reinterpret_cast<void*>(untagHeepPtr(uintptr_t(p)));
    }

    inline const void *untagHeepPtr(const void *p)
    {
        return reinterpret_cast<const void*>(untagHeepPtr(uintptr_t(p)));
    }

    std::string fileNameFromPath(const std::string &filePath);
    std::string fileDirectory(const std::string &filePath);
    std::string fileExtension(const std::string &filePath);

    namespace String
    {
        static inline bool StartsWith(const std::string &str, const std::string &str2)
        {
            return str.length() >= str2.length() && str.compare(0, str2.length(), str2) == 0;
        }

        static inline bool Contains(const std::string &str, const std::string &str2)
        {
            return str.length() >= str2.length() && str.find(str2) != std::string::npos;
        }

        static inline bool EndsWith(const std::string &str, const std::string &str2)
        {
            return str.length() >= str2.length() && str.compare(str.length() - str2.length(), str2.length(), str2) == 0;
        }

        void Trim(std::string &str);

        bool ValidateHex(std::string &hex);

        std::string Fmt(const char *fmt, ...);

        std::string Random(size_t length);
    } // namespace String

    template <typename T>
    T randInt(T min, T max)
    {
        using param_type = typename std::uniform_int_distribution<T>::param_type;

        static std::mutex mtx;
        std::lock_guard<std::mutex> lock(mtx);

        static std::mt19937 gen{std::random_device{}()};
        static std::uniform_int_distribution<T> dist;

        return dist(gen, param_type{min, max});
    }

    template <typename T>
    std::string data2Hex(const T &data)
    {
        const auto *byteData = reinterpret_cast<const unsigned char *>(&data);
        std::stringstream hexStringStream;

        hexStringStream << std::hex << std::setfill('0');
        for (size_t index = 0; index < sizeof(T); ++index)
            hexStringStream << std::setw(2) << static_cast<int>(byteData[index]);

        return hexStringStream.str();
    }

    std::string data2Hex(const void *data, const size_t dataLength);
    void dataFromHex(const std::string &in, void *data);

    template <size_t rowSize = 8, bool showASCII = true>
    std::string HexDump(const void *address, size_t len)
    {
        if (!address || len == 0 || rowSize == 0)
            return "";

        const unsigned char *data = static_cast<const unsigned char *>(address);

        std::stringstream ss;
        ss << std::hex << std::uppercase << std::setfill('0');

        size_t i, j;

        for (i = 0; i < len; i += rowSize)
        {
            // offset
            ss << std::setw(8) << i << ": ";

            // row bytes
            for (j = 0; (j < rowSize) && ((i + j) < len); j++)
                ss << std::setw(2) << static_cast<unsigned int>(data[i + j]) << " ";

            // fill row empty space
            for (; j < rowSize; j++)
                ss << "   ";

            // ASCII
            if (showASCII)
            {
                ss << " ";

                for (j = 0; (j < rowSize) && ((i + j) < len); j++)
                {
                    if (std::isprint(data[i + j]))
                        ss << data[i + j];
                    else
                        ss << '.';
                }
            }

            ss << std::endl;
        }

        return ss.str();
    }

} // namespace KittyUtils
