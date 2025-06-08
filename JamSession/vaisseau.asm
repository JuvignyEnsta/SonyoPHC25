; /=/===============================================================================================================/=/
; /=/                                Gestion du vaisseau contrôlé par le joueur                                     /=/
; /=/===============================================================================================================/=/
; >===================================================================================================================<
; >==                                 Dessine le vaisseau au pixel prés sur l'écran                                 ==<
; >== En entrée : HL = adresse où afficher le vaisseau (voir doc)                                                   ==<
; >===================================================================================================================<
draw_spaceship:
	LD IX, sprites16x16
	LD A, L 
	AND 0X03 ; On récupère le n° d'animation du vaisseau (décalage précalculé)
	RLA      ; 2A
	RLA      ; 4A
	RLA      ; 8A
	RLA      ; 16A 
	RLA      ; 32A 
	RLA      ; 64A
	LD B, 0
	LD C, A
	ADD IX, BC
	SRL H    ; On divise HL par 4 pour avoir le décalage mémoire écran : 
	RR  L
	SRL H 
	RR  L
	LD BC, 0x6000
	ADD HL, BC ; On a maintenant l'adresse mémoire écran
	LD B, 16 
	LD DE, 29 
.loop:
	LD A, (IX)
	LD (HL), A 
	INC HL 
	INC IX 
	LD A, (IX)
	LD (HL), A
	INC HL 
	INC IX 
	LD A, (IX)
	LD (HL), A
	INC HL 
	INC IX 
	LD A, (IX)
	LD (HL), A
	ADD HL, DE 
	INC IX 
	DJNZ .loop
	RET
; >===================================================================================================================<
; >==                           Dessine le vaisseau en explostion au pixel prés sur l'écran                         ==<
; >== En entrée : HL = adresse où afficher le vaisseau (voir doc)                                                   ==<
; >===================================================================================================================<
draw_exploseship:
	LD IX, sprites16x16 + 5*256
	LD A, L 
	AND 0X03 ; On récupère le n° d'animation du vaisseau en explosion(décalage précalculé)
	RLA      ; 2A
	RLA      ; 4A
	RLA      ; 8A
	RLA      ; 16A 
	RLA      ; 32A 
	RLA      ; 64A
	LD B, 0
	LD C, A
	ADD IX, BC
	SRL H    ; On divise HL par 4 pour avoir le décalage mémoire écran : 
	RR  L
	SRL H 
	RR  L
	LD BC, 0x6000
	ADD HL, BC ; On a maintenant l'adresse mémoire écran
	LD B, 16 
	LD DE, 29 
.loop:
	LD A, (IX)
	LD (HL), A 
	INC HL 
	INC IX 
	LD A, (IX)
	LD (HL), A
	INC HL 
	INC IX 
	LD A, (IX)
	LD (HL), A
	INC HL 
	INC IX 
	LD A, (IX)
	LD (HL), A
	ADD HL, DE 
	INC IX 
	DJNZ .loop
	RET
; >===================================================================================================================<
; >==                           Efface le vaisseau de sa position actuelle sur l'écran                              ==<
; >===================================================================================================================<
clear_ship:
    LD HL, 0x6000 + 0x15E0 ; HL correspond à position écran x = 0, y = 175 (32*175)
	LD A, (vaisseau) ; Lit la position x du vaisseau en pixel
	SRL A    // x / 2 
	SRL A    // x / 4 pour convertir en paquet de quatre
    LD B, 0
    LD C, A
    ADD HL, BC
	LD DE, 29 ; // Saut de 29 pixels pour passer à la ligne suivante
	LD B, 16  ; // 16 lignes à effacer
	LD A, 170
.loop:
	LD (HL), A
	inc HL
	LD (HL), A
	inc HL 
	LD (HL), A
	inc HL
	LD (HL), A
	ADD HL, DE
	DJNZ .loop
	RET
; >====================================================================================================================<
; >==                              Affiche le vaisseau du joueur (selon son état)                                    ==<
; >====================================================================================================================<
affiche_joueur:
    LD HL, 175*128 
    LD DE, vaisseau
    LD A, (DE)
    BIT 7, A
    JR NZ, .explosion
    ; Le vaisseau est en vie
    OR L
    LD L, A
    CALL draw_spaceship
    RET
.explosion:
    ; Le vaisseau est en train d'exploser
    AND 0x7F
    OR L
    LD L, A
    CALL draw_exploseship
    RET
; >===================================================================================================================<
; >=                                  Gestion par le joueur du vaisseau spatial                                     ==<
; >===================================================================================================================<
player_action:
    LD HL, vaisseau
    LD A, (HL)
    BIT 7, A    ; On vérifie que le vaisseau n'est pas en train d'être détruit
    RET NZ      ; Si en train d'être détruit, plus de contrôle du joueur
    IN A, (134)
    CP 0xFF
    JR Z, .next1
    ; La touche gauche a été pressée :
    LD A, (HL)
    OR A
    JR Z, .next1 ; Si le vaisseau est déjà à la gauche de l'écran, on ne fait rien 
    ;PUSH HL
    ;EX AF, AF'
    ;CALL clear_ship
    ;EX AF, AF'
    ;POP HL
    DEC A
    LD (HL), A
    CALL affiche_joueur
    JR .next2
.next1
    IN A, (132)
    CP 0xFF
    JR Z, .next2 
    ; La touche droite a été pressée
    LD A, (HL)
    CP 72 
    JR NC, .next2 ; Si le vaisseau est déjà à la droite de l'écran, on ne fait rien 
    PUSH HL
    EX AF, AF'
    CALL clear_ship
    EX AF, AF'
    POP HL
    INC A 
    LD (HL), A
    CALL affiche_joueur
.next2
    IN A, (131)
    CP 0xFF
    JR Z, .next3
    ; La touche espace a été pressée
    LD A, (fire_delay)
    OR A
    JR Z, .launch_missile
    DEC A
    LD (fire_delay), A
    JR .next3
.launch_missile:
    LD A, 0x20
    LD (fire_delay), A
    LD A, (vaisseau)
    AND 0x7F
    ADD A, 6
    CALL active_missile
.next3
    IN A, (131)
    CP 0xFF
    JR Z, .end
    ; On active une bombe pour éliminer tous les ennemis de l'écran
    ; A FAIRE LA ROUTINE POUR L'APPELER ICI (écrire la routine dans le fichier alien.asm)
.end:
    RET
fire_delay: db 0x0
; define_uninit vaisseau, 14  ;
; ------------------- données sur le vaisseau du joueur -----------------------
; Premier octet : [S|x6|x5|x4|x3|x2|x1|x0] où S état du vaisseau (0 ok, 1 touché), 0 <= x <= 127
; octets 2-13   : 6*[A|y7|y6|y5|y4|y3|y2|y1][y0|x6|x5|x4|x3|x2|x1|x0] où A missile activé, 0<=y<=255, 0<=x<=127
; octets 14     : Nombre bombes restantes : 3 bits, 1 bit bombe activée ou non, Compteur affichage explosion vaisseau (4 bits)
; ------------------- données sur le vaisseau du joueur -----------------------
