EXE = SpringJumpsPrefs
VERSION = 1.0

CODESIGN = /opt/iPhone/ldid -S

# These paths must be changed to match the compilation environment
SYS_PATH = /opt/iPhone/sys
PREFSAPP_PATH = ./PrefsApp

CC = arm-apple-darwin9-gcc
CFLAGS = -march=armv6 -mcpu=arm1176jzf-s -Wall -Os -ObjC -std=gnu99 -include common.h
LD = $(CC)
LDFLAGS = -march=armv6 \
		  -mcpu=arm1176jzf-s \
		  -bind_at_load \
		  -multiply_defined suppress \
          -framework CoreFoundation \
		  -framework Foundation \
          -framework CoreGraphics \
          -framework UIKit \
		  -F$(SYS_PATH)/System/Library/PrivateFrameworks \
          -framework SpringBoardServices \
          -lobjc

DIRLIST    = . Classes $(PREFSAPP_PATH)

INCLUDES = -F$(SYS_PATH)/System/Library/PrivateFrameworks
INCLUDES += $(foreach dir,$(DIRLIST),-I$(dir))

SRCS       := $(foreach dir,$(DIRLIST), $(wildcard $(dir)/*.m))
HDRS       := $(foreach dir,$(DIRLIST), $(wildcard $(dir)/*.h))
OBJS       := $(SRCS:.m=.o)

all: $(EXE)

$(EXE): $(OBJS) $(HDRS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@
	$(CODESIGN) $(EXE)

%.o: %.m
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(INCLUDES) $< -o $@
	   
clean:
	rm -f $(OBJS) $(EXE)

.PHONY: all clean
