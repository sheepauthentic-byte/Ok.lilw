#import "../Macros.h"
#import "Foundation/Foundation.h"
#include <chrono>

// Store address
uint32_t currentPlayerID = 0;
uint32_t playerID = 0;
uintptr_t summonerSpell; // Bổ trợ
uintptr_t skill1;        // Chiêu 1
uintptr_t skill2;        // Chiêu 2
uintptr_t skill3;        // Chiêu 3
uintptr_t m_isCharging;
uintptr_t m_currentSkillSlotType;
uint64_t skillSlotOffset;
uint64_t skillComponentOffset;
uint64_t instanceSkillComponentSelf;
uint64_t onClickSelectHeroSkinOffset;
uint64_t heroSelectBanPickOnSkinSelectOffset;
uint64_t heroSelectBanPickOnHeroSkinWearSucOffset;
uint64_t heroSelectBanPickOnHeroSkinWearFailOffset;
uint64_t isCanUseSkinOffset;
uint64_t getHeroWearSkinIdOffset;
uint64_t isHaveHeroSkinOffset;
uint64_t getCurrentRankDetailOffset;
uint64_t tryShowLegendRankOffset;
uint64_t isShowLegendRankModeOffset;
uint64_t unpack_COMDT_TOP_OR_AREA_LEGEND_TITLE_INFO_Offset;
uint64_t unpackOffset;
uint64_t canPlayerShowLegendRankOffset;
uint64_t actorLink_updateOffset;
uint64_t getLegendTitleAreaTypeOffset;
uint64_t validOffset;
uint64_t setLegendTitleCompleteOffset;
uint64_t getPlayerOffset;
uint64_t actorLink_destroyOffset;
uint64_t lactor_updateLogic;
uint64_t lactor_destroy;
uint64_t hackMapOffset;
uint64_t showRankOffset;
uint64_t showSummonerSpellOffset;
uint64_t autoWinOffset;
uint64_t camOffset;
uint64_t getMasterRoleInfoOffset;
uint64_t updateOffset;
uint64_t updateLogicOffset;
uint64_t skillDirectOffset;
uint64_t isOpenOffset;
uint64_t buttonOffset;
uint64_t updateFrameLaterOffset;
uint64_t sampleFrameSyncDataOffset;
uint64_t handleReportFirebase;
uint64_t handleUpdate;
uint64_t onHashCheckRsp;
uint64_t enequeHashOffset;
uint64_t setLoginOffset;
uint64_t showHistoryOffset;
uint64_t onEnterOffset;
uint64_t endGameOffset;
uint64_t disconnectOffset;
uint64_t isPlayerOffset;
uint64_t hideUIDOffset;
uint64_t showUltiEnemyInGameOffset;
uint64_t showInfoEnemyInGameOffset;
uint64_t skinResourceModifyBeginLoadMsgOffset;
uint64_t skinResourceGetOriSkinIdOffset;
uint64_t skinHelperGetSkinCfgIdOffset;
uint64_t killUTGetNotifyOffset;
uint64_t killUTGETNotifyOffset;
uint64_t battleEquipSystemUpdateOffset;
uint64_t lEquipComponent_UpdateLogicOffset;
uint64_t passiveSkill_InitOffset;
uint64_t passiveEvent_UnInitOffset;
uint64_t characterCustomizationUtils_GetComponentBattleEffectFlagOffset;
uint64_t characterCustomizationUtils_HandleSkinCustomizationImplOffset;
uint64_t actorServerDataProvider_ConvertServerHeroInfoOffset;
uint64_t gameBuilderProxy_HandlePreLoadDateSkinDegeneratedOffset;
uint64_t mobaUtility_SpawnActorOffset;
uint64_t unpack_COMDT_CHOICEHERO_Offset;
uint64_t unpack_COMDT_PLAYERINFO_Offset;

// Store Data
static EntityInfo EnemyCache;
static void *Lactor = nullptr;
static void *g_HostLActorRoot = nullptr;
static void *hostEquipComp = nullptr;
static EntityManager *espManager;
static EntityManager *ActorLinker_enemy;
static std::unordered_map<int, int> modKillNotifyMap;
static std::vector<std::string> modKillNotifyOptions;
static std::vector<int> modKillNotifyValues;
static std::vector<std::string> modSkinButtonOptions;
static std::vector<int> modSkinButtonValues;
static int themeID = 0;
static std::vector<SwapItem> swapItems;
static const std::vector<SwapItem> swapItemsDefault = {
    {1337, ENCRYPT("Giáp hộ mệnh"), false, 0},
    {11271, ENCRYPT("Liềm đoạt mệnh"), false, 0},
    {1242, ENCRYPT("Băng sương"), false, 0},
    {1328, ENCRYPT("Hercule thịnh nộ"), false, 0},
    {1149, ENCRYPT("Thương khung kiếm"), false, 0},
    {1340, ENCRYPT("Nham thuẫn"), false, 0}};
static void *lastBattleEquipSystemInstance = nullptr;
static int resurrectUsedCount = 0;
static std::set<int32_t> hostProccedPassives;
static void *logicalEquipComp = nullptr;
static uintptr_t myActorServerData = 0;
static uintptr_t modVisualData = 0;
/*
Giáp hộ mệnh => equipID: 1337, passiveSkillID: 91337
Liềm đoạt mệnh => equipID: 11271, passiveSkillID: 911271
Hercule thịnh nộ => equipID: 1328, passiveSkillID: 91328
Thương khung kiếm => equipID: 1149
Băng sương => equipID: 1242
Nham thuẫn => equipID: 1340
*/
static std::unordered_map<uint32_t, PassiveSkillInfo> passiveSkillInfoMap = {
    {1337, {1337, 91337, nullptr}},
    {11271, {11271, 911271, nullptr}},
    {1328, {1328, 91328, nullptr}}};
static std::unordered_map<uint32_t, uint32_t> currentCDLatestMap;
static std::unordered_map<uint32_t, uint32_t> currentCDCurrentMap;
static float lastCameraHeight = -1.0f;
static CSProtocol::COMDT_PLAYERINFO *instance_COMDT_PLAYERINFO_cache = nullptr;
static CSProtocol::COMDT_HERO_COMMON_INFO
    *instance_COMDT_HERO_COMMON_INFO_cache = nullptr;

// Store Flag
static bool modNotify = false;
static int selectedKillNotify = 0;
static int modeNotify = 1;
static bool isJsonLoaded = false;
static bool espEnable;
static bool playerLine;
static bool showNumberOfEnemies;
static bool playerBox;
static bool playerHealth;
static bool playerName;
static bool playerDistance;
static bool enableAimbot = false;
static float cameraHeight = 1;
static const float minCameraHeight = 1;
static const float maxCameraHeight = 10;
static bool ignoreDrawEnemyVisible = false;
static bool autoPunish = false; // Auto trừng trị
static bool onlyPunishDragonOrCaesar = false;
static bool frozen = false;  // Flag Băng sương
static bool execute = false; // Flag Bộc phá
static bool heal = false;    // Flag Hồi máu
static bool healing = false; // Flag Cấp cứu
static int slot;
static float hpHealDefault = 50;
static float hpHeal = hpHealDefault; // % HP Hồi máu
static float hpFrozenDefault = 20;
static float hpFrozen = hpFrozenDefault; // % HP Băng sương
static float hpExecuteDefault = 13.79;
static float hpExecute = hpExecuteDefault; // % HP Bộc phá
static float hpHealingDefault = 30;
static float hpHealing = hpHealingDefault; // % HP Cấp cứu
static bool modSkinButton = false;
static int modeSkinButton = 1;
static int selectedButton = 0;
static uint32_t currentHeroId = 0;
static uint32_t currentSkinId = 0;
static bool isCharging;
static int aimType = 0;
static int drawType = 0;
static int skillSlot;
static float aimDistance = 25.0f;
static float aimSpeed = 0.45f;
static bool hackMap = false;
static bool unlockSkin = false;
static bool blockHost = false;
static int blockHostOption = 1;
static int bypassDelay = 10;
static int renamePlayerMode = 0;
static char customNamePlayer[64] = "";
static NSMutableDictionary *heroTextures;
static bool aimSkill1 = false;
static bool aimSkill2 = false;
static bool aimSkill3 = false;
static std::vector<int> activeSkills;
static ImVec4 lineDrawAimColor = ImVec4(1.0f, 0.0f, 0.0f, 1.0f);
static std::string nameReal;
static bool unlockModRank;
static int fakeStars = 1;
static int fakeRank = 28;
static int fakeRankIndex = 0;
static int fakeMark = 1;
static int topRank = 1;
static int topHero = 0;
static bool hideUID;
static bool showRank;
static bool showInfoEnemyInGame;
static bool showUltiEnemyInGame;
static bool showSummonerSpell;
static bool showHistory;
static bool modTextKillNotifyFirstKill;
static bool modTextKillNotifyKill;
static bool modTextKillNotifyDoubleKill;
static bool modTextKillNotifyTripleKill;
static bool modTextKillNotifyQuataKill;
static bool modTextKillNotifyPentaKill;
static bool modTextKillNotifyGotcha;
static bool modTextKillNotifyLegend;
static bool modTextKillNotifyLegendary;
static bool modTextKillNotifyHallow;
static bool modTextKillNotifyDestroyTower;
static bool modTextKillNotifyAce;
static bool modTextKillNotifyShutdown;
static bool modTextKillNotifyMinionSuperStart;
static bool modTextKillNotifyKillCeasar;
static bool modTextKillNotifyKillDarkCeasar;
static bool modTextKillNotifyKillDarkTyrantCeasar;
static bool modTextKillNotifyKillDragon;
static bool modTextKillNotifyKillLightDragon;
static char modTextKillNotifyFirstKillText[64] = "";
static char modTextKillNotifyKillText[64] = "";
static char modTextKillNotifyDoubleKillText[64] = "";
static char modTextKillNotifyTripleKillText[64] = "";
static char modTextKillNotifyQuataKillText[64] = "";
static char modTextKillNotifyPentaKillText[64] = "";
static char modTextKillNotifyGotchaText[64] = "";
static char modTextKillNotifyLegendText[64] = "";
static char modTextKillNotifyLegendaryText[64] = "";
static char modTextKillNotifyHallowText[64] = "";
static char modTextKillNotifyDestroyTowerText[64] = "";
static char modTextKillNotifyAceText[64] = "";
static char modTextKillNotifyShutdownText[64] = "";
static char modTextKillNotifyMinionSuperStartText[64] = "";
static char modTextKillNotifyKillCeasarText[64] = "";
static char modTextKillNotifyKillDarkCeasarText[64] = "";
static char modTextKillNotifyKillDarkTyrantCeasarText[64] = "";
static char modTextKillNotifyKillDragonText[64] = "";
static char modTextKillNotifyKillLightDragonText[64] = "";
static bool autoBuyFirstRecItem;
static bool autoSwapEquipEnabled;
static bool matchStateInitialized;

// Helper
using CreateStringUtf16Fn = monoString *(*)(const uint16_t *value,
                                            int startIndex, int length);
monoString *CreateMonoString(const char *utf8) {
    static auto CreateStringUtf16 =
        reinterpret_cast<CreateStringUtf16Fn>(getRealOffset(ENCRYPTOFFSET(
            "0x39AD9F8"))); // class String | private static object Ctor(object
                            // ptr, object startIndex, object length) { } //
                            // RVA: 0x39AD9F8

    if (!CreateStringUtf16)
        return nullptr;
    if (!utf8)
        utf8 = "";

    NSString *ns = [NSString stringWithUTF8String:utf8];
    if (!ns)
        ns = @"";

    NSUInteger len = ns.length;
    if (len == 0)
        return CreateStringUtf16(nullptr, 0, 0);

    std::vector<uint16_t> buf(len);
    [ns getCharacters:reinterpret_cast<unichar *>(buf.data())
                range:NSMakeRange(0, len)];

    return CreateStringUtf16(buf.data(), 0, (int)len);
}

int msToSeconds(int ms) { return ms <= 0 ? 0 : ((ms + 999) / 1000); }

// Define function orig
bool (*RequestUseSkill)(void *instance);
bool (*RequestUseSkillSlot)(void *instance, int slot, int mode, int objID,
                            int subSkillID);
bool (*ActorLinker_IsHostPlayer)(void *instance);
int (*ActorLinker_ActorTypeDef)(void *instance);
int (*ActorLinker_COM_PLAYERCAMP)(void *instance);
Vector3 (*ActorLinker_getPosition)(void *instance);
bool (*ActorLinker_get_bVisible)(void *instance);
uintptr_t (*LActorRoot_LHeroWrapper)(void *instance);
int (*LActorRoot_COM_PLAYERCAMP)(void *instance);
bool (*LObjWrapper_get_IsDeadState)(void *instance);
bool (*ObjLinkerWrapper_get_IsDeadState)(void *instance);
bool (*LObjWrapper_IsAutoAI)(void *instance);
int (*ValuePropertyComponent_get_actorHp)(void *instance);
int (*ValuePropertyComponent_get_actorHpTotal)(void *instance);
uintptr_t (*AsHero)(void *);
monoString *(*_SetPlayerName)(uintptr_t, monoString *, monoString *, bool,
                              monoString *);
void (*old_RefreshHeroPanel)(void *instance, bool bForceRefreshAddSkillPanel,
                             bool bRefreshSymbol, bool bRefreshHeroSkill);
void *(*get_VHostLogic)();
List<void *> *(*PlrList)(void *ins);
bool (*SkillSlot_get_IsCDReady)(void *instance);
int (*SkillSlot_get_CurSkillID)(void *instance);
void (*SendBuyEquipFrameCommand)(void *instance, uint32_t equipID,
                                 bool isQuicklyBuy);
void *(*GetEquipInfo)(uint32_t ID);          // Get info item by item id
void *(*get_HostEquipComp)(void *instance);  // Get list item bought
void *(*get_m_hostCtrlHero)(void *instance); // Get info hero => Get coins
void (*SendSellEquipFrameCommand)(void *instance,
                                  uint32_t slotIndex); // Request sell item
uint32_t (*GetEquipActiveSkillCD)(
    void *instance, uint32_t InEquipID); // Get CD skill item active
void (*GMSetOriSkinId)(uint64_t, uint32_t, uint32_t);
uint32_t (*GetOriSkinId)(uint64_t, uint32_t);
void (*OnCameraHeightChanged)(void *player);
bool (*get_m_hostCtrlHeroPermitedToBuyEquip)(void *);
void *(*GetQuickBuyUIView)(void *);
monoString *(*get_HostName)();

// Orig & Hook Function
// ================= ESP =================

void (*old_ActorLinker_Update)(void *instance);
void ActorLinker_Update(void *instance) {
    if (!instance)
        return old_ActorLinker_Update(instance);

    const bool needName = renamePlayerMode != 0;
    const bool needTrack = espEnable || enableAimbot;

    if (!needName && !needTrack) {
        return old_ActorLinker_Update(instance);
    }

    uintptr_t HudControl =
        *(uintptr_t *)((uintptr_t)instance +
                       ENCRYPTOFFSET("0x70")); // class ActorLinker | public
                                               // object HudControl; // 0x70
    if (renamePlayerMode != 0 && HudControl > 0) {
        // Show name countdown skill
        if (renamePlayerMode == 1) {
            /*
            AsHero return HeroWrapperData
            struct HeroWrapperData {
                float currentCD; // 0x1C
                float maxCD; // 0x4
            }
            heroWrapSkillData_1 // 0x20 | Skill 1
            heroWrapSkillData_2 // 0x40 | Skill 2
            heroWrapSkillData_3 // 0x60 | Skill 3
            heroWrapSkillData_4 // 0x80
            heroWrapSkillData_5 // 0xA0 | Phép bổ trợ
            heroWrapSkillData_ex3 // 0xC0
            */
            uintptr_t SkillControl = AsHero(instance);
            if (SkillControl > 0) {
                int Skill1Cd = msToSeconds(
                    *(int *)(SkillControl + (skill1 + ENCRYPTOFFSET("0x1C"))));
                int Skill2Cd = msToSeconds(
                    *(int *)(SkillControl + (skill2 + ENCRYPTOFFSET("0x1C"))));
                int Skill3Cd = msToSeconds(
                    *(int *)(SkillControl + (skill3 + ENCRYPTOFFSET("0x1C"))));
                int SkillSmmpnorSpellCd = msToSeconds(
                    *(int *)(SkillControl +
                             (summonerSpell + ENCRYPTOFFSET("0x1C"))));
                string sk1, sk2, sk3, sk4;

                sk1 = (Skill1Cd == 0)
                          ? ENCRYPT(" [C1] ")
                          : ENCRYPT(" [") + to_string(Skill1Cd) + ENCRYPT("] ");
                sk2 = (Skill2Cd == 0)
                          ? ENCRYPT(" [C2]")
                          : ENCRYPT(" [") + to_string(Skill2Cd) + ENCRYPT("] ");
                sk3 = (Skill3Cd == 0)
                          ? ENCRYPT(" [C3] ")
                          : ENCRYPT(" [") + to_string(Skill3Cd) + ENCRYPT("] ");
                sk4 = (SkillSmmpnorSpellCd == 0)
                          ? ENCRYPT(" [BO TRO] ")
                          : ENCRYPT(" [") + to_string(SkillSmmpnorSpellCd) +
                                ENCRYPT("] ");

                string ShowSkill = sk1 + sk2 + sk3;
                string ShowSkill2 = sk4;
                const char *str1 = ShowSkill.c_str();
                const char *str2 = ShowSkill2.c_str();

                monoString *playerName = CreateMonoString(str1);
                monoString *prefixName = CreateMonoString(str2);
                monoString *customName = CreateMonoString("");
                _SetPlayerName(HudControl, playerName, prefixName, true,
                               customName);
            }
        } else if (renamePlayerMode == 2) { // Show name custom
            monoString *playerName = CreateMonoString(customNamePlayer);
            monoString *prefixName = CreateMonoString("");
            monoString *customName = CreateMonoString("");
            _SetPlayerName(HudControl, playerName, prefixName, true,
                           customName);
        }
    }
    old_ActorLinker_Update(instance);

    if (ActorLinker_ActorTypeDef(instance) == 0) {
        if (ActorLinker_IsHostPlayer(instance) == true) {
            espManager->tryAddMyPlayer(instance);
            Lactor = instance;
        } else {
            if (espManager->myPlayer != NULL) {
                if (ActorLinker_COM_PLAYERCAMP(espManager->myPlayer) !=
                    ActorLinker_COM_PLAYERCAMP(instance)) {
                    ActorLinker_enemy->tryAddEnemy(instance);
                }
            }
        }
    }
}

void (*old_LActorRoot_UpdateLogic)(void *instance, int delta);
void LActorRoot_UpdateLogic(void *instance, int delta) {
    if (instance != NULL) {
        old_LActorRoot_UpdateLogic(instance, delta);
        if (espManager->myPlayer != NULL) {
            if (LActorRoot_LHeroWrapper(instance) != uintptr_t(NULL)) {
                if (LActorRoot_COM_PLAYERCAMP(instance) ==
                    ActorLinker_COM_PLAYERCAMP(espManager->myPlayer)) {
                    espManager->tryAddEnemy(instance);
                } else {
                    g_HostLActorRoot = instance;
                }
            }
        }
    }
}

void (*old_ActorLinker_ActorDestroy)(void *instance);
void ActorLinker_ActorDestroy(void *instance) {
    if (instance != NULL) {
        old_ActorLinker_ActorDestroy(instance);
        ActorLinker_enemy->removeEnemyGivenObject(instance);
        if (espManager->myPlayer == instance) {
            espManager->myPlayer = NULL;
        }
        if (Lactor == instance) {
            Lactor = NULL;
        }
    }
}

void (*old_LActorRoot_ActorDestroy)(void *instance, bool bTriggerEvent);
void LActorRoot_ActorDestroy(void *instance, bool bTriggerEvent) {
    if (instance != NULL) {
        old_LActorRoot_ActorDestroy(instance, bTriggerEvent);
        espManager->removeEnemyGivenObject(instance);
    }
}

// ================= HACK MAP =================

void (*old_SetVisible)(void *instance, COM_PLAYERCAMP camp, bool bVisible,
                       bool forceSync);
void SetVisible(void *instance, COM_PLAYERCAMP camp, bool bVisible,
                bool forceSync) {
    if (instance != NULL && hackMap) {
        bVisible = true;
        forceSync = false;
    }
    return old_SetVisible(instance, camp, bVisible, forceSync);
}

// ================= CAMERA HEIGHT =================

void (*old_LateUpdate)(void *player);
void LateUpdate(void *player) {
    if (player != nullptr) {
        if (cameraHeight != lastCameraHeight) {
            OnCameraHeightChanged(player);
            lastCameraHeight = cameraHeight;
        }
    }
    return old_LateUpdate(player);
}

float (*old_GetZoomRate)(void *player);
float GetZoomRate(void *player) {
    float original = old_GetZoomRate(player);

    if (player == nullptr) {
        return original;
    }

    return fmaxf(original, cameraHeight);
}

// ================= AIMBOT =================

Vector3 calculateSkillDirection(Vector3 myPosi, Vector3 enemyPosi,
                                bool isMoving, Vector3 moveForward,
                                int currentSpeed) {
    if (isMoving) {
        float distance = Vector3::Distance(myPosi, enemyPosi);
        float bulletTime = distance / (aimDistance / aimSpeed);

        enemyPosi += Vector3::Normalized(moveForward) *
                     (currentSpeed / 1000.0f) * bulletTime;
    }

    Vector3 direction = enemyPosi - myPosi;
    direction.Normalize();
    return direction;
}

Vector3 (*old_GetUseSkillDirection)(void *instance, bool isTouchUse);
Vector3 GetUseSkillDirection(void *instance, bool isTouchUse) {
    if (instance != NULL && enableAimbot && EnemyCache.ConfigID != 0) {
        if (EnemyCache.myPos != Vector3::zero() &&
            EnemyCache.enemyPos != Vector3::zero() &&
            std::find(activeSkills.begin(), activeSkills.end(), skillSlot) !=
                activeSkills.end()) {
            return calculateSkillDirection(
                EnemyCache.myPos, EnemyCache.enemyPos, EnemyCache.isMoving,
                EnemyCache.moveForward, EnemyCache.currentSpeed);
        }
    }
    return old_GetUseSkillDirection(instance, isTouchUse);
}

// ================= AUTO =================

bool (*old_UpdateLogic)(void *instance, int delta);
bool UpdateLogic(void *instance, int delta) {
    if (instance != NULL) {
        isCharging = *(bool *)((uintptr_t)instance + m_isCharging);
        skillSlot = *(int *)((uintptr_t)instance + m_currentSkillSlotType);
    }
    return old_UpdateLogic(instance, delta);
}

void (*old_skillComponentUpdateFunc)(void *ins, int del);
void skillComponentUpdateFunc(void *ins, int del) {
    old_skillComponentUpdateFunc(ins, del);

    if (ins != nullptr) {
        void *(*GetSkillSlot)(void *instance, int slot) =
            (void *(*)(void *, int))getRealOffset(
                ENCRYPTOFFSET("0x5F26B3C")); // class SkillComponent | public
                                             // object GetSkillSlot(object slot)
                                             // { } // RVA: 0x5F26B3C
        void *skillSlot = GetSkillSlot(ins, 5); // Lấy slot phép bổ trợ
        if (skillSlot == nullptr) {
            return;
        }

        int slot = *(int *)((uintptr_t)skillSlot +
                            ENCRYPTOFFSET("0x80")); // class SkillSlot | public
                                                    // object SlotType; // 0x80
        bool checkActor =
            *(bool *)((uintptr_t)skillSlot +
                      ENCRYPTOFFSET("0x70")); // class SkillSlot | public object
                                              // Actor; // 0x70

        if (checkActor && slot == 5) {
            instanceSkillComponentSelf = (uint64_t)ins;
        }
    }
}

// public object LateUpdate(object nDelta) { }
void (*old_skillSlotFunc)(void *ins, int del);
void skillSlotFunc(void *ins, int del) {
    if (!frozen && !heal && !healing && !execute && !autoPunish) {
        return old_skillSlotFunc(ins, del);
    }

    if (ins != NULL) {
        /*
        slot: Int (SlotType) | public object SlotType; // 0x80
        slot: 0 -> Đánh thường
        slot: 1 -> Chiêu 1
        slot: 2 -> Chiêu 2
        slot: 3 -> Chiêu 3
        slot: 4 -> 90013: Hồi máu (5v5) | 80115: Tốc biến (3v3)
        slot: 5 -> Bổ trợ
                -> 80104: Trừng trị
                -> 80116: Tê tái
                -> 80503: Tự bảo tồn
                -> 80504: Lá chắn sinh mệnh
                -> 80109: Tốc hành
                -> 80108: Bộc phá
                -> 80110: Gầm thét
                -> 80102: Cấp cứu
                -> 80105: Suy nhược
                -> 80103: Ngất ngư
                -> 80115: Tốc biến
        slot: 6 -> 90005: Biến về (5v5) | 90013: Hồi máu (3v3)
        slot: 9 -> Đồ đã mua (Băng sương, Cung tà ma, ...)
                -> 91145: Cung tà ma
                -> 91149: Thương khung kiếm
                -> 80112: Băng sương
                -> 91020: Nham thuẫn
                -> 91148: Xạ nhật cung
        */
        slot = *(int *)((uintptr_t)ins +
                        ENCRYPTOFFSET("0x80")); // class SkillSlot | public
                                                // object SlotType; // 0x80
    }

    bool needSelfHpCheck = (frozen && slot == 9) ||
                           (heal && (slot == 4 || slot == 6)) ||
                           (healing && slot == 5);
    bool needSkillMeta = ((slot == 4 || slot == 6) && heal) ||
                         (slot == 5 && (healing || execute || autoPunish)) ||
                         (slot == 9 && frozen);
    bool get_IsCDReady = false;
    int get_CurSkillID = 0;
    if (ins != NULL && needSkillMeta) {
        get_IsCDReady = SkillSlot_get_IsCDReady(ins);
        get_CurSkillID = SkillSlot_get_CurSkillID(ins);
    }

    // Băng sương - Hồi máu - Cấp cứu
    if (needSelfHpCheck && get_IsCDReady && Lactor != NULL) {
        auto valueComponent =
            *(uintptr_t *)((uintptr_t)Lactor +
                           ENCRYPTOFFSET(
                               "0x28")); // class ActorLinker | public object
                                         // ValueComponent; // 0x28
        if (valueComponent != 0) {
            int hp = *(
                int *)((uintptr_t)valueComponent +
                       ENCRYPTOFFSET(
                           "0x40")); // class ValueLinkerComponent | private
                                     // object <actorHp>k__BackingField; // 0x40
            int hpTotal =
                *(int *)((uintptr_t)valueComponent +
                         ENCRYPTOFFSET(
                             "0x44")); // class ValueLinkerComponent | private
                                       // object <actorHpTotal>k__BackingField;
                                       // // 0x44
            float percentHP = ((float)hp / (float)hpTotal) * 100.0f;

            if (frozen && percentHP <= hpFrozen && slot == 9 &&
                hpFrozen > 1.0f && get_CurSkillID == 80112 && get_IsCDReady) {
                RequestUseSkill(ins); // Sử dụng Băng Sương
            } // Hết Băng Sương

            if (heal && percentHP <= hpHeal && (slot == 4 || slot == 6) &&
                get_CurSkillID == 90013 && get_IsCDReady && hpHeal > 1.0f) {
                RequestUseSkill(ins); // Sử dụng Hồi Máu
            } // Hết Hồi Máu

            if (healing && percentHP <= hpHealing && slot == 5 &&
                hpHealing > 1.0f && get_CurSkillID == 80102 && get_IsCDReady) {
                RequestUseSkill(ins); // Sử dụng Cấp Cứu
            } // Hết Cứu
        }
    }

    bool needExecuteScan =
        execute && slot == 5 && get_IsCDReady && get_CurSkillID == 80108;
    bool needPunishScan = autoPunish && slot == 5 && get_IsCDReady &&
                          (get_CurSkillID == 80104 || get_CurSkillID == 80116);

    if (needExecuteScan || needPunishScan) {
        static auto lastScanTime = std::chrono::steady_clock::time_point{};
        auto now = std::chrono::steady_clock::now();
        if (now - lastScanTime < std::chrono::milliseconds(50)) {
            return old_skillSlotFunc(ins, del);
        }
        lastScanTime = now;

        // Get object manager all actors in game
        ActorManager *get_actorManager = KyriosFramework::get_actorManager();
        if (get_actorManager == nullptr)
            return old_skillSlotFunc(ins, del);

        // Get all players
        List<ActorEntry> *GetAllHeros = get_actorManager->GetAllHeros();
        if (GetAllHeros == nullptr)
            return old_skillSlotFunc(ins, del);
        // Convert to C Pointer Array
        ActorEntry *actorLinkers = GetAllHeros->getItems();
        if (GetAllHeros->getSize() > 0 && actorLinkers == nullptr)
            return old_skillSlotFunc(ins, del);

        // Scan => Get info my player (position, configID, level)
        for (int i = 0; i < GetAllHeros->getSize(); i++) {
            ActorLinker *actorLinker = actorLinkers[i].actor;
            if (actorLinker == nullptr)
                continue;

            if (actorLinker->IsHostPlayer()) {
                EnemyCache.myPos = actorLinker->get_position();
                EnemyCache.ConfigID = actorLinker->ObjLinker()->ConfigID();
                EnemyCache.Level = actorLinker->ValueComponent()->Level();
            }

            if (actorLinker->IsHostCamp() || !actorLinker->get_bVisible() ||
                actorLinker->ValueComponent()->get_actorHp() < 1) {
                continue;
            }
            Vector3 EnemyPos = actorLinker->get_position();
            float Health = actorLinker->ValueComponent()->get_actorHp();
            float MaxHealth = actorLinker->ValueComponent()->get_actorHpTotal();
            int HealthPercent =
                (int)std::round((float)Health / MaxHealth * 100);
            float Distance = Vector3::Distance(EnemyCache.myPos, EnemyPos);

            // Bộc phá
            if (needExecuteScan && HealthPercent < hpExecute &&
                Distance < 5.0f && HealthPercent > 1.0f) {
                RequestUseSkill(ins);
            }
        }

        // Trừng trị
        if (needPunishScan) {
            // Get all quái & lính
            List<ActorEntry> *GetAllMonsters =
                get_actorManager->GetAllMonsters();
            if (GetAllMonsters == nullptr)
                return old_skillSlotFunc(ins, del);
            // Convert to C Pointer Array
            ActorEntry *actorLinkersm = GetAllMonsters->getItems();
            if (GetAllMonsters->getSize() > 0 && actorLinkersm == nullptr)
                return old_skillSlotFunc(ins, del);

            for (int i = 0; i < GetAllMonsters->getSize(); i++) {
                ActorLinker *actorLinker = actorLinkersm[i].actor;
                if (actorLinker == nullptr)
                    continue;

                float Health = actorLinker->ValueComponent()->get_actorHp();
                if (Health < 1)
                    continue;

                EnemyCache.Hud = actorLinker->HudControl()->Hud();
                EnemyCache.Hudh = actorLinker->HudControl()->Hudh();
                EnemyCache.ConfigID = actorLinker->ObjLinker()->ConfigID();

                Vector3 EnemyPos = actorLinker->get_position();
                float Distance = Vector3::Distance(EnemyCache.myPos, EnemyPos);

                /*
                EnemyCache.Hud == 1: Bùa Xanh, Bùa Đỏ
                    => EnemyCache.Hudh == 3250: Bùa xanh
                    => EnemyCache.Hudh == 2900: Bùa đỏ
                EnemyCache.Hud == 2: Quái con và lính
                EnemyCache.Hud == 4: Tà Thần, Rồng
                */
                if (
                    // ĐK1: Trừng trị Bùa
                    (Distance < 4.0f &&
                     Health <= (1350 + (100 * (EnemyCache.Level - 1))) &&
                     EnemyCache.Hud == 1 && !onlyPunishDragonOrCaesar &&
                     (EnemyCache.Hudh == 2900 || EnemyCache.Hudh == 3250)) ||
                    // ĐK2: Trừng trị Rồng và Tà thần
                    (Distance < 4.0f &&
                     Health <= (1350 + (100 * (EnemyCache.Level - 1))) &&
                     EnemyCache.Hud == 4)) {
                    int mRealObjID =
                        *(int *)((uintptr_t)actorLinker +
                                 ENCRYPTOFFSET(
                                     "0x128")); // class ActorLinker | private
                                                // object mRealObjID; // 0x128
                    RequestUseSkillSlot((void *)instanceSkillComponentSelf,
                                        slot, 1, mRealObjID, 0);
                }
            }
        }
    }

    return old_skillSlotFunc(ins, del);
}

// ================= AUTO SELL ITEM =================

static bool pendingSwapBuyAfterSell = false;
static std::chrono::steady_clock::time_point pendingSwapBuyStartedAt =
    std::chrono::steady_clock::now();

// Sort list item swap
static void ReorganizeSwapItems() {
    std::vector<SwapItem> enabledItems;
    std::vector<SwapItem> disabledItems;
    for (const auto &item : swapItems) {
        if (item.enabled) {
            enabledItems.push_back(item);
        } else {
            disabledItems.push_back(item);
        }
    }
    swapItems.clear();
    if (enabledItems.size() > 0) {
        std::sort(enabledItems.begin(), enabledItems.end(),
                  [](const SwapItem &a, const SwapItem &b) {
                      return a.number < b.number;
                  });
    }
    swapItems.insert(swapItems.end(), enabledItems.begin(), enabledItems.end());
    swapItems.insert(swapItems.end(), disabledItems.begin(),
                     disabledItems.end());
}

// Get info config lobby from id skill item (equipID)
static uintptr_t GetResEquipInBattle(uint32_t equipID) {
    if (!GetEquipInfo)
        return 0;
    uintptr_t equipInfo =
        (uintptr_t)GetEquipInfo(equipID); // return instance of class CEquipInfo
    if (!checkPointer64bits(equipInfo))
        return 0;
    return ReadMemorySafe<uintptr_t>(
        equipInfo + ENCRYPTOFFSET("0x8")); // class CEquipInfo | public object
                                           // m_resEquipInBattle; // 0x8
}

static uint32_t GetBuyPrice(uintptr_t resEquip) {
    if (!resEquip)
        return 0;
    return ReadMemorySafe<uint32_t>(
        resEquip + ENCRYPTOFFSET("0x28")); // class ResEquipInBattle | public
                                           // object dwBuyPrice; // 0x28
}

static bool CheckPassiveSkillAttach(uint32_t equipID) {
    return currentCDLatestMap[equipID] == 0 && currentCDCurrentMap[equipID] > 0;
}

/*
// Namespace: NucleusDrive.Logic
public class CEquipPassiveSkillInfo {
 object m_equipID; // 0x8
 object m_equipBuyPrice; // 0xC
 object m_passiveSkillID; // 0x14
 object m_passiveSkillGroupID; // 0x18
 object m_isEnabled; // 0x1A
 object m_passiveSkillRelatedFuncIDs; // 0x20
 object m_isNeedRemoved; // 0x28
 object m_Priority; // 0x2A
 object m_sequence; // 0x2C
}
*/
// Check item PassiveSkill CD > 0?
static bool CheckCDPassiveSkill(uint32_t equipID, bool canCheckAttach) {
    if (passiveSkillInfoMap.find(equipID) == passiveSkillInfoMap.end())
        return false;

    uint32_t currentCD = 0;
    uintptr_t passiveEvent =
        (uintptr_t)passiveSkillInfoMap[equipID].passiveEvent;

    // If the item hasn't been sold yet, check currentCD in passiveEvent
    if (checkPointer64bits(passiveEvent)) {
        currentCD = ReadMemorySafe<uint32_t>(
            passiveEvent +
            ENCRYPTOFFSET("0x60")); // class PassiveEvent | protected object
                                    // deltaTime; // 0x60
    }
    // If the item has been sold, check m_equipPassiveCdList (instance of
    // LEquipComponent) in logicalEquipComp
    else {
        if (checkPointer64bits((uintptr_t)logicalEquipComp)) {
            uintptr_t m_equipPassiveCdListPtr = ReadMemorySafe<uintptr_t>(
                (uintptr_t)logicalEquipComp +
                ENCRYPTOFFSET(
                    "0x68")); // class LEquipComponent | private object
                              // m_equipPassiveCdList; // 0x68 | List
            List<CEquipPassiveCdInfo *> m_equipPassiveCdList =
                ReadMemorySafe<List<CEquipPassiveCdInfo *>>(
                    m_equipPassiveCdListPtr);
            uint32_t size = m_equipPassiveCdList.getSize();

            for (uint32_t i = 0; i < size; ++i) {
                CEquipPassiveCdInfo *infoCD = m_equipPassiveCdList[i];
                if (infoCD->get_m_passiveSkillId() ==
                    passiveSkillInfoMap[equipID].passiveSkillID) {
                    currentCD = infoCD->get_m_passiveCd();
                }
            }
        }
    }
    currentCDLatestMap[equipID] = currentCDCurrentMap[equipID];
    currentCDCurrentMap[equipID] = currentCD;

    if (canCheckAttach) {
        return CheckPassiveSkillAttach(equipID) && currentCD > 0;
    }
    return currentCD > 0;
}

// Check skill item need user active, CD > 0?
static bool CheckCDActiveSkill(uint32_t equipID, bool canCheckAttach) {
    ActorLinker *actor = (ActorLinker *)Lactor;
    uintptr_t equipLinkerComp = actor->EquipLinkerComp();

    if (checkPointer64bits(equipLinkerComp)) {
        uint32_t currentCD =
            GetEquipActiveSkillCD((void *)equipLinkerComp, equipID);

        currentCDLatestMap[equipID] = currentCDCurrentMap[equipID];
        currentCDCurrentMap[equipID] = currentCD;

        if (canCheckAttach) {
            return CheckPassiveSkillAttach(equipID) && currentCD > 0;
        }
        return currentCD > 0;
    }

    return false;
}

void (*old_LEquipComponent_UpdateLogic)(void *instance, void *nDelta);
void LEquipComponent_UpdateLogic(void *instance, void *nDelta) {
    old_LEquipComponent_UpdateLogic(instance, nDelta);

    uintptr_t actor = ReadMemorySafe<uintptr_t>(
        (uintptr_t)instance +
        ENCRYPTOFFSET("0x20")); // class LEquipComponent extend LActorComponent
                                // | public object actor; // 0x20

    if (actor == (uintptr_t)g_HostLActorRoot) {
        logicalEquipComp = instance;
    }
}

void (*old_PassiveSkill_Init)(void *instance, uint32_t id, void *root);
void PassiveSkill_Init(void *instance, uint32_t id, void *root) {
    old_PassiveSkill_Init(instance, id, root);

    for (auto &[key, value] : passiveSkillInfoMap) {
        if (value.passiveSkillID == id) {
            uintptr_t passiveEvent = ReadMemorySafe<uintptr_t>(
                (uintptr_t)instance +
                ENCRYPTOFFSET("0x88")); // class PassiveSkill | public object
                                        // passiveEvent; // 0x88
            if (checkPointer64bits(passiveEvent)) {
                value.passiveEvent = (void *)passiveEvent;
            }
        }
    }
}

void (*old_PassiveEvent_UnInit)(void *instance);
void PassiveEvent_UnInit(void *instance) {
    for (auto &[key, value] : passiveSkillInfoMap) {
        if (value.passiveEvent == (void *)instance) {
            value.passiveEvent = nullptr;
        }
    }

    old_PassiveEvent_UnInit(instance);
}

void (*old_CBattleEquipSystem_Update)(void *instance);
void CBattleEquipSystem_Update(void *instance) {
    old_CBattleEquipSystem_Update(instance);

    if (instance && autoBuyFirstRecItem) {
        if (get_m_hostCtrlHeroPermitedToBuyEquip) {
            bool canBuy = get_m_hostCtrlHeroPermitedToBuyEquip(instance);
            if (!canBuy) {
                goto nextStep;
            }
        }

        if (GetQuickBuyUIView) {
            void *quickBuyView = GetQuickBuyUIView(instance);
            if (quickBuyView == nullptr) {
                goto nextStep;
            }
        }

        Array<uint32_t> *array =
            *(Array<uint32_t> *
                  *)((uintptr_t)instance +
                     ENCRYPTOFFSET(
                         "0x40")); // class CBattleEquipSystem | private object
        // m_hostPlayerQuicklyBuyEquipIDs; // 0x40
        if (checkPointer64bits((uintptr_t)array)) {
            uint64_t length = array->getLength();
            if (length == 2) {
                uint32_t itemID = (*array)[0];
                if (itemID > 0) {
                    static uint32_t lastTriedBuyItemID = 0;
                    static std::chrono::steady_clock::time_point lastBuyTime =
                        std::chrono::steady_clock::now();

                    auto now = std::chrono::steady_clock::now();
                    auto elapsed =
                        std::chrono::duration_cast<std::chrono::milliseconds>(
                            now - lastBuyTime)
                            .count();

                    if (itemID != lastTriedBuyItemID || elapsed >= 1000) {
                        lastTriedBuyItemID = itemID;
                        lastBuyTime = now;

                        onMain(^{
                          if (autoBuyFirstRecItem && SendBuyEquipFrameCommand) {
                              SendBuyEquipFrameCommand(instance, itemID, true);
                          }
                        });
                    }
                }
            }
        }
    }

nextStep:
    if (instance && autoSwapEquipEnabled) {
        if (get_m_hostCtrlHeroPermitedToBuyEquip) {
            bool canBuy = get_m_hostCtrlHeroPermitedToBuyEquip(instance);
            if (!canBuy)
                return;
        }

        if (instance != lastBattleEquipSystemInstance) {
            lastBattleEquipSystemInstance = instance;
            matchStateInitialized = false;
        }

        static std::chrono::steady_clock::time_point lastActionTime =
            std::chrono::steady_clock::now();
        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                           now - lastActionTime)
                           .count();

        if (elapsed >= 500) {
            hostEquipComp =
                get_HostEquipComp ? get_HostEquipComp(instance) : nullptr;
            ActorLinker *playerObj = (espManager && espManager->myPlayer)
                                         ? (ActorLinker *)espManager->myPlayer
                                         : (ActorLinker *)Lactor;

            if (hostEquipComp && playerObj) {
                uintptr_t m_equipInfos = ReadMemorySafe<uintptr_t>(
                    (uintptr_t)hostEquipComp +
                    ENCRYPTOFFSET(
                        "0x30")); // class VEquipLinkerComponent | private
                                  // object m_equipInfos; // 0x30
                uint32_t m_equipInfos_maxLength = ReadMemorySafe<uint32_t>(
                    m_equipInfos + ENCRYPTOFFSET("0x10"));
                uint32_t m_equipInfos_Size =
                    std::min(m_equipInfos_maxLength, (uint32_t)6);
                ValueLinkerComponent *valueComponent =
                    playerObj->ValueComponent();
                uint32_t currentGold =
                    valueComponent ? valueComponent->get_GoldCoinInBattle()
                                   : -999;

                if (!matchStateInitialized) {
                    uint32_t activeEquipCount = 0;
                    if (checkPointer64bits(m_equipInfos) &&
                        m_equipInfos_Size > 0 && m_equipInfos_Size <= 6) {
                        for (uint32_t slot = 0; slot < m_equipInfos_Size;
                             slot++) {
                            uint32_t equipID = ReadMemorySafe<uint32_t>(
                                m_equipInfos + ENCRYPTOFFSET("0x18") +
                                slot * ENCRYPTOFFSET("0xC")); // object 12 bytes
                            if (equipID > 0) {
                                activeEquipCount++;
                            }
                        }
                    }

                    bool isNewMatch =
                        (activeEquipCount == 0) ||
                        (activeEquipCount <= 1 && currentGold <= 800);
                    if (isNewMatch) {
                        resurrectUsedCount = 0;
                        pendingSwapBuyAfterSell = false;
                        [common setInt:0
                                forKey:NSSENCRYPT("swap_resurrect_count")];
                    } else {
                        resurrectUsedCount = [common
                            integerForKey:NSSENCRYPT("swap_resurrect_count")
                             defaultValue:0];
                    }
                    matchStateInitialized = true;
                }

                uint32_t activeEquipCount = 0;

                if (checkPointer64bits(m_equipInfos) && m_equipInfos_Size > 0 &&
                    m_equipInfos_Size <= 6) {
                    for (uint32_t slot = 0; slot < m_equipInfos_Size; slot++) {
                        uint32_t equipID = ReadMemorySafe<uint32_t>(
                            m_equipInfos + ENCRYPTOFFSET("0x18") +
                            slot * ENCRYPTOFFSET("0xC")); // object 12 bytes

                        if (equipID > 0) {
                            activeEquipCount++;
                            uintptr_t resEquip = GetResEquipInBattle(equipID);
                            if (checkPointer64bits(resEquip)) {
                                // Check Giáp hộ mệnh + Liềm đoạt mệnh + Hercule
                                // thịnh nộ
                                if (equipID == 1337 || equipID == 11271 ||
                                    equipID == 1328) {
                                    uint32_t totalHp = ((ActorLinker *)Lactor)
                                                           ->ValueComponent()
                                                           ->get_actorHpTotal();
                                    uint32_t currentHp = ((ActorLinker *)Lactor)
                                                             ->ValueComponent()
                                                             ->get_actorHp();

                                    float percent = 0.0f;
                                    if (totalHp > 0) {
                                        percent =
                                            (float)currentHp / (float)totalHp;
                                    }

                                    bool attached =
                                        CheckCDPassiveSkill(equipID, true);
                                    bool inCD = false;

                                    if (!attached) {
                                        inCD =
                                            CheckCDPassiveSkill(equipID, false);
                                    }

                                    /*
                                    Check frame của item skill kích hoạt tự
                                    động thì bán Hoặc nếu user tự mua lại =>
                                    lúc đó currentCD > 0 thì sẽ không auto bán
                                    được => check kèm nếu attached = false
                                    (không tự kích hoạt) thì sẽ check theo
                                    currentCD > 0 kèm lượng máu < 20% thì bán
                                    */
                                    bool onCD =
                                        attached || (inCD && percent < 0.2f);
                                    if (onCD) {
                                        if (SendSellEquipFrameCommand) {
                                            SendSellEquipFrameCommand(instance,
                                                                      slot);
                                            activeEquipCount--;
                                            lastActionTime = now;
                                            pendingSwapBuyAfterSell = true;
                                            pendingSwapBuyStartedAt = now;
                                            if (equipID == 1337) {
                                                resurrectUsedCount++;
                                                [common
                                                    setInt:resurrectUsedCount
                                                    forKey:NSSENCRYPT(
                                                               "swap_resurrect_"
                                                               "count")];
                                            }
                                            break;
                                        }
                                    }
                                }
                                // Check Thương khung kiếm + Băng sương +
                                // Nham thuẫn
                                else if (equipID == 1149 || equipID == 1242 ||
                                         equipID == 1340) {
                                    uint32_t totalHp = ((ActorLinker *)Lactor)
                                                           ->ValueComponent()
                                                           ->get_actorHpTotal();
                                    uint32_t currentHp = ((ActorLinker *)Lactor)
                                                             ->ValueComponent()
                                                             ->get_actorHp();

                                    float percent = 0.0f;
                                    if (totalHp > 0) {
                                        percent =
                                            (float)currentHp / (float)totalHp;
                                    }

                                    bool attached =
                                        CheckCDActiveSkill(equipID, true);
                                    bool inCD = false;

                                    if (!attached) {
                                        inCD =
                                            CheckCDActiveSkill(equipID, false);
                                    }

                                    /*
                                    Check frame của item skill kích hoạt thủ
                                    công bởi user thì bán Hoặc nếu user tự mua
                                    lại => lúc đó currentCD > 0 thì sẽ không
                                    auto bán được => check kèm nếu attached =
                                    false (không tự kích hoạt) thì sẽ check theo
                                    currentCD > 0 kèm lượng máu < 20% thì bán
                                    */
                                    bool onCD =
                                        attached || (inCD && percent < 0.2f);
                                    if (onCD) {
                                        if (SendSellEquipFrameCommand) {
                                            SendSellEquipFrameCommand(instance,
                                                                      slot);
                                            activeEquipCount--;
                                            lastActionTime = now;
                                            pendingSwapBuyAfterSell = true;
                                            pendingSwapBuyStartedAt = now;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if (pendingSwapBuyAfterSell) {
                    auto pendingElapsed =
                        std::chrono::duration_cast<std::chrono::milliseconds>(
                            now - pendingSwapBuyStartedAt)
                            .count();
                    if (pendingElapsed > 2000) {
                        pendingSwapBuyAfterSell = false;
                    }
                }

                if (pendingSwapBuyAfterSell && activeEquipCount < 6) {
                    m_equipInfos = ReadMemorySafe<uintptr_t>(
                        (uintptr_t)hostEquipComp +
                        ENCRYPTOFFSET(
                            "0x30")); // class VEquipLinkerComponent | private
                                      // object m_equipInfos; // 0x30
                    m_equipInfos_maxLength = ReadMemorySafe<uint32_t>(
                        m_equipInfos + ENCRYPTOFFSET("0x10"));
                    m_equipInfos_Size =
                        std::min(m_equipInfos_maxLength, (uint32_t)6);
                    for (const auto &targetItem : swapItems) {
                        if (targetItem.enabled) {
                            // Check if you have purchased
                            bool alreadyEquipped = false;
                            if (checkPointer64bits(m_equipInfos) &&
                                m_equipInfos_Size > 0 &&
                                m_equipInfos_Size <= 6) {
                                for (uint32_t slot = 0;
                                     slot < m_equipInfos_Size; slot++) {
                                    uint32_t equipID = ReadMemorySafe<uint32_t>(
                                        m_equipInfos + ENCRYPTOFFSET("0x18") +
                                        slot * ENCRYPTOFFSET(
                                                   "0xC")); // object 12 bytes
                                    if (equipID > 0 &&
                                        equipID == targetItem.id) {
                                        alreadyEquipped = true;
                                        break;
                                    }
                                }
                            }
                            if (alreadyEquipped)
                                continue;

                            uintptr_t resEquip =
                                GetResEquipInBattle(targetItem.id);
                            if (resEquip) {
                                if (targetItem.id == 1337 &&
                                    resurrectUsedCount >= 2) {
                                    continue;
                                }

                                // Check Giáp hộ mệnh + Liềm đoạt mệnh + Hercule
                                // thịnh nộ
                                if (targetItem.id == 1337 ||
                                    targetItem.id == 11271 ||
                                    targetItem.id == 1328) {
                                    bool inCD = CheckCDPassiveSkill(
                                        targetItem.id, false);
                                    if (inCD)
                                        continue;
                                }
                                // Check Thương khung kiếm + Băng sương + Nham
                                // thuẫn
                                else if (targetItem.id == 1149 ||
                                         targetItem.id == 1242 ||
                                         targetItem.id == 1340) {
                                    if (CheckCDActiveSkill(targetItem.id,
                                                           false)) {
                                        continue;
                                    }
                                }

                                uint32_t buyPrice = GetBuyPrice(resEquip);
                                if (currentGold == 0 || buyPrice == 0) {
                                    pendingSwapBuyAfterSell = false;
                                    break;
                                }
                                if (currentGold >= buyPrice) {
                                    if (SendBuyEquipFrameCommand) {
                                        SendBuyEquipFrameCommand(
                                            instance, targetItem.id, false);
                                        lastActionTime = now;
                                        pendingSwapBuyAfterSell = false;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// ================= MOD RANK =================

void *(*old_GetMasterRoleInfo)(void *);
void *GetMasterRoleInfo(void *instance) {
    if (instance != NULL && unlockModRank) {
        void *CRoleInfo = old_GetMasterRoleInfo(instance);
        if (CRoleInfo) {
            *(int *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x34C")) =
                fakeStars; // Number star rank | m_rankScore | class CRoleInfo |
                           // public object m_rankScore; // 0x34C
            *(int *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x364")) =
                fakeStars; // Number star rank history latest |
                           // m_rankHistoryHighestScore | class CRoleInfo |
                           // public object m_rankHistoryHighestScore; // 0x364

            *(uint8_t *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x350")) =
                fakeRank; // Current rank | m_rankShowGrade | class CRoleInfo |
                          // public object m_rankShowGrade; // 0x350
            *(uint8_t *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x351")) =
                fakeRank; // Max history rank all session |
                          // m_rankHistoryHighestShowGrade | class CRoleInfo |
                          // public object m_rankHistoryHighestShowGrade; //
                          // 0x351
            *(uint8_t *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x352")) =
                fakeRank; // Max history rank current session |
                          // m_rankSeasonHighestShowGrade | class CRoleInfo |
                          // public object m_rankSeasonHighestShowGrade; //
                          // 0x352

            *(int *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x354")) =
                topRank; // Top master | m_rankClass | class CRoleInfo | public
                         // object m_rankClass; // 0x354
            *(int *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x358")) =
                topRank; // Top master | m_rankHistoryHighestClass | class
                         // CRoleInfo | public object m_rankHistoryHighestClass;
                         // // 0x358
            *(int *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x35C")) =
                topRank; // Top master | m_rankSeasonHighestClass | class
                         // CRoleInfo | public object m_rankSeasonHighestClass;
                         // // 0x35C

            *(int *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x36C")) =
                fakeMark; // Number of session master |
                          // mCurSeasonReachRankSTimes | class CRoleInfo |
                          // public object mCurSeasonReachRankSTimes; // 0x36C
            *(int *)((uint64_t)CRoleInfo + ENCRYPTOFFSET("0x370")) =
                fakeMark; // Number of session master | mTotalReachRankSTimes |
                          // class CRoleInfo | public object
                          // mTotalReachRankSTimes; // 0x370
            return CRoleInfo;
        }
    }
    return old_GetMasterRoleInfo(instance);
}

bool (*old_CanPlayerShowLegendRank)(void *instance, void *playerData,
                                    void *dataProvider, int targetCampId,
                                    bool isWarmBattle, void **actorMeta,
                                    int *adCode, int *rankNo, int *medalType);
bool CanPlayerShowLegendRank(void *instance, void *playerData,
                             void *dataProvider, int targetCampId,
                             bool isWarmBattle, void **actorMeta, int *adCode,
                             int *rankNo, int *medalType) {
    if (instance != NULL && unlockModRank) {
        void *VHostLogic = get_VHostLogic();
        int playerID = 0;
        if (VHostLogic != nullptr) {
            playerID =
                *(int *)((uintptr_t)VHostLogic +
                         ENCRYPTOFFSET(
                             "0x10")); // class VHostLogic | private object
                                       // <HostPlayerId>k__BackingField; // 0x10
        }
        if (playerData != nullptr) {
            int PlayerID =
                *(int *)((uintptr_t)playerData +
                         ENCRYPTOFFSET(
                             "0x8")); // class VHostLogic | private object
                                      // <hostPlayer>k__BackingField; // 0x8
            if (PlayerID == playerID) {
                return true;
            }
        }
    }
    return old_CanPlayerShowLegendRank(instance, playerData, dataProvider,
                                       targetCampId, isWarmBattle, actorMeta,
                                       adCode, rankNo, medalType);
}

bool (*old_IsShowLegendRankMode)(void *instance, void *levelContext);
bool IsShowLegendRankMode(void *instance, void *levelContext) {
    if (instance != NULL && unlockModRank) {
        return true;
    }
    return old_IsShowLegendRankMode(instance, levelContext);
}

bool IsSelfLoadingPlayer(void *playerData) {
    if (!playerData)
        return false;

    void *VHostLogic = get_VHostLogic();
    if (!VHostLogic)
        return false;

    int hostPlayerId = *(
        int *)((uintptr_t)VHostLogic +
               ENCRYPTOFFSET("0x10")); // class VHostLogic | private object
                                       // <HostPlayerId>k__BackingField; // 0x10

    int playerId =
        *(int *)((uintptr_t)playerData +
                 ENCRYPTOFFSET("0x8")); // class VHostLogic | private object
                                        // <hostPlayer>k__BackingField; // 0x8

    return playerId == hostPlayerId;
}

bool (*old_TryShowLegendRank)(void *instance, bool canShowProficiency,
                              void *elementGo, void *playerData, int adCode,
                              int rankNo, int medalType);
bool TryShowLegendRank(void *instance, bool canShowProficiency, void *elementGo,
                       void *playerData, int adCode, int rankNo,
                       int medalType) {
    if (instance != NULL && unlockModRank && IsSelfLoadingPlayer(playerData)) {
        /*
        1 => Cục xám (Sơ cấp)
        2 => Cục xanh lá (Trung cấp)
        3 => Cục xanh dương (Cao cấp)
        4 => Cục tím (Huyền thoại)
        5 => Cục đỏ (Top 1 máy chủ)
        6 => Cục vàng (Số 1 máy chủ)
        */
        medalType = topHero;
    }
    return old_TryShowLegendRank(instance, canShowProficiency, elementGo,
                                 playerData, adCode, rankNo, medalType);
}

void *(*old_OpenWaterMark)(void *instance);
void *OpenWaterMark(void *instance) {
    if (hideUID) {
        return nullptr;
    }
    return old_OpenWaterMark(instance);
}

// ================= MOD SKIN =================

bool checkEnableModSkin() { return CSProtocol::saveData::enable && unlockSkin; }

bool (*old_IsCanUseSkin)(void *instance, uint32_t heroId, uint32_t skinId);
bool IsCanUseSkin(void *instance, uint32_t heroId, uint32_t skinId) {
    if (unlockSkin && heroId != 0) {
        return true;
    }
    return old_IsCanUseSkin(instance, heroId, skinId);
}

bool (*old_IsHaveHeroSkin)(void *instance, uint32_t heroId, uint32_t skinId,
                           bool isIncludeTimeLimited);
bool IsHaveHeroSkin(void *instance, uint32_t heroId, uint32_t skinId,
                    bool isIncludeTimeLimited = false) {
    if (unlockSkin && heroId != 0) {
        return true;
    }
    return old_IsHaveHeroSkin(instance, heroId, skinId, isIncludeTimeLimited);
}

void (*old_OnClickSelectHeroSkin)(void *instance, uint32_t heroId,
                                  uint32_t skinId);
void OnClickSelectHeroSkin(void *instance, uint32_t heroId, uint32_t skinId) {
    if (unlockSkin && heroId != 0) {
        CSProtocol::saveData::setData(heroId, skinId);
        CSProtocol::saveData::setEnable(true);

        old_RefreshHeroPanel(instance, 1, 1, 1);
    }

    old_OnClickSelectHeroSkin(instance, heroId, skinId);
}

void (*old_HeroSelectBanPick_OnHeroSkinWearSuc)(void *instance, uint32_t heroId,
                                                uint32_t skinId);
void HeroSelectBanPick_OnHeroSkinWearSuc(void *instance, uint32_t heroId,
                                         uint32_t skinId) {
    if (checkEnableModSkin() && heroId != 0 &&
        heroId == CSProtocol::saveData::heroId) {
        skinId = CSProtocol::saveData::skinId;
    }

    old_HeroSelectBanPick_OnHeroSkinWearSuc(instance, heroId, skinId);
}

void (*old_HeroSelectBanPick_OnHeroSkinWearFail)(void *instance);
void HeroSelectBanPick_OnHeroSkinWearFail(void *instance) {
    if (checkEnableModSkin() && CSProtocol::saveData::heroId != 0) {
        return;
    }

    old_HeroSelectBanPick_OnHeroSkinWearFail(instance);
}

void (*old_HeroSelectBanPick_OnSkinSelect)(void *instance, void *uiEvent);
void HeroSelectBanPick_OnSkinSelect(void *instance, void *uiEvent) {
    if (unlockSkin && uiEvent != nullptr) {
        /*
        Namespace: Assets.Scripts.UI | uiEvent
        public class CUIEvent {
            public stUIEventParams m_eventParams; // 0x20
        }
        Namespace: Assets.Scripts.UI
        public struct stUIEventParams {
            public object tag; // 0x2BC
            public object tag2; // 0x2C0
        }
        */
        uint32_t heroId =
            *(uint32_t *)((uint64_t)uiEvent +
                          ENCRYPTOFFSET("0x2DC")); // 0x20 + 0x2BC = 0x2DC
        uint32_t skinId =
            *(uint32_t *)((uint64_t)uiEvent +
                          ENCRYPTOFFSET("0x2E0")); // 0x20 + 0x2C0 = 0x2E0

        if (heroId != 0) {
            CSProtocol::saveData::setData(heroId, skinId);
            CSProtocol::saveData::setEnable(true);
            if (old_HeroSelectBanPick_OnHeroSkinWearSuc) {
                HeroSelectBanPick_OnHeroSkinWearSuc(instance, heroId, skinId);
                return;
            }
        }
    }

    old_HeroSelectBanPick_OnSkinSelect(instance, uiEvent);
}

uint32_t (*old_GetHeroWearSkinId)(void *instance, uint32_t heroId);
uint32_t GetHeroWearSkinId(void *instance, uint32_t heroId) {
    currentHeroId = heroId;
    uint32_t skinId = old_GetHeroWearSkinId(instance, heroId);
    if (unlockSkin && heroId != 0 && heroId == CSProtocol::saveData::heroId) {
        skinId = CSProtocol::saveData::skinId;
        CSProtocol::saveData::setEnable(true);
    }

    currentSkinId = skinId;
    if (modeSkinButton == 1) {
        std::ostringstream oss;
        oss << heroId << std::setw(2) << std::setfill('0') << skinId;
        selectedButton = std::stoi(oss.str());
    }

    return skinId;
}

TdrErrorType (*old_unpack_COMDT_PLAYERINFO)(
    CSProtocol::COMDT_PLAYERINFO *instance, TdrReadBuf &srcBuf, int32_t cutVer);
TdrErrorType unpack_COMDT_PLAYERINFO(CSProtocol::COMDT_PLAYERINFO *instance,
                                     TdrReadBuf &srcBuf, int32_t cutVer) {
    if (instance) {
        instance_COMDT_PLAYERINFO_cache = instance;
    }
    TdrErrorType res = old_unpack_COMDT_PLAYERINFO(instance, srcBuf, cutVer);

    return res;
}

TdrErrorType (*old_unpack_COMDT_CHOICEHERO)(
    CSProtocol::COMDT_CHOICEHERO *instance, TdrReadBuf &srcBuf, int32_t cutVer);
TdrErrorType unpack_COMDT_CHOICEHERO(CSProtocol::COMDT_CHOICEHERO *instance,
                                     TdrReadBuf &srcBuf, int32_t cutVer) {
    TdrErrorType res = old_unpack_COMDT_CHOICEHERO(instance, srcBuf, cutVer);

    if (instance && instance_COMDT_HERO_COMMON_INFO_cache &&
        instance_COMDT_HERO_COMMON_INFO_cache->getdwHeroID() ==
            CSProtocol::saveData::heroId &&
        instance_COMDT_PLAYERINFO_cache &&
        instance_COMDT_PLAYERINFO_cache->get_bObjType() == 1 &&
        !strcmp(instance_COMDT_PLAYERINFO_cache->get_szName(),
                get_HostName()->toCString())) {
        instance->set_bSkinWakeLevel(5);
        instance->set_ullSkinWakeFeatureMask(0xFFFFFFFFFFFFFFFFULL);
    }

    return res;
}

void hook_unpack(CSProtocol::COMDT_HERO_COMMON_INFO *instance) {
    if (!instance)
        return;

    if (!checkEnableModSkin())
        return;

    uint16_t originalSkinId = instance->getwSkinID();
    if (instance->getdwHeroID() == CSProtocol::saveData::heroId &&
        instance_COMDT_PLAYERINFO_cache &&
        instance_COMDT_PLAYERINFO_cache->get_bObjType() == 1 &&
        !strcmp(instance_COMDT_PLAYERINFO_cache->get_szName(),
                get_HostName()->toCString())) {
        instance_COMDT_HERO_COMMON_INFO_cache = instance;
        CSProtocol::saveData::setSkinIdOrig(originalSkinId);
    }

    if (instance->getdwHeroID() == CSProtocol::saveData::heroId &&
        CSProtocol::saveData::heroId != 0 &&
        CSProtocol::saveData::skinId != 0 && instance_COMDT_PLAYERINFO_cache &&
        instance_COMDT_PLAYERINFO_cache->get_bObjType() == 1 &&
        !strcmp(instance_COMDT_PLAYERINFO_cache->get_szName(),
                get_HostName()->toCString())) {
        instance->setwSkinID(CSProtocol::saveData::skinId);
        CSProtocol::saveData::setDataUnpackSkin(instance, originalSkinId);
    }
}

TdrErrorType (*old_unpack)(CSProtocol::COMDT_HERO_COMMON_INFO *instance,
                           TdrReadBuf &srcBuf, int32_t cutVer);
TdrErrorType unpack(CSProtocol::COMDT_HERO_COMMON_INFO *instance,
                    TdrReadBuf &srcBuf, int32_t cutVer) {
    TdrErrorType result = old_unpack(instance, srcBuf, cutVer);

    if (unlockSkin) {
        hook_unpack(instance);
    }

    return result;
}

// Fix game virtual
bool (*old_sub_2ac2be8)(void *, uint32_t, uint32_t *, void *);
bool hook_sub_2ac2be8(void *dict, uint32_t heroId, uint32_t *skinId,
                      void *method) {
    bool result = old_sub_2ac2be8(dict, heroId, skinId, method);
    uintptr_t caller = getOffset((uintptr_t)__builtin_return_address(0));

    // class ActorServerDataProvider | internal object
    // ConvertServerHeroInfo(object serverData, object serverHeroInfo, object
    // OriSkinIds)
    // 0x4213034 is line caller in function ConvertServerHeroInfo
    if (result && skinId && checkEnableModSkin() &&
        caller == ENCRYPTOFFSET("0x4213034") &&
        heroId == CSProtocol::saveData::heroId) {
        if (*skinId == CSProtocol::saveData::skinId) {
            *skinId = CSProtocol::saveData::skinIdOrig;
        }
    }

    return result;
}

static void copyVisualData(uintptr_t dst, uintptr_t src) {
    const uintptr_t fields[] = {
        ENCRYPTOFFSET("0xA0"), // class ActorServerData | public object
                               // BattleEffectIds; // 0xA0
        ENCRYPTOFFSET("0xA8"), // class ActorServerData | public object
                               // SkinPartsIds; // 0xA8
        ENCRYPTOFFSET("0xB0"), // class ActorServerData | public object
                               // AnimationIds; // 0xB0
        ENCRYPTOFFSET(
            "0xB8"), // class ActorServerData | public object MoWenIds; // 0xB8
        ENCRYPTOFFSET("0xC0"), // class ActorServerData | public object
                               // BattleResInfos; // 0xC0
    };

    for (uintptr_t offset : fields) {
        uintptr_t src_array = ReadMemorySafe<uintptr_t>(src + offset);
        uintptr_t dst_array = ReadMemorySafe<uintptr_t>(dst + offset);

        if (src_array && dst_array) {
            uint32_t src_size =
                ReadMemorySafe<uint32_t>(src_array + ENCRYPTOFFSET("0x10"));
            uint32_t dst_size =
                ReadMemorySafe<uint32_t>(dst_array + ENCRYPTOFFSET("0x10"));
            if (src_size <= dst_size) {
                *(uint32_t *)(dst_array + ENCRYPTOFFSET("0x10")) = src_size;
                for (uint32_t i = 0; i < src_size; i++) {
                    uint32_t val = ReadMemorySafe<uint32_t>(
                        src_array + ENCRYPTOFFSET("0x18") + i * 4);
                    *(uint32_t *)(dst_array + ENCRYPTOFFSET("0x18") + i * 4) =
                        val;
                }
            } else {
                *(uintptr_t *)(dst + offset) = src_array;
            }
        } else if (src_array) {
            *(uintptr_t *)(dst + offset) = src_array;
        }
    }
}

static uint32_t setVisualSkin() {
    if (!myActorServerData) {
        return UINT32_MAX;
    }

    uint32_t oldSkin = ReadMemorySafe<uint32_t>(
        myActorServerData +
        ENCRYPTOFFSET(
            "0x84")); // class ActorServerData | public object SkinId; // 0x84
    *(uint32_t *)(myActorServerData + ENCRYPTOFFSET("0x84")) =
        CSProtocol::saveData::skinId; // class ActorServerData | public object
                                      // SkinId; // 0x84

    return oldSkin;
}

static void restoreVisualSkin(uint32_t oldSkin) {
    if (!myActorServerData || oldSkin == UINT32_MAX)
        return;

    *(uint32_t *)(myActorServerData + ENCRYPTOFFSET("0x84")) =
        oldSkin; // class ActorServerData | public object SkinId; // 0x84
}

uintptr_t (*old_ConvertServerHeroInfo)(void *, void *, void *, void *);
uintptr_t ConvertServerHeroInfo(void *instance, void *serverDataRef,
                                void *serverHeroInfo, void *oriSkinIds) {
    uintptr_t result = old_ConvertServerHeroInfo(instance, serverDataRef,
                                                 serverHeroInfo, oriSkinIds);

    uintptr_t data =
        serverDataRef ? ReadMemorySafe<uintptr_t>((uintptr_t)serverDataRef) : 0;
    if (!data)
        return result;

    uint32_t heroId = ReadMemorySafe<uint32_t>(
        data + ENCRYPTOFFSET("0x8")); // class ActorServerData | public object
                                      // TheActorMeta; // 0x8
    uint32_t skinId = ReadMemorySafe<uint32_t>(
        data +
        ENCRYPTOFFSET(
            "0x84")); // class ActorServerData | public object SkinId; // 0x84

    if (heroId != CSProtocol::saveData::heroId)
        return result;

    if (skinId == CSProtocol::saveData::skinId) {
        modVisualData = data;
    } else if (skinId == CSProtocol::saveData::skinIdOrig && modVisualData) {
        copyVisualData(data, modVisualData);
        *(uint32_t *)(data + ENCRYPTOFFSET("0x84")) =
            CSProtocol::saveData::skinId; // class ActorServerData | public
                                          // object SkinId; // 0x84
    }

    myActorServerData = data;
    return result;
}

uintptr_t (*old_HandlePreLoadDateSkinDegenerated)(void *, void *);
uintptr_t HandlePreLoadDateSkinDegenerated(void *instance, void *preloadData) {
    setVisualSkin();
    uintptr_t result =
        old_HandlePreLoadDateSkinDegenerated(instance, preloadData);
    restoreVisualSkin(CSProtocol::saveData::skinIdOrig);

    return result;
}

uintptr_t (*old_MobaUtility_SpawnActor)(void *, void *);
uintptr_t MobaUtility_SpawnActor(void *actor, void *data) {
    /*
    public struct ActorMeta {
     public object ConfigId; // 0xFFFFFFFFFFFFFFF8 (-8)
     public object PlayerId; // 0xFFFFFFFFFFFFFFFC (-4)
     public object HostObjId; // 0x0
     public object HostConfigId; // 0x4
     ...
     public object SkinID; // 0x18
    }
    */
    uint32_t heroId =
        actor ? ReadMemorySafe<uint32_t>((uintptr_t)actor +
                                         ENCRYPTOFFSET("0x1F8"))
              : 0; // class ActorLinker | public object TheActorMeta; // 0x1F8

    if (!checkEnableModSkin() || heroId != CSProtocol::saveData::heroId)
        return old_MobaUtility_SpawnActor(actor, data);

    setVisualSkin();
    uintptr_t result = old_MobaUtility_SpawnActor(actor, data);
    restoreVisualSkin(CSProtocol::saveData::skinIdOrig);

    return result;
}

uint32_t (*old_GetComponentBattleEffectFlag)(void *actorMeta,
                                             uint32_t *componentId);
uint32_t GetComponentBattleEffectFlag(void *actorMeta, uint32_t *componentId) {
    if (!actorMeta || !checkEnableModSkin())
        return old_GetComponentBattleEffectFlag(actorMeta, componentId);

    uintptr_t meta = (uintptr_t)actorMeta;
    uint32_t heroId = ReadMemorySafe<uint32_t>(meta);
    if (heroId != CSProtocol::saveData::heroId)
        return old_GetComponentBattleEffectFlag(actorMeta, componentId);

    uint32_t playerId = ReadMemorySafe<uint32_t>(
        meta + ENCRYPTOFFSET("0x4")); // struct ActorMeta | public object
                                      // PlayerId; // 0xFFFFFFFFFFFFFFFC (-0x4)
    uint32_t oldSkinId = ReadMemorySafe<uint32_t>(
        meta + ENCRYPTOFFSET(
                   "0x20")); // struct ActorMeta | public object SkinID; // 0x18

    uint32_t oldOriSkinId = GetOriSkinId(playerId, heroId);

    *(uint32_t *)(meta + ENCRYPTOFFSET("0x20")) =
        CSProtocol::saveData::skinId; // struct ActorMeta | public object
                                      // SkinID; // 0x18
    GMSetOriSkinId(playerId, heroId, CSProtocol::saveData::skinId);

    uint32_t result = old_GetComponentBattleEffectFlag(actorMeta, componentId);

    *(uint32_t *)(meta + ENCRYPTOFFSET("0x20")) =
        oldSkinId; // struct ActorMeta | public object SkinID; // 0x18
    GMSetOriSkinId(playerId, heroId, oldOriSkinId);

    return result;
}

uint64_t (*old_HandleSkinCustomizationImpl)(void *actorMeta, void *actorLinker,
                                            void *tmpObj, void *strategy,
                                            void *combiner,
                                            uintptr_t batchFlag);
uint64_t HandleSkinCustomizationImpl(void *actorMeta, void *actorLinker,
                                     void *tmpObj, void *strategy,
                                     void *combiner, uintptr_t batchFlag) {
    if (!actorMeta || !checkEnableModSkin())
        return old_HandleSkinCustomizationImpl(actorMeta, actorLinker, tmpObj,
                                               strategy, combiner, batchFlag);

    uintptr_t meta = (uintptr_t)actorMeta;
    uint32_t heroId = ReadMemorySafe<uint32_t>(meta); // ConfigId
    if (heroId != CSProtocol::saveData::heroId)
        return old_HandleSkinCustomizationImpl(actorMeta, actorLinker, tmpObj,
                                               strategy, combiner, batchFlag);

    uint32_t playerId = ReadMemorySafe<uint32_t>(
        meta + ENCRYPTOFFSET("0x4")); // struct ActorMeta | public object
                                      // PlayerId; // 0xFFFFFFFFFFFFFFFC (-0x4)
    uint32_t oldSkinId = ReadMemorySafe<uint32_t>(
        meta +
        ENCRYPTOFFSET(
            "0x20")); //  // struct ActorMeta | public object SkinID; // 0x18

    uint32_t oldOriSkinId = GetOriSkinId(playerId, heroId);

    *(uint32_t *)(meta + ENCRYPTOFFSET("0x20")) =
        CSProtocol::saveData::skinId; // struct ActorMeta | public object
                                      // SkinID; // 0x18
    GMSetOriSkinId(playerId, heroId, CSProtocol::saveData::skinId);

    uint64_t result = old_HandleSkinCustomizationImpl(
        actorMeta, actorLinker, tmpObj, strategy, combiner, batchFlag);

    *(uint32_t *)(meta + ENCRYPTOFFSET("0x20")) =
        oldSkinId; // struct ActorMeta | public object SkinID; // 0x18
    GMSetOriSkinId(playerId, heroId, oldOriSkinId);

    return result;
}

// ================= MOD SKIN BUTTON =================

bool (*old_IsAtMyTeam)(void *ins, uint32_t playerId, uint32_t configId);
bool IsAtMyTeam(void *ins, uint32_t playerId, uint32_t configId) {
    if (ins != NULL && old_IsAtMyTeam(ins, playerId, configId) &&
        currentHeroId == configId) {
        currentPlayerID = playerId;
    }
    return old_IsAtMyTeam(ins, playerId, configId);
}

bool (*old_IsOpen)();
bool IsOpen() {
    if (modSkinButton) {
        return true;
    }
    return old_IsOpen();
}

int ResolvePersonalButtonID() {
    if (modeSkinButton == 0) {
        if (selectedButton >= 0 &&
            selectedButton < static_cast<int>(modSkinButtonValues.size())) {
            return modSkinButtonValues[selectedButton];
        }
    } else if (modeSkinButton == 1 && selectedButton > 0) {
        if (std::find(modSkinButtonValues.begin(), modSkinButtonValues.end(),
                      selectedButton) != modSkinButtonValues.end()) {
            return selectedButton;
        }
    }

    return -1;
}
int (*old_get_PersonalBtnId)();
int get_PersonalBtnId() {
    if (modSkinButton) {
        int buttonID = ResolvePersonalButtonID();
        if (buttonID >= 0) {
            return buttonID;
        }
    }
    return old_get_PersonalBtnId();
}

// ================= MOD KILL NOTIFY =================

int ResolveKillNotifyID() {
    if (modeNotify == 0) {
        if (selectedKillNotify >= 0 &&
            selectedKillNotify < static_cast<int>(modKillNotifyValues.size())) {
            int skinID = modKillNotifyValues[selectedKillNotify];
            return modKillNotifyMap[skinID];
        }
    } else if (modeNotify == 1) {
        std::ostringstream oss;
        oss << currentHeroId << std::setw(2) << std::setfill('0')
            << currentSkinId;
        selectedKillNotify = std::stoi(oss.str());

        if (std::find(modKillNotifyValues.begin(), modKillNotifyValues.end(),
                      selectedKillNotify) != modKillNotifyValues.end()) {
            return modKillNotifyMap[selectedKillNotify];
        }
    }

    return -1;
}
void (*old_GetPlayer)(void *ins, int uid);
void GetPlayer(void *ins, int uid) {
    int killNotifyID = ResolveKillNotifyID();
    if (ins != NULL && killNotifyID > 0 && modNotify) {
        List<void *> *target = PlrList(ins);
        if (target != NULL) {
            void **playerItem = (void **)target->getItems();
            for (int i = 0; i < target->getSize(); i++) {
                void *Player = playerItem[i];
                if (Player != NULL) {
                    playerID =
                        *(uint32_t *)((uintptr_t)Player +
                                      ENCRYPTOFFSET(
                                          "0x8")); // class PlayerBase | public
                                                   // object PlayerId; // 0x8
                    if (playerID == currentPlayerID) {
                        *(int *)((uintptr_t)Player + ENCRYPTOFFSET("0xFC")) =
                            killNotifyID; // class PlayerBase | public object
                                          // broadcastID; // 0xFC
                    }
                }
            }
        }
    }
    return old_GetPlayer(ins, uid);
}

// ================= MOD TEXT KILL NOTIFY =================

/*
Type: 1 => Chiến công đầu
Type: 2 => Hạ
Type: 3 => DoubleKill
Type: 4 => TripleKill
Type: 5 => QuataKill
Type: 6 => PentaKill
Type: 11 => Gotcha
Type: 12 => Gotcha
Type: 13 => Truyền thuyết
Type: 14 => Huyền thoại
Type: 15 => Thần thánh
Type: 21 => Phá trụ địch
Type: 1000 => Quét sạch
Type: 3000 => Chấm dứt
Type: 3102 => Lính siêu cấp xuất chiến

Type: 106 => Ceasar
Type: 107 => Ceasar hắc ám
Type: 108 => Ceasar bạo chúa

Type: 109 => Rồng
Type: 110 => Rồng ánh sáng
*/

bool checkFlagModKillNotify(int type) {
    switch (type) {
    case 1:
        return modTextKillNotifyFirstKill;
    case 2:
        return modTextKillNotifyKill;
    case 3:
        return modTextKillNotifyDoubleKill;
    case 4:
        return modTextKillNotifyTripleKill;
    case 5:
        return modTextKillNotifyQuataKill;
    case 6:
        return modTextKillNotifyPentaKill;
    case 11:
        return modTextKillNotifyGotcha;
    case 12:
        return modTextKillNotifyGotcha;
    case 13:
        return modTextKillNotifyLegend;
    case 14:
        return modTextKillNotifyLegendary;
    case 15:
        return modTextKillNotifyHallow;
    case 21:
        return modTextKillNotifyDestroyTower;
    case 1000:
        return modTextKillNotifyAce;
    case 3000:
        return modTextKillNotifyShutdown;
    case 3102:
        return modTextKillNotifyMinionSuperStart;
    case 106:
        return modTextKillNotifyKillCeasar;
    case 107:
        return modTextKillNotifyKillDarkCeasar;
    case 108:
        return modTextKillNotifyKillDarkTyrantCeasar;
    case 109:
        return modTextKillNotifyKillDragon;
    case 110:
        return modTextKillNotifyKillLightDragon;
    default:
        return false;
    }
}

const char *getCustomTextKillNotify(int type) {
    switch (type) {
    case 1:
        return modTextKillNotifyFirstKillText;
    case 2:
        return modTextKillNotifyKillText;
    case 3:
        return modTextKillNotifyDoubleKillText;
    case 4:
        return modTextKillNotifyTripleKillText;
    case 5:
        return modTextKillNotifyQuataKillText;
    case 6:
        return modTextKillNotifyPentaKillText;
    case 11:
        return modTextKillNotifyGotchaText;
    case 12:
        return modTextKillNotifyGotchaText;
    case 13:
        return modTextKillNotifyLegendText;
    case 14:
        return modTextKillNotifyLegendaryText;
    case 15:
        return modTextKillNotifyHallowText;
    case 21:
        return modTextKillNotifyDestroyTowerText;
    case 1000:
        return modTextKillNotifyAceText;
    case 3000:
        return modTextKillNotifyShutdownText;
    case 3102:
        return modTextKillNotifyMinionSuperStartText;
    case 106:
        return modTextKillNotifyKillCeasarText;
    case 107:
        return modTextKillNotifyKillDarkCeasarText;
    case 108:
        return modTextKillNotifyKillDarkTyrantCeasarText;
    case 109:
        return modTextKillNotifyKillDragonText;
    case 110:
        return modTextKillNotifyKillLightDragonText;
    default:
        return "";
    }
}

void *(*old_GetNotifyText)(void *type, void *bSrc, void *inKillerActorType,
                           void *thumbsUpCount, void *playerId);
void *GetNotifyText(void *type, void *bSrc, void *inKillerActorType,
                    void *thumbsUpCount, void *playerId) {
    void *res = old_GetNotifyText(type, bSrc, inKillerActorType, thumbsUpCount,
                                  playerId);

    int typeInt = (int)(uintptr_t)type;
    if (!checkFlagModKillNotify(typeInt))
        return res;

    const char *customName = getCustomTextKillNotify(typeInt);
    if (!customName || customName[0] == '\0')
        return res;

    monoString *custom = CreateMonoString(customName);

    return (void *)custom;
}

void *(*old_GETNotifyText)(void *type, void *bSrc, void *inKillerActorType,
                           void *thumbsUpCount, void *playerId,
                           void *victimPlayerId);
void *GETNotifyText(void *type, void *bSrc, void *inKillerActorType,
                    void *thumbsUpCount, void *playerId, void *victimPlayerId) {
    void *res = old_GETNotifyText(type, bSrc, inKillerActorType, thumbsUpCount,
                                  playerId, victimPlayerId);

    int typeInt = (int)(uintptr_t)type;
    if (!checkFlagModKillNotify(typeInt))
        return res;

    const char *customName = getCustomTextKillNotify(typeInt);
    if (!customName || customName[0] == '\0')
        return res;

    monoString *custom = CreateMonoString(customName);

    return (void *)custom;
}

// ================= ANTI - BLOCK HOST =================

void showAntiReportOn() {
    onMain(^{
      [[ImGuiDrawView sharedInstance]
          activeHack:NSSENCRYPT("Chống tố cáo đang được bật 💀💀💀")
             message:NSSENCRYPT("Tha hồ mà chơi thôi hẹ hẹ hẹ")
                font:[UIFont fontWithName:NSSENCRYPT("AvenirNext-Bold") size:15]
            duration:3.0];
    });
}

void (*old_OnEnter)(void *instance);
void OnEnter(void *instance) {
    if (instance != NULL && blockHost) {
        AntiHookEnable = YES;
        showAntiReportOn();
    }
    old_OnEnter(instance);
}

void ShowEndGameX() {
    onMain((^{
      NSString *title = [NSString
          stringWithFormat:@"%@ %d %@",
                           NSSENCRYPT("Sau khi trận đấu kết thúc, hãy đợi"),
                           bypassDelay, NSSENCRYPT("giây")];
      [[ImGuiDrawView sharedInstance]
          activeHack:title
             message:NSSENCRYPT("Sẽ tự bay ra ngoài sảnh chờ, không cần lo!")
                font:[UIFont fontWithName:NSSENCRYPT("AvenirNext-Bold") size:15]
            duration:3.0];
    }));
}

void (*old_EndGame)(void *instance, bool bSyncUnload, int waitingFinishState);
void EndGame(void *instance, bool bSyncUnload, int waitingFinishState) {
    if (instance != NULL && blockHost) {
        AntiHookEnable = NO;
        if (waitingFinishState == 3) {
            if (blockHostOption == 0) {
                timer(2) { exit(0); });
            }
            if (blockHostOption == 1) {
                ShowEndGameX();
                timer(bypassDelay) { old_EndGame(instance, bSyncUnload, 3); });
            }
        }
        return;
    }
    old_EndGame(instance, bSyncUnload, waitingFinishState);
}

void (*old_Disconnected)(void *instance);
void Disconnected(void *instance) {
    if (instance != NULL && blockHost) {
        return;
    }
    old_Disconnected(instance);
}
