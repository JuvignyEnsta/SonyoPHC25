;# ##############################################################################
;#                Fonctions générales utiles pour divers projets                #
;# ##############################################################################
    IFNDEF STDLIB_ASM
    DEFINE STDLIB_ASM true
;## =============================================================================
;## == Sous programme de  multiplication  entière  d'un  nombre  16 bits par un =
;## == nombre 8 bits.                                                           =
;## == En entrée : DE contient le multiplicande  (16 bits)                      =
;## ==              A contient le multiplicateur (8 bits )                      =
;## == En sortie : HL contient le résultat de la multiplication (16 bits)       =
;## =============================================================================
mult_16x8:
	LD HL, 0
	LD  B, 8
H0: ADD HL,HL
	SLA A
	JR NC, H1 
	ADD HL,DE
H1: DJNZ H0
	RET
;## =============================================================================
;## == Sous-programme qui rajoute la valeur signée de A à HL                   ==
;## ==     En entrée :                                                         ==
;## ==        HL : la valeur 16 bits auquel on veut additionner                ==
;## ==         A : la valeur à rajouter                                        ==
;## =============================================================================
add_16_8:
	PUSH DE
	LD E, A      ; On stocke A dans E
	ADD A, A     ; Permet de mettre le signe de A dans le flag de retenu
	SBC A, A     ; A = 0 si flag de retenu, 0xFF sinon
	LD D,  A     ; Maintenant DE est la valeur signée de A en 16 bits
	ADD HL, DE
	POP DE
	RET
;## =============================================================================
;## == Sous-programme qui retranche la valeur signée de A à HL                 ==
;## ==     En entrée :                                                         ==
;## ==        HL : la valeur 16 bits auquel on veut soustraire                 ==
;## ==         A : la valeur à soustraire                                      ==
;## =============================================================================
sub_16_8:
	PUSH DE
	LD E, A
	XOR A
	SUB E       ; A <- -A
	LD E, A
	ADD A, A
	SBC A, A
	LD  D, A
	ADD HL, DE
	POP DE
	RET
;## =============================================================================
;# == Sous programmes de génération de nombres pseudo-aléatoires                =
;## =============================================================================
;## == Initialisation du générateur aléatoire                                   =
;## =============================================================================
init_rand:
	LD A, R
	LD (SEED), A
    INC A            ; Pour être sûr de ne pas avoir une graîne nulle ^^
    LD (SEED+1), A
	RET
;## =============================================================================
;## == Définition de la graîne aléatoire                                       ==
;## ==     En entrée : HL contient la valeur de la graîne                      ==
;## =============================================================================
set_seed:
    ; On vérifie que la graîne n'est pas nulle :
    LD A, H
    OR L
    JP Z, init_rand ; Si HL est nul, on initialise une graîne aléatoire    
    LD (SEED), HL
    RET
;## =============================================================================
;## == Génération d'un nombre pseudo-aléatoire à l'aide d'un xorshift          ==
;## == Pour le détail de la théorie, voir le papier de 2003 de George Marsaglia==
;## ==                  Xorshift RNGs                                          ==
;## ==  16-bit xorshift pseudorandom number generator by John Metcalf          ==
;## ==  20 bytes, 86 cycles (excluding ret)                                    ==
;## ==-------------------------------------------------------------------------==
;## == RETOUR   HL = pseudorandom number                                       ==
;## == Modifie   A et DE                                                            ==
;## == Génère des nombres pseudo-éléatoires avec une période de 65535          ==
;## == en utilisant la méthode xorshift :                                      ==
;## ==               hl ^= hl << 7                                             ==
;## ==               hl ^= hl >> 9                                             ==
;## ==               hl ^= hl << 8                                             ==
;## ==                                                                         ==
;## == Plusieurs alternatives pour le triplet de nombre de décalage sont       ==
;## == possibles :                                                             ==
;## ==            6, 7, 13                                                     ==
;## ==            7, 9, 13                                                     ==
;## ==            9, 7, 13                                                     ==
;## ==                                                                         ==
;## =============================================================================
rand:
SEED: EQU rand+1
	ld  hl,0xA280   ; yw -> zt
    ld  de,0xC0DE   ; xz -> yw
    ld  (rand+4),hl  ; x = y, z = w
    ld  a,l         ; w = w ^ ( w << 3 )
    add a,a
    add a,a
    add a,a
    xor l
    ld  l,a
    ld  a,d         ; t = x ^ (x << 1)
    add a,a
    xor d
    ld  h,a
    rra             ; t = t ^ (t >> 1) ^ w
    xor h
    xor l
    ld  h,e         ; y = z
    ld  l,a         ; w = t
    ld  (rand+1),hl
    ret 
;## =============================================================================
;## == Transformation d'un entier non signé codé sur  16  bits en une suite de ==
;## == chiffres allant représentant le nombre correspondant.                   ==
;## ==                                                                         ==
;## == En entrée : HL contient le nombre à convertir                           ==
;## == En sortie : HL contient l'adresse du tableau contenant les chiffres.    ==
;## == Il est alors possible d'utiliser affiche_nombre pour afficher le nombre ==
;## == passé dans HL.                                                          ==
; =============================================================================
convert_to_digits:
	LD IX, BUF   ; IX sert à remplir le buffer qui contiendra les chiffres
trd:
	LD DE, 10000   ; Garder les dizaines de milliers
	CALL car
	LD DE, 1000    ; Garder les milliers
	CALL car
	LD DE, 100     ; Garder les centaines	set_position_screen_3 25, 1
	CALL car 
	LD DE, 10      ; Garder les dizaines
	CALL car
	LD A,L         ; L contient le nombre des unités
	ADD 0x30
	LD (IX), A 
	LD (IX+1),0    ; Pour la fin du buffer
	LD HL, BUF
	LD B, 4
.loop:
	LD A, (HL)
	CP '0'
	JR NZ, .fin
	INC HL
	DJNZ .loop
.fin:
	RET 
car:
	OR A           ; Mise à zéro du flag C (carry)
	LD B, 255      ; B = -1
g9:
	SBC HL, DE     ; HL -= DE jusqu'à débordement
	INC B          ; Incrément de B pour calculer le chiffre
	JR NC, g9      ; On boucle jusqu'à débordement
	ADD HL, DE     ; Pour compenser le débordement et conserver le reste
	LD A, B        ; A contient le chiffre 
	ADD 0x30    ; Conversion en caractère ASCII
	LD (IX), A   ; Qu'on stocke dans le buffer 
	INC IX         ; Pour stocker le prochain chiffre
	RET 
BUF: byte 0x30,0x30,0x30,0x30,0x30,0

    ENDIF