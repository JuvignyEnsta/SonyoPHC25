# Makefile pour compiler le code pour PHC 25
AS := sjasmplus 

SRCS := raptalien.asm
DEPS := macros.asm fonte.asm sprite8x16.asm sprite16x16.asm

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
