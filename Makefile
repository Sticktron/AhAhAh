ARCHS = armv7 arm64
TARGET = iphone:clang:9.2:7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AhAhAh
AhAhAh_CFLAGS = -fobjc-arc
AhAhAh_FILES = Tweak.xm AhAhAhController.m
AhAhAh_FRAMEWORKS = UIKit MediaPlayer LocalAuthentication
AhAhAh_PRIVATE_FRAMEWORKS = Celestial

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_STORE" -delete

after-install::
	install.exec "killall -9 backboardd"
