ARCHS = armv7 arm64
TARGET = iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AhAhAh
AhAhAh_CFLAGS = -fobjc-arc
AhAhAh_FILES = Tweak.xm AhAhAhController.m
AhAhAh_FRAMEWORKS = UIKit MediaPlayer LocalAuthentication
AhAhAh_PRIVATE_FRAMEWORKS = Celestial

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
