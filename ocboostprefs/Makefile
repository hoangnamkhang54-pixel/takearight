TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = OCBoostPrefs
OCBoostPrefs_FILES = OCBRootListController.m
OCBoostPrefs_FRAMEWORKS = UIKit
OCBoostPrefs_INSTALL_PATH = /Library/PreferenceBundles
OCBoostPrefs_CFLAGS = -fobjc-arc
OCBoostPrefs_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
