# Garena Liên Quân Mobile | com.garena.game.kgvn | 1.62.1.6 | 1.62.11638984

TARGET := iphone:clang:latest:10.0
INSTALL_TARGET_PROCESSES = kgvn
FINALPACKAGE = 1
ARCHS = arm64
_IGNORE_WARNINGS = 1

THEOS_PACKAGE_SCHEME = rootless

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
THEOS_PACKAGE_DIR = rootless
else ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
THEOS_PACKAGE_DIR = roothide
else
THEOS_PACKAGE_DIR = rootful
endif

KITTYMEMORY_SRC = $(wildcard KittyMemory/*.cpp)
IMGUI_SRC = $(wildcard IMGUI/*.cpp) $(wildcard IMGUI/*.mm)
ESP_SRC = $(wildcard Esp/*.m)
COMMON_SRC = Common.mm
LIB_SRC = $(wildcard lib/*.c) $(wildcard lib/*.cpp)
DOBBY_SRC = lib/libdobby_v2.a
OXORANY_SRC = $(wildcard Security/oxorany/*.cpp)
GIOVOTINH_SRC = $(wildcard GioVoTinh/*.cpp) $(wildcard GioVoTinh/*.mm)
UTILS_SRC = $(wildcard Utils/*.mm)
RESOURCES_SRC = Resources/HeroTextureData.mm
ANTIHOOK_SRC = $(wildcard AntiHook/*.m)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LienQuanVNMod

$(TWEAK_NAME)_FRAMEWORKS = Security QuartzCore CoreGraphics CoreText  AVFoundation Accelerate GLKit SystemConfiguration GameController UIKit SafariServices Accelerate Foundation QuartzCore CoreGraphics AudioToolbox CoreText Metal MobileCoreServices Security SystemConfiguration IOKit CoreTelephony CoreImage CFNetwork AdSupport AVFoundation
$(TWEAK_NAME)_FILES = ImGuiDrawView.mm $(KITTYMEMORY_SRC) $(COMMON_SRC) $(IMGUI_SRC) $(ESP_SRC) $(LIB_SRC) $(OXORANY_SRC) $(GIOVOTINH_SRC) $(UTILS_SRC) $(RESOURCES_SRC) $(ANTIHOOK_SRC)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_CCFLAGS = -std=c++17 -DkITTYMEMORY_DEBUG
$(TWEAK_NAME)_LDFLAGS = $(DOBBY_SRC)

ifeq ($(strip $(_IGNORE_WARNINGS)),1)
$(TWEAK_NAME)_CFLAGS += -w
$(TWEAK_NAME)_CCFLAGS += -w
endif

include $(THEOS_MAKE_PATH)/tweak.mk
