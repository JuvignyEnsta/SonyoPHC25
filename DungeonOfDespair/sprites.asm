;## ###################################################################################################################
;#  Bibliothèque de gestion des différents sprites (et de leurs tailles)                                             ##
;## ###################################################################################################################
    IFNDEF SPRITES_ASM
    DEFINE SPRITES_ASM true

    include "constantes.asm"

;## ###################################################################################################################
;## Affichage d'un sprite 8x8 à l'écran à une position donnée                                                        ##
;##      En entrée :                                                                                                 ##
;##         HL : addresse du sprite (8 octets)                                                                       ##
;##         DE : décalage par rapport à l'adresse écran pour afficher le sprite                                      ##
;## ###################################################################################################################
draw_sprite_8x8:
    PUSH HL
    PUSH DE
    PUSH BC
    PUSH HL
    LD HL, SCREEN_ADDR
    ADD HL, DE
    EX DE, HL
    POP HL
    EX DE, HL
    LD B, 8
.loop:
    LD A, (DE)
    LD C, A
    LD A, (HL)
    OR C
    LD (HL), A
    LD A, 32
    ADD L
    LD L, A
    JR NC, .endloop
    INC H
.endloop:
    INC DE
    DJNZ .loop
    POP BC
    POP DE
    POP HL
    RET

    ENDIF
    