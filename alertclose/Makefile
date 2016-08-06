include $(THEOS_MAKE_PATH)/common.mk

BUNDLE_NAME = alertclose
alertclose_FILES = alertclose.mm
alertclose_INSTALL_PATH = /Library/PreferenceBundles
alertclose_FRAMEWORKS = UIKit MessageUI
alertclose_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/alertclose.plist$(ECHO_END)
