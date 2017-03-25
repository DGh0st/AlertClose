export ARCHS = armv7 arm64
export TARGET = iphone:clang:8.1:latest

PACKAGE_VERSION = 1.6.8

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AlertClose
AlertClose_FILES = Tweak.xm
AlertClose_FRAMEWORKS = UIKit
AlertClose_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += alertclose
include $(THEOS_MAKE_PATH)/aggregate.mk
