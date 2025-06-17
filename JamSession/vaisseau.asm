; /=/===============================================================================================================/=/
; /=/                                Gestion du vaisseau contrôlé par le joueur                                     /=/
; /=/===============================================================================================================/=/
; >===================================================================================================================<
; >==                                 Dessine le vaisseau au pixel prés sur l'écran                                 ==<
; >== En entrée : HL = adresse où afficher le vaisseau (voir doc)                                                   ==<
; >===================================================================================================================<
draw_spaceship: ;! A OPTIMISER EN EVITANT D'UTILISER LE REGISTRE IX (A REMPLACER PAR DE)
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
draw_exploseship: ;! A OPTIMISER EN EVITANT D'UTILISER LE REGISTRE IX (A REMPLACER PAR DE)
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
; >== En entrée :                                                                                                   ==<
; >==      HL contient l'adresse où il faut effacer le vaisseau
; >===================================================================================================================<
clear_ship:
	LD DE, 29                                                  ; Saut de 29 pixels pour passer à la ligne suivante
	LD B, 16                                                   ; 16 lignes à effacer
	LD A, BACKGROUND                                           ; Couleur de fond pour effacer le vaisseau
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
    LD HL, SPACESHIP_Y*128 
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
	LD A, (fire_delay)
	OR A
	JR Z, .do_bomb_delay
	DEC A
	LD (fire_delay), A
.do_bomb_delay:
	LD A, (bomb_delay)
	OR A
	JR Z, .do_action
	DEC A
	LD (bomb_delay), A
.do_action:
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
    DEC A
    LD (HL), A
    JR .next2
.next1
    IN A, (132)
    CP 0xFF
    JR Z, .next2 
    ; La touche droite a été pressée
    LD A, (HL)
    CP 72 
    JR NC, .next2 ; Si le vaisseau est déjà à la droite de l'écran, on ne fait rien 
    INC A 
    LD (HL), A
.next2
    IN A, (131)
    CP 0xFF
    JR Z, .next3
    ; La touche espace a été pressée
    LD A, (fire_delay)
    OR A
    JR NZ, .next3
    LD A, 0x10
    LD (fire_delay), A
    LD A, (vaisseau)
    AND 0x7F
    ADD A, 6
    CALL active_missile
.next3
    IN A, (129)
    CP 0xFF
    JR Z, .end
	LD A, (bomb_delay)
	OR A
	JR NZ, .end
    ; On active une bombe pour éliminer tous les ennemis de l'écran
	LD A, 0x20
	LD (bomb_delay), A
	CALL utilise_bombe
.end:
    CALL affiche_joueur
    RET
fire_delay: db 0x0
bomb_delay: db 0x0
; >====================================================================================================================<
; >== Test si le vaisseau rentre en collision avec un Alien ou non                                                   ==<
; >====================================================================================================================<
ship_collision:
	LD A, (vaisseau)                  ; puisque le dernier bit est nul, on a bien que le x du vaisseau en pixel
	AND 0X7F
	LD C, A                           ; C = xv (x du vaisseau)
	LD HL, ennemis
	LD B, max_nb_aliens
.loop:
	LD A, (HL)
	AND IS_ACTIVE                     ; On vérifie si l'alien est actif
	JR Z, .next 					  ; si non, on passe à l'alien suivant
	INC HL
	LD E, (HL)
	INC HL
	LD A, (HL)                       ; DE contient les coordonnées de l'alien
	AND 0x7F
	CP 0x50                           ; y >= 160 pour l'alien ?
	JR C, .no_collision              ; Si non, pas de collision possible, on passe à l'alien suivant
	LD A, E                           ; On prend la valeur de xₐ en supprimant y₀ en se rappelant que C contient le xv du vaisseau	
	AND 0x7F
	CP 11 
	JR C, .comp2
	SUB 11                            ; On soustrait 11 pour prendre en compte la largeur du vaisseau
	CP C                              ; Non, ce n'est pas un amstrad. xv + 11  < xₐ ?
	JR NC, .no_collision              ; Si oui, pas possible qu'il y a une collision
.comp2:
	LD A, E                           ; On relit xₐ
	AND 0x7F
	ADD 11                            ; On ajoute 11. A = xₐ + 11
	CP C                              ; On test xv > xₐ + 11 ?
	JR C, .no_collision               ; Dans ce cas, pas possible qu'il y ait une collision
	; Sinon, oui, on a une collision. Couic le vaisseau
	CALL supprime_vie
	LD A, (vaisseau)
	OR 0x80
	LD (vaisseau), A
	CALL affiche_joueur
	LD B, 128
.loop2:
.wait1:
	IN A, (0x40)
	AND   0x10
;	JR Z, .end
;	IN A, (0x40)
;	AND   0x10
	JR Z, .wait1
.wait2:
	IN A, (0x40)
	AND   0x10
	JR NZ, .wait2
	DJNZ .loop2
	LD A, (vaisseau)
	AND 0x7F   
	LD (vaisseau), A
	CALL affiche_joueur
	JP clear_aliens
.next:
	INC HL
	INC HL
.no_collision:
	INC HL
	INC HL
	DJNZ .loop
	RET
; define_uninit vaisseau, 14  ;
; ------------------- données sur le vaisseau du joueur -----------------------
; Premier octet : [S|x6|x5|x4|x3|x2|x1|x0] où S état du vaisseau (0 ok, 1 touché), 0 <= x <= 127
; octets 2-13   : 6*[A|y7|y6|y5|y4|y3|y2|y1][y0|x6|x5|x4|x3|x2|x1|x0] où A missile activé, 0<=y<=255, 0<=x<=127
; octets 14     : Nombre bombes restantes : 3 bits, 1 bit bombe activée ou non, Compteur affichage explosion vaisseau (4 bits)
; ------------------- données sur le vaisseau du joueur -----------------------
