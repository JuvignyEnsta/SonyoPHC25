;/=/                                     BIBLIOTHEQUE DE GESTION DES ALIENS                                             
; >====================================================================================================================<
; >==                                 Applique le masque pour affichage d'un alien                                   ==<
; >== Entrée : BC  = décalage à partir adresse base du sprite de l'alien                                             ==<
; >==          HL  = adresse de début d'affichage à l'écran                                                          ==<
; >====================================================================================================================<
put_mask:
	LD IX, mask
	ADD IX, BC 
	LD B, 16 
	LD DE, 29
.loop:
	LD A, (HL)
	LD C, (IX)
	AND C
	LD (HL), A 
	INC HL 
	INC IX 
	LD A, (HL)
	LD C, (IX)
	AND C
	LD (HL), A 
	INC HL 
	INC IX 
	LD A, (HL)
	LD C, (IX)
	AND C
	LD (HL), A 
	INC HL 
	INC IX 
	LD A, (HL)
	LD C, (IX)
	AND C
	LD (HL), A 
	ADD HL, DE
	INC IX 
	DJNZ .loop 
	RET
; >====================================================================================================================<
; >==                                     Dessine le sprite par dessus le masque                                     ==<
; >== Entrée : BC  = décalage à partir de l'adresse base des sprites aliens                                          ==<
; >==          HL = adresse début affichage à l'écran                                                                ==<
; >====================================================================================================================<
put_sprite:
	LD IX, sprites16x16+256
	ADD IX, BC 
	LD B, 16 
	LD DE, 29
.loop:
	LD A, (HL)
	LD C, (IX)
	OR C
	LD (HL), A
	INC HL 
	INC IX 
	LD A, (HL)
	LD C, (IX)
	OR C
	LD (HL), A 
	INC HL 
	INC IX 
	LD A, (HL)
	LD C, (IX)
	OR C
	LD (HL), A 
	INC HL 
	INC IX 
	LD A, (HL)
	LD C, (IX)
	OR C
	LD (HL), A 
	ADD HL, DE
	INC IX 
	DJNZ .loop 
	RET
; >====================================================================================================================<
; >==                    Dessine un alien à l'écran avec gestion masquage pour superposition                         ==<
; >== Entrée : A : numéro du sprite de l'alien                                                                       ==<
; >==          HL : adresse au pixel près de l'écran où dessiner le sprite                                           ==<
; >====================================================================================================================<
draw_alien:
	LD D, A ; DE = numéro du sprite de l'alien * 256
	; Calcul du masque pour le sprite de base :
	LD A, L 
	AND 0X03 ; On récupère le n° d'animation du vaisseau (décalage précalculé)
	RLA      ; 2A
	RLA      ; 4A
	RLA      ; 8A
	RLA      ; 16A 
	RLA      ; 32A 
	RLA      ; 64A
	SRL H    ; On divise HL par 4 pour avoir l'adresse mémoire écran : 
	RR  L
	SRL H 
	RR  L
	LD BC, 0x6000
	ADD HL, BC
	LD B, D    ; BC = numéro du sprite de l'alien * 256 
	LD C, A    ;    + n°animation * 64
	PUSH BC
	PUSH HL 
	CALL put_mask
	POP HL 
	POP BC 
	CALL put_sprite
	RET
; >====================================================================================================================<
; >==                   Efface tous les ennemis actifs de leur position actuelle sur l'écran                         ==<
; >====================================================================================================================<
clear_aliens:
	LD B, 8 ; Nombre max d'aliens gérés 
	LD IX, ennemis
	LD DE, 4 
.loop:
	LD A, (IX)
	AND 192
	OR A 
	JR NZ, .clear
	ADD IX, DE    ; Prochain alien
	DJNZ .loop
	RET
	PUSH BC
.clear:
	LD H, (IX+1) ; Position y de l'alien
	LD L, (IX+2) ; Position x de l'alien (en pixel)
	SRL H 
	RR  L 
	SRL H 
	RR  L   ; HL = HL / 4
	LD BC, 0x6000
	ADD HL, BC
	LD DE, 29
	LD  B, 16
	LD  A, 170
.loop_clear:
	LD (HL), A
	inc HL
	LD (HL), A
	inc HL 
	LD (HL), A
	inc HL
	LD (HL), A
	ADD HL, DE
	DJNZ .loop_clear
	LD DE, 4
	POP BC 
	DJNZ .loop
	RET
; >====================================================================================================================<
; >== Premier type de déplacement :                                                                                  ==<
; >==     Se déplace vers le bas/haut et tous les 10 cycles un coup à droite ou à gauche (63/255 chance, bit 5 = 0   ==<
; >==     à gauche, bit  5 = 1 à droite )                                                                            ==<
; >== En entrée :                                                                                                    ==<
; >==     HL = pointeur sur l'alien dont on s'occupe                                                                 ==<
; >====================================================================================================================<
alien_depl1:
    LD A, (HL)
    CP  0x80              ; Test si l'alien a déjà enlevé un colon
    JR NC, .a_colon
.no_colon:
    ; L'alien n'a pas enlevé de colon
    AND 0x3C              ; On teste si le compteur de cycle est à zéro ou non
    JR Z, .test_devie1
    ; Là, on va tout droit :-)
    LD A, (HL)
    LD B, -4
    ADD A, B       ; On décrémente le compteur
    INC HL
    LD DE, (HL)
    EX DE, HL
    LD BC, +128
    JR .descend
.test_devie1:
    ; Test si l'alien va dévier (compteur ) zéro
    LD A, (HL)
    AND 0xC3
    OR 40
    LD (HL), A ; On remet le compteur à 10 (x4 car décalé de 2 bits)
    INC HL 
    LD DE, (HL)
    EX DE, HL
    LD BC, +128
    LD A, 255
    CALL rand
    AND 0xC0            ; Test si le bit 6 ou 7 est non nul
    JR NZ, .descend     ; Si l'un des deux est non nul, l'alien descent tout droit
    AND 0x20            ; Test si l'alien dévie sur la gauche ou la droite
    JR Z, .gauche1       ; Si le bit 5 est  nul, dévie vers la gauche
    ; On dévie à droite : on teste si l'alien est sur le bord droit :
.droite1:
    LD A, L             ; On récupère x
    AND 0x7F            ; en prenant soin de virer le bit 7 qui correspond à y0
    CP 72               ; Compare avec le bord
    JR NC, .descend     ; Pas de dérive vers  la droite puisqu'on est déjà au bord
    INC BC
    JR .descend
.gauche1:
    LD A, L             ; On récupère x
    AND 0x7F            ; En supprimant le bit 7 (y0)
    OR A                ; Pour tester si A est nul
    JR Z, .descend      ; Si x = 0, on ne dévie pas vers la gauche
    DEC BC
.descend:
    ADD HL, BC 
    EX HL, DE
    LD (HL), DE
    ;! Changer l'état de l'alien si l'alien est arrivé en bas de l'écran !!!!!! A faire en dehors de cette routine plutôt
    RET
.a_colon:
    ; L'alien a enlevé un colon
    AND 0x3C              ; On teste si le compteur de cycle est à zéro ou non
    JR Z, .test_devie2
    ; Là, on va tout droit :-)
    LD A, (HL)
    LD B, -4
    ADD A, B       ; On décrémente le compteur
    INC HL
    LD DE, (HL)
    EX DE, HL
    LD BC, -128
    JR .remonte
.test_devie2:
    ; Test si l'alien va dévier (compteur ) zéro
    LD A, (HL)
    AND 0xC3
    OR 40
    LD (HL), A ; On remet le compteur à 10 (x4 car décalé de 2 bits)
    INC HL 
    LD DE, (HL)
    EX DE, HL
    LD BC, +128
    LD A, 255
    CALL rand
    AND 0xC0            ; Test si le bit 6 ou 7 est non nul
    JR NZ, .remonte     ; Si l'un des deux est non nul, l'alien descent tout droit
    AND 0x20            ; Test si l'alien dévie sur la gauche ou la droite
    JR Z, .gauche2       ; Si le bit 5 est  nul, dévie vers la gauche
    ; On dévie à droite : on teste si l'alien est sur le bord droit :
.droite2:
    LD A, L             ; On récupère x
    AND 0x7F            ; en prenant soin de virer le bit 7 qui correspond à y0
    CP 72               ; Compare avec le bord
    JR NC, .remonte     ; Pas de dérive vers  la droite puisqu'on est déjà au bord
    INC BC
    JR .remonte
.gauche2:
    LD A, L             ; On récupère x
    AND 0x7F            ; En supprimant le bit 7 (y0)
    OR A                ; Pour tester si A est nul
    JR Z, .remonte      ; Si x = 0, on ne dévie pas vers la gauche
    DEC BC
.remonte:
    ADD HL, BC 
    EX HL, DE
    LD (HL), DE
    ;! Idem, gérer la désactivation de l'alien dès qu'il remonte en y = 0
    RET

; -------------------------- Tableau des ennemis ------------------------------
; Huits ennemis simultanés, chaque ennemi est défini par 4 octets :
; Octet 1   : [E1|E0|C3|C2|C1|C0|T1|t0] : E état (00 : Inactif, 01 : actif, 10 : En explosion, 11 : actif avec colon), C : compteur, T : Type (4 types possibles)
; Octet 2-3 : [0|0|y7|y6|y5|y4|y3|y2][y1|y0|x5|x4|x3|x2|x1|x0]
; Octet 4   : utilisateur
