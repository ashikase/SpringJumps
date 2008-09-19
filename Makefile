PKG_ROOT=/opt/iPhone/sys
SUB_PATH=/files/Platforms/iPhone/build/Users/saurik/mobilesubstrate

name = PageCuts
target = arm-apple-darwin9-

all: $(name).dylib $(control)

clean:
	rm -f $(name).dylib

$(name).dylib: PageCuts.mm
	$(target)g++ -dynamiclib -ggdb -O2 -Wall -Werror -o $@ $(filter %.mm,$^) -init _PageCutsInitialize -lobjc -framework CoreFoundation -framework Foundation -framework UIKit -framework CoreGraphics -F${PKG_ROOT}/System/Library/PrivateFrameworks -I$(SUB_PATH) -L$(SUB_PATH) -lsubstrate

%: %.mm
	$(target)g++ -o $@ -Wall -Werror $< -lobjc -framework CoreFoundation -framework Foundation

.PHONY: all clean
