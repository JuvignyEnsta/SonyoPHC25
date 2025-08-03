;# Routines graphiques
    include "constantes.asm"

;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Fonction pour effacer l'écran
cls:
    XOR A
	LD HL, SCREEN_ADDR   ; Adresse mémoire du début de l'écran
	LD DE, SCREEN_ADDR+1 ; Adresse mémoire du début de l'écran + 1
	LD BC, 6143          ; Taille écran graphique - 1 
	LD (HL), A
	LDIR 
	RET     
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une ligne verticale
;### E contient l'abcisse
;### D contient l'ordonnée minimale
;### B contient la hauteur de la ligne
draw_vline:
    LD HL, SCREEN_ADDR
    LD C, 128
    LD A, E
    AND 7
    JR Z, .skip_shift
    LD C, 64
    DEC A
    JR Z, .skip_shift
    LD C, 32
    DEC A
    JR Z, .skip_shift
    LD C, 16
    DEC A
    JR Z, .skip_shift
    LD C, 8
    DEC A
    JR Z, .skip_shift
    LD C, 4
    DEC A
    JR Z, .skip_shift
    LD C, 2
    DEC A
    JR Z, .skip_shift
    LD C, 1
.skip_shift:
    SRL D
    RR  E

    SRL D
    RR  E

    SRL D
    RR  E
    ADD HL, DE
    LD DE, 32
.vloop:
    LD A, (HL)
    OR C
    LD (HL), A
    ADD HL, DE
    DJNZ .vloop
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une ligne horizontale
;### E contient l'abcisse
;### D contient l'ordonnée minimale
;### B contient la longueur de la ligne
draw_hline:
    ; Si B est plus petit que 8, on dessine la droite pixel par pixel :
    LD A, B
    OR A
    RET Z                      ; Si B est nul, on n'affiche rien
    LD HL, SCREEN_ADDR
    LD C, 255
    LD A, E
    AND 7
    JR Z, .skip_shift
    LD C, 127
    DEC A
    JR Z, .skip_shift
    LD C, 63
    DEC A
    JR Z, .skip_shift
    LD C, 31
    DEC A
    JR Z, .skip_shift
    LD C, 15
    DEC A
    JR Z, .skip_shift
    LD C, 7
    DEC A
    JR Z, .skip_shift
    LD C, 3
    DEC A
    JR Z, .skip_shift
    LD C, 1
.skip_shift:
    PUSH DE
    SRL D                      ; Calcul l'adresse de l'octet contenant le premier pixel de la droite
    RR  E

    SRL D
    RR  E

    SRL D
    RR  E
    ADD HL, DE
    LD A, (HL)                ; Affichage des premiers pixels de la droite (dans le premier octet)
    OR C
    LD (HL), A
    INC HL
    POP DE
    PUSH BC
    ; Affiche par paquet d'octets en fonction de la longueur et décalage de la ligne :
    LD A, E
    AND 7
    ADD B                      ; A = longueur + (x mod 8)
    DEC A 
    JR Z, .finish_line
    SRL A
    SRL A
    SRL A                      ; A = (longueur + (x mod 8))//8
    JR Z, .end1
    DEC A                      ; Pour ne garder que les octets dont les huit pixels doivent être allumés
    JR Z, .finish_line
    LD B, A
.big_loop:
    LD A, (HL)
    OR 0xFF 
    LD (HL), A
    INC HL 
    DJNZ .big_loop
.finish_line:
    POP BC
    LD A, E
    ADD B
    ;DEC A
    LD C, 0xFF
    AND 7 
    JR Z, .end_line
    LD C, 0x80
    DEC A 
    JR Z, .end_line
    LD C, 0xC0
    DEC A
    JR Z, .end_line
    LD C, 0xE0
    DEC A
    JR Z, .end_line
    LD C, 0xF0
    DEC A
    JR Z, .end_line
    LD C, 0xF8
    DEC A
    JR Z, .end_line
    LD C, 0xFC
    DEC A
    JR Z, .end_line
    LD C, 0xFE    
.end_line:
    LD A, (HL)
    OR C
    LD (HL), A
.end:
    RET
.end1:
    POP BC
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Fonction pour effacer l'écran
cls_frame:
    XOR A
	LD HL, DoubleBuffering   ; Adresse mémoire du début de l'écran
	LD DE, DoubleBuffering+1 ; Adresse mémoire du début de l'écran + 1
	LD BC, 2760          ; Taille écran graphique - 1 
	LD (HL), A
	LDIR 
	RET     
; =============================================================================
; == Fonction pour attendre la fin du balayage vidéo                         ==
; =============================================================================
wait_vsync:
.wait1:
	IN A, (0x40)
	AND   0x10
;	JR Z, .end
;	IN A, (0x40)
;	AND   0x10
	JR Z, .wait1
;.wait2:
;	IN A, (0x40)
;	AND   0x10
;	JR NZ, .wait2
.end:
	RET 
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Efface la fenêtre affichant le labyrinthe
blit:
    CALL wait_vsync
    LD B, 120
    XOR A
	LD HL, DoubleBuffering     ; Adresse mémoire du début du buffer
	LD DE, SCREEN_ADDR         ; Adresse mémoire du début de l'écran
.loop:
    PUSH BC
	LD BC, 23          ; Largeur fenêtre en caractère
    LDIR
    PUSH HL
    EX HL, DE
    LD DE, 9
    ADD HL, DE
    EX HL, DE
    POP HL
    POP BC
    DJNZ .loop
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine le cadre de la fenêtre affichant le labyrinthe
draw_frame:
    LD D,0
    LD E,0
    LD B,184
    CALL draw_hline
    LD D,0
    LD E,0
    LD B,120
    CALL draw_vline
    LD D,0
    LD E,184
    LD B,120
    CALL draw_vline
    LD D,120
    LD E,0
    LD B,184
    CALL draw_hline
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une image dans le double buffer (sans masquage)
;       DE contient l'adresse du début de l'image à afficher
;       HL contient l'adresse du buffer où on commence à dessiner l'image
;       B  contient la hauteur de l'image (en pixel)
;       C  contient la largeur de l'image (en octet)
put_image:
    PUSH HL
    PUSH BC
    LD B, 0
    EX HL, DE
    LDIR
    EX HL, DE
    POP BC
    POP HL
    LD A, 23
    ADD L
    LD L, A
    JR NC, .no_carry
    INC H
.no_carry:
    DJNZ put_image    
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une image à l'écran (sans masquage devant être fait avant)
;       DE contient l'adresse du début de l'image à afficher
;       HL contient l'adresse du buffer où on commence à dessiner l'image
;       B  contient la hauteur de l'image (en pixel)
;       C  contient la largeur de l'image (en octet)
draw_image:
    PUSH HL
    PUSH BC
    LD B, C
.hloop:
    LD A, (DE)
    OR (HL)
    LD (HL), A
    INC HL
    INC DE
    DJNZ .hloop
    POP BC
    POP HL
    LD A, 23
    ADD L
    LD L, A
    JR NC, .no_carry
    INC H
.no_carry:
    DJNZ draw_image    
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une image à l'écran (sans masquage devant être fait avant) avec flip à l'envers
;       DE contient l'adresse du début de l'image à afficher
;       HL contient l'adresse de l'écran où on commence à dessiner l'image
;       B  contient la hauteur de l'image (en pixel)
;       C  contient la largeur de l'image (en octet)
draw_vflip_image:
    PUSH HL
    PUSH BC
    LD B, C
.hloop:
    LD A, (DE)
    OR (HL)
    LD (HL), A
    INC HL
    INC DE
    DJNZ .hloop
    POP BC
    POP HL
    LD A, L
    SUB 23
    LD L, A
    JR NC, .no_carry
    DEC H
.no_carry:
    DJNZ draw_vflip_image    
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine la symmétrie horizontale d'une image à l'écran (sans masquage devant être fait avant)
;       DE contient l'adresse du début de l'image à afficher
;       HL contient l'adresse de l'écran où on commence à dessiner l'image
;        B contient la hauteur de l'image (en pixel)
;        C contient la largeur de l'image (en octet, soit par paquet de huit pixels)
draw_sym_image:
    LD A, C
    DEC A
    ADD L, A     ; Rajoute le décalage pour arriver au dernier octet horizontal pris par l'image
.vloop:
    PUSH HL
    PUSH BC
    LD B, C
.hloop:
    PUSH HL
    LD A, (DE)
    ; Calcul de l'octet symmétrique (http://www.retroprogramming.com/2014/01/fast-z80-bit-reversal.html)
    LD L, A                    ; A = 76543210
    RLCA
    RLCA                       ; A = 54321076
    XOR L
    AND 0xAA
    XOR L                      ; A =56341270
    LD L, A
    RLCA
    RLCA
    RLCA                       ; A = 40170563
    RRC L                      ; L = 05634127
    XOR L
    AND 0x66
    XOR L                      ; A = 01234567
    POP HL
    OR (HL)
    LD (HL), A
    DEC HL 
    INC DE
    DJNZ .hloop
    POP BC
    POP HL
    LD A, 23
    ADD L
    LD L, A
    JR NC, .no_carry
    INC H
.no_carry:
    DJNZ .vloop
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Applique un masque à l'écran pour préparer le dessin d'une image
;        DE contient l'adresse du masque à appliquer
;        HL contient l'adresse de l'écran où on commange à appliquer le masque
;         B contient la hauteur du masque
;         C contient la largeur du masque (en octet)
apply_mask:
    PUSH HL
    PUSH BC
    LD B, C
.hloop:
    LD A, (DE)
    AND (HL)
    LD (HL), A
    INC HL
    INC DE
    DJNZ .hloop
    POP BC
    POP HL
    LD A, 23
    ADD L
    LD L, A
    JR NC, .no_carry
    INC H
.no_carry:
    DJNZ apply_mask    
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Applique un masque à l'écran pour préparer le dessin d'une image avec symétrie verticale
;        DE contient l'adresse du masque à appliquer
;        HL contient l'adresse de l'écran où on commange à appliquer le masque
;         B contient la hauteur du masque
;         C contient la largeur du masque (en octet)
apply_vflip_mask:
    PUSH HL
    PUSH BC
    LD B, C
.hloop:
    LD A, (DE)
    AND (HL)
    LD (HL), A
    INC HL
    INC DE
    DJNZ .hloop
    POP BC
    POP HL
    LD A, L
    SUB 23
    LD L, A
    JR NC, .no_carry
    DEC H
.no_carry:
    DJNZ apply_vflip_mask    
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Applique le symmétrique d'un masque à l'écran pour préparer le dessin d'une image
;        DE contient l'adresse du masque à appliquer
;        HL contient l'adresse de l'écran où on commange à appliquer le masque
;         B contient la hauteur du masque
;         C contient la largeur du masque (en octet)
apply_sym_mask:
    LD A, C
    DEC A
    ADD L, A     ; Rajoute le décalage pour arriver au dernier octet horizontal pris par l'image
.vloop:
    PUSH HL
    PUSH BC
    LD B, C
.hloop:
    PUSH HL
    LD A, (DE)
    ; Calcul de l'octet symmétrique (http://www.retroprogramming.com/2014/01/fast-z80-bit-reversal.html)
    LD L, A                    ; A = 76543210
    RLCA
    RLCA                       ; A = 54321076
    XOR L
    AND 0xAA
    XOR L                      ; A =56341270
    LD L, A
    RLCA
    RLCA
    RLCA                       ; A = 40170563
    RRC L                      ; L = 05634127
    XOR L
    AND 0x66
    XOR L                      ; A = 01234567
    POP HL
    AND (HL)
    LD (HL), A
    DEC HL 
    INC DE
    DJNZ .hloop
    POP BC
    POP HL
    LD A, 23
    ADD L
    LD L, A
    JR NC, .no_carry
    INC H
.no_carry:
    DJNZ .vloop
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine le plafond comme fond d'image
draw_ceil:
    ; Décompression dans le buffer pour affichage
    LD HL, plafond
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering ;SCREEN_ADDR
    LD BC, 256*27+23
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine un mur juste à gauche du joueur
mur_gauche0:
    LD HL, murs_gauche_mask_0
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering ; SCREEN_ADDR
    LD BC, 120*256+3
    CALL apply_mask
    LD HL, murs_gauche_0
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering; SCREEN_ADDR
    LD BC, 120*256+3
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine un mur juste à droite du joueur
mur_droite0:
    LD HL, murs_gauche_mask_0
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering+22; SCREEN_ADDR+22
    LD BC, 120*256+3
    CALL apply_sym_mask
    LD HL, murs_gauche_0
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering+22; SCREEN_ADDR+22
    LD BC, 120*256+3
    CALL draw_sym_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine un mur un pas en avant, à gauche du joueur
mur_gauche1:
    LD HL, murs_gauche_mask_1
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering+3; SCREEN_ADDR + 3
    LD BC, 103*256+3
    CALL apply_mask
    LD HL, murs_gauche_1
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering+3; SCREEN_ADDR + 3
    LD BC, 103*256+3
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine un mur un pas en avant, à droite du joueur
mur_droite1:
    LD HL, murs_gauche_mask_1
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 19; SCREEN_ADDR + 19
    LD BC, 103*256+3
    CALL apply_sym_mask
    LD HL, murs_gauche_1
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 19 ; SCREEN_ADDR + 19
    LD BC, 103*256+3
    CALL draw_sym_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine un mur à gauche du joueur
mur_gauche2:
    LD HL, murs_gauche_mask_2
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 6 + 19*23
    LD BC, 60*256+2
    CALL apply_mask
    LD HL, murs_gauche_2
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 6 + 19*23
    LD BC, 60*256+2
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine un mur de deux cases devant et à droite du joueur
mur_droite2:
    LD HL, murs_gauche_mask_2
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 16 + 19*23
    LD BC, 60*256+2
    CALL apply_sym_mask
    LD HL, murs_gauche_2
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 16 + 19*23
    LD BC, 60*256+2
    CALL draw_sym_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine un mur trois cases devant et à gauche du joueur
mur_gauche3:
    LD HL, murs_gauche_mask_3
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8 + 27*23
    LD BC, 36*256+1
    CALL apply_mask
    LD DE, murs_gauche_3   ; Non compressé,car compression prend plus de place mémoire !
    LD HL, DoubleBuffering + 8 + 27*23
    LD BC, 36*256+1
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine un mur trois cases devant et à droite du joueur
mur_droite3:
    LD HL, murs_gauche_mask_3
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 14 + 27*23
    LD BC, 36*256+1
    CALL apply_sym_mask
    LD DE, murs_gauche_3   ; Non compressé,car compression prend plus de place mémoire !
    LD HL, DoubleBuffering + 14 + 27*23
    LD BC, 36*256+1
    CALL draw_sym_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine en mur juste devant le joueur
mur_face0:
    LD HL, murs_face_0
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 3 + 7*23
    LD BC, 17 + 96*256
    CALL put_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine en mur juste devant et à gauche du joueur
mur_face0g:
    LD HL, murs_face_0g
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 7*23
    LD BC, 3 + 96*256
    CALL put_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine en mur juste devant et à droite du joueur
mur_face0d:
    LD HL, murs_face_0d
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 20 + 7*23
    LD BC, 3 + 96*256
    CALL put_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine en mur juste à une case du joueur
mur_face1:
    LD HL, murs_face_1
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 6 + 19*23
    LD BC, 11 + 60*256
    CALL put_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine en mur à gauche juste à une case du joueur
mur_face1g:
    LD HL, murs_face_1g
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 0 + 19*23
    LD BC, 6 + 60*256
    CALL put_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine en mur à gauche juste à une case du joueur
mur_face1d:
    LD HL, murs_face_1d
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 17 + 19*23
    LD BC, 6 + 60*256
    CALL put_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine en mur à deux cases du joueur
mur_face2:
    LD HL, murs_face_2
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8 + 23*23
    LD BC, 7 + 38*256
    CALL put_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine en mur à deux cases du joueur
mur_face2g:
    LD HL, murs_face_2
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 1 + 23*23
    LD BC, 7 + 38*256
    CALL put_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine en mur à deux cases du joueur
mur_face2d:
    LD HL, murs_face_2
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 15 + 23*23
    LD BC, 7 + 38*256
    CALL put_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une échelle au niveau du joueur
echelle0:
    LD HL, ladder0_mask
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8
    LD BC, 67*256+7
    CALL apply_mask
    LD HL, ladder0
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8
    LD BC, 7 + 67*256
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une échelle au niveau du joueur
echelle_bas0:
    LD HL, ladder0_mask
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8 + 119*23
    LD BC, 67*256+7
    CALL apply_vflip_mask
    LD HL, ladder0
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8 + 119*23
    LD BC, 7 + 67*256
    CALL draw_vflip_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une échelle à une case du joueur
echelle1:
    LD HL, ladder1_mask
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8 + 10*23
    LD BC, 39*256+7
    CALL apply_mask
    LD HL, ladder1
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8 + 10*23
    LD BC, 7 + 39*256
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une échelle à une case du joueur
echelle_bas1:
    LD HL, ladder1_mask
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8 + 100*23
    LD BC, 39*256+7
    CALL apply_vflip_mask
    LD HL, ladder1
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 8 + 100*23
    LD BC, 7 + 39*256
    CALL draw_vflip_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une échelle à une case du joueur
echelle2:
    LD HL, ladder2_mask
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 9 + 20*23
    LD BC, 17*256+4
    CALL apply_mask
    LD HL, ladder2
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 9 + 20*23
    LD BC, 4 + 17*256
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une échelle à une case du joueur
echelle_bas2:
    LD HL, ladder2_mask
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 9 + 78*23
    LD BC, 17*256+4
    CALL apply_vflip_mask
    LD HL, ladder2
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 9 + 78*23
    LD BC, 4 + 17*256
    CALL draw_vflip_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une échelle à une case du joueur
echelle3:
    LD DE, ladder3_mask
    LD HL, DoubleBuffering + 10 + 26*23
    LD BC, 10*256+3
    CALL apply_mask
    LD DE, ladder3
    LD HL, DoubleBuffering + 10 + 26*23
    LD BC, 3 + 10*256
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine une échelle à une case du joueur
echelle_bas3:
    LD DE, ladder3_mask
    LD HL, DoubleBuffering + 10 + 62*23
    LD BC, 10*256+3
    CALL apply_vflip_mask
    LD DE, ladder3
    LD HL, DoubleBuffering + 10 + 62*23
    LD BC, 3 + 10*256
    CALL draw_vflip_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
;## Dessine un objet sur la case du joueur
; DE contient le décalage
item0:
    LD HL, food0_mask
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 11 + 100*23
    LD BC, 16*256+3
    CALL apply_mask
    LD HL, food0
    LD DE, buffer
    CALL dzx0_standard
    LD DE, buffer
    LD HL, DoubleBuffering + 11 + 100*23
    LD BC, 3 + 16*256
    CALL draw_image
    RET
;/===//////////////////////////////////////////////////////////////////////////////////////////////
plafond:
    incbin "plafond.zxz"
murs_gauche_mask_0:
    incbin "murs_mask_gauche0.zxz"
murs_gauche_0:
    incbin "murs_gauche0.zxz"
murs_gauche_mask_1:
    incbin "murs_mask_gauche1.zxz"
murs_gauche_1:
    incbin "murs_gauche1.zxz"
murs_gauche_mask_2:
    incbin "murs_mask_gauche2.zxz"
murs_gauche_2:
    incbin "murs_gauche2.zxz"
murs_gauche_mask_3:
    incbin "murs_mask_gauche3.zxz"
murs_gauche_3:
    incbin "murs_gauche3.bin"
murs_face_0:
    incbin "wall_face0.zxz"
murs_face_0g:
    incbin "wall_face0g.zxz"
murs_face_0d:
    incbin "wall_face0d.zxz"
murs_face_1:
    incbin "wall_face1.zxz"
murs_face_1g:
    incbin "wall_face1g.zxz"
murs_face_1d:
    incbin "wall_face1d.zxz"
murs_face_2:
    incbin "wall_face2.zxz"
ladder0:
    incbin "ladder0.zxz"
ladder0_mask:
    incbin "ladder0_mask.zxz"
ladder1:
    incbin "ladder1.zxz"
ladder1_mask:
    incbin "ladder1_mask.zxz"
ladder2:
    incbin "ladder2.zxz"
ladder2_mask:
    incbin "ladder2_mask.zxz"
ladder3:
    incbin "ladder3.bin"
ladder3_mask:
    incbin "ladder3_mask.bin"
food0:
    incbin "food1.zxz"
food0_mask:
    incbin "food1_mask.zxz"
buffer:
    BLOCK 2048, 0xAA
