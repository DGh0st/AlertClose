export ARCHS = armv7 arm64
export TARGET = iphone:clang:latest:latest

PACKAGE_VERSION = 1.1

include theos/makefiles/common.mk

TWEAK_NAME = AlertClose
AlertClose_FILES = Tweak.xm
AlertClose_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += alertclose
include $(THEOS_MAKE_PATH)/aggregate.mk
