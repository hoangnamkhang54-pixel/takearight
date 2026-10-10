TARGET := iphone:clang:latest:15.0
ARCHS = arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = OCBoostPrefs
OCBoostPrefs_FILES = OCBRootListController.m
OCBoostPrefs_FRAMEWORKS = UIKit
OCBoostPrefs_PRIVATE_FRAMEWORKS = Preferences
OCBoostPrefs_INSTALL_PATH = /Library/PreferenceBundles
OCBoostPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
