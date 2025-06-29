# Makefile pour compiler le code pour PHC 25
AS := sjasmplus 

SRC_TESTPRINT42  := test_print42.asm
TESTPRINT42_DEPS := constantes.asm graphism.asm print42.asm

SRC_TESTMAP      := test_map.asm
TESTMAP_DEPS     := constantes.asm graphism.asm print42.asm donjon.asm sprites.asm

all:	TESTS

TESTS:	tst_prt42.phc tst_map.phc

bin_to_phc:
	gcc -Wall -O2 -o bin_to_phc main.c

tst_prt42.phc: $(SRC_TESTPRINT42) $(TESTPRINT42_DEPS) bin_to_phc
	$(AS) --raw=test_print42.rom --sym=test_print42.sym --lst=test_print42.lst $(SRC_TESTPRINT42) 
	./bin_to_phc DOD test_print42.rom tst_prt42.phc

tst_map.phc: $(SRC_TESTMAP) $(TESTMAP_DEPS) bin_to_phc
	$(AS) --raw=test_map.rom --sym=test_map.sym --lst=test_map.lst $(SRC_TESTMAP) 
	./bin_to_phc MAP test_map.rom tst_map.phc

clean:
	rm -fr *.rom *.sym *.lst bin_to_phc *.phc

.PHONY: all clean
