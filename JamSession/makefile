# Makefile pour compiler le code pour PHC 25
AS := sjasmplus 

SRCS := raptalien.asm
DEPS := macros.asm alien.asm dzx0_standard.asm missiles.asm sprite.asm vaisseau.asm font.zx0 mask_sprite.zx0 sprite16x16.zx0

TARGET_NAME := raptalien
TARGET      := $(TARGET_NAME).rom

all: $(TARGET)

$(TARGET): $(SRCS) $(DEPS)
	$(AS) --raw=$(TARGET) --sym=$(TARGET_NAME).sym --lst=$(TARGET_NAME).lst $(SRCS) 

clean:
	rm -fr $(OBJS) $(TARGET) $(TARGET_NAME).sym $(TARGET_NAME).lst rapt.phc

phc: $(TARGET)
	gcc -Wall -O2 -o bin_to_phc main.c
	./bin_to_phc RAPT $(TARGET) rapt.phc 

.PHONY: all clean
