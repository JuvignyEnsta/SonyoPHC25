# Makefile pour compiler le code pour PHC 25
AS := sjasmplus 

SRC_MAZE3D  := laby3d.asm
MAZE3D_DEPS := constantes.asm graphism.asm donjon.asm stdlib.asm

all:	maze3d.phc

bin_to_phc:
	gcc -Wall -O2 -o bin_to_phc main.c

maze3d.phc: $(SRC_MAZE3D) $(MAZE3D_DEPS) bin_to_phc
	$(AS) --raw=maze3d.rom --sym=maze3d.sym --lst=maze3d.lst $(SRC_MAZE3D) 
	./bin_to_phc DOD maze3d.rom maze3d.phc

clean:
	rm -fr *.rom *.sym *.lst bin_to_phc *.phc

.PHONY: all clean
