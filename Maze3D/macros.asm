;#                   Diverses macros
    IFNDEF MACROS_ASM
    DEFINE MACROS_ASM true

    ; Sets the screen mode. Uses the original ROM variable to keep compatibililty
    MACRO set_screen set_screen_mask, set_screen_set
        ld  a,(PORT_40_CACHE)
        and set_screen_mask
        or  set_screen_set
        ld  (PORT_40_CACHE), a
        out (0x40), a
    ENDM
;## ####################################################################################################################
;##                 Définition d'une macro permettant de spécifier où on affichera le prochain message                ##
;## ####################################################################################################################
    MACRO PrintAt42 y, x
        LD HL, printAt42Coords.x
        LD (HL), x
        INC HL
        LD (HL), y
    ENDM
;## ####################################################################################################################
;##                                     Memset pour remplir une zone mémoire                                          ##
;## ####################################################################################################################
    MACRO memset memset_dest, memset_size, memset_byte
        LD  HL, memset_dest
        LD  BC, memset_size
        LD   A, memset_byte

        LD (HL),  A
        LD DE  , HL
        INC DE
        DEC BC
        LDIR
    ENDM
;## ####################################################################################################################
;##                                Macros aidant à définir les variables non initialisées                             ##
;## ####################################################################################################################
    MACRO define_uninit_begin address
uninit_pointer = address
    ENDM

    MACRO define_uninit name, size
name    equ uninit_pointer
uninit_pointer = uninit_pointer + size
    ENDM

    ENDIF