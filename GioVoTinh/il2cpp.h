/*
 *
 *      IL2CPP RESOLVER FOR THEOS
 *           by Batchh
 *          Version 0.3
 *
 */

// Update by Le Tien Dat

#include "../Il2cppResolver/Utils/MemoryInfo.hpp"
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <string>
#include <vector>

#define REQUIRE(sym)                                                           \
    if (!(IL2CPP::sym))                                                        \
    return false

namespace IL2CPP {
const void *(*il2cpp_assembly_get_image)(const void *assembly);
void *(*il2cpp_domain_get)();
void **(*il2cpp_domain_get_assemblies)(const void *domain, size_t *size);
const char *(*il2cpp_image_get_name)(void *image);
void *(*il2cpp_class_from_name)(const void *image, const char *namespaze,
                                const char *name);
void *(*il2cpp_class_get_field_from_name)(void *klass, const char *name);
void *(*il2cpp_class_get_method_from_name)(void *klass, const char *name,
                                           int argsCount);
size_t (*il2cpp_field_get_offset)(void *field);
void (*il2cpp_field_static_get_value)(void *field, void *value);
void (*il2cpp_field_static_set_value)(void *field, void *value);

void *(*il2cpp_string_new)(const char *str);
void *(*il2cpp_string_new_utf16)(const wchar_t *str, int32_t length);
uint16_t *(*il2cpp_string_chars)(void *str);

// v2
char *(*il2cpp_thread_get_name)(void *thread, uint32_t *len);
void *(*il2cpp_thread_current)();
void *(*il2cpp_thread_attach)(void *domain);
void (*il2cpp_thread_detach)(void *thread);
void *(*il2cpp_runtime_invoke)(const void *method, void *obj, void **params,
                               void **exc);
void *(*il2cpp_object_unbox)(void *obj);
void *(*il2cpp_object_new)(const void *klass);
uint32_t (*il2cpp_gchandle_new)(void *obj, bool pinned);
void (*il2cpp_gchandle_free)(uint32_t gchandle);
} // namespace IL2CPP

bool Il2CppAttach() {
    NSString *applicationPath = [[NSBundle mainBundle] bundlePath];
    NSString *unityFrameworkPath = [applicationPath
        stringByAppendingPathComponent:@"Frameworks/UnityFramework.framework/"
                                       @"UnityFramework"]; // THIS NEED TO BE
                                                           // CHANGED IF Il2CPP
                                                           // ISN'T INIT IN
                                                           // "UnityFramework"
    void *handle = dlopen([unityFrameworkPath UTF8String], RTLD_LAZY);
    while (!handle) {
        NSLog(@"Error: Failed to load UnityFramework");
        handle = dlopen([unityFrameworkPath UTF8String], RTLD_LAZY);
        sleep(1);
    }

    IL2CPP::il2cpp_assembly_get_image =
        reinterpret_cast<const void *(*)(const void *)>(
            dlsym(handle, "il2cpp_assembly_get_image"));
    IL2CPP::il2cpp_domain_get =
        reinterpret_cast<void *(*)()>(dlsym(handle, "il2cpp_domain_get"));
    IL2CPP::il2cpp_domain_get_assemblies =
        reinterpret_cast<void **(*)(const void *, size_t *)>(
            dlsym(handle, "il2cpp_domain_get_assemblies"));
    IL2CPP::il2cpp_image_get_name = reinterpret_cast<const char *(*)(void *)>(
        dlsym(handle, "il2cpp_image_get_name"));
    IL2CPP::il2cpp_class_from_name =
        reinterpret_cast<void *(*)(const void *, const char *, const char *)>(
            dlsym(handle, "il2cpp_class_from_name"));
    IL2CPP::il2cpp_class_get_method_from_name =
        reinterpret_cast<void *(*)(void *, const char *, int)>(
            dlsym(handle, "il2cpp_class_get_method_from_name"));
    IL2CPP::il2cpp_class_get_field_from_name =
        reinterpret_cast<void *(*)(void *, const char *)>(
            dlsym(handle, "il2cpp_class_get_field_from_name"));
    IL2CPP::il2cpp_field_get_offset = reinterpret_cast<size_t (*)(void *)>(
        dlsym(handle, "il2cpp_field_get_offset"));
    IL2CPP::il2cpp_field_static_get_value =
        reinterpret_cast<void (*)(void *, void *)>(
            dlsym(handle, "il2cpp_field_static_get_value"));
    IL2CPP::il2cpp_field_static_set_value =
        reinterpret_cast<void (*)(void *, void *)>(
            dlsym(handle, "il2cpp_field_static_set_value"));

    // Additional IL2CPP function assignments
    IL2CPP::il2cpp_string_new = reinterpret_cast<void *(*)(const char *)>(
        dlsym(handle, "il2cpp_string_new"));
    IL2CPP::il2cpp_string_new_utf16 =
        reinterpret_cast<void *(*)(const wchar_t *, int32_t)>(
            dlsym(handle, "il2cpp_string_new_utf16"));
    IL2CPP::il2cpp_string_chars = reinterpret_cast<uint16_t *(*)(void *)>(
        dlsym(handle, "il2cpp_string_chars"));

    // v2
    IL2CPP::il2cpp_thread_get_name =
        reinterpret_cast<char *(*)(void *, uint32_t *)>(
            dlsym(handle, "il2cpp_thread_get_name"));
    IL2CPP::il2cpp_thread_current =
        reinterpret_cast<void *(*)()>(dlsym(handle, "il2cpp_thread_current"));
    IL2CPP::il2cpp_thread_attach = reinterpret_cast<void *(*)(void *)>(
        dlsym(handle, "il2cpp_thread_attach"));
    IL2CPP::il2cpp_thread_detach = reinterpret_cast<void (*)(void *)>(
        dlsym(handle, "il2cpp_thread_detach"));
    IL2CPP::il2cpp_runtime_invoke =
        reinterpret_cast<void *(*)(const void *, void *, void **, void **)>(
            dlsym(handle, "il2cpp_runtime_invoke"));
    IL2CPP::il2cpp_object_unbox = reinterpret_cast<void *(*)(void *)>(
        dlsym(handle, "il2cpp_object_unbox"));
    IL2CPP::il2cpp_object_new = reinterpret_cast<void *(*)(const void *)>(
        dlsym(handle, "il2cpp_object_new"));
    IL2CPP::il2cpp_gchandle_new = reinterpret_cast<uint32_t (*)(void *, bool)>(
        dlsym(handle, "il2cpp_gchandle_new"));
    IL2CPP::il2cpp_gchandle_free = reinterpret_cast<void (*)(uint32_t)>(
        dlsym(handle, "il2cpp_gchandle_free"));

    dlclose(handle);

    REQUIRE(il2cpp_assembly_get_image);
    REQUIRE(il2cpp_domain_get);
    REQUIRE(il2cpp_domain_get_assemblies);
    REQUIRE(il2cpp_image_get_name);
    REQUIRE(il2cpp_class_from_name);
    REQUIRE(il2cpp_class_get_method_from_name);
    REQUIRE(il2cpp_class_get_field_from_name);
    REQUIRE(il2cpp_field_get_offset);
    REQUIRE(il2cpp_field_static_get_value);
    REQUIRE(il2cpp_field_static_set_value);
    REQUIRE(il2cpp_string_new);
    REQUIRE(il2cpp_string_new_utf16);
    REQUIRE(il2cpp_string_chars);
    REQUIRE(il2cpp_thread_get_name);
    REQUIRE(il2cpp_thread_current);
    REQUIRE(il2cpp_thread_attach);
    REQUIRE(il2cpp_thread_detach);
    REQUIRE(il2cpp_runtime_invoke);
    REQUIRE(il2cpp_object_unbox);
    REQUIRE(il2cpp_object_new);
    REQUIRE(il2cpp_gchandle_new);
    REQUIRE(il2cpp_gchandle_free);

    return true;
}

void *GetImage(const char *image) {
    size_t size;
    void **assemblies = IL2CPP::il2cpp_domain_get_assemblies(
        IL2CPP::il2cpp_domain_get(), &size);
    for (int i = 0; i < size; ++i) {
        void *img = (void *)IL2CPP::il2cpp_assembly_get_image(assemblies[i]);
        const char *img_name = IL2CPP::il2cpp_image_get_name(img);
        if (strcmp(img_name, image) == 0) {
            return img;
        }
    }
    return 0;
}

void *GetClass(const char *image, const char *namespaze, const char *clazz) {
    void *img = GetImage(image);

    if (!img) {
        return nullptr;
    }

    void *klass = IL2CPP::il2cpp_class_from_name(img, namespaze, clazz);

    if (!klass) {
        return nullptr;
    }

    return klass;
}

const void *GetMethodOffset(const char *image, const char *namespaze,
                            const char *klass_name, const char *name,
                            int argsCount) {
    void *img = GetImage(image);

    if (!img) {
        return nullptr;
    }

    void *klass = IL2CPP::il2cpp_class_from_name(img, namespaze, klass_name);

    if (!klass) {
        return nullptr;
    }

    void **method = (void **)IL2CPP::il2cpp_class_get_method_from_name(
        klass, name, argsCount);

    if (!method) {
        return nullptr;
    }

    return *method;
}

uintptr_t GetFieldOffset(const char *image, const char *namespaze,
                         const char *clazz, const char *name) {
    void *img = GetImage(image);
    if (!img) {
        printf("Il2cpp: couldn't find image %s\n", image);
        return 0;
    }

    void *klass = IL2CPP::il2cpp_class_from_name(img, namespaze, clazz);
    if (!klass) {
        printf("Il2cpp: couldn't find class %s\n", clazz);
        return 0;
    }

    void *field = IL2CPP::il2cpp_class_get_field_from_name(klass, name);
    if (!field) {
        printf("Il2cpp: couldn't find field %s\n", name);
        return 0;
    }

    return IL2CPP::il2cpp_field_get_offset(field);
}

void GetStaticFieldValue(const char *image, const char *namespaze,
                         const char *clazz, const char *name, void *output) {
    void *img = GetImage(image);

    if (!img) {
        return;
    }

    void *klass = IL2CPP::il2cpp_class_from_name(img, namespaze, clazz);

    if (!klass) {
        return;
    }

    void *field = IL2CPP::il2cpp_class_get_field_from_name(klass, name);

    if (!field) {
        return;
    }

    IL2CPP::il2cpp_field_static_get_value(field, output);
}

void SetStaticFieldValue(const char *image, const char *namespaze,
                         const char *clazz, const char *name, void *value) {
    void *img = GetImage(image);

    if (!img) {
        return;
    }

    void *klass = IL2CPP::il2cpp_class_from_name(img, namespaze, clazz);

    if (!klass) {
        return;
    }

    void *field = IL2CPP::il2cpp_class_get_field_from_name(klass, name);

    if (!field) {
        return;
    }

    IL2CPP::il2cpp_field_static_set_value(field, value);
}

class Il2CppString {
  private:
    void *str;

  public:
    // Constructors
    Il2CppString(const char *utf8Str) {
        str = IL2CPP::il2cpp_string_new(utf8Str);
    }

    Il2CppString(const wchar_t *utf16Str, int32_t length) {
        str = IL2CPP::il2cpp_string_new_utf16(utf16Str, length);
    }

    // Destructor
    ~Il2CppString() {
        // Release IL2CPP string if needed
    }

    // Get characters from the IL2CPP string
    uint16_t *getChars() { return IL2CPP::il2cpp_string_chars(str); }

    // Convert IL2CPP string to UTF-8
    std::string toUtf8String() {
        uint16_t *chars = getChars();
        if (!chars) {
            return "";
        }

        std::string utf8Str;
        for (int i = 0; chars[i] != '\0'; ++i) {
            utf8Str += static_cast<char>(chars[i]);
        }
        return utf8Str;
    }

    // Convert IL2CPP string to UTF-16
    std::wstring toUtf16String() {
        uint16_t *chars = getChars();
        if (!chars) {
            return L"";
        }

        std::wstring utf16Str;
        for (int i = 0; chars[i] != '\0'; ++i) {
            utf16Str += static_cast<wchar_t>(chars[i]);
        }
        return utf16Str;
    }

    // Get internal IL2CPP string pointer (if needed)
    void *getInternalString() { return str; }
};

class Il2CppField {
  private:
    void *image;
    void *klass;
    void *field;

  public:
    // Constructor initializes the image from assembly name
    Il2CppField(const char *assemblyName) {
        image = GetImage(assemblyName);
        if (!image) {
            //[menu showPopup:@"Error" description:@"Cannot find specified
            // image."];
            NSLog(@"Error: Cannot find specified image.");
        }
    }

    // Get class by namespace and class name
    Il2CppField &getClass(const char *namespaze, const char *className) {
        klass = IL2CPP::il2cpp_class_from_name(image, namespaze, className);
        if (!klass) {
            //[menu showPopup:@"Error" description:[NSString
            // stringWithFormat:@"Cannot find class %s in namespace %s.",
            // className, namespaze]];
            NSLog(@"Error: Cannot find class %s in namespace %s.", className,
                  namespaze);
        }
        return *this;
    }

    // Get field by field name
    Il2CppField &getField(const char *fieldName) {
        field = IL2CPP::il2cpp_class_get_field_from_name(klass, fieldName);
        if (!field) {
            //[menu showPopup:@"Error" description:[NSString
            // stringWithFormat:@"Cannot find field %s in class.", fieldName]];
            NSLog(@"Error: Cannot find field %s in class.", fieldName);
        }
        return *this;
    }

    // Get field offset
    size_t getOffset() const { return IL2CPP::il2cpp_field_get_offset(field); }

    // Get field value
    template <typename T> T getValue() {
        T value;
        IL2CPP::il2cpp_field_static_get_value(field, &value);
        return value;
    }

    // Set field value
    template <typename T> void setValue(T value) {
        IL2CPP::il2cpp_field_static_set_value(field, &value);
    }

    // Show field value using menu popup
    template <typename T> void showValue(const char *fieldName) {
        T value = getValue<T>();
        // NSString* message = [NSString stringWithFormat:@"%s Value = %d",
        // fieldName, value]; [menu showPopup:@"Field Value"
        // description:message];
        NSLog(@"%s Value = %d", fieldName, value);
    }
};

class Il2CppMethod {
  private:
    void *image;
    void *klass;
    void *method;

  public:
    // Constructor initializes the image from assembly name
    Il2CppMethod(const char *assemblyName) {
        image = GetImage(assemblyName);
        if (!image) {
            //[menu showPopup:@"Error" description:@"Cannot find specified
            // image."];
            NSLog(@"Error: Cannot find specified image.");
        }
    }

    // Get class by namespace and class name
    Il2CppMethod &getClass(const char *namespaze, const char *className) {
        klass = IL2CPP::il2cpp_class_from_name(image, namespaze, className);
        if (!klass) {
            //[menu showPopup:@"Error" description:[NSString
            // stringWithFormat:@"Cannot find class %s in namespace %s.",
            // className, namespaze]];
            NSLog(@"Error: Cannot find class %s in namespace %s.", className,
                  namespaze);
        }
        return *this;
    }

    // Get method by method name and number of arguments
    uint64_t getMethod(const char *methodName, int argsCount) {
        void **methodPointer =
            (void **)IL2CPP::il2cpp_class_get_method_from_name(
                klass, methodName, argsCount);
        if (!methodPointer || !*methodPointer) {
            //[menu showPopup:@"Error" description:[NSString
            // stringWithFormat:@"Cannot find method %s with %d arguments.",
            // methodName, argsCount]];
            NSLog(@"Error: Cannot find method %s with %d arguments.",
                  methodName, argsCount);
            return 0;
        }
        method = *methodPointer;

        MemoryInfo info = getBaseAddress("UnityFramework");
        uint64_t rvaOffset = reinterpret_cast<uint64_t>(method) - info.address;

        return rvaOffset;
    }

    // Invoke the method with given arguments
    template <typename Ret, typename... Args> Ret invoke(Args... args) {
        using MethodType = Ret (*)(Args...);
        MethodType methodFunc = reinterpret_cast<MethodType>(method);
        return methodFunc(args...);
    }
};

typedef void (*Il2CppMethodPointer)();

struct MethodInfo;

struct VirtualInvokeData {
    Il2CppMethodPointer methodPtr;
    const MethodInfo *method;
};

struct Il2CppType {
    void *data;
    unsigned int bits;
};

struct Il2CppClass;

struct Il2CppObject {
    Il2CppClass *klass;
    void *monitor;
};

union Il2CppRGCTXData {
    void *rgctxDataDummy;
    const MethodInfo *method;
    const Il2CppType *type;
    Il2CppClass *klass;
};

struct Il2CppClass_1 {
    void *image;
    void *gc_desc;
    const char *name;
    const char *namespaze;
    Il2CppType *byval_arg;
    Il2CppType *this_arg;
    Il2CppClass *element_class;
    Il2CppClass *castClass;
    Il2CppClass *declaringType;
    Il2CppClass *parent;
    void *generic_class;
    void *typeDefinition;
    void *interopData;
    void *fields;
    void *events;
    void *properties;
    void *methods;
    Il2CppClass **nestedTypes;
    Il2CppClass **implementedInterfaces;
    void *interfaceOffsets;
};

struct Il2CppClass_2 {
    Il2CppClass **typeHierarchy;
    uint32_t cctor_started;
    uint32_t cctor_finished;
    uint64_t cctor_thread;
    int32_t genericContainerIndex;
    int32_t customAttributeIndex;
    uint32_t instance_size;
    uint32_t actualSize;
    uint32_t element_size;
    int32_t native_size;
    uint32_t static_fields_size;
    uint32_t thread_static_fields_size;
    int32_t thread_static_fields_offset;
    uint32_t flags;
    uint32_t token;
    uint16_t method_count;
    uint16_t property_count;
    uint16_t field_count;
    uint16_t event_count;
    uint16_t nested_type_count;
    uint16_t vtable_count;
    uint16_t interfaces_count;
    uint16_t interface_offsets_count;
    uint8_t typeHierarchyDepth;
    uint8_t genericRecursionDepth;
    uint8_t rank;
    uint8_t minimumAlignment;
    uint8_t packingSize;
    uint8_t bitflags1;
    uint8_t bitflags2;
};

struct Il2CppClass {
    Il2CppClass_1 _1;
    void *static_fields;
    Il2CppRGCTXData *rgctx_data;
    Il2CppClass_2 _2;
    VirtualInvokeData vtable[255];
};

typedef int32_t il2cpp_array_size_t;
typedef int32_t il2cpp_array_lower_bound_t;
struct Il2CppArrayBounds {
    il2cpp_array_size_t length;
    il2cpp_array_lower_bound_t lower_bound;
};

struct MethodInfo {
    Il2CppMethodPointer methodPointer;
    void *invoker_method;
    const char *name;
    Il2CppClass *declaring_type;
    const Il2CppType *return_type;
    const void *parameters;
    union {
        const Il2CppRGCTXData *rgctx_data;
        const void *methodDefinition;
    };
    union {
        const void *genericMethod;
        const void *genericContainer;
    };
    int32_t customAttributeIndex;
    uint32_t token;
    uint16_t flags;
    uint16_t iflags;
    uint16_t slot;
    uint8_t parameters_count;
    uint8_t bitflags;
};

// template <typename T> struct Il2CppArray {
//     Il2CppClass *klass;
//     void *monitor;
//     void *bounds;
//     int max_length;
//     T m_Items[65535];
//
//     int getLength() { return max_length; }
//
//     T *getPointer() { return (T *)m_Items; }
//
//     T &operator[](int i) { return m_Items[i]; }
//
//     T &operator[](int i) const { return m_Items[i]; }
//
//     std::vector<T> toCPPlist() {
//         std::vector<T> ret;
//         ret.reserve(max_length);
//
//         for (int i = 0; i < max_length; i++) {
//             ret.push_back(m_Items[i]);
//         }
//
//         return ret;
//     }
// };

template <typename T> struct Il2CppArray {
    Il2CppClass *klass; // 0x00
    void *bounds;       // 0x08
    uint64_t length;    // 0x10
    T m_Items[1];       // 0x18

    T *getPointer() { return (T *)m_Items; }

    uint64_t getLength() { return length; }

    T &operator[](int i) { return m_Items[i]; }

    T &operator[](int i) const { return m_Items[i]; }

    std::vector<T> toCPPlist() {
        std::vector<T> ret;
        ret.reserve(length);

        for (int i = 0; i < length; i++) {
            ret.push_back(m_Items[i]);
        }

        return ret;
    }
};

template <typename T> using Array = Il2CppArray<T>;

// template <typename T> struct Il2CppList {
//     Il2CppClass *klass;
//     void *unk1;
//     Il2CppArray<T> *items;
//     int size;
//     int version;
//
//     T *getItems() { return items->getPointer(); }
//
//     int getSize() { return size; }
//
//     int getVersion() { return version; }
//
//     T &operator[](int i) { return items->m_Items[i]; }
//
//     T &operator[](int i) const { return items->m_Items[i]; }
//
//     std::vector<T> toCPPlist() {
//         std::vector<T> ret;
//         ret.reserve(size); // Reserve space in the vector for the items.
//
//         for (int i = 0; i < size; i++) {
//             ret.push_back(items->m_Items[i]);
//         }
//
//         return ret;
//     }
// };

template <typename T> struct Il2CppList {
    Il2CppClass *klass;      // 0x00
    Il2CppArray<T> *items;   // 0x08
    int size;                // 0x10
    int version;             // 0x14
    void *syncRootOrUnknown; // 0x18

    T *getItems() { return items ? items->getPointer() : nullptr; }

    int getSize() { return size; }

    int getVersion() { return version; }

    T &operator[](int i) { return items->m_Items[i]; }

    T &operator[](int i) const { return items->m_Items[i]; }

    std::vector<T> toCPPlist() {
        std::vector<T> ret;
        ret.reserve(size); // Reserve space in the vector for the items.

        for (int i = 0; i < size; i++) {
            ret.push_back(items->m_Items[i]);
        }

        return ret;
    }
};

template <typename T> using List = Il2CppList<T>;

template <typename K, typename V> struct Il2CppDictionary {
    Il2CppClass *klass;
    void *unk1;
    Il2CppArray<int **> *table;
    Il2CppArray<void **> *linkSlots;
    Il2CppArray<K> *keys;
    Il2CppArray<V> *values;
    int touchedSlots;
    int emptySlot;
    int size;

    K *getKeys() { return keys->getPointer(); }

    V *getValues() { return values->getPointer(); }

    int getNumKeys() { return keys->getLength(); }

    int getNumValues() { return values->getLength(); }

    int getSize() { return size; }
};

template <typename K, typename V> using Dictionary = Il2CppDictionary<K, V>;
