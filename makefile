# Makefile pour compiler le code pour PHC 25
CC = zcc 
CFLAGS = +z80 -mz80 -O2 -nostdlib --no-crt --code-loc0xe000 --data-loc0xB000 -sub-type=basic -c
all: libsprite.o libsprite.s libsprite.dat
libsprite.o: libsprite.c
	$(CC) $(CFLAGS) -o $@ $<
libsprite.s: libsprite.c
	$(CC) $(CFLAGS) -S -o $@ $<
libsprite.dat: libsprite.o 
	z88dk.z88dk-z80nm -c $< > $@
clean:
	rm -f *.o *.s *.dat
.PHONY: all clean
