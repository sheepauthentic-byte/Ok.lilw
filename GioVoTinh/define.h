//
//  define.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/18/26.
//

#import "../Macros.h"
#import "../Security/oxorany/oxorany_include.h"
#import "helper.h"
#import "il2cpp.h"
#import "realName.h"
#include <string.h>

struct EntityInfo {
    Vector3 myPos;
    Vector3 enemyPos;
    Vector3 moveForward;
    int ConfigID;
    int ConfigIDLatest;
    bool isMoving;
    int currentSpeed;
    int Hud;
    int Hudh;
    int Level;
    int actorHp;
};

enum COM_PLAYERCAMP {
    ComPlayercampMid = 0,
    ComPlayercamp1 = 1,
    ComPlayercamp2 = 2,
    ComPlayercamp3 = 3,
    ComPlayercamp4 = 4,
    ComPlayercamp5 = 5,
    ComPlayercamp6 = 6,
    ComPlayercamp7 = 7,
    ComPlayercamp8 = 8,
    ComPlayercampCount = 9,
    ComPlayercampOb = 10,
    ComPlayercampInvalid = 254,
    ComPlayercampAll = 255
};

enum class TdrErrorType {
    TDR_NO_ERROR = 0,
    TDR_ERR_SHORT_BUF_FOR_WRITE = -1,
    TDR_ERR_SHORT_BUF_FOR_READ = -2,
    TDR_ERR_STR_LEN_TOO_BIG = -3,
    TDR_ERR_STR_LEN_TOO_SMALL = -4,
    TDR_ERR_STR_LEN_CONFLICT = -5,
    TDR_ERR_MINUS_REFER_VALUE = -6,
    TDR_ERR_REFER_SURPASS_COUNT = -7,
    TDR_ERR_ARG_IS_NULL = -8,
    TDR_ERR_CUTVER_TOO_SMALL = -9,
    TDR_ERR_CUTVER_CONFILICT = -10,
    TDR_ERR_PARSE_TDRIP_FAILED = -11,
    TDR_ERR_INVALID_TDRIP_VALUE = -12,
    TDR_ERR_INVALID_TDRTIME_VALUE = -13,
    TDR_ERR_INVALID_TDRDATE_VALUE = -14,
    TDR_ERR_INVALID_TDRDATETIME_VALUE = -15,
    TDR_ERR_FUNC_LOCALTIME_FAILED = -16,
    TDR_ERR_INVALID_HEX_STR_LEN = -17,
    TDR_ERR_INVALID_HEX_STR_FORMAT = -18,
    TDR_ERR_INVALID_BUFFER_PARAMETER = -19,
    TDR_ERR_NET_CUTVER_INVALID = -20,
    TDR_ERR_ACCESS_VILOATION_EXCEPTION = -21,
    TDR_ERR_ARGUMENT_NULL_EXCEPTION = -22,
    TDR_ERR_USE_HAVE_NOT_INIT_VARIABLE_ARRAY = -23,
    TDR_ERR_INVALID_FORMAT = -24,
    TDR_ERR_HAVE_NOT_SET_SIZEINFO = -25,
    TDR_ERR_VAR_STRING_LENGTH_CONFILICT = -26,
    TDR_ERR_VAR_ARRAY_CONFLICT = -27,
    TDR_ERR_BAD_TLV_MAGIC = -28,
    TDR_ERR_UNMATCHED_LENGTH = -29,
    TDR_ERR_UNION_SELECTE_FIELD_IS_NULL = -30,
    TDR_ERR_SUSPICIOUS_SELECTOR = -31,
    TDR_ERR_UNKNOWN_TYPE_ID = -32,
    TDR_ERR_LOST_REQUIRED_FIELD = -33,
    TDR_ERR_NULL_ARRAY = -34
};

class TdrReadBuf {
  private:
    std::vector<uint8_t> beginPtr;
    int32_t position;
    int32_t length;
    bool isNetEndian;

  public:
    bool isUseCache;
};

struct SwapItem {
    uint32_t id;
    std::string name;
    bool enabled;
    uint8_t number;
};
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(SwapItem, id, name, enabled, number)

class CActorInfo {
  public:
    std::string *ActorName() {
        return *(std::string **)((uintptr_t)this + ENCRYPTOFFSET("0x10"));
    }

    int hudHeight() {
        return *(int *)((uintptr_t)this + ENCRYPTOFFSET("0xD4"));
    }
};

struct CDInfo {
    float iconPosX;
    float iconPosY;
    std::string heroNameStr;
    uintptr_t skill1;
    uintptr_t skill2;
    uintptr_t skill3;
    uintptr_t skill4;
};

struct PassiveSkillInfo {
    uint32_t equipID;
    uint32_t passiveSkillID;
    void *passiveEvent;
};

class CEquipPassiveCdInfo {
  public:
    uint32_t get_m_passiveSkillId() {
        return ReadMemorySafe<uint32_t>((uintptr_t)this + ENCRYPTOFFSET("0x8"));
    }

    uint32_t get_m_passiveCd() {
        return ReadMemorySafe<uint32_t>((uintptr_t)this + ENCRYPTOFFSET("0xC"));
    }
};

class ActorLinker;
class LActorRoot;

struct ActorEntry {
    void *entryA;
    ActorLinker *actor;
};

class ValueLinkerComponent {
  public:
    int get_actorHp() {
        int (*get_actorHp_)(ValueLinkerComponent *objLinkerWrapper) = (int (*)(
            ValueLinkerComponent *))getRealOffset(ENCRYPTOFFSET("0x67BACB8"));
        return get_actorHp_(this);
    }

    int get_actorHpTotal() {
        int (*get_actorHpTotal_)(ValueLinkerComponent *objLinkerWrapper) =
            (int (*)(ValueLinkerComponent *))getRealOffset(
                ENCRYPTOFFSET("0x67BACC8"));
        return get_actorHpTotal_(this);
    }

    int get_GoldCoinInBattle() {
        int (*get_GoldCoinInBattle_)(ValueLinkerComponent *objLinkerWrapper) =
            (int (*)(ValueLinkerComponent *))getRealOffset(
                ENCRYPTOFFSET("0x67BACF8"));
        return get_GoldCoinInBattle_(this);
    }

    int Level() {
        return *(int *)((uintptr_t)this + ENCRYPTOFFSET("0x5C"));
    } // class ValueLinkerComponent | private object
      // <actorSoulLevel>k__BackingField; // 0x5C
};

class ActorConfig {
  public:
    int ConfigID() {
        return *(int *)((uintptr_t)this + ENCRYPTOFFSET("0x1C"));
    } // class ActorConfig | public object ConfigID; // 0x1C
};

class HudComponent3D {
  public:
    int Hud() {
        return *(int *)((uintptr_t)this + ENCRYPTOFFSET("0x34"));
    } // class HudComponent3D | public object HudType; // 0x34

    int Hudh() {
        return *(int *)((uintptr_t)this + ENCRYPTOFFSET("0x30"));
    } // class HudComponent3D | public object hudHeight; // 0x30
};

class VActorMovementComponent {
  public:
    int get_maxSpeed() {
        int (*get_maxSpeed_)(VActorMovementComponent *component) =
            (int (*)(VActorMovementComponent *))getRealOffset(
                ENCRYPTOFFSET("0x67C58E8"));
        return get_maxSpeed_(this);
    }
};

/*
struct PoolObjHandle {
 _handleSeq: 0x0 (4 bytes)
 _handleObj: 0x8 (8 bytes)
}
*/
template <typename T> class PoolObjHandle {
  public:
    uint32_t seq;     // 0x0 (4 bytes)
    uint32_t padding; // 0x4 (4 bytes)
    T *obj;           // 0x8 (8 bytes)

    uint32_t get_handleSeq() { return seq; }

    T *get_handleObj() { return obj; }
};

class ActorLinker {
  public:
    uintptr_t EquipLinkerComp() {
        // Return instance of class VEquipLinkerComponent
        return *(uintptr_t *)((uintptr_t)this +
                              ENCRYPTOFFSET(
                                  "0x20")); // class ActorLinker | public object
                                            // EquipLinkerComp; // 0x20
    }

    ValueLinkerComponent *ValueComponent() {
        return *(
            ValueLinkerComponent *
                *)((uintptr_t)this +
                   ENCRYPTOFFSET("0x28")); // class ActorLinker | public object
                                           // ValueComponent; // 0x28
    }

    ActorConfig *ObjLinker() {
        return *(ActorConfig **)((uintptr_t)this +
                                 ENCRYPTOFFSET(
                                     "0x118")); // class ActorLinker | public
                                                // object ObjLinker; // 0x118
    }

    VActorMovementComponent *MovementComponent() {
        return *(
            VActorMovementComponent *
                *)((uintptr_t)this +
                   ENCRYPTOFFSET("0x38")); // class ActorLinker | public object
                                           // MovementComponent; // 0x38
    }

    Vector3 get_position() {
        Vector3 (*get_position_)(ActorLinker *linker) = (Vector3(*)(
            ActorLinker *))(getRealOffset(ENCRYPTOFFSET("0x6782294")));
        return get_position_(this);
    }

    Quaternion get_rotation() {
        Quaternion (*get_rotation_)(ActorLinker *linker) = (Quaternion(*)(
            ActorLinker *))(getRealOffset(ENCRYPTOFFSET("0x6782044")));
        return get_rotation_(this);
    }

    bool IsHostCamp() {
        bool (*IsHostCamp_)(ActorLinker *linker) = (bool (*)(ActorLinker *))(
            getRealOffset(ENCRYPTOFFSET("0x678CA54")));
        return IsHostCamp_(this);
    }

    bool IsHostPlayer() {
        bool (*IsHostPlayer_)(ActorLinker *linker) = (bool (*)(ActorLinker *))(
            getRealOffset(ENCRYPTOFFSET("0x678CAB8")));
        return IsHostPlayer_(this);
    }

    bool isMoving() {
        return *(bool *)((uintptr_t)this +
                         ENCRYPTOFFSET("0x446")); // class ActorLinker | public
                                                  // object isMoving; // 0x446
    }

    Vector3 moveForward() {
        return *(
            Vector3 *)((uintptr_t)this +
                       ENCRYPTOFFSET("0x4F0")); // class ActorLinker | private
                                                // object moveForward; // 0x4F0
    }

    int groundSpeed() {
        return *(int *)((uintptr_t)this +
                        ENCRYPTOFFSET("0x4EC")); // class ActorLinker | private
                                                 // object groundSpeed; // 0x4EC
    }

    Vector3 get_logicMoveForward() {
        Vector3 (*get_logicMoveForward_)(ActorLinker *linker) = (Vector3(*)(
            ActorLinker *))(getRealOffset(ENCRYPTOFFSET("0x6781DF8")));
        return get_logicMoveForward_(this);
    }

    // Not found in file dump.cs
    Vector3 NormalMoveLerp() {
        Vector3 (*NormalMoveLerp)(ActorLinker *linker) =
            (Vector3(*)(ActorLinker *))(GetMethodOffset(
                oxorany("Project_d.dll"), oxorany("Kyrios.Actor"),
                oxorany("ActorLinker"), oxorany("NormalMoveLerp"), 4));
        return NormalMoveLerp(this);
    }

    bool get_bVisible() {
        bool (*get_bVisible_)(ActorLinker *linker) = (bool (*)(ActorLinker *))(
            getRealOffset(ENCRYPTOFFSET("0x67827B4")));
        return get_bVisible_(this);
    }

    uintptr_t AsHero() {
        uintptr_t (*AsHero_)(ActorLinker *linker) = (uintptr_t (*)(
            ActorLinker *))(getRealOffset(ENCRYPTOFFSET("0x678C7A4")));
        return AsHero_(this);
    }

    HudComponent3D *HudControl() {
        return *(HudComponent3D **)((uintptr_t)this +
                                    ENCRYPTOFFSET(
                                        "0x70")); // class ActorLinker | public
                                                  // object HudControl; // 0x70
    }
};

class LActorRoot {
  public:
    uintptr_t getEquipComponent() {
        return ReadMemorySafe<uintptr_t>(
            (uintptr_t)this +
            ENCRYPTOFFSET("0x318")); // class LActorRoot | public object
                                     // EquipComponent; // 0x318
    }

    uintptr_t getValueComponent() {
        return ReadMemorySafe<uintptr_t>(
            (uintptr_t)this +
            ENCRYPTOFFSET("0x308")); // class LActorRoot | public object
                                     // ValueComponent; // 0x308
    }

    uintptr_t getObjLinker() {
        return ReadMemorySafe<uintptr_t>(
            (uintptr_t)this +
            ENCRYPTOFFSET("0x338")); // class LActorRoot | public object
                                     // ObjLinker; // 0x338
    }
};

class ActorManager {
  public:
    List<ActorEntry> *GetAllHeros() {
        List<ActorEntry> *(*_GetAllHeros)(ActorManager *actorManager) =
            (List<ActorEntry> *
             (*)(ActorManager *))(getRealOffset(ENCRYPTOFFSET("0x679FCF8")));
        return _GetAllHeros(this);
    }

    List<ActorEntry> *GetAllMonsters() {
        List<ActorEntry> *(*_GetAllMonsters)(ActorManager *actorManager) =
            (List<ActorEntry> *
             (*)(ActorManager *))(getRealOffset(ENCRYPTOFFSET("0x679FE78")));
        return _GetAllMonsters(this);
    }
};

class KyriosFramework {
  public:
    static ActorManager *get_actorManager() {
        auto get_actorManager_ =
            (ActorManager * (*)())(getRealOffset(ENCRYPTOFFSET("0x6637718")));
        return get_actorManager_();
    }
};

namespace CSProtocol {

class COMDT_PLAYERINFO {
  public:
    uint8_t get_bObjCamp() {
        return ReadMemorySafe<uint8_t>(
            (uint64_t)this +
            ENCRYPTOFFSET("0x8")); // class COMDT_PLAYERINFO | public object
                                   // bObjCamp; // 0x8
    };

    uint8_t get_bObjType() {
        return ReadMemorySafe<uint8_t>(
            (uint64_t)this +
            ENCRYPTOFFSET("0x9")); // class COMDT_PLAYERINFO | public object
                                   // bObjType; // 0x9
    };

    const char *get_szName() {
        uintptr_t nameObj = ReadMemorySafe<uintptr_t>(
            (uintptr_t)this +
            ENCRYPTOFFSET("0x18")); // class COMDT_PLAYERINFO | public object
                                    // szName; // 0x18 | Array
        if (!checkPointer64bits(nameObj))
            return "";

        uint32_t len =
            ReadMemorySafe<uint32_t>(nameObj + ENCRYPTOFFSET("0x10"));

        if (len == 0 || len > 128)
            return "";

        return (const char *)(nameObj + ENCRYPTOFFSET("0x18"));
    }
};

class COMDT_HERO_COMMON_INFO {
  public:
    uint32_t getdwHeroID() {
        return *(
            uint32_t *)((uint64_t)this +
                        ENCRYPTOFFSET("0x8")); // class COMDT_HERO_COMMON_INFO |
                                               // public object dwHeroID; // 0x8
    };

    uint16_t getwSkinID() {
        return *(uint16_t *)((uint64_t)this +
                             ENCRYPTOFFSET(
                                 "0x3A")); // class COMDT_HERO_COMMON_INFO |
                                           // public object wSkinID; // 0x3A
    };

    void setdwHeroID(uint32_t dwHeroID) {
        *(uint32_t *)((uint64_t)this + ENCRYPTOFFSET("0x8")) =
            dwHeroID; // class COMDT_HERO_COMMON_INFO | public object dwHeroID;
                      // // 0x8
    };

    void setwSkinID(uint16_t wSkinID) {
        *(uint16_t *)((uint64_t)this + ENCRYPTOFFSET("0x3A")) =
            wSkinID; // class COMDT_HERO_COMMON_INFO | public object wSkinID; //
                     // 0x3A
    };
};

class COMDT_CHOICEHERO {
  public:
    uint8_t get_bSkinWakeLevel() {
        return ReadMemorySafe<uint8_t>(
            (uintptr_t)this +
            ENCRYPTOFFSET("0xC0")); // class COMDT_CHOICEHERO | public object
                                    // bSkinWakeLevel; // 0xC0
    }

    uint64_t get_ullSkinWakeFeatureMask() {
        return ReadMemorySafe<uint64_t>(
            (uintptr_t)this +
            ENCRYPTOFFSET("0xC8")); // class COMDT_CHOICEHERO | public object
                                    // ullSkinWakeFeatureMask; // 0xC8
    }

    void set_bSkinWakeLevel(uint8_t value) {
        WriteMemorySafe<uint8_t>((uintptr_t)this + ENCRYPTOFFSET("0xC0"),
                                 value); // class COMDT_CHOICEHERO | public
                                         // object bSkinWakeLevel; // 0xC0
    }

    void set_ullSkinWakeFeatureMask(uint64_t value) {
        WriteMemorySafe<uint64_t>(
            (uintptr_t)this + ENCRYPTOFFSET("0xC8"),
            value); // class COMDT_CHOICEHERO | public object
                    // ullSkinWakeFeatureMask; // 0xC8
    }
};

struct saveData {
    static uint32_t heroId;
    static uint16_t skinId;
    static uint16_t skinIdOrig;
    static bool enable;
    static std::pair<COMDT_HERO_COMMON_INFO *, uint16_t> unpackSkin;

    static void setEnable(bool eb) { enable = eb; }

    static uint32_t getHeroId() { return heroId; }

    static uint16_t getSkinId() { return skinId; }

    static uint16_t getSkinIdOrig() { return skinIdOrig; }

    static void setData(uint32_t hId, uint16_t sId) {
        heroId = hId;
        skinId = sId;
    }

    static void setSkinIdOrig(uint16_t sId) {
        if (sId == 0 || sId == skinId)
            return;
        skinIdOrig = sId;
    }

    static void setDataUnpackSkin(COMDT_HERO_COMMON_INFO *instance,
                                  uint16_t skinId) {
        unpackSkin.first = instance;
        unpackSkin.second = skinId;
    }

    static void applyOrigSkins() {
        if (!unpackSkin.first)
            return;

        unpackSkin.first->setwSkinID(unpackSkin.second);
    }

    static void applyModSkins() {
        if (!unpackSkin.first)
            return;

        unpackSkin.first->setwSkinID(skinId);
    }

    static void clearCachedHeroInfos() {
        unpackSkin.first = nullptr;
        unpackSkin.second = 0;
    }

    static bool getEnable() { return enable; }
};

uint32_t saveData::heroId = 0;
uint16_t saveData::skinId = 0;
uint16_t saveData::skinIdOrig = 0;
bool saveData::enable = false;
std::pair<COMDT_HERO_COMMON_INFO *, uint16_t> saveData::unpackSkin;
} // namespace CSProtocol
