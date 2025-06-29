	IFNDEF GRAPHISM_ASM
	DEFINE GRAPHISM_ASM true
    include "constantes.asm"

;## =============================================================================
;## == Fonction pour effacer l'écran                                           ==
;## =============================================================================
cls:
    XOR A
	LD HL, SCREEN_ADDR   ; Adresse mémoire du début de l'écran
	LD DE, SCREEN_ADDR+1 ; Adresse mémoire du début de l'écran + 1
	LD BC, 6143          ; Taille écran graphique - 1 
	LD (HL), A
	LDIR 
	RET 

	ENDIF