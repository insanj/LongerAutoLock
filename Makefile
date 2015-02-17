THEOS_PACKAGE_DIR_NAME = debs
TARGET = iphone:clang:latest:6.0
ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = LongerAutoLock
LongerAutoLock_OBJC_FILES = LongerAutoLock.xm
LongerAutoLock_FRAMEWORKS = UIKit
LongerAutoLock_PRIVATE_FRAMEWORKS = Preferences
LongerAutoLock_CFLAGS = -fobjc-arc
LongerAutoLock_LIBRARIES = cephei

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-after-install::
	install.exec "killall -9 Preferences"