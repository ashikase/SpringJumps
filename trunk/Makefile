NAME = SpringJumps

# These paths must be changed to match the compilation environment
SYS_PATH = /opt/iPhone/sys
SUB_PATH=/files/Platforms/iPhone/Projects/Others/saurik/mobilesubstrate
LDID = /opt/iPhone/ldid

CXX = arm-apple-darwin9-g++
CXXFLAGS = -g0 -O1 -Wall -Werror -I$(SUB_PATH) -IPrefsApp
LDFLAGS = -lobjc \
		  -multiply_defined suppress \
		  -framework CoreFoundation \
		  -framework Foundation \
		  -framework UIKit \
		  -F$(SYS_PATH)/System/Library/PrivateFrameworks \
		  -framework GraphicsServices \
		  -L$(SUB_PATH) -lsubstrate

SRCS  = SpringJumps.mm Dock.mm

all: $(NAME).dylib $(control)

clean:
	rm -f $(NAME).dylib

# Replace 'iphone' with the IP or hostname of your device
install:
	$(LDID) -S $(NAME).dylib
	ssh root@iphone rm -f /Library/MobileSubstrate/DynamicLibraries/$(NAME).dylib
	scp $(NAME).dylib root@iphone:/Library/MobileSubstrate/DynamicLibraries/
	ssh root@iphone restart

$(NAME).dylib: $(SRCS)
	$(CXX) -dynamiclib $(CXXFLAGS) -o $@ $(filter %.mm,$^) $(filter %.m,$^) -init _SpringJumpsInitialize $(LDFLAGS)

.PHONY: all clean
