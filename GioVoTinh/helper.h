//
//  helper.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/18/26.
//

#import "../Utils/Quaternion.h"
#import "../Utils/Vector3.h"

int count(int num) {
    int div = 1, num1 = num;
    while (num1 != 0) {
        num1 = num1 / 10;
        div = div * 10;
    }
    return div;
}

Vector3 VInt2Vector(VInt3 location, VInt3 forward) {
    return Vector3((float)(location.X * count(forward.X) + forward.X) /
                       (1000 * count(forward.X)),
                   (float)(location.Y * count(forward.Y) + forward.Y) /
                       (1000 * count(forward.Y)),
                   (float)(location.Z * count(forward.Z) + forward.Z) /
                       (1000 * count(forward.Z)));
}

Vector3 RotateVectorByQuaternion(Quaternion q) {
    Vector3 v(0.0f, 0.0f, 1.0f);
    float w = q.w, x = q.x, y = q.y, z = q.z;

    Vector3 u(x, y, z);
    Vector3 cross1 = Vector3::Cross(u, v);
    Vector3 cross2 = Vector3::Cross(u, cross1);
    Vector3 result = v + 2.0f * cross1 * w + 2.0f * cross2;

    return result;
}

float SquaredDistance(Vector3 v, Vector3 o) {
    return (v.x - o.x) * (v.x - o.x) + (v.y - o.y) * (v.y - o.y) +
           (v.z - o.z) * (v.z - o.z);
}

template <typename T> static inline bool checkPointer(uintptr_t addr) {
    return addr && (addr & (alignof(T) - 1)) == 0;
}

static inline bool checkPointer64bits(uintptr_t addr) {
    return addr && (addr & 7) == 0;
}

template <typename T> T ReadMemorySafe(uintptr_t addr, T defaultValue = T()) {
    if (addr != 0) {
        constexpr size_t sz = sizeof(T);
        // Check alignment memory
        if constexpr ((sz & (sz - 1)) == 0) {
            if ((addr & (sz - 1)) != 0)
                return defaultValue;
        } else {
            if (addr % sz != 0)
                return defaultValue;
        }
        return *(T *)addr;
    }
    return defaultValue;
}

template <typename T> bool WriteMemorySafe(uintptr_t addr, T value) {
    if (addr != 0) {
        constexpr size_t sz = sizeof(T);
        // Check alignment memory
        if constexpr ((sz & (sz - 1)) == 0) {
            if ((addr & (sz - 1)) != 0)
                return false;
        } else {
            if (addr % sz != 0)
                return false;
        }
        *(T *)addr = value;
        return true;
    }
    return false;
}
