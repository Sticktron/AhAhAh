ARCHS = armv7 armv7s arm64

TARGET = iphone:clang:latest:7.0

THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = AhAhAh
AhAhAh_CFLAGS = -fobjc-arc
AhAhAh_FILES = AhAhAh.xm
AhAhAh_FRAMEWORKS = Foundation UIKit MediaPlayer

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
