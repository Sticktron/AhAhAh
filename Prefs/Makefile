ARCHS = armv7 arm64
TARGET = iphone:clang:9.2:7.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AhAhAhPrefs
AhAhAhPrefs_CFLAGS = -fobjc-arc
AhAhAhPrefs_FILES = AhAhAhPrefsController.m AhAhAhPrefsThemeController.m AhAhAhPrefsCustomCells.m
AhAhAhPrefs_INSTALL_PATH = /Library/PreferenceBundles
AhAhAhPrefs_FRAMEWORKS = UIKit MobileCoreServices AssetsLibrary CoreGraphics CoreMedia AVFoundation LocalAuthentication Social
AhAhAhPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AhAhAhPrefs.plist$(ECHO_END)
