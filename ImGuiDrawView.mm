#import "Esp/ImGuiDrawView.h"
#import "Font/Icon.h"
#import "Font/IconCpp.h"
#import "Font/Vietnamese.h"
#import "GioVoTinh/define.h"
#import "GioVoTinh/hook.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/imgui_internal.h"
#import "IMGUI/stb_image.h"
#import "Macros.h"
#import "Resources/FloatButton.h"
#import "Resources/HeroTextureData.h"
#import "Resources/ImGuiStyle.h"
#import "Utils/FPS.h"
#import "Utils/StringToChar.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>

#define NAME_BINARY "Frameworks/UnityFramework.framework/UnityFramework"
#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale
#define kFloatButtonWidth 40
#define kFloatButtonHeight 40
#define kPaddingVertical 10
#define kPaddingHorizontal 35

enum : int {
    ImGuiIOSKey_Backspace = 8,
    ImGuiIOSKey_Enter = 13,
    ImGuiIOSKey_Escape = 27,
    ImGuiIOSKey_Tab = 9,
};

struct CheckboxImGuiItem {
    std::string label;
    bool *value;
};

@interface ImGuiDrawView () <MTKViewDelegate, UITextFieldDelegate, UIKeyInput>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, weak) UIView *floatButtonHostView;
@property(nonatomic, strong) UIImageView *floatButtonImageView;
@property(nonatomic, assign) BOOL keyboardDismissedByUser;
@property(nonatomic, assign) BOOL hookingDone;
@end

static bool supportRotateScreen = false;
static bool isShowMenu = false;

@implementation ImGuiDrawView

+ (instancetype)sharedInstance {
    static ImGuiDrawView *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device)
        abort();

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO &io = ImGui::GetIO();
    (void)io;

    io.KeyMap[ImGuiKey_Tab] = ImGuiIOSKey_Tab;
    io.KeyMap[ImGuiKey_Enter] = ImGuiIOSKey_Enter;
    io.KeyMap[ImGuiKey_KeyPadEnter] = ImGuiIOSKey_Enter;
    io.KeyMap[ImGuiKey_Escape] = ImGuiIOSKey_Escape;
    io.KeyMap[ImGuiKey_Backspace] = ImGuiIOSKey_Backspace;

    RenderTheme(themeID);

    ImFontConfig config;
    ImFontConfig icons_config;
    config.FontDataOwnedByAtlas = false;
    icons_config.MergeMode = true;
    icons_config.PixelSnapH = true;
    icons_config.OversampleH = 2;
    icons_config.OversampleV = 2;

    io.Fonts->AddFontFromMemoryCompressedTTF(
        (void *)zzz_compressed_data, zzz_compressed_size, 60.0f, NULL,
        io.Fonts->GetGlyphRangesVietnamese());

    static const ImWchar icons_ranges[] = {ICON_MIN_FA, ICON_MAX_FA, 0};
    io.Fonts->AddFontFromMemoryCompressedTTF(font_awesome_data,
                                             font_awesome_size, 60.0f,
                                             &icons_config, icons_ranges);

    ImGui_ImplMetal_Init(_device);
    [self initImageTexture:_device];

    return self;
}

- (void)loadView {
    self.view =
        [[MTKView alloc] initWithFrame:CGRectMake(0, 0, kWidth, kHeight)];
    [self setup];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0
                                                   green:0
                                                    blue:0
                                                   alpha:0];
    self.mtkView.clipsToBounds = YES;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(handleKeyboardWillHide:)
               name:UIKeyboardWillHideNotification
             object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup {
    [common setFrameworkName:NAME_BINARY];
    [self initData];
    [self loadSetting];
    [self loadThemeFromRemote];
    [self loadDataFromRemote];

    // Try resolve il2cpp to load symbol il2cpp_*
    // Run on background thread
    static dispatch_once_t once;
    timer_background(2) {
        dispatch_once(&once, ^{
          if ([self handleIl2cpp]) {
              LOG(@"%@", NSSENCRYPT("Primary IL2CPP attach success"));
              timer_background(0.1) {
                  [self loadSymbolAutoUpdate];
                  timer(1) { [self hook]; });
              });
              return;
          }

          LOG(@"%@", NSSENCRYPT("Second: Try IL2CppResolver"));
          NSString *dirString = binaryPath(@NAME_BINARY);
          if (IL2CPP_Resolver::Initialize(true, WAIT_TIME_SEC,
                                          [dirString UTF8String])) {
              LOG(@"%@", NSSENCRYPT("Second: IL2CppResolver success!"));
              [self assignPointerIl2cpp];
              timer_background(0.1) {
                  [self loadSymbolAutoUpdate];
                  timer(1) { [self hook]; });
              });
              return;
          }

          LOG(@"%@", NSSENCRYPT("All resolver paths failed"));
          LOG(@"%@", NSSENCRYPT("Use hard offset"));

          timer_background(0.1) {
              [self loadSymbolHardOffset];
              timer(1) { [self hook]; });
          });
        });
    });
}

- (void)initData {
    self.hookingDone = NO;

    static dispatch_once_t once;
    dispatch_once(&once, ^{
      espManager = new EntityManager();
      ActorLinker_enemy = new EntityManager();
    });
}

- (BOOL)handleIl2cpp {
    LOG(@"%@", NSSENCRYPT("First: Try il2cpp"));
    BOOL res = Il2CppAttach();
    LOG(@"%@", res ? NSSENCRYPT("First: il2cpp success!")
                   : NSSENCRYPT("First: il2cpp fail!"));

    return res;
}

- (void)assignPointerIl2cpp {
    IL2CPP::il2cpp_assembly_get_image =
        reinterpret_cast<const void *(*)(const void *)>(
            IL2CPP_Resolver::Functions.m_AssembliesGetImage);
    IL2CPP::il2cpp_domain_get =
        reinterpret_cast<void *(*)()>(IL2CPP_Resolver::Functions.m_DomainGet);
    IL2CPP::il2cpp_domain_get_assemblies =
        reinterpret_cast<void **(*)(const void *, size_t *)>(
            IL2CPP_Resolver::Functions.m_DomainGetAssemblies);
    IL2CPP::il2cpp_image_get_name = reinterpret_cast<const char *(*)(void *)>(
        IL2CPP_Resolver::Functions.m_ImageGetName);
    IL2CPP::il2cpp_class_from_name =
        reinterpret_cast<void *(*)(const void *, const char *, const char *)>(
            IL2CPP_Resolver::Functions.m_ClassFromName);
    IL2CPP::il2cpp_class_get_method_from_name =
        reinterpret_cast<void *(*)(void *, const char *, int)>(
            IL2CPP_Resolver::Functions.m_ClassGetMethodFromName);
    IL2CPP::il2cpp_class_get_field_from_name =
        reinterpret_cast<void *(*)(void *, const char *)>(
            IL2CPP_Resolver::Functions.m_ClassGetFieldFromName);
    IL2CPP::il2cpp_field_get_offset = reinterpret_cast<size_t (*)(void *)>(
        IL2CPP_Resolver::Functions.m_ClassGetFieldOffset);
    IL2CPP::il2cpp_field_static_get_value =
        reinterpret_cast<void (*)(void *, void *)>(
            IL2CPP_Resolver::Functions.m_FieldStaticGetValue);
    IL2CPP::il2cpp_field_static_set_value =
        reinterpret_cast<void (*)(void *, void *)>(
            IL2CPP_Resolver::Functions.m_FieldStaticSetValue);

    // Additional IL2CPP function assignments
    IL2CPP::il2cpp_string_new = reinterpret_cast<void *(*)(const char *)>(
        IL2CPP_Resolver::Functions.m_StringNew);
    IL2CPP::il2cpp_string_new_utf16 =
        reinterpret_cast<void *(*)(const wchar_t *, int32_t)>(
            IL2CPP_Resolver::Functions.m_StringNewUTF16);
    IL2CPP::il2cpp_string_chars = reinterpret_cast<uint16_t *(*)(void *)>(
        IL2CPP_Resolver::Functions.m_StringChars);

    // v2
    IL2CPP::il2cpp_thread_get_name =
        reinterpret_cast<char *(*)(void *, uint32_t *)>(
            IL2CPP_Resolver::Functions.m_ThreadGetName);
    IL2CPP::il2cpp_thread_current = reinterpret_cast<void *(*)()>(
        IL2CPP_Resolver::Functions.m_ThreadCurrent);
    IL2CPP::il2cpp_thread_attach = reinterpret_cast<void *(*)(void *)>(
        IL2CPP_Resolver::Functions.m_ThreadAttach);
    IL2CPP::il2cpp_thread_detach = reinterpret_cast<void (*)(void *)>(
        IL2CPP_Resolver::Functions.m_ThreadDetach);
    IL2CPP::il2cpp_runtime_invoke =
        reinterpret_cast<void *(*)(const void *, void *, void **, void **)>(
            IL2CPP_Resolver::Functions.m_RuntimeInvoke);
    IL2CPP::il2cpp_object_unbox = reinterpret_cast<void *(*)(void *)>(
        IL2CPP_Resolver::Functions.m_ObjectUnbox);
    IL2CPP::il2cpp_object_new = reinterpret_cast<void *(*)(const void *)>(
        IL2CPP_Resolver::Functions.m_pObjectNew);
    IL2CPP::il2cpp_gchandle_new = reinterpret_cast<uint32_t (*)(void *, bool)>(
        IL2CPP_Resolver::Functions.m_GchandleNew);
    IL2CPP::il2cpp_gchandle_free = reinterpret_cast<void (*)(uint32_t)>(
        IL2CPP_Resolver::Functions.m_GchandleFree);
}

- (void)loadDataFromRemote {
    isJsonLoaded = false;

    NSString *urlString = [NSString
        stringWithFormat:@"%s%@", BaseURL(), NSSENCRYPT("/HeroInfoAOV.json")];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *task = [session
          dataTaskWithURL:url
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          if (error) {
              LOG(NSSENCRYPT("Failed to load HeroInfoAOV data: %@"), error);
              return;
          }

          NSString *jsonString =
              [[NSString alloc] initWithData:data
                                    encoding:NSUTF8StringEncoding];
          try {
              nlohmann::json j = nlohmann::json::parse([jsonString UTF8String],
                                                       nullptr, true, true);
              static std::unordered_map<int, int> nextModKillNotifyMap;
              ;
              std::vector<std::string> nextModKillNotifyOptions;
              std::vector<int> nextModKillNotifyValues;
              std::vector<std::string> nextModSkinButtonOptions;
              std::vector<int> nextModSkinButtonValues;
              std::vector<HeroInfoEntry> nextHeroInfos;

              for (auto &hero : j) {
                  if (!hero.contains("heroID") || !hero.contains("heroName") ||
                      !hero.contains("nameReal")) {
                      continue;
                  }

                  HeroInfoEntry heroInfo;
                  heroInfo.heroID = hero["heroID"].get<int>();
                  heroInfo.heroName = hero["heroName"].get<std::string>();
                  heroInfo.nameReal = hero["nameReal"].get<std::string>();
                  nextHeroInfos.push_back(heroInfo);

                  if (!hero.contains("skins") || !hero["skins"].is_array()) {
                      continue;
                  }

                  for (auto &skin : hero["skins"]) {
                      if (!skin.contains("skinID") ||
                          !skin.contains("skinName")) {
                          continue;
                      }

                      int skinID = skin["skinID"].get<int>();
                      std::string skinName =
                          skin["skinName"].get<std::string>();
                      int killNotifyID = skin.value("killNotifyID", -999);

                      if (killNotifyID > 0) {
                          nextModKillNotifyMap.insert({skinID, killNotifyID});
                          nextModKillNotifyOptions.push_back(skinName);
                          nextModKillNotifyValues.push_back(skinID);
                      }

                      if (skin.value("hasButtonSkin", false)) {
                          nextModSkinButtonOptions.push_back(skinName);
                          nextModSkinButtonValues.push_back(skinID);
                      }
                  }
              }

              modKillNotifyMap = std::move(nextModKillNotifyMap);
              modKillNotifyOptions = std::move(nextModKillNotifyOptions);
              modKillNotifyValues = std::move(nextModKillNotifyValues);
              modSkinButtonOptions = std::move(nextModSkinButtonOptions);
              modSkinButtonValues = std::move(nextModSkinButtonValues);
              setHeroInfos(std::move(nextHeroInfos));

              isJsonLoaded = true;
              LOG(@"%@", NSSENCRYPT("loadDataFromRemote success!"));
          } catch (const std::exception &e) {
              LOG(NSSENCRYPT("loadDataFromRemote error: %s"), e.what());
          }
        }];

    [task resume];
}

- (void)loadThemeFromRemote {
    NSString *urlString = [NSString
        stringWithFormat:@"%s%@", BaseURL(), NSSENCRYPT("/ThemeModMenu.json")];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *task = [session
          dataTaskWithURL:url
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          if (error) {
              LOG(NSSENCRYPT("Failed to load ThemeModMenu data: %@"), error);
              return;
          }

          NSString *jsonString =
              [[NSString alloc] initWithData:data
                                    encoding:NSUTF8StringEncoding];
          try {
              nlohmann::json j = nlohmann::json::parse([jsonString UTF8String],
                                                       nullptr, true, true);

              if (!j.contains("themeID")) {
                  LOG(@"%@",
                      NSSENCRYPT(
                          "loadThemeFromRemote don't include field themeID"));
                  return;
              }

              themeID = j["themeID"].get<int>();
              RenderTheme(themeID);
              LOG(@"%@", NSSENCRYPT("loadThemeFromRemote success!"));
          } catch (const std::exception &e) {
              LOG(NSSENCRYPT("loadThemeFromRemote error: %s"), e.what());
          }
        }];

    [task resume];
}

- (void)loadSymbolAutoUpdate {
    Il2CppMethod methodAccessSystem(ENCRYPT("Project_d.dll"));
    Il2CppMethod methodAccessSystem2(ENCRYPT("Project.Plugins_d.dll"));
    Il2CppMethod methodAccessRes(ENCRYPT("AovTdr.dll"));
    Il2CppMethod methodAccess(ENCRYPT("AovUISys.dll"));

    summonerSpell =
        (uintptr_t)ENCRYPTOFFSET("0xA0"); // class HeroWrapperData | public
                                          // object heroWrapSkillData_5; // 0xA0
    skill1 =
        (uintptr_t)ENCRYPTOFFSET("0x20"); // class HeroWrapperData | public
                                          // object heroWrapSkillData_1; // 0x20
    skill2 =
        (uintptr_t)ENCRYPTOFFSET("0x40"); // class HeroWrapperData | public
                                          // object heroWrapSkillData_2; // 0x40
    skill3 =
        (uintptr_t)ENCRYPTOFFSET("0x60"); // class HeroWrapperData | public
                                          // object heroWrapSkillData_3; // 0x60

    actorLink_updateOffset =
        methodAccessSystem
            .getClass(oxorany("Kyrios.Actor"), oxorany("ActorLinker"))
            .getMethod(oxorany("Update"), 0);

    getLegendTitleAreaTypeOffset =
        methodAccess
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("CLegendUtility"))
            .getMethod(oxorany("GetLegendTitleAreaType"), 1);

    validOffset = methodAccess
                      .getClass(oxorany("Assets.Scripts.GameSystem"),
                                oxorany("CLegendHeroTitleData"))
                      .getMethod(oxorany("get_Valid"), 0);

    setLegendTitleCompleteOffset =
        methodAccess
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("CLegendUtility"))
            .getMethod(oxorany("SetLegendTitleComplete"), 12);

    getPlayerOffset = methodAccessSystem2
                          .getClass(oxorany("NucleusDrive.Logic.GameKernal"),
                                    oxorany("GamePlayerCenter"))
                          .getMethod(oxorany("GetPlayer"), 1);

    PlrList = (List<void *> * (*)(void *))((uintptr_t)GetMethodOffset(
        oxorany("Project.Plugins_d.dll"),
        oxorany("NucleusDrive.Logic.GameKernal"), oxorany("GamePlayerCenter"),
        oxorany("GetAllPlayers"), 0));

    get_VHostLogic = (void *(*)())GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Kyrios"), oxorany("KyriosFramework"),
        oxorany("get_hostLogic"), 0);

    actorLink_destroyOffset =
        methodAccessSystem
            .getClass(oxorany("Kyrios.Actor"), oxorany("ActorLinker"))
            .getMethod(oxorany("DestroyActor"), 0);

    lactor_updateLogic =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("LActorRoot"))
            .getMethod(oxorany("UpdateLogic"), 1);

    lactor_destroy =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("LActorRoot"))
            .getMethod(oxorany("DestroyActor"), 1);

    hackMapOffset =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("LVActorLinker"))
            .getMethod(oxorany("SetVisible"), 3);

    camOffset =
        methodAccessSystem.getClass(oxorany(""), oxorany("CameraSystem"))
            .getMethod(oxorany("GetZoomRate"), 0);

    getMasterRoleInfoOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("CRoleInfoManager"))
            .getMethod(oxorany("GetMasterRoleInfo"), 0);

    updateOffset =
        methodAccessSystem.getClass(oxorany(""), oxorany("CameraSystem"))
            .getMethod(oxorany("LateUpdate"), 0);

    updateLogicOffset = methodAccessSystem
                            .getClass(oxorany("Assets.Scripts.GameSystem"),
                                      oxorany("CSkillButtonManager"))
                            .getMethod(oxorany("UpdateLogic"), 1);

    skillDirectOffset = methodAccessSystem
                            .getClass(oxorany("Assets.Scripts.GameLogic"),
                                      oxorany("SkillControlIndicator"))
                            .getMethod(oxorany("GetUseSkillDirection"), 1);

    updateFrameLaterOffset =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("LFrameSynchr"))
            .getMethod(oxorany("UpdateFrameLater"), 0);

    sampleFrameSyncDataOffset =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("LSynchrReport"))
            .getMethod(oxorany("SampleFrameSyncData"), 0);

    handleReportFirebase =
        methodAccessSystem.getClass(oxorany(""), oxorany("FirebasePush"))
            .getMethod(oxorany("handleReportInfoResult"), 1);

    handleUpdate = methodAccessSystem2
                       .getClass(oxorany("NucleusDrive.Statistics"),
                                 oxorany("HangUpStaticInfoState"))
                       .getMethod(oxorany("HandleUpdate"), 1);
    onHashCheckRsp =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("LSynchrReport"))
            .getMethod(oxorany("OnHashCheckRsp"), 1);

    enequeHashOffset =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("LSynchrReport"))
            .getMethod(oxorany("EnqueHashValueByFrameNum"), 2);

    setLoginOffset = methodAccessSystem2
                         .getClass(oxorany("NucleusDrive.Logic"),
                                   oxorany("LDedicatedSvrConnector"))
                         .getMethod(oxorany("SetLogin"), 2);

    showHistoryOffset = methodAccessSystem
                            .getClass(oxorany("Assets.Scripts.GameSystem"),
                                      oxorany("CPlayerProfile"))
                            .getMethod(oxorany("get_IsHostProfile"), 0);

    isOpenOffset = methodAccessSystem
                       .getClass(oxorany("Assets.Scripts.GameSystem"),
                                 oxorany("PersonalButton"))
                       .getMethod(oxorany("IsOpen"), 0);

    buttonOffset = methodAccessSystem
                       .getClass(oxorany("Assets.Scripts.GameSystem"),
                                 oxorany("PersonalButton"))
                       .getMethod(oxorany("get_PersonalBtnId"), 0);

    skillSlotOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameLogic"), oxorany("SkillSlot"))
            .getMethod(oxorany("LateUpdate"), 1);

    onClickSelectHeroSkinOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("HeroSelectNormalWindow"))
            .getMethod(oxorany("OnClickSelectHeroSkin"), 2);

    heroSelectBanPickOnSkinSelectOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("HeroSelectBanPickWindow"))
            .getMethod(oxorany("HeroSelect_OnSkinSelect"), 1);
    heroSelectBanPickOnHeroSkinWearSucOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("HeroSelectBanPickWindow"))
            .getMethod(oxorany("OnHeroSkinWearSuc"), 2);
    heroSelectBanPickOnHeroSkinWearFailOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("HeroSelectBanPickWindow"))
            .getMethod(oxorany("OnHeroSkinWearFail"), 0);

    isCanUseSkinOffset = methodAccessSystem
                             .getClass(oxorany("Assets.Scripts.GameSystem"),
                                       oxorany("CRoleInfo"))
                             .getMethod(oxorany("IsCanUseSkin"), 2);

    getHeroWearSkinIdOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("CRoleInfo"))
            .getMethod(oxorany("GetHeroWearSkinId"), 1);

    isHaveHeroSkinOffset = methodAccessSystem
                               .getClass(oxorany("Assets.Scripts.GameSystem"),
                                         oxorany("CRoleInfo"))
                               .getMethod(oxorany("IsHaveHeroSkin"), 3);

    getCurrentRankDetailOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("CLadderSystem"))
            .getMethod(oxorany("GetCurrentRankDetail"), 0);

    tryShowLegendRankOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("PVPLoadingView"))
            .getMethod(oxorany("TryShowLegendRank"), 6);

    isShowLegendRankModeOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("PVPLoadingView"))
            .getMethod(oxorany("IsShowLegendRankMode"), 1);

    unpackOffset =
        methodAccessRes
            .getClass(oxorany("CSProtocol"), oxorany("COMDT_HERO_COMMON_INFO"))
            .getMethod(oxorany("unpack"), 2);

    unpack_COMDT_TOP_OR_AREA_LEGEND_TITLE_INFO_Offset =
        methodAccessRes
            .getClass(oxorany("CSProtocol"),
                      oxorany("COMDT_TOP_OR_AREA_LEGEND_TITLE_INFO"))
            .getMethod(oxorany("unpack"), 2);

    canPlayerShowLegendRankOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("PVPLoadingView"))
            .getMethod(oxorany("CanPlayerShowLegendRank"), 8);

    onEnterOffset = methodAccessSystem
                        .getClass(oxorany("Assets.Scripts.GameSystem"),
                                  oxorany("PVPLoadingView"))
                        .getMethod(oxorany("OnEnter"), 0);

    endGameOffset =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("LFramework"))
            .getMethod(oxorany("EndGame"), 2);

    disconnectOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.Framework"),
                      oxorany("RelaySvrConnectProxy/RelaySvrConnector"))
            .getMethod(oxorany("Disconnect"), 0);

    isPlayerOffset =
        methodAccessSystem2
            .getClass(oxorany("LDataProvider"), oxorany("PlayerBase"))
            .getMethod(oxorany("IsAtMyTeam"), 2);

    hideUIDOffset = methodAccessSystem
                        .getClass(oxorany("Assets.Scripts.GameSystem"),
                                  oxorany("CLobbySystem"))
                        .getMethod(oxorany("OpenWaterMark"), 0);

    showUltiEnemyInGameOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("HeroInfoPanel"))
            .getMethod(oxorany("InitHeroItemData"), 2) +
        ENCRYPTOFFSET("0x274");

    showInfoEnemyInGameOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("HeroInfoPanel"))
            .getMethod(oxorany("ShowHeroInfo"), 2) +
        ENCRYPTOFFSET("0x18");

    showRankOffset = methodAccessSystem
                         .getClass(oxorany("Assets.Scripts.GameSystem"),
                                   oxorany("PVPLoadingView"))
                         .getMethod(oxorany("OnEnter"), 0) +
                     ENCRYPTOFFSET("0x1834");

    showSummonerSpellOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("UIBattleStatView/HeroItem"))
            .getMethod(oxorany("updateTalentSkillCD"), 1) +
        ENCRYPTOFFSET("0x1F8");

    skillComponentOffset = methodAccessSystem
                               .getClass(oxorany("Assets.Scripts.GameLogic"),
                                         oxorany("SkillComponent"))
                               .getMethod(oxorany("LateUpdate"), 1);

    skinResourceModifyBeginLoadMsgOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameLogic"),
                      oxorany("SkinResourceHelper"))
            .getMethod(oxorany("ModifyBeginLoadMsg"), 1);

    skinResourceGetOriSkinIdOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameLogic"),
                      oxorany("SkinResourceHelper"))
            .getMethod(oxorany("GetOriSkinId"), 2);

    skinHelperGetSkinCfgIdOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("SkinHelper"))
            .getMethod(oxorany("GetSkinCfgId"), 2);

    battleEquipSystemUpdateOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("CBattleEquipSystem"))
            .getMethod(oxorany("Update"), 0);

    lEquipComponent_UpdateLogicOffset =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("LEquipComponent"))
            .getMethod(oxorany("UpdateLogic"), 1);

    passiveSkill_InitOffset =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("PassiveSkill"))
            .getMethod(oxorany("Init"), 2);

    passiveEvent_UnInitOffset =
        methodAccessSystem2
            .getClass(oxorany("NucleusDrive.Logic"), oxorany("PassiveEvent"))
            .getMethod(oxorany("UnInit"), 0);

    characterCustomizationUtils_GetComponentBattleEffectFlagOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("CharacterCustomizationUtils"))
            .getMethod(oxorany("GetComponentBattleEffectFlag"), 2);

    characterCustomizationUtils_HandleSkinCustomizationImplOffset =
        methodAccessSystem
            .getClass(oxorany("Assets.Scripts.GameSystem"),
                      oxorany("CharacterCustomizationUtils"))
            .getMethod(oxorany("HandleSkinCustomizationImpl"), 6);

    actorServerDataProvider_ConvertServerHeroInfoOffset =
        methodAccessSystem2
            .getClass(oxorany("LDataProvider"),
                      oxorany("ActorServerDataProvider"))
            .getMethod(oxorany("ConvertServerHeroInfo"), 3);

    gameBuilderProxy_HandlePreLoadDateSkinDegeneratedOffset =
        methodAccessSystem.getClass(oxorany(""), oxorany("GameBuilderProxy"))
            .getMethod(oxorany("HandlePreLoadDateSkinDegenerated"), 1);

    mobaUtility_SpawnActorOffset =
        methodAccessSystem.getClass(oxorany(""), oxorany("MobaUtility"))
            .getMethod(oxorany("SpawnActor"), 2);

    unpack_COMDT_CHOICEHERO_Offset =
        methodAccessRes
            .getClass(oxorany("CSProtocol"), oxorany("COMDT_CHOICEHERO"))
            .getMethod(oxorany("unpack"), 2);

    unpack_COMDT_PLAYERINFO_Offset =
        methodAccessRes
            .getClass(oxorany("CSProtocol"), oxorany("COMDT_PLAYERINFO"))
            .getMethod(oxorany("unpack"), 2);

    RequestUseSkill = (bool (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameLogic"),
        oxorany("SkillSlot"), oxorany("RequestUseSkill"), 0);
    RequestUseSkillSlot = (bool (*)(void *, int, int, int, int))GetMethodOffset(
        oxorany("Project.Plugins_d.dll"), oxorany("Assets.Scripts.GameLogic"),
        oxorany("SkillComponent"), oxorany("RequestUseSkillSlot"), 4);
    ActorLinker_IsHostPlayer = (bool (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Kyrios.Actor"),
        oxorany("ActorLinker"), oxorany("IsHostPlayer"), 0);
    ActorLinker_ActorTypeDef = (int (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Kyrios.Actor"),
        oxorany("ActorLinker"), oxorany("get_objType"), 0);
    ActorLinker_COM_PLAYERCAMP = (int (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Kyrios.Actor"),
        oxorany("ActorLinker"), oxorany("get_objCamp"), 0);
    ActorLinker_getPosition = (Vector3(*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Kyrios.Actor"),
        oxorany("ActorLinker"), oxorany("get_position"), 0);
    ActorLinker_get_bVisible = (bool (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Kyrios.Actor"),
        oxorany("ActorLinker"), oxorany("get_bVisible"), 0);
    LActorRoot_LHeroWrapper = (uintptr_t (*)(void *))GetMethodOffset(
        oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"),
        oxorany("LActorRoot"), oxorany("AsHero"), 0);
    LActorRoot_COM_PLAYERCAMP = (int (*)(void *))GetMethodOffset(
        oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"),
        oxorany("LActorRoot"), oxorany("GiveMyEnemyCamp"), 0);
    LObjWrapper_get_IsDeadState = (bool (*)(void *))GetMethodOffset(
        oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"),
        oxorany("LObjWrapper"), oxorany("get_IsDeadState"), 0);
    ObjLinkerWrapper_get_IsDeadState = (bool (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Kyrios.Actor"),
        oxorany("ObjLinkerWrapper"), oxorany("get_IsDeadState"), 0);
    LObjWrapper_IsAutoAI = (bool (*)(void *))GetMethodOffset(
        oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"),
        oxorany("LObjWrapper"), oxorany("IsAutoAI"), 0);
    ValuePropertyComponent_get_actorHp = (int (*)(void *))GetMethodOffset(
        oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"),
        oxorany("ValuePropertyComponent"), oxorany("get_actorHp"), 0);
    ValuePropertyComponent_get_actorHpTotal = (int (*)(void *))GetMethodOffset(
        oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"),
        oxorany("ValuePropertyComponent"), oxorany("get_actorHpTotal"), 0);
    AsHero = (uintptr_t (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Kyrios.Actor"),
        oxorany("ActorLinker"), oxorany("AsHero"), 0);
    _SetPlayerName = (monoString * (*)(uintptr_t, monoString *, monoString *,
                                       bool, monoString *))
        GetMethodOffset(oxorany("Project_d.dll"),
                        oxorany("Assets.Scripts.GameLogic"),
                        oxorany("HudComponent3D"), oxorany("SetPlayerName"), 4);
    old_RefreshHeroPanel = (void (*)(void *, bool, bool, bool))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("HeroSelectNormalWindow"), oxorany("RefreshHeroPanel"), 3);
    SkillSlot_get_IsCDReady = (bool (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("SkillSlot"), oxorany("get_IsCDReady"), 0);
    SkillSlot_get_CurSkillID = (int (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("SkillSlot"), oxorany("get_CurSkillID"), 0);
    SendBuyEquipFrameCommand =
        (void (*)(void *, uint32_t, bool))GetMethodOffset(
            oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
            oxorany("CBattleEquipSystem"), oxorany("SendBuyEquipFrameCommand"),
            2);
    GetEquipInfo = (void *(*)(uint32_t))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("CBattleEquipSystem"), oxorany("GetEquipInfo"), 1);
    get_HostEquipComp = (void *(*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("CBattleEquipSystem"), oxorany("get_HostEquipComp"), 0);
    get_m_hostCtrlHero = (void *(*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("CBattleEquipSystem"), oxorany("get_m_hostCtrlHero"), 0);
    SendSellEquipFrameCommand = (void (*)(void *, uint32_t))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("CBattleEquipSystem"), oxorany("SendSellEquipFrameCommand"), 1);
    GetEquipActiveSkillCD = (uint32_t (*)(void *, uint32_t))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Kyrios.Actor"),
        oxorany("VEquipLinkerComponent"), oxorany("GetEquipActiveSkillCD"), 1);
    GMSetOriSkinId = (void (*)(uint64_t, uint32_t, uint32_t))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameLogic"),
        oxorany("SkinResourceHelper"), oxorany("GMSetOriSkinId"), 3);
    GetOriSkinId = (uint32_t (*)(uint64_t, uint32_t))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameLogic"),
        oxorany("SkinResourceHelper"), oxorany("GetOriSkinId"), 2);
    OnCameraHeightChanged = (void (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany(""), oxorany("CameraSystem"),
        oxorany("OnCameraHeightChanged"), 0);
    get_m_hostCtrlHeroPermitedToBuyEquip = (bool (*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("CBattleEquipSystem"),
        oxorany("get_m_hostCtrlHeroPermitedToBuyEquip"), 0);
    GetQuickBuyUIView = (void *(*)(void *))GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("CBattleEquipSystem"), oxorany("GetQuickBuyUIView"), 0);
    get_HostName = (monoString * (*)()) GetMethodOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("CRoleInfo"), oxorany("get_HostName"), 0);

    m_isCharging = (uintptr_t)GetFieldOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("CSkillButtonManager"), oxorany("m_isCharging"));
    m_currentSkillSlotType = (uintptr_t)GetFieldOffset(
        oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"),
        oxorany("CSkillButtonManager"), oxorany("m_currentSkillSlotType"));
}

- (void)loadSymbolHardOffset {
    // ====================== FIELD OFFSETS ======================

    summonerSpell =
        (uintptr_t)ENCRYPTOFFSET("0xA0"); // class HeroWrapperData | public
                                          // object heroWrapSkillData_5; // 0xA0
    skill1 =
        (uintptr_t)ENCRYPTOFFSET("0x20"); // class HeroWrapperData | public
                                          // object heroWrapSkillData_1; // 0x20
    skill2 =
        (uintptr_t)ENCRYPTOFFSET("0x40"); // class HeroWrapperData | public
                                          // object heroWrapSkillData_2; // 0x40
    skill3 =
        (uintptr_t)ENCRYPTOFFSET("0x60"); // class HeroWrapperData | public
                                          // object heroWrapSkillData_3; // 0x60
    m_isCharging =
        (uintptr_t)ENCRYPTOFFSET("0x96"); // class CSkillButtonManager | private
                                          // object m_isCharging; // 0x96
    m_currentSkillSlotType = (uintptr_t)ENCRYPTOFFSET(
        "0x64"); // class CSkillButtonManager | public object
                 // m_currentSkillSlotType; // 0x64

    // ====================== METHOD / STATIC OFFSETS ======================
    actorLink_updateOffset = (uintptr_t)ENCRYPTOFFSET("0x6788F10");
    getLegendTitleAreaTypeOffset = (uintptr_t)ENCRYPTOFFSET("0xD749B8");
    validOffset = (uintptr_t)ENCRYPTOFFSET("0xD6D218");
    setLegendTitleCompleteOffset = (uintptr_t)ENCRYPTOFFSET("0xD71E8C");
    getPlayerOffset = (uintptr_t)ENCRYPTOFFSET("0x3DA22FC");
    actorLink_destroyOffset = (uintptr_t)ENCRYPTOFFSET("0x6788910");
    lactor_updateLogic = (uintptr_t)ENCRYPTOFFSET("0x460AFBC");
    lactor_destroy = (uintptr_t)ENCRYPTOFFSET("0x460A7AC");
    hackMapOffset = (uintptr_t)ENCRYPTOFFSET("0x462BF18");
    camOffset = (uintptr_t)ENCRYPTOFFSET("0x6ACBB9C");
    getMasterRoleInfoOffset = (uintptr_t)ENCRYPTOFFSET("0x5A47840");
    updateOffset = (uintptr_t)ENCRYPTOFFSET("0x6AC8E18");
    updateLogicOffset = (uintptr_t)ENCRYPTOFFSET("0x58ACD74");
    skillDirectOffset = (uintptr_t)ENCRYPTOFFSET("0x5E0BD30");
    updateFrameLaterOffset = (uintptr_t)ENCRYPTOFFSET("0x497A038");
    sampleFrameSyncDataOffset = (uintptr_t)ENCRYPTOFFSET("0x4A2F084");
    handleReportFirebase = (uintptr_t)ENCRYPTOFFSET("0x5761B78");
    handleUpdate = (uintptr_t)ENCRYPTOFFSET("0x4490690");
    onHashCheckRsp = (uintptr_t)ENCRYPTOFFSET("0x4A2D4AC");
    enequeHashOffset = (uintptr_t)ENCRYPTOFFSET("0x4A2F30C");
    setLoginOffset = (uintptr_t)ENCRYPTOFFSET("0x49FD8CC");
    showHistoryOffset = (uintptr_t)ENCRYPTOFFSET("0x53EA8F8");
    isOpenOffset = (uintptr_t)ENCRYPTOFFSET("0x5865048");
    buttonOffset = (uintptr_t)ENCRYPTOFFSET("0x5865AC4");
    skillSlotOffset = (uintptr_t)ENCRYPTOFFSET("0x5E2BE2C");
    onClickSelectHeroSkinOffset = (uintptr_t)ENCRYPTOFFSET("0x535FC34");
    heroSelectBanPickOnSkinSelectOffset = (uintptr_t)ENCRYPTOFFSET("0x52C62D8");
    heroSelectBanPickOnHeroSkinWearSucOffset =
        (uintptr_t)ENCRYPTOFFSET("0x52CD928");
    heroSelectBanPickOnHeroSkinWearFailOffset =
        (uintptr_t)ENCRYPTOFFSET("0x52CDDB8");
    isCanUseSkinOffset = (uintptr_t)ENCRYPTOFFSET("0x5A2CEB8");
    getHeroWearSkinIdOffset = (uintptr_t)ENCRYPTOFFSET("0x5A3D8E0");
    isHaveHeroSkinOffset = (uintptr_t)ENCRYPTOFFSET("0x5A2C14C");
    getCurrentRankDetailOffset = (uintptr_t)ENCRYPTOFFSET("0x5416BA0");
    isShowLegendRankModeOffset = (uintptr_t)ENCRYPTOFFSET("0x5A7CBAC");
    tryShowLegendRankOffset = (uintptr_t)ENCRYPTOFFSET("0x5A8153C");
    unpackOffset = (uintptr_t)ENCRYPTOFFSET("0x9F475C");
    unpack_COMDT_TOP_OR_AREA_LEGEND_TITLE_INFO_Offset =
        (uintptr_t)ENCRYPTOFFSET("0x9FC864");
    canPlayerShowLegendRankOffset = (uintptr_t)ENCRYPTOFFSET("0x5A80DAC");
    onEnterOffset = (uintptr_t)ENCRYPTOFFSET("0x5A77E78");
    endGameOffset = (uintptr_t)ENCRYPTOFFSET("0x49DE30C");
    disconnectOffset = (uintptr_t)ENCRYPTOFFSET("0x4F3D140");
    isPlayerOffset = (uintptr_t)ENCRYPTOFFSET("0x421D614");
    hideUIDOffset = (uintptr_t)ENCRYPTOFFSET("0x53812FC");
    showUltiEnemyInGameOffset =
        (uintptr_t)ENCRYPTOFFSET("0x580F2C0") + ENCRYPTOFFSET("0x274");
    showInfoEnemyInGameOffset =
        (uintptr_t)ENCRYPTOFFSET("0x580F614") + ENCRYPTOFFSET("0x18");
    showRankOffset = onEnterOffset + ENCRYPTOFFSET("0x1834"); // Check B.NE
    showSummonerSpellOffset =
        (uintptr_t)ENCRYPTOFFSET("0x57C2264") + ENCRYPTOFFSET("0x1F8");
    skillComponentOffset = (uintptr_t)ENCRYPTOFFSET("0x5F2A8B8");
    skinResourceModifyBeginLoadMsgOffset =
        (uintptr_t)ENCRYPTOFFSET("0x5E306F4");
    skinResourceGetOriSkinIdOffset = (uintptr_t)ENCRYPTOFFSET("0x5E31054");
    skinHelperGetSkinCfgIdOffset = (uintptr_t)ENCRYPTOFFSET("0x51AE078");
    killUTGetNotifyOffset = (uintptr_t)ENCRYPTOFFSET("0x585730C");
    killUTGETNotifyOffset = (uintptr_t)ENCRYPTOFFSET("0x58594E4");
    battleEquipSystemUpdateOffset = (uintptr_t)ENCRYPTOFFSET("0x5C8F5F4");
    lEquipComponent_UpdateLogicOffset = (uintptr_t)ENCRYPTOFFSET("0x450013C");
    passiveSkill_InitOffset = (uintptr_t)ENCRYPTOFFSET("0x489CD7C");
    passiveEvent_UnInitOffset = (uintptr_t)ENCRYPTOFFSET("0x4894BC8");
    characterCustomizationUtils_GetComponentBattleEffectFlagOffset =
        (uintptr_t)ENCRYPTOFFSET("0x59AC8AC");
    characterCustomizationUtils_HandleSkinCustomizationImplOffset =
        (uintptr_t)ENCRYPTOFFSET("0x59ACD24");
    actorServerDataProvider_ConvertServerHeroInfoOffset =
        (uintptr_t)ENCRYPTOFFSET("0x4212E00");
    gameBuilderProxy_HandlePreLoadDateSkinDegeneratedOffset =
        (uintptr_t)ENCRYPTOFFSET("0x5F4C918");
    mobaUtility_SpawnActorOffset = (uintptr_t)ENCRYPTOFFSET("0x678FF08");
    unpack_COMDT_CHOICEHERO_Offset = (uintptr_t)ENCRYPTOFFSET("0xC6F4C0");
    unpack_COMDT_PLAYERINFO_Offset = (uintptr_t)ENCRYPTOFFSET("0xC74920");

    // ====================== FUNCTION POINTERS ======================
    RequestUseSkill =
        (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x5E2CE10"));
    RequestUseSkillSlot = (bool (*)(void *, int, int, int, int))getRealOffset(
        ENCRYPTOFFSET("0x5F2A2B8"));
    ActorLinker_IsHostPlayer =
        (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x678CAB8"));
    ActorLinker_ActorTypeDef =
        (int (*)(void *))getRealOffset(ENCRYPTOFFSET("0x6782968"));
    ActorLinker_COM_PLAYERCAMP =
        (int (*)(void *))getRealOffset(ENCRYPTOFFSET("0x6782908"));
    ActorLinker_getPosition =
        (Vector3(*)(void *))getRealOffset(ENCRYPTOFFSET("0x6782294"));
    ActorLinker_get_bVisible =
        (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x67827B4"));
    LActorRoot_LHeroWrapper =
        (uintptr_t (*)(void *))getRealOffset(ENCRYPTOFFSET("0x460394C"));
    LActorRoot_COM_PLAYERCAMP =
        (int (*)(void *))getRealOffset(ENCRYPTOFFSET("0x460B88C"));
    LObjWrapper_get_IsDeadState =
        (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x457A544"));
    ObjLinkerWrapper_get_IsDeadState =
        (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x67B3A6C"));
    LObjWrapper_IsAutoAI =
        (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x459D124"));
    ValuePropertyComponent_get_actorHp =
        (int (*)(void *))getRealOffset(ENCRYPTOFFSET("0x4538128"));
    ValuePropertyComponent_get_actorHpTotal =
        (int (*)(void *))getRealOffset(ENCRYPTOFFSET("0x45388D4"));
    AsHero = (uintptr_t (*)(void *))getRealOffset(ENCRYPTOFFSET("0x678C7A4"));
    _SetPlayerName = (monoString * (*)(uintptr_t, monoString *, monoString *,
                                       bool, monoString *))
        getRealOffset(ENCRYPTOFFSET("0x5EA3B6C"));
    old_RefreshHeroPanel = (void (*)(void *, bool, bool, bool))getRealOffset(
        ENCRYPTOFFSET("0x535A470"));
    SkillSlot_get_IsCDReady =
        (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x5E2A4D8"));
    SkillSlot_get_CurSkillID =
        (int (*)(void *))getRealOffset(ENCRYPTOFFSET("0x5E2A538"));
    get_VHostLogic = (void *(*)())getRealOffset(ENCRYPTOFFSET("0x6631FEC"));
    PlrList =
        (List<void *> * (*)(void *)) getRealOffset(ENCRYPTOFFSET("0x3DA1DB8"));
    SendBuyEquipFrameCommand = (void (*)(void *, uint32_t, bool))getRealOffset(
        ENCRYPTOFFSET("0x5C94F58"));
    GetEquipInfo =
        (void *(*)(uint32_t))getRealOffset(ENCRYPTOFFSET("0x5C8B30C"));
    get_HostEquipComp =
        (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x5C8C570"));
    get_m_hostCtrlHero =
        (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x5C8C55C"));
    SendSellEquipFrameCommand =
        (void (*)(void *, uint32_t))getRealOffset(ENCRYPTOFFSET("0x5C950C4"));
    GetEquipActiveSkillCD = (uint32_t (*)(void *, uint32_t))getRealOffset(
        ENCRYPTOFFSET("0x68172F8"));
    GMSetOriSkinId = (void (*)(uint64_t, uint32_t, uint32_t))getRealOffset(
        ENCRYPTOFFSET("0x5E31198"));
    GetOriSkinId = (uint32_t (*)(uint64_t, uint32_t))getRealOffset(
        ENCRYPTOFFSET("0x5E31054"));
    OnCameraHeightChanged =
        (void (*)(void *))getRealOffset(ENCRYPTOFFSET("0x6AC9C54"));
    get_m_hostCtrlHeroPermitedToBuyEquip =
        (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x5C8C654"));
    GetQuickBuyUIView =
        (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x5C99630"));
    get_HostName =
        (monoString * (*)()) getRealOffset(ENCRYPTOFFSET("0x5A308F4"));
}

- (void)loadSetting {
    // ESP
    hackMap = [common boolForKey:NSSENCRYPT("hackMap") defaultValue:NO];
    espEnable = [common boolForKey:NSSENCRYPT("espEnable") defaultValue:NO];
    playerLine = [common boolForKey:NSSENCRYPT("playerLine") defaultValue:NO];
    playerBox = [common boolForKey:NSSENCRYPT("playerBox") defaultValue:NO];
    showNumberOfEnemies = [common boolForKey:NSSENCRYPT("showNumberOfEnemies")
                                defaultValue:NO];
    playerHealth = [common boolForKey:NSSENCRYPT("playerHealth")
                         defaultValue:NO];
    playerDistance = [common boolForKey:NSSENCRYPT("playerDistance")
                           defaultValue:NO];
    playerName = [common boolForKey:NSSENCRYPT("playerName") defaultValue:NO];
    ignoreDrawEnemyVisible =
        [common boolForKey:NSSENCRYPT("ignoreDrawEnemyVisible")
              defaultValue:NO];
    showInfoEnemyInGame = [common boolForKey:NSSENCRYPT("showInfoEnemyInGame")
                                defaultValue:NO];
    showUltiEnemyInGame = [common boolForKey:NSSENCRYPT("showUltiEnemyInGame")
                                defaultValue:NO];
    showSummonerSpell = [common boolForKey:NSSENCRYPT("showSummonerSpell")
                              defaultValue:NO];
    cameraHeight = [common floatForKey:NSSENCRYPT("cameraHeight_")
                          defaultValue:1.0];
    renamePlayerMode = [common integerForKey:NSSENCRYPT("renamePlayerMode")
                                defaultValue:0];

    {
        NSString *value = [common stringForKey:NSSENCRYPT("customNamePlayer")
                                  defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String], customNamePlayer,
                               sizeof(customNamePlayer));
    }

    // Aimbot
    enableAimbot = [common boolForKey:NSSENCRYPT("enableAimbot")
                         defaultValue:NO];
    aimSkill1 = [common boolForKey:NSSENCRYPT("aimSkill1") defaultValue:NO];
    aimSkill2 = [common boolForKey:NSSENCRYPT("aimSkill2") defaultValue:NO];
    aimSkill3 = [common boolForKey:NSSENCRYPT("aimSkill3") defaultValue:NO];
    [self syncAimSkill];
    aimDistance = [common floatForKey:NSSENCRYPT("aimDistance")
                         defaultValue:25.0f];
    aimSpeed = [common floatForKey:NSSENCRYPT("aimSpeed") defaultValue:0.45f];
    aimType = [common integerForKey:NSSENCRYPT("aimType") defaultValue:0];
    drawType = [common integerForKey:NSSENCRYPT("drawType") defaultValue:0];

    // Auto
    autoBuyFirstRecItem = [common boolForKey:NSSENCRYPT("autoBuyFirstRecItem")
                                defaultValue:NO];
    autoSwapEquipEnabled = [common boolForKey:NSSENCRYPT("autoSwapEquipEnabled")
                                 defaultValue:NO];
    [self loadSettingSwapItems];
    autoPunish = [common boolForKey:NSSENCRYPT("autoPunish") defaultValue:NO];
    onlyPunishDragonOrCaesar =
        [common boolForKey:NSSENCRYPT("onlyPunishDragonOrCaesar")
              defaultValue:NO];
    execute = [common boolForKey:NSSENCRYPT("execute") defaultValue:NO];
    hpExecute = [common floatForKey:NSSENCRYPT("hpExecute")
                       defaultValue:hpExecuteDefault];
    frozen = [common boolForKey:NSSENCRYPT("frozen") defaultValue:NO];
    hpFrozen = [common floatForKey:NSSENCRYPT("hpFrozen")
                      defaultValue:hpFrozenDefault];
    heal = [common boolForKey:NSSENCRYPT("heal") defaultValue:NO];
    hpHeal = [common floatForKey:NSSENCRYPT("hpHeal")
                    defaultValue:hpHealDefault];
    healing = [common boolForKey:NSSENCRYPT("healing") defaultValue:NO];
    hpHealing = [common floatForKey:NSSENCRYPT("hpHealing")
                       defaultValue:hpHealingDefault];

    // Mod skin
    unlockSkin = [common boolForKey:NSSENCRYPT("unlockSkin") defaultValue:NO];
    modSkinButton = [common boolForKey:NSSENCRYPT("modSkinButton")
                          defaultValue:NO];
    modeSkinButton = [common integerForKey:NSSENCRYPT("modeSkinButton")
                              defaultValue:1];
    selectedButton = [common integerForKey:NSSENCRYPT("selectedButton")
                              defaultValue:0];
    modNotify = [common boolForKey:NSSENCRYPT("modNotify") defaultValue:NO];
    modeNotify = [common integerForKey:NSSENCRYPT("modeNotify") defaultValue:1];
    selectedKillNotify = [common integerForKey:NSSENCRYPT("selectedKillNotify")
                                  defaultValue:0];

    // Mod rank
    unlockModRank = [common boolForKey:NSSENCRYPT("unlockModRank")
                          defaultValue:NO];
    fakeRank = [common integerForKey:NSSENCRYPT("fakeRank") defaultValue:28];
    fakeRankIndex = [common integerForKey:NSSENCRYPT("fakeRankIndex")
                             defaultValue:0];
    fakeStars = [common integerForKey:NSSENCRYPT("fakeStars") defaultValue:1];
    fakeMark = [common integerForKey:NSSENCRYPT("fakeMark") defaultValue:1];
    topRank = [common integerForKey:NSSENCRYPT("topRank") defaultValue:1];
    topHero = [common integerForKey:NSSENCRYPT("topHero") defaultValue:0];

    // Mod text kill notify
    modTextKillNotifyFirstKill =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyFirstKill")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyFirstKillText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyFirstKillText,
                               sizeof(modTextKillNotifyFirstKillText));
    }

    modTextKillNotifyKill =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyKill") defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyKillText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String], modTextKillNotifyKillText,
                               sizeof(modTextKillNotifyKillText));
    }

    modTextKillNotifyDoubleKill =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyDoubleKill")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyDoubleKillText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyDoubleKillText,
                               sizeof(modTextKillNotifyDoubleKillText));
    }

    modTextKillNotifyTripleKill =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyTripleKill")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyTripleKillText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyTripleKillText,
                               sizeof(modTextKillNotifyTripleKillText));
    }

    modTextKillNotifyQuataKill =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyQuataKill")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyQuataKillText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyQuataKillText,
                               sizeof(modTextKillNotifyQuataKillText));
    }

    modTextKillNotifyPentaKill =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyPentaKill")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyPentaKillText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyPentaKillText,
                               sizeof(modTextKillNotifyPentaKillText));
    }

    modTextKillNotifyGotcha =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyGotcha")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyGotchaText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String], modTextKillNotifyGotchaText,
                               sizeof(modTextKillNotifyGotchaText));
    }

    modTextKillNotifyLegend =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyLegend")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyLegendText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String], modTextKillNotifyLegendText,
                               sizeof(modTextKillNotifyLegendText));
    }

    modTextKillNotifyLegendary =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyLegendary")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyLegendaryText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyLegendaryText,
                               sizeof(modTextKillNotifyLegendaryText));
    }

    modTextKillNotifyHallow =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyHallow")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyHallowText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String], modTextKillNotifyHallowText,
                               sizeof(modTextKillNotifyHallowText));
    }

    modTextKillNotifyDestroyTower =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyDestroyTower")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyDestroyTowerText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyDestroyTowerText,
                               sizeof(modTextKillNotifyDestroyTowerText));
    }

    modTextKillNotifyShutdown =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyShutdown")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyShutdownText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyShutdownText,
                               sizeof(modTextKillNotifyShutdownText));
    }

    modTextKillNotifyKillCeasar =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyKillCeasar")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyKillCeasarText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyKillCeasarText,
                               sizeof(modTextKillNotifyKillCeasarText));
    }

    modTextKillNotifyKillDarkCeasar =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyKillDarkCeasar")
              defaultValue:NO];
    {
        NSString *value = [common
            stringForKey:NSSENCRYPT("modTextKillNotifyKillDarkCeasarText")
            defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyKillDarkCeasarText,
                               sizeof(modTextKillNotifyKillDarkCeasarText));
    }

    modTextKillNotifyKillDarkTyrantCeasar =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyKillDarkTyrantCeasar")
              defaultValue:NO];
    {
        NSString *value = [common
            stringForKey:NSSENCRYPT("modTextKillNotifyKillDarkTyrantCeasarText")
            defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer(
            [value UTF8String], modTextKillNotifyKillDarkTyrantCeasarText,
            sizeof(modTextKillNotifyKillDarkTyrantCeasarText));
    }

    modTextKillNotifyKillDragon =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyKillDragon")
              defaultValue:NO];
    {
        NSString *value =
            [common stringForKey:NSSENCRYPT("modTextKillNotifyKillDragonText")
                    defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyKillDragonText,
                               sizeof(modTextKillNotifyKillDragonText));
    }

    modTextKillNotifyKillLightDragon =
        [common boolForKey:NSSENCRYPT("modTextKillNotifyKillLightDragon")
              defaultValue:NO];
    {
        NSString *value = [common
            stringForKey:NSSENCRYPT("modTextKillNotifyKillLightDragonText")
            defaultValue:NSSENCRYPT("")];
        LoadStringToCharBuffer([value UTF8String],
                               modTextKillNotifyKillLightDragonText,
                               sizeof(modTextKillNotifyKillLightDragonText));
    }

    // Setting
    hideUID = [common boolForKey:NSSENCRYPT("hideUID") defaultValue:NO];
    showRank = [common boolForKey:NSSENCRYPT("showRank") defaultValue:NO];
    showHistory = [common boolForKey:NSSENCRYPT("showHistory") defaultValue:NO];
    blockHost = [common boolForKey:NSSENCRYPT("blockHost") defaultValue:NO];
    blockHostOption = [common integerForKey:NSSENCRYPT("blockHostOption")
                               defaultValue:1];
    bypassDelay = [common integerForKey:NSSENCRYPT("bypassDelay")
                           defaultValue:10];
}

- (void)loadSettingSwapItems {
    NSString *nsJson = [common stringForKey:NSSENCRYPT("swap_items_json")
                               defaultValue:@""];
    if ([nsJson length] > 0) {
        try {
            std::string jsonStr = [nsJson UTF8String];
            nlohmann::json j = nlohmann::json::parse(jsonStr);
            swapItems = j.get<std::vector<SwapItem>>();
        } catch (...) {
            swapItems = swapItemsDefault;
        }
    } else {
        swapItems = swapItemsDefault;
    }
}

- (void)syncAimSkill {
    activeSkills.clear();
    if (aimSkill1) {
        activeSkills.push_back(1);
    }
    if (aimSkill2) {
        activeSkills.push_back(2);
    }
    if (aimSkill3) {
        activeSkills.push_back(3);
    }
}

- (void)setupFloatButton {
    [self.floatButtonImageView removeFromSuperview];
    self.floatButtonImageView = nil;
    self.floatButtonHostView = nil;

    NSString *pureBase64 = floatButton;
    if ([pureBase64 hasPrefix:@"data:"]) {
        NSArray *components = [pureBase64 componentsSeparatedByString:@","];
        if (components.count > 1)
            pureBase64 = components[1];
    }
    NSData *data = [[NSData alloc]
        initWithBase64EncodedString:pureBase64
                            options:
                                NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:data];
    if (!image)
        return;

    UIView *hostView = self.view.superview;
    if (!hostView) {
        UIWindow *keyWindow = [common getKeyWindow];
        UIViewController *topVC = [common getTopViewController:keyWindow];
        hostView = topVC.view;
    }
    if (!hostView)
        return;

    self.floatButtonHostView = hostView;

    CGRect bounds = hostView.bounds;
    CGFloat x = (bounds.size.width - kFloatButtonWidth) / 2;
    CGFloat y = (bounds.size.height - kFloatButtonHeight) / 2;

    self.floatButtonImageView = [[UIImageView alloc]
        initWithFrame:CGRectMake(x, y, kFloatButtonWidth, kFloatButtonHeight)];
    self.floatButtonImageView.image = image;
    self.floatButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.floatButtonImageView.layer.cornerRadius = kFloatButtonWidth / 2;
    self.floatButtonImageView.clipsToBounds = YES;
    self.floatButtonImageView.userInteractionEnabled = YES;

    [hostView addSubview:self.floatButtonImageView];
    [hostView bringSubviewToFront:self.floatButtonImageView];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handlePanFloatButton:)];
    [self.floatButtonImageView addGestureRecognizer:panGesture];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handleTapFloatButton)];
    [self.floatButtonImageView addGestureRecognizer:tapGesture];
}

- (void)handlePanFloatButton:(UIPanGestureRecognizer *)gesture {
    UIView *hostView =
        self.floatButtonHostView ?: self.floatButtonImageView.superview;
    if (!hostView)
        return;

    CGPoint translation = [gesture translationInView:hostView];

    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect bounds = hostView.bounds;
        CGFloat minX = (kFloatButtonWidth / 2) + kPaddingVertical;
        CGFloat maxX =
            bounds.size.width - (kFloatButtonWidth / 2) - kPaddingVertical;
        CGFloat minY = (kFloatButtonHeight / 2) + kPaddingVertical;
        CGFloat maxY =
            bounds.size.height - (kFloatButtonHeight / 2) - kPaddingVertical;
        CGPoint newCenter =
            CGPointMake(self.floatButtonImageView.center.x + translation.x,
                        self.floatButtonImageView.center.y + translation.y);
        newCenter.x = fmax(minX, fmin(newCenter.x, maxX));
        newCenter.y = fmax(minY, fmin(newCenter.y, maxY));
        self.floatButtonImageView.center = newCenter;

        [gesture setTranslation:CGPointZero inView:hostView];
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [self snapFloatButtonToEdgeAtFirst:NO];
    }
}

- (void)snapFloatButtonToEdgeAtFirst:(BOOL)atFirst {
    UIView *hostView =
        self.floatButtonHostView ?: self.floatButtonImageView.superview;
    if (!hostView)
        return;

    CGRect bounds = hostView.bounds;
    CGRect frame = self.floatButtonImageView.frame;
    CGFloat targetX =
        (self.floatButtonImageView.center.x < bounds.size.width / 2)
            ? kPaddingHorizontal
            : bounds.size.width - frame.size.width - kPaddingHorizontal;
    CGFloat targetY =
        (self.floatButtonImageView.center.y < bounds.size.height / 2)
            ? kPaddingVertical
            : bounds.size.height - frame.size.height - kPaddingVertical;
    CGFloat spaceX = fabs(targetX - self.floatButtonImageView.frame.origin.x);
    CGFloat spaceY = fabs(targetY - self.floatButtonImageView.frame.origin.y);

    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       CGRect finalFrame = self.floatButtonImageView.frame;
                       if (atFirst || spaceX < spaceY) {
                           finalFrame.origin.x = targetX;
                       } else {
                           finalFrame.origin.y = targetY;
                       }
                       self.floatButtonImageView.frame = finalFrame;
                     }
                     completion:nil];
}

- (void)handleTapFloatButton {
    if (self.onCallChange) {
        isShowMenu = !isShowMenu;
        self.onCallChange(isShowMenu);
    }
    [self.floatButtonImageView.superview
        bringSubviewToFront:self.floatButtonImageView];

    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc]
        initWithStyle:UIImpactFeedbackStyleLight];
    [generator impactOccurred];
}

- (void)hook {
    LOG(@"%@", NSSENCRYPT("========= Start hooking ========="));

    HOOK_V3(actorLink_updateOffset, ActorLinker_Update, old_ActorLinker_Update);
    HOOK_V3(lactor_updateLogic, LActorRoot_UpdateLogic,
            old_LActorRoot_UpdateLogic);
    HOOK_V3(actorLink_destroyOffset, ActorLinker_ActorDestroy,
            old_ActorLinker_ActorDestroy);
    HOOK_V3(lactor_destroy, LActorRoot_ActorDestroy,
            old_LActorRoot_ActorDestroy);
    HOOK_V3(hackMapOffset, SetVisible, old_SetVisible);

    timer(0.1) {
        HOOK_V3(updateOffset, LateUpdate, old_LateUpdate);
        HOOK_V3(camOffset, GetZoomRate, old_GetZoomRate);
        HOOK_V3(onEnterOffset, OnEnter, old_OnEnter);
        HOOK_V3(skillSlotOffset, skillSlotFunc, old_skillSlotFunc);
        HOOK_V3(skillComponentOffset, skillComponentUpdateFunc,
                old_skillComponentUpdateFunc);
    });

    timer(0.2) {
        HOOK_V3(getMasterRoleInfoOffset, GetMasterRoleInfo,
                old_GetMasterRoleInfo);
        HOOK_V3(canPlayerShowLegendRankOffset, CanPlayerShowLegendRank,
                old_CanPlayerShowLegendRank);
        HOOK_V3(isShowLegendRankModeOffset, IsShowLegendRankMode,
                old_IsShowLegendRankMode);
        HOOK_V3(tryShowLegendRankOffset, TryShowLegendRank,
                old_TryShowLegendRank);
        HOOK_V3(updateLogicOffset, UpdateLogic, old_UpdateLogic);
    });

    timer(0.3) {
        HOOK_V3(skillDirectOffset, GetUseSkillDirection,
                old_GetUseSkillDirection);
        HOOK_V3(hideUIDOffset, OpenWaterMark, old_OpenWaterMark);
        HOOK_V3(isHaveHeroSkinOffset, IsHaveHeroSkin, old_IsHaveHeroSkin);
        HOOK_V3(isCanUseSkinOffset, IsCanUseSkin, old_IsCanUseSkin);
        HOOK_V3(onClickSelectHeroSkinOffset, OnClickSelectHeroSkin,
                old_OnClickSelectHeroSkin);
        HOOK_V3(battleEquipSystemUpdateOffset, CBattleEquipSystem_Update,
                old_CBattleEquipSystem_Update);
    });

    timer(0.5) {
        HOOK_V3(heroSelectBanPickOnHeroSkinWearSucOffset,
                HeroSelectBanPick_OnHeroSkinWearSuc,
                old_HeroSelectBanPick_OnHeroSkinWearSuc);
        HOOK_V3(heroSelectBanPickOnHeroSkinWearFailOffset,
                HeroSelectBanPick_OnHeroSkinWearFail,
                old_HeroSelectBanPick_OnHeroSkinWearFail);
        HOOK_V3(heroSelectBanPickOnSkinSelectOffset,
                HeroSelectBanPick_OnSkinSelect,
                old_HeroSelectBanPick_OnSkinSelect);
        HOOK_V3(getHeroWearSkinIdOffset, GetHeroWearSkinId,
                old_GetHeroWearSkinId);
        HOOK_V3(unpackOffset, unpack, old_unpack);
    });

    timer(0.6) {
        HOOK_V3(isOpenOffset, IsOpen, old_IsOpen);
        HOOK_V3(buttonOffset, get_PersonalBtnId, old_get_PersonalBtnId);
        HOOK_V3(getPlayerOffset, GetPlayer, old_GetPlayer);
        HOOK_V3(isPlayerOffset, IsAtMyTeam, old_IsAtMyTeam);
        HOOK_V3(endGameOffset, EndGame, old_EndGame);
    });

    timer(0.7) {
        HOOK_V3(disconnectOffset, Disconnected, old_Disconnected);
        HOOK_V3(killUTGetNotifyOffset, GetNotifyText, old_GetNotifyText);
        HOOK_V3(killUTGETNotifyOffset, GETNotifyText, old_GETNotifyText);
        HOOK_V3(lEquipComponent_UpdateLogicOffset, LEquipComponent_UpdateLogic,
                old_LEquipComponent_UpdateLogic);
        HOOK_V3(passiveSkill_InitOffset, PassiveSkill_Init,
                old_PassiveSkill_Init);
    });

    timer(0.8) {
        HOOK_V3(passiveEvent_UnInitOffset, PassiveEvent_UnInit,
                old_PassiveEvent_UnInit);
        HOOK_V3(ENCRYPTOFFSET("0x2AC2BE8"), hook_sub_2ac2be8, old_sub_2ac2be8);
        HOOK_V3(characterCustomizationUtils_GetComponentBattleEffectFlagOffset,
                GetComponentBattleEffectFlag, old_GetComponentBattleEffectFlag);
        HOOK_V3(characterCustomizationUtils_HandleSkinCustomizationImplOffset,
                HandleSkinCustomizationImpl, old_HandleSkinCustomizationImpl);
        HOOK_V3(actorServerDataProvider_ConvertServerHeroInfoOffset,
                ConvertServerHeroInfo, old_ConvertServerHeroInfo);
    });

    timer(0.9) {
        HOOK_V3(gameBuilderProxy_HandlePreLoadDateSkinDegeneratedOffset,
                HandlePreLoadDateSkinDegenerated,
                old_HandlePreLoadDateSkinDegenerated);
        HOOK_V3(mobaUtility_SpawnActorOffset, MobaUtility_SpawnActor,
                old_MobaUtility_SpawnActor);
        HOOK_V3(unpack_COMDT_CHOICEHERO_Offset, unpack_COMDT_CHOICEHERO,
                old_unpack_COMDT_CHOICEHERO);
        HOOK_V3(unpack_COMDT_PLAYERINFO_Offset, unpack_COMDT_PLAYERINFO,
                old_unpack_COMDT_PLAYERINFO);
    });

    [self finishHook];
}

- (void)finishHook {
    timer(1.5) {
        self.hookingDone = YES;

        [self
            activeHack:
                NSSENCRYPT(
                    "Chào bạn nhé! Mình BỆU đây -.- (Liên Quân Mobile Hack)")
               message:NSSENCRYPT(
                           "Chạm vào biểu tượng nổi ở trên màn hình, hoặc nhấn "
                           "giữ màn hình 2 lần bằng 3 ngón tay để mở menu.")
                  font:[UIFont fontWithName:NSSENCRYPT("AvenirNext-Bold")
                                       size:15]
              duration:3.0];

        LOG(@"%@", NSSENCRYPT("========= Hooking done ========="));

        [self setupFloatButton];
        timer(0.3) { [self snapFloatButtonToEdgeAtFirst:YES]; });
    });
}

- (void)patch {
    if (!self.hookingDone)
        return;

    // Patch once time
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      timer_background(0.5) {
          LOG(@"%@", NSSENCRYPT("========= Start patching ========="));

          timer_background(0.1) {
              /*
              nop
              */
              if (showRank) {
                  patchOffset(showRankOffset, ENCRYPTHEX("1F 20 03 D5"));
              } else {
                  restorePatchOffset(showRankOffset, ENCRYPTHEX("1F 20 03 D5"));
              }
          });

          if (showUltiEnemyInGame) {
              patchOffset(showUltiEnemyInGameOffset, ENCRYPTHEX("1F 20 03 D5"));
          } else {
              restorePatchOffset(showUltiEnemyInGameOffset,
                                 ENCRYPTHEX("1F 20 03 D5"));
          }

          timer_background(0.2) {
              /*
              mov x19, #1
              */
              if (showInfoEnemyInGame) {
                  patchOffset(showInfoEnemyInGameOffset,
                              ENCRYPTHEX("33 00 80 D2"));
              } else {
                  restorePatchOffset(showInfoEnemyInGameOffset,
                                     ENCRYPTHEX("33 00 80 D2"));
              }
          });

          timer_background(0.3) {
              /*
              b #0x24
              */
              if (showSummonerSpell) {
                  patchOffset(showSummonerSpellOffset,
                              ENCRYPTHEX("09 00 00 14"));
              } else {
                  restorePatchOffset(showSummonerSpellOffset,
                                     ENCRYPTHEX("09 00 00 14"));
              }
          });

          timer_background(0.4) {
              /*
              mov x0, #1
              ret
              */
              if (showHistory) {
                  patchOffset(showHistoryOffset,
                              ENCRYPTHEX("20 00 80 D2 C0 03 5F D6"));
              } else {
                  restorePatchOffset(showHistoryOffset,
                                     ENCRYPTHEX("20 00 80 D2 C0 03 5F D6"));
              }
          });

          timer_background(0.5) {
              /*
              ret
              */
              patchOffset(handleReportFirebase, ENCRYPTHEX("C0 03 5F D6"));
          });

          timer_background(1) {
              LOG(@"%@", NSSENCRYPT("========= Patching done ========="));
          });
      });
    });
}

+ (void)showChange:(BOOL)open {
    isShowMenu = open;
}

- (MTKView *)mtkView {
    return (MTKView *)self.view;
}

#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event {
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseEnded &&
            touch.phase != UITouchPhaseCancelled) {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches
               withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)hasText {
    return strlen(customNamePlayer) > 0;
}

- (void)insertText:(NSString *)text {
    if (text.length == 0) {
        return;
    }

    ImGuiIO &io = ImGui::GetIO();
    if (!io.WantTextInput) {
        return;
    }

    if ([text isEqualToString:@"\n"]) {
        io.KeysDown[ImGuiIOSKey_Enter] = true;
        return;
    }

    io.AddInputCharactersUTF8(text.UTF8String);
}

- (void)deleteBackward {
    ImGuiIO &io = ImGui::GetIO();
    io.KeysDown[ImGuiIOSKey_Backspace] = true;
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
    if (!ImGui::GetCurrentContext()) {
        return;
    }

    ImGuiIO &io = ImGui::GetIO();
    if (!io.WantTextInput) {
        return;
    }

    self.keyboardDismissedByUser = YES;
    ImGui::ClearActiveID();
}

- (void)syncKeyboardInputState {
    ImGuiIO &io = ImGui::GetIO();

    if (io.WantTextInput) {
        if (!self.keyboardDismissedByUser && ![self isFirstResponder]) {
            [self becomeFirstResponder];
        }
    } else if ([self isFirstResponder]) {
        self.keyboardDismissedByUser = NO;
        [self resignFirstResponder];
    } else {
        self.keyboardDismissedByUser = NO;
    }
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
    UpdateRealtimeFps();
    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale =
        view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = gRealtimeFpsState.deltaTime;

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    if (isShowMenu == true) {
        [self.view setUserInteractionEnabled:YES];
    } else if (isShowMenu == false) {
        [self.view setUserInteractionEnabled:NO];
    }

    MTLRenderPassDescriptor *renderPassDescriptor =
        view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer
            renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();

        ImFont *font = ImGui::GetFont();
        font->Scale = 15.f / font->FontSize;

        bool isIpad = ([[UIDevice currentDevice] userInterfaceIdiom] ==
                       UIUserInterfaceIdiomPad);

        CGFloat width = fmin(kWidth * (isIpad ? 0.5 : 0.8), 600);
        CGFloat height = fmin(kHeight * (isIpad ? 0.6 : 0.8), 600);
        CGFloat x = (kWidth - width) / 2;
        CGFloat y = (kHeight - height) / 2;

        static float lastKnownWidth = 0;
        static float lastKnownHeight = 0;

        if (supportRotateScreen &&
            (lastKnownWidth != kWidth || lastKnownHeight != kHeight)) {
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Always);
            ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_Always);

            lastKnownWidth = kWidth;
            lastKnownHeight = kHeight;
        } else {
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Appearing);
            ImGui::SetNextWindowSize(ImVec2(width, height),
                                     ImGuiCond_Appearing);
        }

        if (isShowMenu) {
            ImGui::Begin(ENCRYPT("Liên Quân Mobile Mod"), &isShowMenu);
            if (ImGui::BeginTabBar(ENCRYPT("MainTabs"))) {
                DrawTabBarFpsBadge();
                if (ImGui::BeginTabItem(ENCRYPT("ESP"))) {
                    [self resolveTabContentScroll:NSSENCRYPT("ESP_Scroll")
                                            block:^{
                                              [self setupTabESP];
                                            }];
                    ImGui::EndTabItem();
                }
                if (ImGui::BeginTabItem(ENCRYPT("Aimbot"))) {
                    [self resolveTabContentScroll:NSSENCRYPT("Aimbot_Scroll")
                                            block:^{
                                              [self setupTabAimbot];
                                            }];
                    ImGui::EndTabItem();
                }
                if (ImGui::BeginTabItem(ENCRYPT("Auto"))) {
                    [self resolveTabContentScroll:NSSENCRYPT("Auto_Scroll")
                                            block:^{
                                              [self setupTabAuto];
                                            }];
                    ImGui::EndTabItem();
                }
                if (ImGui::BeginTabItem(ENCRYPT("Mod Skin"))) {
                    [self resolveTabContentScroll:NSSENCRYPT("ModSkin_Scroll")
                                            block:^{
                                              [self setupTabModSkin];
                                            }];
                    ImGui::EndTabItem();
                }
                if (ImGui::BeginTabItem(ENCRYPT("Mod Kill Notify"))) {
                    [self resolveTabContentScroll:NSSENCRYPT(
                                                      "ModKillNotify_Scroll")
                                            block:^{
                                              [self setupTabModTextKillNotify];
                                            }];
                    ImGui::EndTabItem();
                }
                if (ImGui::BeginTabItem(ENCRYPT("Khác"))) {
                    [self resolveTabContentScroll:NSSENCRYPT("Other_Scroll")
                                            block:^{
                                              [self setupTabOther];
                                            }];
                    ImGui::EndTabItem();
                }
                ImGui::EndTabBar();
            }

            ImGui::End();
        }

        [self syncKeyboardInputState];
        [self patch];

        ImDrawList *draw_list = ImGui::GetBackgroundDrawList();
        drawESP(draw_list);
        drawAimbot(draw_list);

        ImGui::Render();
        ImDrawData *draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);

        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];

    ImGuiIO &resetIO = ImGui::GetIO();
    resetIO.KeysDown[ImGuiIOSKey_Backspace] = false;
    resetIO.KeysDown[ImGuiIOSKey_Enter] = false;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)resolveTabContentScroll:(NSString *)str_id block:(void (^)(void))block {
    ImGui::BeginChild([str_id UTF8String], ImVec2(0, 0), true,
                      ImGuiWindowFlags_AlwaysVerticalScrollbar);
    block();
    ImGui::EndChild();
}

- (void)setupTabESP {
    CheckboxImGuiItem mainItems[] = {
        {ENCRYPT("Map sáng"), &hackMap},
        {ENCRYPT("Vẽ ESP"), &espEnable},
        {ENCRYPT("Vẽ line"), &playerLine},
        {ENCRYPT("Hiển thị tổng số địch"), &showNumberOfEnemies},
        {ENCRYPT("Vẽ box"), &playerBox},
        {ENCRYPT("Hiển thị khoảng cách tới địch"), &playerDistance},
        {ENCRYPT("Hiển thị máu địch"), &playerHealth},
        {ENCRYPT("Bỏ qua vẽ địch đã hiển thị"), &ignoreDrawEnemyVisible},
        {ENCRYPT("Hiển thị tên tướng địch (Phân biệt bot)"), &playerName}};

    if (ImGui::BeginTable("ESP", 2)) {
        for (auto &item : mainItems) {
            ImGui::TableNextColumn();
            ImGui::Checkbox(item.label.c_str(), item.value);
        }
        ImGui::EndTable();
    }
    ImGui::NewLine();

    if (ImGui::Checkbox(ENCRYPT("Hiển thị thông tin team địch"),
                        &showInfoEnemyInGame)) {
        if (showInfoEnemyInGame) {
            patchOffset(showInfoEnemyInGameOffset, ENCRYPTHEX("33 00 80 D2"));
        } else {
            restorePatchOffset(showInfoEnemyInGameOffset,
                               ENCRYPTHEX("33 00 80 D2"));
        }
    }
    if (ImGui::Checkbox(ENCRYPT("Hiển thị trạng thái chiêu cuối team địch"),
                        &showUltiEnemyInGame)) {
        if (showUltiEnemyInGame) {
            patchOffset(showUltiEnemyInGameOffset, ENCRYPTHEX("1F 20 03 D5"));
        } else {
            restorePatchOffset(showUltiEnemyInGameOffset,
                               ENCRYPTHEX("1F 20 03 D5"));
        }
    }
    if (ImGui::Checkbox(ENCRYPT("Hiển thị thông tin phép bổ trợ team địch"),
                        &showSummonerSpell)) {
        if (showSummonerSpell) {
            patchOffset(showSummonerSpellOffset, ENCRYPTHEX("09 00 00 14"));
        } else {
            restorePatchOffset(showSummonerSpellOffset,
                               ENCRYPTHEX("09 00 00 14"));
        }
    }
    if (ImGui::Checkbox(ENCRYPT("Hiển thị rank team địch"), &showRank)) {
        if (showRank) {
            patchOffset(showRankOffset, ENCRYPTHEX("1F 20 03 D5"));
        } else {
            restorePatchOffset(showRankOffset, ENCRYPTHEX("1F 20 03 D5"));
        }
    }
    ImGui::NewLine();

    ImGui::Text("%s", ENCRYPT("Đổi tên player"));
    ImGui::RadioButton(ENCRYPT("Không"), &renamePlayerMode, 0);
    ImGui::SameLine();
    ImGui::RadioButton(ENCRYPT("Thời gian hồi chiêu"), &renamePlayerMode, 1);
    ImGui::SameLine();
    ImGui::RadioButton(ENCRYPT("Tuỳ chỉnh"), &renamePlayerMode, 2);
    ImGui::NewLine();

    if (renamePlayerMode == 2) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập tên tuỳ chỉnh"),
                              ENCRYPT("Dán##FirstKill"), customNamePlayer,
                              IM_ARRAYSIZE(customNamePlayer));
        ImGui::NewLine();
    }

    ImGui::SliderFloat(ENCRYPT("Cam xa"), &cameraHeight, minCameraHeight,
                       maxCameraHeight, ENCRYPT("%.2f"));
    ImGui::Spacing();
}

- (void)setupTabAimbot {
    ImGui::Checkbox(ENCRYPT("Aimbot"), &enableAimbot);
    if (!enableAimbot)
        return;

    if (ImGui::Checkbox(ENCRYPT("Chiêu 1"), &aimSkill1)) {
        if (aimSkill1) {
            if (std::find(activeSkills.begin(), activeSkills.end(), 1) ==
                activeSkills.end()) {
                activeSkills.push_back(1);
            }
        } else {
            activeSkills.erase(
                std::remove(activeSkills.begin(), activeSkills.end(), 1),
                activeSkills.end());
        }
    }

    ImGui::SameLine();
    if (ImGui::Checkbox(ENCRYPT("Chiêu 2"), &aimSkill2)) {
        if (aimSkill2) {
            if (std::find(activeSkills.begin(), activeSkills.end(), 2) ==
                activeSkills.end()) {
                activeSkills.push_back(2);
            }
        } else {
            activeSkills.erase(
                std::remove(activeSkills.begin(), activeSkills.end(), 2),
                activeSkills.end());
        }
    }

    ImGui::SameLine();
    if (ImGui::Checkbox(ENCRYPT("Chiêu 3"), &aimSkill3)) {
        if (aimSkill3) {
            if (std::find(activeSkills.begin(), activeSkills.end(), 3) ==
                activeSkills.end()) {
                activeSkills.push_back(3);
            }
        } else {
            activeSkills.erase(
                std::remove(activeSkills.begin(), activeSkills.end(), 3),
                activeSkills.end());
        }
    }

    ImGui::SliderFloat(ENCRYPT("Khoảng cách Aimbot"), &aimDistance, 0.0f,
                       100.0f, "%.1f");
    ImGui::SliderFloat(ENCRYPT("Độ nhạy khoá mục tiêu"), &aimSpeed, 0.01f,
                       5.00f, "%.1f");

    std::string aimWhenOptionsStr[] = {
        ENCRYPT("% máu thấp nhất"), ENCRYPT("Máu thấp nhất"),
        ENCRYPT("Gần nhất"), ENCRYPT("Gần tia ngắm nhất")};
    const char *aimWhenOptions[] = {
        aimWhenOptionsStr[0].c_str(), aimWhenOptionsStr[1].c_str(),
        aimWhenOptionsStr[2].c_str(), aimWhenOptionsStr[3].c_str()};
    ImGui::Combo(ENCRYPT("Kiểu Aimbot"), &aimType, aimWhenOptions,
                 IM_ARRAYSIZE(aimWhenOptions));

    std::string drawOptionsStr[] = {ENCRYPT("Không vẽ"), ENCRYPT("Luôn luôn"),
                                    ENCRYPT("Chỉ khi ngắm (Chỉ Elsu)")};
    const char *drawOptions[] = {drawOptionsStr[0].c_str(),
                                 drawOptionsStr[1].c_str(),
                                 drawOptionsStr[2].c_str()};
    ImGui::Combo(ENCRYPT("Vẽ tia"), &drawType, drawOptions,
                 IM_ARRAYSIZE(drawOptions));
}

- (void)setupTabAuto {
    ImGui::Checkbox(ENCRYPT("Auto mua đồ (Món đầu đề cử)"),
                    &autoBuyFirstRecItem);
    ImGui::Checkbox(ENCRYPT("Auto bán mua đồ nhanh"), &autoSwapEquipEnabled);
    if (autoSwapEquipEnabled) {
        ImGui::SetWindowFontScale(0.85f);
        ImGui::TextWrapped(
            "%s",
            ENCRYPT("Sẽ tự động bán Giáp hộ mệnh, Liềm đoạt mệnh, Hercule "
                    "thịnh nộ, Băng sương, Thương khung kiếm, Nham thuẫn nếu "
                    "nằm trong đồ đã mua và bị kích hoạt rồi"));
        ImGui::TextWrapped("%s",
                           ENCRYPT("Sau đó tự mua nhanh những món đồ bạn chọn "
                                   "bên dưới theo thứ tự"));
        ImGui::SetWindowFontScale(1.0f);
        ImGui::NewLine();
        ImGui::Indent();

        int firstEnabledIdx = -1;
        int lastEnabledIdx = -1;
        for (int i = 0; i < swapItems.size(); i++) {
            if (swapItems[i].enabled) {
                if (firstEnabledIdx == -1)
                    firstEnabledIdx = i;
                lastEnabledIdx = i;
            }
        }

        for (int i = 0; i < (int)swapItems.size(); i++) {
            ImGui::PushID(i);

            bool enabled = swapItems[i].enabled;
            std::string cbLabel = ENCRYPT("##enabled_") + std::to_string(i);
            if (ImGui::Checkbox(cbLabel.c_str(), &enabled)) {
                swapItems[i].enabled = enabled;
                ReorganizeSwapItems();
            }
            ImGui::SameLine();
            if (swapItems[i].enabled) {
                ImGui::Text(ENCRYPT("[%d] %s"), (i + 1),
                            swapItems[i].name.c_str());
            } else {
                ImGui::Text(ENCRYPT("[-] %s"), swapItems[i].name.c_str());
            }

            if (swapItems[i].enabled) {
                ImGui::SameLine(ImGui::GetWindowWidth() - 90);

                if (i > firstEnabledIdx) {
                    std::string upLabel = std::string(ICON_FA_CARET_UP) +
                                          "##up_" + std::to_string(i);
                    if (ImGui::Button(upLabel.c_str(), ImVec2(25, 20))) {
                        std::swap(swapItems[i], swapItems[i - 1]);
                    }
                } else {
                    ImGui::Dummy(ImVec2(25, 20));
                }
                ImGui::SameLine();

                if (i < lastEnabledIdx) {
                    std::string downLabel = std::string(ICON_FA_CARET_DOWN) +
                                            "##down_" + std::to_string(i);
                    if (ImGui::Button(downLabel.c_str(), ImVec2(25, 20))) {

                        std::swap(swapItems[i], swapItems[i + 1]);
                    }
                } else {
                    ImGui::Dummy(ImVec2(25, 20));
                }
            }
            ImGui::PopID();
        }
        ImGui::Unindent();
    }
    ImGui::NewLine();

    ImGui::Checkbox(ENCRYPT("Auto trừng trị"), &autoPunish);
    if (autoPunish) {
        ImGui::SameLine();
        ImGui::Checkbox(ENCRYPT("Chỉ trừng trị Rồng và Tà Thần"),
                        &onlyPunishDragonOrCaesar);
    }
    ImGui::Checkbox(ENCRYPT("Auto bộc phá"), &execute);
    if (execute) {
        std::ostringstream oss;
        oss << std::fixed << std::setprecision(2) << hpExecuteDefault;
        std::string label =
            ENCRYPT("%HP (Mặc định ") + oss.str() + ENCRYPT("%)");
        ImGui::SliderFloat(label.c_str(), &hpExecute, 0.0f, 100.0f, "%.2f");
    }

    ImGui::Checkbox(ENCRYPT("Auto băng sương"), &frozen);
    if (frozen) {
        std::ostringstream oss;
        oss << std::fixed << std::setprecision(2) << hpFrozenDefault;
        std::string label =
            ENCRYPT("%HP (Mặc định ") + oss.str() + ENCRYPT("%)");
        ImGui::SliderFloat(label.c_str(), &hpFrozen, 0.0f, 100.0f, "%.2f");
    }

    ImGui::Checkbox(ENCRYPT("Auto hồi máu"), &heal);
    if (heal) {
        std::ostringstream oss;
        oss << std::fixed << std::setprecision(2) << hpHealDefault;
        std::string label =
            ENCRYPT("%HP (Mặc định ") + oss.str() + ENCRYPT("%)");
        ImGui::SliderFloat(label.c_str(), &hpHeal, 0.0f, 100.0f, "%.2f");
    }

    ImGui::Checkbox(ENCRYPT("Auto cấp cứu"), &healing);
    if (healing) {
        std::ostringstream oss;
        oss << std::fixed << std::setprecision(2) << hpHealingDefault;
        std::string label =
            ENCRYPT("%HP (Mặc định ") + oss.str() + ENCRYPT("%)");
        ImGui::SliderFloat(label.c_str(), &hpHealing, 0.0f, 100.0f, "%.2f");
    }

    ImGui::NewLine();
    if (ImGui::Button(ENCRYPT("Reset về mặc định"))) {
        hpExecute = hpExecuteDefault;
        hpFrozen = hpFrozenDefault;
        hpHeal = hpHealDefault;
        hpHealing = hpHealingDefault;
    }
    ImGui::Spacing();
}

- (void)setupTabModSkin {
    // Mod rank
    ImGui::Checkbox(ENCRYPT("Mod rank"), &unlockModRank);
    if (unlockModRank) {
        std::string rankOptionsStr[] = {ENCRYPT("Cao Thủ IV"),
                                        ENCRYPT("Cao Thủ III"),
                                        ENCRYPT("Cao Thủ II"),
                                        ENCRYPT("Cao Thủ I"),
                                        ENCRYPT("Chiến tướng (Thách đấu)"),
                                        ENCRYPT("Chiến thần (Thách đấu)")};
        const char *rankOptions[] = {
            rankOptionsStr[0].c_str(), rankOptionsStr[1].c_str(),
            rankOptionsStr[2].c_str(), rankOptionsStr[3].c_str(),
            rankOptionsStr[4].c_str(), rankOptionsStr[5].c_str()};
        if (ImGui::Combo(ENCRYPT("Rank"), &fakeRankIndex, rankOptions,
                         IM_ARRAYSIZE(rankOptions))) {
            switch (fakeRankIndex) {
            case 0: {
                fakeRank = 28; // Cao Thủ IV
                break;
            }
            case 1: {
                fakeRank = 29; // Cao Thủ III
                break;
            }
            case 2: {
                fakeRank = 30; // Cao Thủ II
                break;
            }
            case 3: {
                fakeRank = 31; // Cao Thủ I
                break;
            }
            case 4: {
                fakeRank = 27; // Chiến tướng (Thách đấu)
                break;
            }
            case 5: {
                fakeRank = 32; // Chiến thần (Thách đấu)
                break;
            }
            }
        }

        ImGui::SliderInt(ENCRYPT("Số sao"), &fakeStars, 1, 1000);
        ImGui::SliderInt(ENCRYPT("Số ấn"), &fakeMark, 1, 100);
        ImGui::SliderInt(ENCRYPT("Top rank"), &topRank, 1, 100);

        std::string topRankOptionsStr[] = {ENCRYPT("Không hiện"),
                                           ENCRYPT("Cục xám (Sơ cấp)"),
                                           ENCRYPT("Cục xanh lá (Trung cấp)"),
                                           ENCRYPT("Cục xanh dương (Cao cấp)"),
                                           ENCRYPT("Cục tím (Huyền thoại)"),
                                           ENCRYPT("Cục đỏ (Top 1 máy chủ)"),
                                           ENCRYPT("Cục vàng (Số 1 máy chủ)")};
        const char *topRankOptions[] = {
            topRankOptionsStr[0].c_str(), topRankOptionsStr[1].c_str(),
            topRankOptionsStr[2].c_str(), topRankOptionsStr[3].c_str(),
            topRankOptionsStr[4].c_str(), topRankOptionsStr[5].c_str(),
            topRankOptionsStr[6].c_str()};
        ImGui::Combo(ENCRYPT("Cục"), &topHero, topRankOptions,
                     IM_ARRAYSIZE(topRankOptions));
        ImGui::NewLine();
    }

    // Mod skin
    ImGui::Checkbox(ENCRYPT("Mở khoá tất cả skin"), &unlockSkin);
    if (!unlockSkin)
        return;

    if (!isJsonLoaded) {
        ImGui::NewLine();
        ImGui::Text("%s", ENCRYPT("Không thể load dữ liệu nút bấm và thông báo "
                                  "diệt, kiểm tra lại mạng nhé bro!"));
        return;
    }

    ImGui::Checkbox(ENCRYPT("Mod nút bấm"), &modSkinButton);
    if (modSkinButton) {
        ImGui::RadioButton(ENCRYPT("Tuỳ chọn"), &modeSkinButton, 0);
        ImGui::SameLine();
        ImGui::RadioButton(ENCRYPT("Mặc định theo skin"), &modeSkinButton, 1);

        if (modeSkinButton == 0) {
            if (selectedButton < 0 ||
                selectedButton >=
                    static_cast<int>(modSkinButtonOptions.size())) {
                selectedButton = 0;
            }

            std::vector<const char *> options_buttons_skin_cstr;
            options_buttons_skin_cstr.reserve(modSkinButtonOptions.size());
            for (const auto &opt : modSkinButtonOptions) {
                options_buttons_skin_cstr.push_back(opt.c_str());
            }

            ImGui::Combo(ENCRYPT("Chọn skin nút"), &selectedButton,
                         options_buttons_skin_cstr.data(),
                         options_buttons_skin_cstr.size());
        } else if (modeSkinButton == 1) {
            std::ostringstream oss;
            oss << currentHeroId << std::setw(2) << std::setfill('0')
                << currentSkinId;
            selectedButton = std::stoi(oss.str());
        }
    }

    ImGui::Checkbox(ENCRYPT("Mod thông báo diệt"), &modNotify);
    if (modNotify) {
        ImGui::RadioButton(ENCRYPT("Tuỳ chọn##kill_notify"), &modeNotify, 0);
        ImGui::SameLine();
        ImGui::RadioButton(ENCRYPT("Mặc định theo skin##kill_notify"),
                           &modeNotify, 1);

        if (modeNotify == 0) {
            if (selectedKillNotify < 0 ||
                selectedKillNotify >=
                    static_cast<int>(modKillNotifyOptions.size())) {
                selectedKillNotify = 0;
            }

            std::vector<const char *> options_kill_notify_cstr;
            options_kill_notify_cstr.reserve(modKillNotifyOptions.size());
            for (const auto &opt : modKillNotifyOptions) {
                options_kill_notify_cstr.push_back(opt.c_str());
            }

            ImGui::Combo(ENCRYPT("Chọn thông báo diệt"), &selectedKillNotify,
                         options_kill_notify_cstr.data(),
                         options_kill_notify_cstr.size());
        }
    }
}

static void RenderTextEditorPaste(ImGuiDrawView *self, const char *inputId,
                                  const char *pasteId, char *buffer,
                                  size_t bufferSize) {
    ImGui::InputText(inputId, buffer, bufferSize);
    if (ImGui::IsItemActivated()) {
        self.keyboardDismissedByUser = NO;
    }

    ImGui::SameLine();
    if (ImGui::Button(pasteId)) {
        NSString *pasteText = [UIPasteboard generalPasteboard].string ?: @"";
        LoadStringToCharBuffer([pasteText UTF8String], buffer, bufferSize);
        self.keyboardDismissedByUser = NO;
    }
}

- (void)setupTabModTextKillNotify {
    ImGui::Checkbox(ENCRYPT("Chiến công đầu"), &modTextKillNotifyFirstKill);
    if (modTextKillNotifyFirstKill) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##FirstKill"),
                              ENCRYPT("Dán##FirstKill"),
                              modTextKillNotifyFirstKillText,
                              IM_ARRAYSIZE(modTextKillNotifyFirstKillText));
    }

    ImGui::Checkbox(ENCRYPT("Hạ"), &modTextKillNotifyKill);
    if (modTextKillNotifyKill) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##Kill"),
                              ENCRYPT("Dán##Kill"), modTextKillNotifyKillText,
                              IM_ARRAYSIZE(modTextKillNotifyKillText));
    }

    ImGui::Checkbox(ENCRYPT("Double Kill"), &modTextKillNotifyDoubleKill);
    if (modTextKillNotifyDoubleKill) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##DoubleKill"),
                              ENCRYPT("Dán##DoubleKill"),
                              modTextKillNotifyDoubleKillText,
                              IM_ARRAYSIZE(modTextKillNotifyDoubleKillText));
    }

    ImGui::Checkbox(ENCRYPT("Triple Kill"), &modTextKillNotifyTripleKill);
    if (modTextKillNotifyTripleKill) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##TripleKill"),
                              ENCRYPT("Dán##TripleKill"),
                              modTextKillNotifyTripleKillText,
                              IM_ARRAYSIZE(modTextKillNotifyTripleKillText));
    }

    ImGui::Checkbox(ENCRYPT("Quata Kill"), &modTextKillNotifyQuataKill);
    if (modTextKillNotifyQuataKill) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##QuataKill"),
                              ENCRYPT("Dán##QuataKill"),
                              modTextKillNotifyQuataKillText,
                              IM_ARRAYSIZE(modTextKillNotifyQuataKillText));
    }

    ImGui::Checkbox(ENCRYPT("Penta Kill"), &modTextKillNotifyPentaKill);
    if (modTextKillNotifyPentaKill) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##PentaKill"),
                              ENCRYPT("Dán##PentaKill"),
                              modTextKillNotifyPentaKillText,
                              IM_ARRAYSIZE(modTextKillNotifyPentaKillText));
    }

    ImGui::Checkbox(ENCRYPT("Gotcha"), &modTextKillNotifyGotcha);
    if (modTextKillNotifyGotcha) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##Gotcha"),
                              ENCRYPT("Dán##Gotcha"),
                              modTextKillNotifyGotchaText,
                              IM_ARRAYSIZE(modTextKillNotifyGotchaText));
    }

    ImGui::Checkbox(ENCRYPT("Truyền thuyết"), &modTextKillNotifyLegend);
    if (modTextKillNotifyLegend) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##Legend"),
                              ENCRYPT("Dán##Legend"),
                              modTextKillNotifyLegendText,
                              IM_ARRAYSIZE(modTextKillNotifyLegendText));
    }

    ImGui::Checkbox(ENCRYPT("Huyền thoại"), &modTextKillNotifyLegendary);
    if (modTextKillNotifyLegendary) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##Legendary"),
                              ENCRYPT("Dán##Legendary"),
                              modTextKillNotifyLegendaryText,
                              IM_ARRAYSIZE(modTextKillNotifyLegendaryText));
    }

    ImGui::Checkbox(ENCRYPT("Thần thánh"), &modTextKillNotifyHallow);
    if (modTextKillNotifyHallow) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##Hallow"),
                              ENCRYPT("Dán##Hallow"),
                              modTextKillNotifyHallowText,
                              IM_ARRAYSIZE(modTextKillNotifyHallowText));
    }

    ImGui::Checkbox(ENCRYPT("Phá trụ địch"), &modTextKillNotifyDestroyTower);
    if (modTextKillNotifyDestroyTower) {
        RenderTextEditorPaste(
            self, ENCRYPT("Nhập text tuỳ chỉnh##DestroyTower"),
            ENCRYPT("Dán##DestroyTower"), modTextKillNotifyDestroyTowerText,
            IM_ARRAYSIZE(modTextKillNotifyDestroyTowerText));
    }

    ImGui::Checkbox(ENCRYPT("Quét sạch"), &modTextKillNotifyAce);
    if (modTextKillNotifyAce) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##Ace"),
                              ENCRYPT("Dán##Ace"), modTextKillNotifyAceText,
                              IM_ARRAYSIZE(modTextKillNotifyAceText));
    }

    ImGui::Checkbox(ENCRYPT("Chấm dứt"), &modTextKillNotifyShutdown);
    if (modTextKillNotifyShutdown) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##Shutdown"),
                              ENCRYPT("Dán##Shutdown"),
                              modTextKillNotifyShutdownText,
                              IM_ARRAYSIZE(modTextKillNotifyShutdownText));
    }

    ImGui::Checkbox(ENCRYPT("Lính siêu cấp xuất chiến"),
                    &modTextKillNotifyMinionSuperStart);
    if (modTextKillNotifyMinionSuperStart) {
        RenderTextEditorPaste(
            self, ENCRYPT("Nhập text tuỳ chỉnh##MinionSuperStart"),
            ENCRYPT("Dán##MinionSuperStart"),
            modTextKillNotifyMinionSuperStartText,
            IM_ARRAYSIZE(modTextKillNotifyMinionSuperStartText));
    }

    ImGui::Checkbox(ENCRYPT("Ceasar"), &modTextKillNotifyKillCeasar);
    if (modTextKillNotifyKillCeasar) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##KillCeasar"),
                              ENCRYPT("Dán##KillCeasar"),
                              modTextKillNotifyKillCeasarText,
                              IM_ARRAYSIZE(modTextKillNotifyKillCeasarText));
    }

    ImGui::Checkbox(ENCRYPT("Ceasar hắc ám"), &modTextKillNotifyKillDarkCeasar);
    if (modTextKillNotifyKillDarkCeasar) {
        RenderTextEditorPaste(
            self, ENCRYPT("Nhập text tuỳ chỉnh##KillDarkCeasar"),
            ENCRYPT("Dán##KillDarkCeasar"), modTextKillNotifyKillDarkCeasarText,
            IM_ARRAYSIZE(modTextKillNotifyKillDarkCeasarText));
    }

    ImGui::Checkbox(ENCRYPT("Ceasar bạo chúa"),
                    &modTextKillNotifyKillDarkTyrantCeasar);
    if (modTextKillNotifyKillDarkTyrantCeasar) {
        RenderTextEditorPaste(
            self, ENCRYPT("Nhập text tuỳ chỉnh##KillDarkTyrantCeasar"),
            ENCRYPT("Dán##KillDarkTyrantCeasar"),
            modTextKillNotifyKillDarkTyrantCeasarText,
            IM_ARRAYSIZE(modTextKillNotifyKillDarkTyrantCeasarText));
    }

    ImGui::Checkbox(ENCRYPT("Rồng"), &modTextKillNotifyKillDragon);
    if (modTextKillNotifyKillDragon) {
        RenderTextEditorPaste(self, ENCRYPT("Nhập text tuỳ chỉnh##KillDragon"),
                              ENCRYPT("Dán##KillDragon"),
                              modTextKillNotifyKillDragonText,
                              IM_ARRAYSIZE(modTextKillNotifyKillDragonText));
    }

    ImGui::Checkbox(ENCRYPT("Rồng ánh sáng"),
                    &modTextKillNotifyKillLightDragon);
    if (modTextKillNotifyKillLightDragon) {
        RenderTextEditorPaste(
            self, ENCRYPT("Nhập text tuỳ chỉnh##KillLightDragon"),
            ENCRYPT("Dán##KillLightDragon"),
            modTextKillNotifyKillLightDragonText,
            IM_ARRAYSIZE(modTextKillNotifyKillLightDragonText));
    }
}

- (void)setupTabOther {
    ImGui::TextWrapped(
        "%s",
        ENCRYPT("Bấm vào icon nổi trên màn hình để mở hoặc đóng menu.\nHoặc "
                "dùng 3 "
                "ngón chạm 2 lần để mở menu, 2 ngón chạm 2 lần để ẩn menu"));
    ImGui::NewLine();

    ImGui::Checkbox(ENCRYPT("Ẩn UID"), &hideUID);
    if (ImGui::Checkbox(ENCRYPT("Xem lịch sử đấu người khác (Đểu)"),
                        &showHistory)) {
        if (showHistory) {
            patchOffset(showHistoryOffset,
                        ENCRYPTHEX("20 00 80 D2 C0 03 5F D6"));
        } else {
            restorePatchOffset(showHistoryOffset,
                               ENCRYPTHEX("20 00 80 D2 C0 03 5F D6"));
        }
    }
    ImGui::NewLine();

    ImGui::Checkbox(ENCRYPT("Chặn host (Antiban)"), &blockHost);
    if (blockHost) {
        std::string blockHostOptionsStr[] = {
            ENCRYPT("Hết trận tự kill game"),
            ENCRYPT("Hết trận đợi 1 lúc tự văng ra sảnh")};
        const char *blockHostOptions[] = {blockHostOptionsStr[0].c_str(),
                                          blockHostOptionsStr[1].c_str()};
        ImGui::Combo(ENCRYPT("Kiểu chặn host"), &blockHostOption,
                     blockHostOptions, IM_ARRAYSIZE(blockHostOptions));
        if (blockHostOption == 1) {
            ImGui::SliderInt(ENCRYPT("Đợi 1 lúc là bao lâu? (Giây)"),
                             &bypassDelay, 1, 20);
        }
    }
    ImGui::NewLine();

    if (ImGui::Button(ENCRYPT("Lưu setting"))) {
        [self saveSetting];
    }
    ImGui::Spacing();
    if (ImGui::Button(ENCRYPT("Đăng xuất account"))) {
        [self showQuestionLogoutAccount];
    }
    ImGui::Spacing();
}

- (void)showQuestionLogoutAccount {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NSSENCRYPT("Có chắc muốn đăng xuất không hả?")
                         message:NSSENCRYPT(
                                     "Chắc thì bấm đồng ý? Không thì thôi.")
                  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *actionOk =
        [UIAlertAction actionWithTitle:NSSENCRYPT("Đồng ý luôn")
                                 style:UIAlertActionStyleDestructive
                               handler:^(UIAlertAction *_Nonnull action) {
                                 [self logoutAccount];
                               }];
    UIAlertAction *actionCancel =
        [UIAlertAction actionWithTitle:NSSENCRYPT("Thôi")
                                 style:UIAlertActionStyleDefault
                               handler:nil];
    [alert addAction:actionOk];
    [alert addAction:actionCancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)logoutAccount {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *filePath = [documentsDirectory
        stringByAppendingPathComponent:NSSENCRYPT("beetalk_session.db")];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if ([fileManager fileExistsAtPath:filePath]) {
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (success) {
            [self alertWithTitle:NSSENCRYPT("Thành công")
                         message:NSSENCRYPT("Đã đăng xuất account!")
                     actionTitle:NSSENCRYPT("Oke bay khỏi game")
                     actionStyle:UIAlertActionStyleDefault
                         handler:^(UIAlertAction *action) {
                           exit(0);
                         }];
        } else {
            [self alertWithTitle:NSSENCRYPT("Có lỗi rồi bạn ơi")
                         message:[error localizedDescription]
                     actionTitle:NSSENCRYPT("Oke đã hiểu")
                     actionStyle:UIAlertActionStyleDefault
                         handler:nil];
        }
    } else {
        NSString *errMsg = [NSString
            stringWithFormat:@"%@ %@ %@", NSSENCRYPT("Không tìm thấy file "),
                             filePath, NSSENCRYPT(" để xoá.")];
        [self alertWithTitle:NSSENCRYPT("Có lỗi rồi bạn ơi")
                     message:errMsg
                 actionTitle:NSSENCRYPT("Oke đã hiểu")
                 actionStyle:UIAlertActionStyleDefault
                     handler:nil];
    }
}

- (void)saveSetting {
    // ESP
    [common setBool:hackMap forKey:NSSENCRYPT("hackMap")];
    [common setBool:espEnable forKey:NSSENCRYPT("espEnable")];
    [common setBool:showNumberOfEnemies
             forKey:NSSENCRYPT("showNumberOfEnemies")];
    [common setBool:playerLine forKey:NSSENCRYPT("playerLine")];
    [common setBool:playerBox forKey:NSSENCRYPT("playerBox")];
    [common setBool:playerDistance forKey:NSSENCRYPT("playerDistance")];
    [common setBool:playerHealth forKey:NSSENCRYPT("playerHealth")];
    [common setBool:playerName forKey:NSSENCRYPT("playerName")];
    [common setBool:ignoreDrawEnemyVisible
             forKey:NSSENCRYPT("ignoreDrawEnemyVisible")];
    [common setBool:showInfoEnemyInGame
             forKey:NSSENCRYPT("showInfoEnemyInGame")];
    [common setBool:showUltiEnemyInGame
             forKey:NSSENCRYPT("showUltiEnemyInGame")];
    [common setBool:showSummonerSpell forKey:NSSENCRYPT("showSummonerSpell")];
    [common setFloat:cameraHeight forKey:NSSENCRYPT("cameraHeight_")];
    [common setInt:renamePlayerMode forKey:NSSENCRYPT("renamePlayerMode")];
    [common setString:[NSString stringWithUTF8String:customNamePlayer]
               forKey:NSSENCRYPT("customNamePlayer")];

    // Aimbot
    [common setBool:enableAimbot forKey:NSSENCRYPT("enableAimbot")];
    [common setBool:aimSkill1 forKey:NSSENCRYPT("aimSkill1")];
    [common setBool:aimSkill2 forKey:NSSENCRYPT("aimSkill2")];
    [common setBool:aimSkill3 forKey:NSSENCRYPT("aimSkill3")];
    [common setFloat:aimDistance forKey:NSSENCRYPT("aimDistance")];
    [common setFloat:aimSpeed forKey:NSSENCRYPT("aimSpeed")];
    [common setInt:aimType forKey:NSSENCRYPT("aimType")];
    [common setInt:drawType forKey:NSSENCRYPT("drawType")];

    // Auto
    [common setBool:autoBuyFirstRecItem
             forKey:NSSENCRYPT("autoBuyFirstRecItem")];
    [common setBool:autoSwapEquipEnabled
             forKey:NSSENCRYPT("autoSwapEquipEnabled")];
    [self saveSwapItems];
    [common setBool:autoPunish forKey:NSSENCRYPT("autoPunish")];
    [common setBool:onlyPunishDragonOrCaesar
             forKey:NSSENCRYPT("onlyPunishDragonOrCaesar")];
    [common setBool:execute forKey:NSSENCRYPT("execute")];
    [common setFloat:hpExecute forKey:NSSENCRYPT("hpExecute")];
    [common setBool:frozen forKey:NSSENCRYPT("frozen")];
    [common setFloat:hpFrozen forKey:NSSENCRYPT("hpFrozen")];
    [common setBool:heal forKey:NSSENCRYPT("heal")];
    [common setFloat:hpHeal forKey:NSSENCRYPT("hpHeal")];
    [common setBool:healing forKey:NSSENCRYPT("healing")];
    [common setFloat:hpHealing forKey:NSSENCRYPT("hpHealing")];

    // Mod rank
    [common setBool:unlockModRank forKey:NSSENCRYPT("unlockModRank")];
    [common setInt:fakeRank forKey:NSSENCRYPT("fakeRank")];
    [common setInt:fakeRankIndex forKey:NSSENCRYPT("fakeRankIndex")];
    [common setInt:fakeStars forKey:NSSENCRYPT("fakeStars")];
    [common setInt:fakeMark forKey:NSSENCRYPT("fakeMark")];
    [common setInt:topRank forKey:NSSENCRYPT("topRank")];
    [common setInt:topHero forKey:NSSENCRYPT("topHero")];

    // Mod skin
    [common setBool:unlockSkin forKey:NSSENCRYPT("unlockSkin")];
    [common setBool:modSkinButton forKey:NSSENCRYPT("modSkinButton")];
    [common setInt:modeSkinButton forKey:NSSENCRYPT("modeSkinButton")];
    [common setInt:selectedButton forKey:NSSENCRYPT("selectedButton")];
    [common setBool:modNotify forKey:NSSENCRYPT("modNotify")];
    [common setInt:modeNotify forKey:NSSENCRYPT("modeNotify")];
    [common setInt:selectedKillNotify forKey:NSSENCRYPT("selectedKillNotify")];

    // Mod text kill notify
    [common setBool:modTextKillNotifyFirstKill
             forKey:NSSENCRYPT("modTextKillNotifyFirstKill")];
    [common
        setString:[NSString stringWithUTF8String:modTextKillNotifyFirstKillText]
           forKey:NSSENCRYPT("modTextKillNotifyFirstKillText")];

    [common setBool:modTextKillNotifyKill
             forKey:NSSENCRYPT("modTextKillNotifyKill")];
    [common setString:[NSString stringWithUTF8String:modTextKillNotifyKillText]
               forKey:NSSENCRYPT("modTextKillNotifyKillText")];

    [common setBool:modTextKillNotifyDoubleKill
             forKey:NSSENCRYPT("modTextKillNotifyDoubleKill")];
    [common setString:[NSString
                          stringWithUTF8String:modTextKillNotifyDoubleKillText]
               forKey:NSSENCRYPT("modTextKillNotifyDoubleKillText")];

    [common setBool:modTextKillNotifyTripleKill
             forKey:NSSENCRYPT("modTextKillNotifyTripleKill")];
    [common setString:[NSString
                          stringWithUTF8String:modTextKillNotifyTripleKillText]
               forKey:NSSENCRYPT("modTextKillNotifyTripleKillText")];

    [common setBool:modTextKillNotifyQuataKill
             forKey:NSSENCRYPT("modTextKillNotifyQuataKill")];
    [common
        setString:[NSString stringWithUTF8String:modTextKillNotifyQuataKillText]
           forKey:NSSENCRYPT("modTextKillNotifyQuataKillText")];

    [common setBool:modTextKillNotifyPentaKill
             forKey:NSSENCRYPT("modTextKillNotifyPentaKill")];
    [common
        setString:[NSString stringWithUTF8String:modTextKillNotifyPentaKillText]
           forKey:NSSENCRYPT("modTextKillNotifyPentaKillText")];

    [common setBool:modTextKillNotifyGotcha
             forKey:NSSENCRYPT("modTextKillNotifyGotcha")];
    [common
        setString:[NSString stringWithUTF8String:modTextKillNotifyGotchaText]
           forKey:NSSENCRYPT("modTextKillNotifyGotchaText")];

    [common setBool:modTextKillNotifyLegend
             forKey:NSSENCRYPT("modTextKillNotifyLegend")];
    [common
        setString:[NSString stringWithUTF8String:modTextKillNotifyLegendText]
           forKey:NSSENCRYPT("modTextKillNotifyLegendText")];

    [common setBool:modTextKillNotifyLegendary
             forKey:NSSENCRYPT("modTextKillNotifyLegendary")];
    [common
        setString:[NSString stringWithUTF8String:modTextKillNotifyLegendaryText]
           forKey:NSSENCRYPT("modTextKillNotifyLegendaryText")];

    [common setBool:modTextKillNotifyHallow
             forKey:NSSENCRYPT("modTextKillNotifyHallow")];
    [common
        setString:[NSString stringWithUTF8String:modTextKillNotifyHallowText]
           forKey:NSSENCRYPT("modTextKillNotifyHallowText")];

    [common setBool:modTextKillNotifyDestroyTower
             forKey:NSSENCRYPT("modTextKillNotifyDestroyTower")];
    [common
        setString:[NSString
                      stringWithUTF8String:modTextKillNotifyDestroyTowerText]
           forKey:NSSENCRYPT("modTextKillNotifyDestroyTowerText")];

    [common setBool:modTextKillNotifyShutdown
             forKey:NSSENCRYPT("modTextKillNotifyShutdown")];
    [common
        setString:[NSString stringWithUTF8String:modTextKillNotifyShutdownText]
           forKey:NSSENCRYPT("modTextKillNotifyShutdownText")];

    [common setBool:modTextKillNotifyKillCeasar
             forKey:NSSENCRYPT("modTextKillNotifyKillCeasar")];
    [common setString:[NSString
                          stringWithUTF8String:modTextKillNotifyKillCeasarText]
               forKey:NSSENCRYPT("modTextKillNotifyKillCeasarText")];

    [common setBool:modTextKillNotifyKillDarkCeasar
             forKey:NSSENCRYPT("modTextKillNotifyKillDarkCeasar")];
    [common
        setString:[NSString
                      stringWithUTF8String:modTextKillNotifyKillDarkCeasarText]
           forKey:NSSENCRYPT("modTextKillNotifyKillDarkCeasarText")];

    [common setBool:modTextKillNotifyKillDarkTyrantCeasar
             forKey:NSSENCRYPT("modTextKillNotifyKillDarkTyrantCeasar")];
    [common setString:[NSString stringWithUTF8String:
                                    modTextKillNotifyKillDarkTyrantCeasarText]
               forKey:NSSENCRYPT("modTextKillNotifyKillDarkTyrantCeasarText")];

    [common setBool:modTextKillNotifyKillDragon
             forKey:NSSENCRYPT("modTextKillNotifyKillDragon")];
    [common setString:[NSString
                          stringWithUTF8String:modTextKillNotifyKillDragonText]
               forKey:NSSENCRYPT("modTextKillNotifyKillDragonText")];

    [common setBool:modTextKillNotifyKillLightDragon
             forKey:NSSENCRYPT("modTextKillNotifyKillLightDragon")];
    [common
        setString:[NSString
                      stringWithUTF8String:modTextKillNotifyKillLightDragonText]
           forKey:NSSENCRYPT("modTextKillNotifyKillLightDragonText")];

    // Setting
    [common setBool:hideUID forKey:NSSENCRYPT("hideUID")];
    [common setBool:showRank forKey:NSSENCRYPT("showRank")];
    [common setBool:showHistory forKey:NSSENCRYPT("showHistory")];
    [common setBool:blockHost forKey:NSSENCRYPT("blockHost")];
    [common setInt:blockHostOption forKey:NSSENCRYPT("blockHostOption")];
    [common setInt:bypassDelay forKey:NSSENCRYPT("bypassDelay")];

    [self
        alertWithTitle:NSSENCRYPT("Lưu setting thành công!")
               message:NSSENCRYPT(
                           "Lần tới mở game hack sẽ được tải từ setting đã lưu")
           actionTitle:NSSENCRYPT("Oke biết rồi 😈😈")
           actionStyle:UIAlertActionStyleDefault
               handler:nil];
}

- (void)saveSwapItems {
    nlohmann::json j = swapItems;
    std::string jsonStr = j.dump();
    NSString *nsJson = [NSString stringWithUTF8String:jsonStr.c_str()];
    [common setString:nsJson forKey:NSSENCRYPT("swap_items_json")];
}

void drawEnemyCountView(ImDrawList *draw, int numberOfEnemies) {
    std::string enemyCount = ENCRYPT("Số thằng nhóc [") +
                             std::to_string(numberOfEnemies) + ENCRYPT("]");

    ImFont *font = ImGui::GetFont();
    float fontSize = 18.0f;

    ImVec2 textSize =
        font->CalcTextSizeA(fontSize, FLT_MAX, 0.0f, enemyCount.c_str());

    float paddingX = 10.0f;
    float paddingY = 5.0f;

    ImVec2 center = ImVec2(ImGui::GetIO().DisplaySize.x / 2, 38.0f);

    ImVec2 topLeft = ImVec2(center.x - (textSize.x / 2.0f) - paddingX,
                            center.y - (textSize.y / 2.0f) - paddingY);
    ImVec2 bottomRight = ImVec2(center.x + (textSize.x / 2.0f) + paddingX,
                                center.y + (textSize.y / 2.0f) + paddingY);

    draw->AddRectFilled(topLeft, bottomRight, IM_COL32(20, 20, 24, 190), 5.0f);
    draw->AddRect(topLeft, bottomRight, IM_COL32(255, 99, 99, 230), 5.0f, 0,
                  1.0f);

    ImVec2 textPos =
        ImVec2(center.x - (textSize.x / 2.0f), center.y - (textSize.y / 2.0f));
    draw->AddText(font, fontSize, textPos, IM_COL32(255, 235, 235, 255),
                  enemyCount.c_str());
}

void drawESP(ImDrawList *draw) {
    if (!espEnable || !espManager->myPlayer) {
        return;
    }

    int numberOfEnemies = 0;
    size_t enemyCount = std::min(espManager->enemies->size(),
                                 ActorLinker_enemy->enemies->size());

    for (int i = 0; i < enemyCount; i++) {
        void *actorLinker = espManager->myPlayer;
        void *Enemy = (*espManager->enemies)[i]->object;
        void *EnemyLinker = (*ActorLinker_enemy->enemies)[i]->object;
        // Location enemy for World
        Vector3 EnemyPos = Vector3::zero();

        if (actorLinker && Enemy) {
            CActorInfo *CharInfo =
                *(CActorInfo **)((uintptr_t)EnemyLinker +
                                 ENCRYPTOFFSET(
                                     "0x110")); // class ActorLinker | public
                                                // object CharInfo; // 0x110

            if (!CharInfo)
                continue;

            ImGuiIO &io = ImGui::GetIO();

            /* ========== GET LOCATION ENEMY ========== */
            // Get location of enemy (for World)
            Vector3 EnemyPos = ActorLinker_getPosition(EnemyLinker);

            void *LObjWrapper = (void *)LActorRoot_LHeroWrapper(Enemy);
            void *ObjLinkerWrapper = *(
                void **)((uint64_t)EnemyLinker +
                         ENCRYPTOFFSET("0x118")); // class ActorLinker | public
                                                  // object ObjLinker; // 0x118
            void *ValuePropertyComponent =
                *(void **)((uint64_t)Enemy +
                           ENCRYPTOFFSET(
                               "0x308")); // class LActorRoot | public object
                                          // ValueComponent; // 0x308

            if (!LObjWrapper || !ValuePropertyComponent) {
                continue;
            }

            // Convert location enemy to Vector2 (for Screen)
            Vector2 rootPos_Vec2 = convertToVector2(EnemyPos, io);

            // Check enemy have inside screen (if yes + flag
            // ignoreDrawEnemyVisible = true => no draw)
            bool enemyInsideScreen =
                rootPos_Vec2.x >= 0 && rootPos_Vec2.y >= 0 &&
                rootPos_Vec2.x <= kWidth && rootPos_Vec2.y <= kHeight;

            if (ignoreDrawEnemyVisible && enemyInsideScreen)
                continue;

            /* ========== GET LOCATION MY PLAYER ========== */
            // Get location vector3 myPlayer (for World)
            Vector3 myPos = ActorLinker_getPosition(actorLinker);

            // Calculate distance from me to enemy
            float distanceToMe = Vector3::Distance(myPos, EnemyPos);

            bool enemyDeadByLogic = LObjWrapper_get_IsDeadState(
                LObjWrapper); // Check enemy is dead game mode normal
            bool enemyDeadByLinker =
                ObjLinkerWrapper != nullptr &&
                ObjLinkerWrapper_get_IsDeadState(
                    ObjLinkerWrapper); // Check enemy is dead game mode rank
            bool enemyDeadByHp =
                ValuePropertyComponent_get_actorHp(ValuePropertyComponent) <
                1; // Check hp real < 1 => is dead

            // Only draw if the enemy is not dead
            if (!enemyDeadByLogic && !enemyDeadByLinker && !enemyDeadByHp) {
                if (showNumberOfEnemies) {
                    numberOfEnemies++;
                }

                if (playerLine) {
                    draw->AddLine(
                        ImVec2(ImGui::GetIO().DisplaySize.x / 2, 38),
                        ImVec2(rootPos_Vec2.x, rootPos_Vec2.y - 15.0f),
                        IM_COL32(255, 255, 255, 180), 1.2f);

                    draw->AddCircleFilled(
                        ImVec2(rootPos_Vec2.x, rootPos_Vec2.y - 15.0f), 3.0f,
                        IM_COL32(0, 255, 0, 255));
                }

                float actorHeightWorld = 2.1f;
                float footPaddingWorld = 0.08f;

                Vector3 headWorldPos = Vector3(
                    EnemyPos.x, EnemyPos.y + actorHeightWorld, EnemyPos.z);
                Vector3 footWorldPos = Vector3(
                    EnemyPos.x, EnemyPos.y + footPaddingWorld, EnemyPos.z);

                Vector2 headPos_Vec2 = convertToVector2(headWorldPos, io);
                Vector2 bottomPos_Vec2 = convertToVector2(footWorldPos, io);

                if (playerDistance) {
                    std::string strDistance =
                        ENCRYPT("[ ") + std::to_string((int)distanceToMe) +
                        ENCRYPT("m ]");

                    ImFont *font = ImGui::GetFont();
                    float fontSize = 15.0f;
                    ImVec2 textSize = font->CalcTextSizeA(
                        fontSize, FLT_MAX, 0.0f, strDistance.c_str());

                    draw->AddText(
                        font, fontSize,
                        {rootPos_Vec2.x - (textSize.x / 2), rootPos_Vec2.y + 9},
                        IM_COL32(255, 255, 100, 255), strDistance.c_str());
                }

                float boxHeight = fabsf(bottomPos_Vec2.y - headPos_Vec2.y);
                float boxWidth = boxHeight * 0.7f;
                float boxPaddingY =
                    7.0f - (cameraHeight / maxCameraHeight) * 7.0f;

                if (playerBox) {
                    ImVec2 boxTopLeft = ImVec2(rootPos_Vec2.x - (boxWidth / 2),
                                               headPos_Vec2.y - boxPaddingY);
                    ImVec2 boxBottomRight =
                        ImVec2(rootPos_Vec2.x + (boxWidth / 2),
                               bottomPos_Vec2.y + boxPaddingY);

                    draw->AddRect(boxTopLeft, boxBottomRight,
                                  IM_COL32(255, 255, 255, 180), 0, 240, 1.5f);
                }

                if (playerHealth &&
                    isOutsideScreen(ImVec2(rootPos_Vec2.x, rootPos_Vec2.y),
                                    ImVec2(kWidth, kHeight))) {
                    ImVec2 hintDotRenderPos =
                        ImVec2(rootPos_Vec2.x, rootPos_Vec2.y);

                    // Calculate vector posion enemy with center screen
                    float dx = rootPos_Vec2.x - kWidth / 2;
                    float dy = rootPos_Vec2.y - kHeight / 2;
                    float nx = std::abs(dx) / (kWidth / 2.0f);
                    float ny = std::abs(dy) / (kHeight / 2.0f);

                    float radius = 20.0f;

                    if (nx > ny) {
                        float direction = (dx > 0) ? 1.0f : -1.0f;
                        float ratio = std::abs(1 / nx);
                        hintDotRenderPos.x =
                            kWidth / 2 + direction * (kWidth / 2 - radius - 10);
                        hintDotRenderPos.y = kHeight / 2 + dy * ratio;

                        if (hintDotRenderPos.y < radius + 10)
                            hintDotRenderPos.y = radius + 10;
                        else if (hintDotRenderPos.y > kHeight - radius - 10)
                            hintDotRenderPos.y = kHeight - radius - 10;
                    } else {
                        float direction = (dy > 0) ? 1.0f : -1.0f;
                        float ratio = std::abs(1 / ny);
                        hintDotRenderPos.x = kWidth / 2 + dx * ratio;
                        hintDotRenderPos.y =
                            kHeight / 2 +
                            direction * (kHeight / 2 - radius - 10);

                        if (hintDotRenderPos.x < radius + 10)
                            hintDotRenderPos.x = radius + 10;
                        else if (hintDotRenderPos.x > kWidth - radius - 10)
                            hintDotRenderPos.x = kWidth - radius - 10;
                    }

                    int EnemyHp = ValuePropertyComponent_get_actorHp(
                        ValuePropertyComponent);
                    int EnemyHpTotal = ValuePropertyComponent_get_actorHpTotal(
                        ValuePropertyComponent);

                    draw->AddCircleFilled(hintDotRenderPos, radius,
                                          IM_COL32(0, 0, 0, 60));
                    DrawCircleHealth(hintDotRenderPos, EnemyHp, EnemyHpTotal,
                                     radius);

                    std::string heroName;
                    std::string nameReal;

                    int heroID =
                        ((ActorLinker *)EnemyLinker)->ObjLinker()->ConfigID();
                    getNameFromHeroID(heroName, nameReal, heroID);

                    NSString *heroNameKey =
                        [NSString stringWithCString:nameReal.c_str()
                                           encoding:NSUTF8StringEncoding];
                    heroNameKey = [heroNameKey lowercaseString];
                    id<MTLTexture> heroTexture =
                        [heroTextures objectForKey:heroNameKey];

                    if (heroTexture) {
                        ImVec2 iconSize = ImVec2(radius * 1.8f, radius * 1.8f);
                        ImVec2 iconPos =
                            ImVec2(hintDotRenderPos.x - iconSize.x / 2,
                                   hintDotRenderPos.y - iconSize.y / 2);
                        draw->AddImageRounded(
                            (__bridge ImTextureID)heroTexture, iconPos,
                            ImVec2(iconPos.x + iconSize.x,
                                   iconPos.y + iconSize.y),
                            ImVec2(0, 0), ImVec2(1, 1), IM_COL32_WHITE,
                            iconSize.x / 2.0f);
                    }
                }

                if (playerHealth &&
                    !isOutsideScreen(ImVec2(rootPos_Vec2.x, rootPos_Vec2.y),
                                     ImVec2(kWidth, kHeight))) {
                    int EnemyHp = ValuePropertyComponent_get_actorHp(
                        ValuePropertyComponent);
                    int EnemyHpTotal = ValuePropertyComponent_get_actorHpTotal(
                        ValuePropertyComponent);
                    float PercentHP = ((float)EnemyHp / (float)EnemyHpTotal);

                    ImU32 healthColor = IM_COL32(45, 180, 45, 255);
                    if (EnemyHp <= (EnemyHpTotal * 0.6)) {
                        healthColor = IM_COL32(180, 180, 45, 255);
                    }
                    if (EnemyHp < (EnemyHpTotal * 0.3)) {
                        healthColor = IM_COL32(180, 45, 45, 255);
                    }

                    float healthBarHeight = boxHeight + (boxPaddingY * 2);
                    float healthBarWidth = 5.0f;
                    float currentHealthHeight = healthBarHeight * PercentHP;

                    ImVec2 healthBarBottomLeft =
                        ImVec2(rootPos_Vec2.x + boxWidth / 2 + healthBarWidth,
                               rootPos_Vec2.y + boxPaddingY);
                    ImVec2 healthBarTopRight =
                        ImVec2(healthBarBottomLeft.x + healthBarWidth,
                               healthBarBottomLeft.y - currentHealthHeight);

                    draw->AddRectFilled(healthBarTopRight, healthBarBottomLeft,
                                        healthColor);

                    ImVec2 healthBarRectTopLeft =
                        ImVec2(healthBarBottomLeft.x,
                               healthBarBottomLeft.y - healthBarHeight);
                    ImVec2 healthBarRectBottomRight =
                        ImVec2(healthBarRectTopLeft.x + healthBarWidth,
                               healthBarBottomLeft.y);

                    draw->AddRect(healthBarRectTopLeft,
                                  healthBarRectBottomRight,
                                  IM_COL32(0, 0, 0, 255), 0, 240, 0.4f);
                }

                if (playerName) {
                    std::string heroName;
                    std::string nameP;

                    int heroID =
                        ((ActorLinker *)EnemyLinker)->ObjLinker()->ConfigID();
                    getNameFromHeroID(heroName, nameReal, heroID);
                    if (LObjWrapper_IsAutoAI(LObjWrapper)) {
                        heroName = std::string(ENCRYPT("AI | ") + heroName);
                    }

                    ImFont *font = ImGui::GetFont();
                    float fontSize = 20.0f;
                    ImVec2 textSize = font->CalcTextSizeA(
                        fontSize, FLT_MAX, 0.0f, heroName.c_str());

                    draw->AddText(font, fontSize,
                                  ImVec2(rootPos_Vec2.x - (textSize.x * 0.5f),
                                         rootPos_Vec2.y + 25.0f),
                                  IM_COL32(255, 255, 255, 255),
                                  heroName.c_str());
                }
            }
        }
    }

    if (showNumberOfEnemies) {
        drawEnemyCountView(draw, numberOfEnemies);
    }
}

void drawAimbot(ImDrawList *draw) {
    if (!enableAimbot || activeSkills.empty() || !espManager->myPlayer) {
        EnemyCache.enemyPos = Vector3::zero();
        EnemyCache.moveForward = Vector3::zero();
        EnemyCache.isMoving = false;
        return;
    }

    ActorLinker *hostPlayer = (ActorLinker *)espManager->myPlayer;
    ValueLinkerComponent *hostValue = hostPlayer->ValueComponent();
    ActorConfig *hostConfig = hostPlayer->ObjLinker();
    if (!hostValue || !hostConfig) {
        return;
    }

    EnemyCache.myPos = hostPlayer->get_position();
    EnemyCache.ConfigID = hostConfig->ConfigID();
    EnemyCache.actorHp = hostValue->get_actorHp();

    static auto lastAimScanTime = std::chrono::steady_clock::time_point{};
    auto now = std::chrono::steady_clock::now();
    if (now - lastAimScanTime >= std::chrono::milliseconds(50)) {
        lastAimScanTime = now;

        Quaternion rotation = hostPlayer->get_rotation();
        float minDistance = std::numeric_limits<float>::infinity();
        float minDirection = std::numeric_limits<float>::infinity();
        float minHealth = std::numeric_limits<float>::infinity();
        float minHealth2 = std::numeric_limits<float>::infinity();
        float minHealthPercent = std::numeric_limits<float>::infinity();
        ActorLinker *Entity = nullptr;

        ActorManager *get_actorManager = KyriosFramework::get_actorManager();
        if (get_actorManager == nullptr) {
            EnemyCache.enemyPos = Vector3::zero();
            EnemyCache.moveForward = Vector3::zero();
            EnemyCache.isMoving = false;
            return;
        }

        List<ActorEntry> *GetAllHeros = get_actorManager->GetAllHeros();
        if (GetAllHeros == nullptr) {
            return;
        }

        ActorEntry *actorEntries = GetAllHeros->getItems();
        if (GetAllHeros->getSize() > 0 && actorEntries == nullptr) {
            return;
        }

        for (int i = 0; i < GetAllHeros->getSize(); i++) {
            ActorLinker *actorLinker = actorEntries[i].actor;
            if (actorLinker == nullptr || actorLinker->IsHostCamp() ||
                !actorLinker->get_bVisible()) {
                continue;
            }

            ValueLinkerComponent *valueComponent =
                actorLinker->ValueComponent();
            if (valueComponent == nullptr) {
                continue;
            }

            float Health = valueComponent->get_actorHp();
            if (Health < 1) {
                continue;
            }

            Vector3 EnemyPos = actorLinker->get_position();
            float Distance = Vector3::Distance(EnemyCache.myPos, EnemyPos);
            if (Distance >= aimDistance) {
                continue;
            }

            if (aimType == 0) {
                float MaxHealth = valueComponent->get_actorHpTotal();
                if (MaxHealth <= 0) {
                    continue;
                }
                int HealthPercent =
                    (int)std::round((float)Health / MaxHealth * 100);
                if (HealthPercent < minHealthPercent ||
                    (HealthPercent == minHealthPercent &&
                     Health < minHealth2)) {
                    Entity = actorLinker;
                    minHealthPercent = HealthPercent;
                    minHealth2 = Health;
                }
            } else if (aimType == 1 && Health < minHealth) {
                Entity = actorLinker;
                minHealth = Health;
            } else if (aimType == 2 && Distance < minDistance) {
                Entity = actorLinker;
                minDistance = Distance;
            } else if (aimType == 3) {
                VActorMovementComponent *movement =
                    actorLinker->MovementComponent();
                if (movement == nullptr) {
                    continue;
                }

                float Direction = SquaredDistance(
                    RotateVectorByQuaternion(rotation),
                    calculateSkillDirection(EnemyCache.myPos, EnemyPos,
                                            actorLinker->isMoving(),
                                            actorLinker->get_logicMoveForward(),
                                            movement->get_maxSpeed()));
                if (Direction < minDirection) {
                    Entity = actorLinker;
                    minDirection = Direction;
                }
            }
        }

        if (Entity == nullptr) {
            EnemyCache.enemyPos = Vector3::zero();
            EnemyCache.moveForward = Vector3::zero();
            EnemyCache.isMoving = false;
        } else if (aimType == 3 && !isCharging) {
            EnemyCache.enemyPos = Vector3::zero();
            EnemyCache.moveForward = Vector3::zero();
            EnemyCache.isMoving = false;
        } else {
            EnemyCache.enemyPos = Entity->get_position();
            EnemyCache.moveForward = Entity->get_logicMoveForward();
            EnemyCache.isMoving = Entity->isMoving();
            VActorMovementComponent *movement = Entity->MovementComponent();
            EnemyCache.currentSpeed =
                movement != nullptr ? movement->get_maxSpeed() : 0;
        }
    }
    if (EnemyCache.ConfigID != 0 &&
        EnemyCache.ConfigIDLatest != EnemyCache.ConfigID) {
        EnemyCache.ConfigIDLatest = EnemyCache.ConfigID;

        if (EnemyCache.ConfigID == 196) { // Elsu
            activeSkills.clear();
            activeSkills.push_back(2);
            aimDistance = 25.0f;
            aimSpeed = 0.45f;
        }
        if (EnemyCache.ConfigID == 545) { // Yue
            activeSkills.clear();
            activeSkills.push_back(1);
            activeSkills.push_back(2);
            aimDistance = 12.0f;
            aimSpeed = 0.8f;
        }
        if (EnemyCache.ConfigID == 175) { // Grakk
            activeSkills.clear();
            activeSkills.push_back(2);
            aimDistance = 12.0f;
            aimSpeed = 0.8f;
        }
        if (EnemyCache.ConfigID == 157) { // Raz
            activeSkills.clear();
            activeSkills.push_back(2);
            aimDistance = 12.0f;
            aimSpeed = 0.8f;
        }
        if (EnemyCache.ConfigID == 195) { // Enzo
            activeSkills.clear();
            activeSkills.push_back(2);
            aimDistance = 9.5f;
            aimSpeed = 0.4f;
        }
        if (EnemyCache.ConfigID == 142) { // Natalya
            activeSkills.clear();
            activeSkills.push_back(2);
            aimDistance = 10.0f;
            aimSpeed = 1.0f;
        }
        if (EnemyCache.ConfigID == 521) { // Florentino
            activeSkills.clear();
            activeSkills.push_back(1);
            aimDistance = 7.5f;
            aimSpeed = 0.35f;
        }
        if (EnemyCache.ConfigID == 163) { // Ryoma
            activeSkills.clear();
            activeSkills.push_back(2);
            aimDistance = 7.0f;
            aimSpeed = 0.1f;
        }
        if (EnemyCache.ConfigID == 169) { // Slimz
            activeSkills.clear();
            activeSkills.push_back(1);
            aimDistance = 19.5f;
            aimSpeed = 1.7f;
        }
    }

    bool isDie = EnemyCache.actorHp < 1;
    if (!isDie && drawType != 0 && EnemyCache.ConfigID != 0) {
        if (EnemyCache.myPos != Vector3::zero() &&
            EnemyCache.enemyPos != Vector3::zero()) {
            ImGuiIO &io = ImGui::GetIO();
            Vector3 MyPlayerSC = EnemyCache.myPos;
            Vector2 MyPlayerVec2 = convertToVector2(MyPlayerSC, io);
            Vector3 EnemySC = EnemyCache.enemyPos;
            Vector2 RootVec2 = convertToVector2(EnemySC, io);

            ImColor lineColor = ImColor(lineDrawAimColor.x, lineDrawAimColor.y,
                                        lineDrawAimColor.z, lineDrawAimColor.w);

            ImVec2 imRootVec2 = ImVec2(RootVec2.x, RootVec2.y);
            ImVec2 startLine = ImVec2(MyPlayerVec2.x, MyPlayerVec2.y);

            float circleRadius = 5.0f;
            float thickness = 1.5f;
            int segments = 64;

            if (drawType == 1) {
                draw->AddLine(startLine, imRootVec2, lineColor, 1.7f);
                draw->AddCircle(imRootVec2, circleRadius, lineColor, segments,
                                thickness);
            }

            // Draw Line Aim Skill 2 Only Elsu
            if (drawType == 2 && isCharging && skillSlot == 2 &&
                EnemyCache.ConfigID == 196) {
                draw->AddLine(startLine, imRootVec2, lineColor, 1.7f);
                draw->AddCircle(imRootVec2, circleRadius, lineColor, segments,
                                thickness);
            }
        }
    }
}

Vector2 convertToVector2(Vector3 position, ImGuiIO &io) {
    Vector3 position_W2S = Camera::get_main()->WorldToScreen(position);
    Vector2 vec2 = Vector2::Zero();

    if (position_W2S.z > 0.0f) {
        vec2 = Vector2(position_W2S.x * io.DisplaySize.x,
                       (1.0f - position_W2S.y) * io.DisplaySize.y);
    } else {
        vec2 = Vector2((1.0f - position_W2S.x) * io.DisplaySize.x,
                       position_W2S.y * io.DisplaySize.y);
    }

    return vec2;
}

- (void)initImageTexture:(id<MTLDevice>)device {
    heroTextures = [[NSMutableDictionary alloc] init];

    NSUInteger heroTextureCount = 0;
    const HeroTextureData *heroTextureData =
        HeroTextureDataItems(&heroTextureCount);

    for (NSUInteger i = 0; i < heroTextureCount; i++) {
        [self addHeroTexture:device
                    heroName:heroTextureData[i].heroName
                  base64Data:heroTextureData[i].base64Data];
    }
}

- (void)addHeroTexture:(id<MTLDevice>)device
              heroName:(NSString *)heroName
            base64Data:(NSString *)base64Data {
    NSData *data = [[NSData alloc]
        initWithBase64EncodedString:base64Data
                            options:
                                NSDataBase64DecodingIgnoreUnknownCharacters];
    id<MTLTexture> texture = [self loadImageTexture:device data:data];
    if (texture) {
        [heroTextures setObject:texture forKey:heroName];
    }
}

- (id<MTLTexture>)loadImageTexture:(id<MTLDevice>)device
                              data:(NSData *)imageData {
    int width, height;
    unsigned char *pixels = stbi_load_from_memory(
        (stbi_uc const *)[imageData bytes], (int)[imageData length], &width,
        &height, NULL, 4);

    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor
        texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                     width:(NSUInteger)width
                                    height:(NSUInteger)height
                                 mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    textureDescriptor.storageMode = MTLStorageModeShared;
    id<MTLTexture> texture =
        [device newTextureWithDescriptor:textureDescriptor];
    [texture replaceRegion:MTLRegionMake2D(0, 0, (NSUInteger)width,
                                           (NSUInteger)height)
               mipmapLevel:0
                 withBytes:pixels
               bytesPerRow:(NSUInteger)width * 4];

    return texture;
}

// Show notify
- (void)activeHack:(NSString *)title
           message:(NSString *)message
              font:(UIFont *)font
          duration:(NSTimeInterval)duration {
    static BOOL isShowingNotification = NO;

    if (isShowingNotification) {
        [self hideCurrentNotification];
        isShowingNotification = NO;
    }

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat maxWidth = screenWidth * 0.75;

    UILabel *titleLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxWidth, 0)];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = font;
    titleLabel.textColor = [UIColor colorWithRed:0.2
                                           green:0.8
                                            blue:0.2
                                           alpha:1.0];
    titleLabel.numberOfLines = 0;
    [titleLabel sizeToFit];

    UILabel *messageLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxWidth, 0)];
    messageLabel.text = message;
    messageLabel.textAlignment = NSTextAlignmentLeft;
    messageLabel.font = [UIFont fontWithName:NSSENCRYPT("AvenirNext-Bold")
                                        size:10];
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.numberOfLines = 0;
    [messageLabel sizeToFit];

    CGFloat rectWidth =
        MAX(titleLabel.frame.size.width, messageLabel.frame.size.width) + 60;
    CGFloat rectHeight =
        titleLabel.frame.size.height + messageLabel.frame.size.height + 16;
    CGFloat rectX = screenWidth;
    CGFloat rectY = screenHeight * 0.10;

    UIWindow *mainWindow =
        [[[UIApplication sharedApplication] delegate] window];

    UIView *rect2 =
        [[UIView alloc] initWithFrame:CGRectMake(rectX, rectY, 0, rectHeight)];
    rect2.backgroundColor = [UIColor blackColor];
    [mainWindow addSubview:rect2];

    UIView *rect1 =
        [[UIView alloc] initWithFrame:CGRectMake(rectX, rectY, 0, rectHeight)];
    rect1.backgroundColor = [UIColor colorWithRed:0.2
                                            green:0.8
                                             blue:0.2
                                            alpha:1.0];
    [mainWindow addSubview:rect1];

    [UIView animateWithDuration:0.5
        animations:^{
          rect1.frame =
              CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
          rect2.frame =
              CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.15
              delay:0.0
              options:0
              animations:^{
                rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY,
                                         screenWidth * 0.005, rectHeight);
              }
              completion:^(BOOL finished) {
                titleLabel.alpha = 1;
                messageLabel.alpha = 1;
                [mainWindow addSubview:titleLabel];
                [mainWindow addSubview:messageLabel];
                titleLabel.center =
                    CGPointMake(rectX - rectWidth / 2 + 12,
                                rectY + rectHeight / 2 -
                                    messageLabel.frame.size.height / 2 - 2);
                messageLabel.center =
                    CGPointMake(rectX - rectWidth / 2 + 12,
                                rectY + rectHeight / 2 +
                                    titleLabel.frame.size.height / 2 + 2);

                isShowingNotification = YES;

                [UIView animateWithDuration:0.5
                    delay:duration
                    options:0
                    animations:^{
                      rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY,
                                               rectWidth, rectHeight);
                      titleLabel.center = CGPointMake(
                          rectX + rectWidth / 2 + 12,
                          rectY + rectHeight / 2 -
                              messageLabel.frame.size.height / 2 - 2);
                      messageLabel.center =
                          CGPointMake(rectX + rectWidth / 2 + 12,
                                      rectY + rectHeight / 2 +
                                          titleLabel.frame.size.height / 2 + 2);
                    }
                    completion:^(BOOL finished) {
                      [UIView animateWithDuration:0.15
                          delay:0.0
                          options:0
                          animations:^{
                            rect1.frame =
                                CGRectMake(rectX, rectY, 0, rectHeight);
                            rect2.frame =
                                CGRectMake(rectX, rectY, 0, rectHeight);
                            titleLabel.alpha = 0;
                            messageLabel.alpha = 0;
                          }
                          completion:^(BOOL finished) {
                            [rect1 removeFromSuperview];
                            [rect2 removeFromSuperview];
                            [titleLabel removeFromSuperview];
                            [messageLabel removeFromSuperview];
                          }];
                    }];
              }];
        }];
}

- (void)hideCurrentNotification {
    UIWindow *mainWindow = [common getKeyWindow];

    for (UIView *view in mainWindow.subviews) {
        if ([view isKindOfClass:[UIView class]] && view.backgroundColor) {
            [UIView animateWithDuration:0.15
                animations:^{
                  view.frame =
                      CGRectMake(view.frame.origin.x, view.frame.origin.y, 0,
                                 view.frame.size.height);
                }
                completion:^(BOOL finished) {
                  [view removeFromSuperview];
                }];
        }
    }

    for (UIView *view in mainWindow.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            [UIView animateWithDuration:0.15
                animations:^{
                  view.alpha = 0;
                }
                completion:^(BOOL finished) {
                  [view removeFromSuperview];
                }];
        }
    }
}

// Show alert
- (void)alertWithTitle:(NSString *)title
               message:(NSString *)message
           actionTitle:(NSString *)actionTitle
           actionStyle:(UIAlertActionStyle)actionStyle
               handler:(void (^__nullable)(UIAlertAction *action))handler {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle
                                                     style:actionStyle
                                                   handler:handler];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
