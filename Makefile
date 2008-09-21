PKG_ROOT=/opt/iPhone/sys
SUB_PATH=/files/Platforms/iPhone/build/Users/saurik/mobilesubstrate

name = SpringJumps
target = arm-apple-darwin9-

all: $(name).dylib $(control)

clean:
	rm -f $(name).dylib

strip:
	$(target)strip $(name).dylib

$(name).dylib: SpringJumps.mm
	$(target)g++ -dynamiclib -ggdb -O2 -Wall -Werror -o $@ $(filter %.mm,$^) -init _SpringJumpsInitialize -lobjc -framework CoreFoundation -framework Foundation -framework UIKit -framework CoreGraphics -F${PKG_ROOT}/System/Library/PrivateFrameworks -I$(SUB_PATH) -L$(SUB_PATH) -lsubstrate

.PHONY: all clean strip
