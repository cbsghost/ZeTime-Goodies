#
#  Makefile
#  Zetime-Goodies
#
#  Created by cbs_ghost on 2017/10/15.
#  Copyright (c) 2017 CbS Ghost. All rights reserved.
#

include $(THEOS)/makefiles/common.mk

TARGET = iphone:latest:8.0

TWEAK_NAME = ZeTime-Goodies

TWEAK_TARGET_PROCESS = ZeTime

$(TWEAK_NAME)_FRAMEWORKS += WebKit

$(TWEAK_NAME)_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 ZeTime"
