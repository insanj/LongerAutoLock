THEOS_PACKAGE_DIR_NAME = debs
TARGET=:clang
ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = LongerAutoLock
LongerAutoLock_OBJC_FILES = LongerAutoLock.xm
LongerAutoLock_FRAMEWORKS = UIKit
LongerAutoLock_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-after-install::
	install.exec "killall -9 backboardd"