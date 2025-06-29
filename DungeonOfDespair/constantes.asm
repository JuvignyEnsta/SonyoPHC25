    IFNDEF CONSTANTES_ASM
    DEFINE CONSTANTES_ASM true
;/=/ Constantes utiles pour la gestion du graphisme
SCREEN_ADDR:      EQU 0x6000
HIGH_SCREEN_ADDR: EQU 0x60

PORT_40_CACHE:    EQU 0xF91F

SCREEN_1_MASK:    EQU 0b01001111
SCREEN_1_SET:     EQU 0b00000000
; SCREEN 2 is the same as SCREEN 1

SCREEN_3_MASK:    EQU 0b01001111
SCREEN_3_SET:     EQU 0b10010000

SCREEN_3L_MASK:   EQU 0b01001111
SCREEN_3L_SET:    EQU 0b10000000

SCREEN_4_MASK:    EQU 0b01001111
SCREEN_4_SET:     EQU 0b10110000
;/=/ Constantes propre au jeu lui-même
;/==/ Dimension du donjon (largeur x longueur x hauteur)
DONJON_WIDTH      EQU 8
DONJON_LENGTH     EQU 8
DONJON_HEIGHT     EQU 8
DONJON_SIZE       EQU DONJON_WIDTH * DONJON_LENGTH *  DONJON_HEIGHT
BAS               EQU 0x0
BAS_VALUE         EQU 0x01
SUD               EQU 0x1
SUD_VALUE         EQU 0x02
OUEST             EQU 0x2
OUEST_VALUE       EQU 0x04
EST               EQU 0x3
EST_VALUE         EQU 0x08
NORD              EQU 0x4
NORD_VALUE        EQU 0x10
HAUT              EQU 0x5
HAUT_VALUE        EQU 0x20
;/==/ Constantes pour le contrôle d'affichage du texte :
AT                EQU 22
ENDL              EQU 13
ENDSTR            EQU 0
    ENDIF
