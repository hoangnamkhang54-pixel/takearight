ARCHS = arm64e
TARGET := iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = roothide
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OCBoost
OCBoost_FILES = Tweak.x
OCBoost_CFLAGS = -fobjc-arc
OCBoost_FRAMEWORKS = UIKit QuartzCore Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += ocboostprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
