ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest:7.0
THEOS_BUILD_DIR = Packages

TWEAK_NAME = AhAhAh
AhAhAh_CFLAGS = -fobjc-arc
AhAhAh_FILES = Tweak.xm
AhAhAh_FRAMEWORKS = Foundation UIKit MediaPlayer LocalAuthentication

SUBPROJECTS += Prefs

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk


after-stage::
	find $(FW_STAGING_DIR) -iname '*.plist' -or -iname '*.strings' -exec plutil -convert binary1 {} \;
	find $(FW_STAGING_DIR) -iname '*.png' -exec pincrush-osx -i {} \;


after-install::
	install.exec "killall -9 SpringBoard"

