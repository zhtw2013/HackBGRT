CC      = $(CC_PREFIX)-gcc
CFLAGS  = -std=c11 -O2 -ffreestanding -mno-red-zone -fno-stack-protector -Wshadow -Wall -Wunused -Werror-implicit-function-declaration -Werror
CFLAGS += -I$(GNUEFI_INC) -I$(GNUEFI_INC)/$(GNUEFI_ARCH) -I$(GNUEFI_INC)/protocol
LDFLAGS = -nostdlib -shared -Wl,-dll -Wl,--subsystem,10 -e _EfiMain
LIBS    = -L$(GNUEFI_LIB) -lefi -lgcc

GNUEFI_INC = /usr/$(CC_PREFIX)/include/efi
GNUEFI_LIB = /usr/$(CC_PREFIX)/lib

FILES_C = src/main.c src/util.c src/types.c src/config.c
FILES_H = $(wildcard src/*.h)
GIT_DESCRIBE = $(shell git describe --tags)
CFLAGS += '-DGIT_DESCRIBE=L"$(GIT_DESCRIBE)"'

.PHONY: all default

default: bootx64.efi
all: bootx64.efi bootia32.efi setup.exe

src/GIT_DESCRIBE.cs: src/Setup.cs $(FILES_C) $(FILES_H)
	echo 'public class GIT_DESCRIBE { public static string data = "$(GIT_DESCRIBE)"; }' > $@

setup.exe: src/Setup.cs src/GIT_DESCRIBE.cs
	mcs -define:GIT_DESCRIBE -out:$@ $^

bootx64.efi: CC_PREFIX = x86_64-w64-mingw32
bootx64.efi: GNUEFI_ARCH = x86_64
bootx64.efi: $(FILES_C)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ $(LIBS) -s

bootia32.efi: CC_PREFIX = i686-w64-mingw32
bootia32.efi: GNUEFI_ARCH = ia32
bootia32.efi: $(FILES_C)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ $(LIBS) -s

HackBGRT.tar.xz: bootx64.efi bootia32.efi config.txt splash.bmp setup.exe README.md README.efilib LICENSE
	tar cJf $@ --transform=s,^,HackBGRT/, $^
