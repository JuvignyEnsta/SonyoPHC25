;/=/                                     BIBLIOTHEQUE DE GESTION DES ALIENS                                             
; >====================================================================================================================<
; >==                    Dessine un alien à l'écran avec gestion masquage pour superposition                         ==<
; >== Entrée : HL : pointe sur les données de l'alien                                                                ==<
; >====================================================================================================================<
draw_alien:
	PUSH HL                            ; > Sauvegarde de HL
	INC HL                             
	LD E, (HL)
	INC HL
	LD D, (HL)                         ; DE = (HL)
	EX DE, HL                          ; HL contient les coordonnées de l'alien, DE le pointeur sur y de l'alien
	; Calcul du masque pour le sprite de base :
	SRL H                              ; On divise HL par 4 pour avoir l'adresse mémoire écran : 
	RR  L
	SRL H 
	RR  L
	LD BC, SCREEN_ADDR
	ADD HL, BC                         ; HL contient l'adresse écran
	EX DE, HL                          ; DE contient l'adresse écran
	POP HL                             ; < Restaure HL
	CALL mask_decal                    ; BC contient le décalage à appliquer pour avoir le bon sprite
	EX DE, HL
	CALL draw_sprite
	RET
; >====================================================================================================================<
; >==          Dessine l'explosion d'un alien à l'écran avec gestion masquage pour superposition                     ==<
; >== Entrée : HL : pointe sur les données de l'alien                                                                ==<
; >====================================================================================================================<
draw_explosion:
	PUSH HL                            ; > Sauvegarde HL
	INC HL
	LD A, (HL)
	LD E, (HL)                         ; E contient le poids faible des coordonnées de l'alien
	AND 0x03
	RRCA
	RRCA                               ; A a été multiplié par 64 (en faisant deux décalages cycliques vers la droite)  
	; Masque de décalage
	INC HL
	LD D, (HL)                         ; DE = (HL)
	EX DE, HL                          ; HL contient les coordonnées de l'alien, DE le pointeur sur y de l'alien
	; Calcul du masque pour le sprite de base :
	SRL H                              ; On divise HL par 4 pour avoir l'adresse mémoire écran : 
	RR  L
	SRL H 
	RR  L
	LD BC, SCREEN_ADDR
	ADD HL, BC                         ; HL contient l'adresse écran
	EX DE, HL                          ; DE contient l'adresse écran
	LD BC, 1024
	LD C, A                            ; Bon décalage
	EX DE, HL
	CALL draw_sprite 
	POP HL
	RET
; >====================================================================================================================<
; >== Efface un alien de l'écran par masquage                                                                        ==<
; >== Entrée :                                                                                                       ==<
; >==      HL = pointeur sur l'alien                                                                                 ==<
; >====================================================================================================================<
clear_alien:
	PUSH HL                            ; > Sauvegarde de HL
	INC HL                             
	LD E, (HL)
	INC HL
	LD D, (HL)                         ; DE = (HL)
	EX DE, HL                          ; HL contient les coordonnées de l'alien, DE le pointeur sur y de l'alien
	; Calcul du masque pour le sprite de base :
	SRL H                              ; On divise HL par 4 pour avoir l'adresse mémoire écran : 
	RR  L
	SRL H 
	RR  L
	LD BC, SCREEN_ADDR
	ADD HL, BC                         ; HL contient l'adresse écran
	EX DE, HL                          ; DE contient l'adresse écran
	POP HL                             ; < Restaure HL
	CALL mask_decal                    ; BC contient le décalage à appliquer pour avoir le bon sprite
	EX DE, HL
	CALL clear_sprite
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
    JP NC, .a_colon
.no_colon:
	PUSH  HL
    LD BC, +128
    ; L'alien n'a pas enlevé de colon
    AND 0x0F              ; On teste si le compteur de cycle est à zéro ou non
    JR Z, .test_devie1
    ; Là, on va tout droit :-)
    LD A, (HL)            ; Décrémente le compteur
	DEC A
	LD (HL), A            ; qu'on reécrit en mémoire
    INC HL                ; Va pointer sur les coordonnées de l'alien
    LD DE, (HL)
    EX DE, HL             ; DE pointe sur les coordonnées de l'alien, HL possède les coordonnées
    JR .descend
.test_devie1:
    ; Test si l'alien va dévier (compteur ) zéro
    LD A, (HL)
    AND 0xF0
    OR 0x0A
    LD (HL), A            ; On remet le compteur à 10
    INC HL                ; HL pointe maintenant sur les coordonnées de l'alien
    LD DE, (HL)           ; On récupère les coordonnées dans DE
    EX DE, HL             ; Hop, HL contient les coordonnées et DE le pointeur sur les coordonnées
    LD A, R               ; On prend un nombre aléatoire entre 0 et 255	
    CP 0x40               ; Test si le bit 6 ou 7 est non nul (63/255 de change de dévier)
    JR C, .descend        ; Si A >= 64, on descend tout droit
    AND 0x20              ; Test si l'alien dévie sur la gauche ou la droite
    JR Z, .gauche1        ; Si le bit 5 est  nul, dévie vers la gauche
    ; On dévie à droite : on teste si l'alien est sur le bord droit :
.droite1:
    LD A, L               ; On récupère x
    AND 0x7F              ; en prenant soin de virer le bit 7 qui correspond à y0
    CP 72                 ; Compare avec le bord
    JR NC, .descend       ; Pas de dérive vers  la droite puisqu'on est déjà au bord
    INC BC                ; Incrémente BC pour dévier vers la droite
    JR .descend
.gauche1:
    LD A, L             ; On récupère x
    AND 0x7F            ; En supprimant le bit 7 (y0)
    OR A                ; Pour tester si A est nul
    JR Z, .descend      ; Si x = 0, on ne dévie pas vers la gauche
    DEC BC              ; Décrémente BC pour dévier vers la gauche
.descend: 
	; /===/ On efface le sprite de l'alien : 
	POP HL              ; < Restaure HL => pointe sur l'alien
	PUSH BC             ; > Sauvegarde BC
	PUSH HL             ; > Sauvegarde HL
	CALL clear_alien    ; On efface le sprite de son ancienne position
	POP HL              ; < Restaure HL => pointe sur l'alien

	INC HL
	LD E, (HL)
	INC HL
	LD D, (HL)
	DEC HL
	EX HL, DE
	POP BC              ; < Restaure BC
    ADD HL, BC          ; Passage à la ligne suivante avec déviation éventuelle
    EX HL, DE           ; Echange, maintenant DE contient les coordonnées, et HL pointe sur les coordonnées de l'alien
    LD (HL), DE         ; On recopie les coordonnées en mémoire
	DEC HL
	JP draw_alien
.a_colon:
	PUSH HL
    LD BC, -128         ; Pour passer à la ligne précédente
    ; L'alien a enlevé un colon
    AND 0x0F            ; On teste si le compteur de cycle est à zéro ou non
    JR Z, .test_devie2
    ; Là, on va tout droit :-)
    LD A, (HL)
	DEC A
	LD (HL), A          ; On décrémente le compteur de cycle
    INC HL              ; HL pointe sur les coordonnées de l'alien
    LD DE, (HL)         ; DE contient les coordonnées de l'alien
    EX DE, HL           ; Echange, DE contient le pointeur sur les coordonnées, et HL les coordonnées
    JR .remonte         ; Aller, on remonte
.test_devie2:
    ; Test si l'alien va dévier (compteur ) zéro
    LD A, (HL)
    AND 0xF0
    OR  0X0A
    LD (HL), A          ; On remet le compteur à 10
    INC HL              ; HL pointe sur les coordonnées de l'alien
    LD DE, (HL)         ; DE contient les coordonnées de l'alien
    EX DE, HL           ; Echange : DE pointe sur les coordonnées, HL contient les coordonnées
    LD A, R             ; Valeur au hasard entre 0 et 255 pour A
    CP 0x40             ; Teste si A est supérieur ou égal à 64
    JR C, .remonte      ; Si A supérieur à 64, l'alien descent tout droit
    AND 0x20            ; Test si l'alien dévie sur la gauche ou la droite
    JR Z, .gauche2       ; Si le bit 5 est  nul, dévie vers la gauche
    ; On dévie à droite : on teste si l'alien est sur le bord droit :
.droite2:
    LD A, L             ; On récupère x
    AND 0x7F            ; en prenant soin de virer le bit 7 qui correspond à y0
    CP 72               ; Compare avec le bord
    JR NC, .remonte     ; Pas de dérive vers  la droite puisqu'on est déjà au bord
    INC BC              ; Incrémente BC pour déplacer vers la droite
    JR .remonte
.gauche2:
    LD A, L             ; On récupère x
    AND 0x7F            ; En supprimant le bit 7 (y0)
    OR A                ; Pour tester si A est nul
    JR Z, .remonte      ; Si x = 0, on ne dévie pas vers la gauche
    DEC BC              ; Décrémente BC pour déplacer vers la gauche
.remonte:
	JP .descend
; >====================================================================================================================<
; >== Second type de mouvement :                                                                                     ==<
; >==     Change constamment de direction : 85/255 gauche, 86/255 aucun, 85/255 droite                               ==<
; >== En entrée :                                                                                                    ==<
; >==     HL = pointeur sur l'alien dont on s'occupe                                                                 ==<
; >====================================================================================================================<
alien_depl2:
	LD A, (HL)            ; On charge l'état de l'alien dans A
	CP  0x80              ; Test si l'alien a déjà enlevé un colon
    JP NC, .a_colon
.no_colon:
    ; L'alien n'a pas enlevé de colon
	PUSH HL
    LD BC, +128           ; Pour passer à la ligne suivante
	INC HL                ; HL pointe maintenant sur les coordonnées de l'alien
    LD DE, (HL)           ; On récupère les coordonnées dans DE
    EX DE, HL             ; Hop, HL contient les coordonnées et DE le pointeur sur les coordonnées

	LD A, R               ; A prend une valeur au hasard entre 0 et 255
	CP 0x40               ; A < 87 ?
	JR C, alien_depl1.descend ; Si oui, on ne fait que descendre
	AND 0x02              ; A < 172 ?
	JR Z,  .droite1       ; Si oui, on va à droite
.gauche1:                 ; Bon, là, on va à gauche
    LD A, L               ; On récupère x
    AND 0x7F              ; En supprimant le bit 7 (y0)
    OR A                  ; x = 0 ?
    JP Z, alien_depl1.descend ; Si x = 0, on ne dévie pas vers la gauche
	DEC BC                ; décrément pour dévier vers la gauche
	JP alien_depl1.descend 
.droite1:                 ; On va vers la droite
    LD A, L               ; On récupère x
    AND 0x7F              ; en prenant soin de virer le bit 7 qui correspond à y0
    CP 72                 ; x >= 72 ?
    JP NC, alien_depl1.descend       ; Alors pas de dérive vers  la droite puisqu'on est déjà au bord
	INC BC                ; Incrément pour dévier vers la droite
	JP alien_depl1.descend
.a_colon:
    ; L'alien a enlevé un colon
	PUSH HL
    LD BC, -128           ; Pour passer à la ligne précédente
	INC HL                ; HL pointe maintenant sur les coordonnées de l'alien
    LD DE, (HL)           ; On récupère les coordonnées dans DE
    EX DE, HL             ; Hop, HL contient les coordonnées et DE le pointeur sur les coordonnées
	LD A, R               ; A prend une valeur au hasard entre 0 et 255
	CP 0x40                 ; A < 87 ?
	JP C, alien_depl1.descend        ; Si oui, on remonte seulement
	AND 0x20                ; A < 172 ?
	JR Z,  .droite2       ; On dévie vers la droite
.gauche2:                 ; Là, on dévie vers la gauche si possible
    LD A, L               ; On récupère x
    AND 0x7F              ; En supprimant le bit 7 (y0)
    OR A                  ; x == 0 ?
    JP Z, alien_depl1.descend        ; Si x == 0, on ne dévie pas vers la gauche
	DEC BC                ; Décrémentation pour dévier vers la gauche
	JP alien_depl1.descend 
.droite2:                 ; Là, on veut dévier vers la droite
    LD A, L               ; On récupère x
    AND 0x7F              ; en prenant soin de virer le bit 7 qui correspond à y0
    CP 72                 ; x >= 72 ?
    JP NC, alien_depl1.descend       ; Alors pas de dérive vers  la droite puisqu'on est déjà au bord
	INC BC                ; Incrémentation pour dévier vers la droite
	JP alien_depl1.descend
; >====================================================================================================================<
; >== Troisième type de mouvement :                                                                                  ==<
; >==     Se dirige toujours en biais, vers la gauche ou la droite (50%) en changeant de direction tous les n cycles ==<
; >== En entrée :                                                                                                    ==<
; >==     HL = Pointeur sur un ennemi du tableau d'ennemis                                                           ==<
; >====================================================================================================================<
alien_depl3:
	; Pour l'état de l'alien, on a : [E1|E0|T1|T0|D|C2|C1|C0] où D est la direction de déviation
	LD A, (HL)            ; On charge l'état de l'alien dans A
	AND 0x0F              ; Test si le compteur est nul ou non
	JR NZ, .deplacement   ; Si le compteur est non nul, on poursuit le déplacement
	LD A, R               ; A prend une valeurs entre 0 et 255
	AND 0x10              ; Pour tester une chance sur deux d'aller à gauche ou à droite (ou aurait pu prend un autre bit, mais bon)
	JR Z, .gauche         ; A gauche si le 7e bit est nul
.droite:                  ; OK, le hasard a décidé de dévier vers la droite
	LD A, (HL)            ; On recharge l'état de l'alien dans A
	OR 0x0F               ; bit 3 mis à 1 pour dire qu'on va à droite et compteur = à 7
	LD (HL), A
	JR .deplacement       ; Et hop, on se déplace
.gauche:                  ; OK, le hasard a décidé de dévier vers la gauche
	LD A, (HL)            ; On recharge l'état dans A
	AND 0xF7              ; bit 3 mis à 0 pour dire qu'on va gauche
	OR  0x07              ; et compteur mis à 7
	LD (HL), A
.deplacement:             ; Aller, gestion des déplacements en suivant l'état
	LD A, (HL)
	DEC A                 ; On décrémente le compteur
	LD (HL), A            ; On met à jour l'état de l'alien
    CP  0x80              ; Test si l'alien a déjà enlevé un colon
    JR NC, .a_colon       ; Saut à .a_colon si l'alien a déjà enlevé un colon
.no_colon:
	PUSH HL
    ; L'alien n'a pas enlevé de colon (le feignant)
	LD BC, 128            ; Dans ce cas, on se prépare à aller à la ligne suivante
	INC HL                ; HL pointe maintenant sur les coordonnées de l'alien
	LD DE, (HL)           ; DE contient les coordonnées de l'alien
	EX DE, HL             ; Echange : DE pointe sur les coordonnées et HL contient les coordonnées
	BIT 3, A              ; Si bit mis, on va à droite
	JR Z, .gauche1        ; Donc, si il y est pas, on va à gauche :-p
    ; On dévie à droite : on teste si l'alien est sur le bord droit :
.droite1:
    LD A, L               ; On récupère x
    AND 0x7F              ; en prenant soin de virer le bit 7 qui correspond à y0
    CP 72                 ; x < 72 ?
    JP NC, alien_depl1.descend ; Si x < 72, Pas de dérive vers  la droite puisqu'on est déjà au bord
    INC BC                ; Incrément pour dévier vers la droite 
    JP alien_depl1.descend
.gauche1:
    LD A, L               ; On récupère x
    AND 0x7F              ; En supprimant le bit 7 (y0)
    OR A                  ; Pour tester si A est nul
    JP Z, alien_depl1.descend ; Si x = 0, on ne dévie pas vers la gauche
    DEC BC                ; Décrément pour dévier vers la gauche
    JP alien_depl1.descend
.a_colon:
	PUSH HL
    ; L'alien a enlevé un colon
	LD BC, -128           ; On prépare BC pour aller sur la ligne précédente
	INC HL                ; On incrémente HL pour pointer sur les coordonnées de l'alien
	LD DE, (HL)           ; On charge les coordonnées dans DE
	EX DE, HL             ; Echange : DE pointe sur les coordonnées, HL contient les coordonnées
	BIT 3, A              ; Si bit 3 non nul, on va à droite
	JR Z, .gauche2        ; sinon on va à gauche
    ; On dévie à droite : on teste si l'alien est sur le bord droit :
.droite2:               ; Cas où on va à droite
    LD A, L             ; On récupère x
    AND 0x7F            ; en prenant soin de virer le bit 7 qui correspond à y0
    CP 72               ; x >= 72 ?
    JP NC, alien_depl1.descend ; Si x >= 72, Pas de dérive vers  la droite puisqu'on est déjà au bord
    INC BC              ; Incrément pour dévier sur la droite
    JP alien_depl1.descend
.gauche2:               ; Cas où on dévie vers la gauche
    LD A, L             ; On récupère x
    AND 0x7F            ; En supprimant le bit 7 (y0)
    OR A                ; Pour tester si A est nul
    JP Z, alien_depl1.descend ; Si x = 0, on ne dévie pas vers la gauche
    DEC BC
	JP alien_depl1.descend
; >====================================================================================================================<
; >== Dessine un alien en téléportation                                                                              ==<
; >== En entrée :                                                                                                    ==<
; >==      HL = Pointeur sur un alien du tableau                                                                     ==<
; >====================================================================================================================<
alien_teleport:
	; Affichage de l'alien :
	PUSH HL                           ; > Sauvegarde HL
	CALL draw_alien
	POP HL                            ; < Restauration HL
	PUSH HL                           ; > Sauvegarde HL
	INC HL
	INC HL
	INC HL
	LD A, (HL)
	DEC HL
	LD D, (HL)   	
	DEC HL
	LD E, (HL)
	EX DE, HL
	; Calcul de l'adresse  :
	SRL H                              ; On divise HL par 4 pour avoir l'adresse mémoire écran : 
	RR  L
	SRL H 
	RR  L
	LD BC, SCREEN_ADDR
	ADD HL, BC                         ; HL contient l'adresse écran
	LD B, 16
	LD DE, 29
	LD C, A
.loop:
	LD A, (HL)
	AND C
	OR BACKGROUND
	LD (HL), A
	INC HL
	LD A, (HL)
	AND C
	OR BACKGROUND
	LD (HL), A
	INC HL
	LD A, (HL)
	AND C
	OR BACKGROUND
	LD (HL), A
	INC HL
	LD A, (HL)
	AND C
	OR BACKGROUND
	LD (HL), A
	ADD HL, DE
	DJNZ .loop
	POP HL                             ; < Restauration HL
	RET	
; >====================================================================================================================<
; >== Efface les colories de téléportation                                                                           ==<
; >== En entrée :                                                                                                    ==<
; >==      HL = Pointeur sur un alien du tableau                                                                     ==<
; >====================================================================================================================<
clear_teleport:
	; Affichage de l'alien :
	PUSH HL                            ; > Sauvegarde HL
	INC HL
	LD E, (HL)
	INC HL
	LD D, (HL)   	
	EX DE, HL
	; Calcul de l'adresse  :
	SRL H                              ; On divise HL par 4 pour avoir l'adresse mémoire écran : 
	RR  L
	SRL H 
	RR  L
	LD BC, SCREEN_ADDR
	ADD HL, BC                         ; HL contient l'adresse écran
	LD B, 16
	LD DE, 29
	LD A, BACKGROUND
.loop:
	LD (HL), A
	INC HL
	LD (HL), A
	INC HL
	LD (HL), A
	INC HL
	LD (HL), A
	ADD HL, DE
	DJNZ .loop
	POP HL                             ; < Restauration HL
	RET	
; >====================================================================================================================<
; >== Quatrième et dernier déplacement :                                                                             ==<
; >==     Se déplace horizontalement pendant n1 cycle, puis se téléporte 8 pixels plus bas, à un endroit au hasard   ==<
; >==     en x. Le temps de téléportation dure n2 cycle pendant lequel l'alien est intouchable. Puis repart à droite ==<
; >==     ou à gauche au hasard à partir de sa nouvelle position pendant n1 cycle, etc.                              ==<
; >== En entrée : HL = Pointeur sur un ennemi du tableau d'ennemis                                                   ==<
; >====================================================================================================================<
alien_depl4:
	; Pour le 4e octet : [E1|E0|c5|c4|c3|c2|c1|c0] : E, état déplacement, c0-c5 => Nombre de cycle courant
	;> E1 : 0 => déplacement horizontal, 1 => Téléportation
	;> E0 : déplacement 1 : à droite, 0 : à gauche par convention
	INC HL
	INC HL
	INC HL       ; Pointe sur le dernier octet pour regarder l'état du déplacement de l'alien
	LD A, (HL)
	AND 0x3F;    ; Garde le compteur
	JR NZ, .gere ; Si compteur non nul, on saute à la gestion propre du déplacement
	; On change d'état et on remet le compteur
	LD A, (HL)
	BIT 7, A 
	JR NZ, .init_depl      ; Si en état de téléportation, on va se mettre en déplacement
	; Là on va s'apprêter à téléporter l'alien, donc initialiser son état et retourner (pas de déplacement)
	LD (HL), 0x8F ; Compteur à 15 pour le compteur et état téléportation (et en passant gauche, mais on s'en fout)
	; /===/ On affiche le sprite de l'alien : 
	DEC HL                 ; On repointe sur le poids fort des coordonnées de l'alien
	LD D, (HL)             
	DEC HL                 ; On pointe sur le poids faible des coordonnées de l'alien
	LD E, (HL)
	DEC HL                 ; On pointe sur le début de l'alien
	JP draw_alien
.init_depl:
	; On était en état de téléportation. On va devoir donc calculer une nouvelle position en x et dans quelle direction il doit se déplacer
	LD A, R               ; Tirage au hasard entre 0 et 255
	AND 0x01              ; On teste le bit de poids faible pour savoir si on va à gauche ou à droite
	JR Z, .vers_droite    ; Par convention, on dit que si ce bit est nul, on va à droite sinon à gauche 
	LD (HL), 0b00011111   ; E0 = 0 = déplacement vers gauche, E1 = 0 = déplacement, compteur = 31
	JR .teleporte
.vers_droite:
	LD (HL), 0b01011111   ; E0 = 1 = déplacement vers droite, E1 = 0 = déplacement, compteur = 31 
.teleporte:
	DEC HL
	DEC HL                ; HL pointe maintenant sur les coordonnées de l'alien

	DEC HL
	CALL clear_teleport
	INC HL

	LD A, R               ; Tirage A qui contenait la direction + la nouvelle position en x après téléportation
	AND 0x3F              ; x entre 0 et 63 (pour être sûr de ne pas dépasser la limite à droite de la partie jeu)
	LD B, A               ; on charge A dans B
	LD A, (HL)			  ; On recharge l'ancienne position en x (avec un bout d'y)
	AND 0x80              ; On vire l'ancien x
	OR B                  ; Et on le remplace par le x qu'on vient de calculer
	LD (HL), A            ; On remplace l'ancien x de l'alien par le nouveau
; Calcul nouvel y :
	DEC HL                ; Avant cela, on va chercher l'état de l'alien du point de vue colon ou pas
	PUSH BC               ; > Sauvegarde BC
	PUSH HL               ; > Sauvegarde HL
	CALL clear_alien
	POP HL                ; < Restauration HL
	POP BC                ; < Restauration BC

	LD A, (HL)            ; On charge son état
	AND 0x80              ; J'ai un colon ?
	JR NZ, .a_colon       ; Si j'en ai un, je saut à .a_colon
	LD C, 2            ; BC = 512 afin de faire un saut de quatre lignes vers le bas car je n'ai pas de colon
	JR .cont_colon        ; Aller, hop, on saute à .cont_colon pour calculer le saut en y avec BC comme paramètre
.a_colon:
	LD C, -2           ; Cas où j'ai un colon, alors on va sauter de quatre lignes, mais vers le haut cette fois-ci
.cont_colon:
	INC HL                ; On repointe sur les coordonnées de l'alien (dont le x est déjà modifié)
	INC HL
	LD A, (HL)
	ADD C
	AND 0x7F
	LD (HL), A
	DEC HL
	DEC HL
	JP draw_alien
.gere:
	LD D, H
	LD E, L      ; Plus rapide que LD DE, HL (?!)
	LD A, (HL)   ; Décrémente compteur
	DEC A
	LD (HL), A   ; fin décrémente compteur
	BIT 7, A     ; En téléportation ?
	JP Z, .no_alien_teleport
	DEC HL
	DEC HL
	DEC HL
	JP alien_teleport
.no_alien_teleport:
	LD A, (HL)
	DEC HL       ; Non, je suis en déplacement, donc je décrémente deux fois
	DEC HL       ; pour arriver sur les coordonnées de notre alien
	BIT 6, A     ; Puisque A contient déjà l'état de notre alien, vérifions si on doit aller à gauche ou à droite
	JR NZ, .a_droite  ; L'état me dit que je dois aller à droite
.a_gauche:
	; sinon, ici, l'état me dit que je doit aller à gauche
	; Vérifions si je suis complètement à gauche  de l'écran ?
	LD A, (HL)   ; Je lis la valeur des coordonnées X pointé par HL
	AND 0x7F     ; x = 0 ?
	JR NZ, .depl_gauche ; Non, c'est bon, je peux me déplacer à gauche
	; Ah non, je suis complètement  à gauche, je dois donc changer de direction :
	EX DE, HL    ; On restaure le pointeur sur l'état de notre alien (et DE contient l'adresse des coordonnées de notre alien)
	LD A, (HL)   ; On charge l'état de notre alien
	OR 0x40      ; On inverse la direction en mettant E0 = 1
	LD (HL), A   ; On sauvegarde le nouvel état
	EX DE, HL    ; On restaura dans HL le pointeur sur les coordonnées de notre alien
	JR .depl_droite
.depl_gauche:
	DEC HL
	PUSH HL     ; > Sauvegarde HL
	CALL clear_alien
	POP HL      ; < Restauration HL
	INC HL
	LD A, (HL)  ; On lit le x de l'alien
	DEC A       ; On décrémente pour que l'alien aille à gauche
	LD (HL), A  ; On sauvegarde le nouveau x pour l'alien
	DEC HL
	JP draw_alien
.a_droite:
	; On doit aller à droite
	; On vérifie d'abord que mon alien n'est pas complètement à droite de l'aire de jeu
	LD A, (HL) 
	AND 0x7F
	CP 72
	JR C, .depl_droite  ; Si je ne suis pas complètement à droite, je peux me déplacer à droite
	; Ah non, je suis complètement à droite, je dois donc changer de direction :
	EX DE, HL    ; On restaure le pointeur sur l'état de notre alien (et DE contient l'adresse des coordonnées de notre alien)
	LD A, (HL)   ; On charge l'état de notre alien
	AND 0b10111111 ; On inverse la direction en mettant E0 = 0
	LD (HL), A   ; On sauvegarde le nouvel état
	EX DE, HL    ; On restaure dans HL les coordonnées de notre alien
	JR .depl_gauche
.depl_droite
	DEC HL
	PUSH HL      ; > Sauvegarde HL
	CALL clear_alien
	POP HL       ; < Restauration HL
	INC HL
	LD A, (HL)   ; On lit le x de l'alien
	INC A        ; On incrémente pour que l'alien aille à droite
	LD (HL), A   ; On sauvegarde le nouveau x pour l'alien
	DEC HL
	JP draw_alien
; >====================================================================================================================<
; >== Test si un alien doit changé d'état en fonction de ses coordonnées !                                           ==<
; >== En entrée : HL pointe sur le début des donnnées de l'alien                                                     ==<
; >====================================================================================================================<
alien_state:
	;/===/ Rappel état : 00 : inactif, 01 : actif, 10 : En explosion, 11 : contient un colon
	LD A, (HL)         ; On stocke  l'état de l'alien dans A
	AND 0b11000000     ; On ne conserve que l'état
	CP  0b11000000     ; L'alien possède un colon ?
	JR Z, .a_colon     ; On saute à .a_colon si c'est le cas
	CP 0b01000000      ; L'alien est actif sans colon ?
	JR Z, .no_colon    ; On saute à .no_colon si c'est le cas
	RET
;	CP 0b10000000      ; L'alien est-il en train d'exploser ?
;	RET NZ             ; On retourne car inactif, donc rien à faire
	; Cas où on est en train d'exploser.
	; On va lire le nombre de cycle restant avant fin explosion :
;	AND 0x0F           ; On ne conserve que les bits allant de 0 à 3 (nombre de cycle)
;	OR A               ; Compteur nul ?
;	JR  NZ, .continue ; On désactive l'alien
;	CALL clear_teleport
;	LD A, (HL)         ; Déactive l'alien
;	AND 0x3F
;	LD (HL), A
;	RET
;.continue:
;	CALL draw_explosion
;	LD A, (HL)         ; On recharge l'état dans A
;	DEC A              ; On décrémente le compteur 
;	LD (HL), A         ; On enregistre le compteur mis à jour
;	RET                ; Et au revoir !
.a_colon:              ; On traite le cas où l'alien a capturé un colon
	LD DE, HL          ; Sauvegarde de HL dans DE
	INC HL 
	INC HL             ; Pour aller voir le y de l'alien
	LD A, (HL)         ; On charge le y (sans son premier bit)
	OR A               ; y < 2 ?
	RET NZ             ; Si non, on retourne car l'alien ne s'est pas encore enfuit
	EX DE, HL          ; On restaure HL
	LD A, (HL)
	AND 0x3F           ; On rend l'alien inactif (près donc à recevoir un nouvel alien)
	LD (HL), A         ; Màj de l'état en mémoire
	CALL clear_alien
	RET
.no_colon:
	LD DE, HL          ; Sauvegarde de HL dans DE
	INC HL 
	INC HL             ; Pour aller voir le y de l'alien
	LD A, (HL)         ; On charge le y (sans son premier bit)
	CP 88              ; Si y < 88
	RET C              ; On retourne car l'alien n'a pas atterrit sur la planète pour enlevé un colon
	EX DE, HL          ; On restaure HL dans le cas où l'alien a atterit
	LD A, (HL)         ; On charge l'état de l'alien
	OR 0xC0            ; On marque l'alien comme transportant maintenant un colon
	LD (HL), A
	;RET; ! A ENLEVER
	JP enleve_colon
; >====================================================================================================================<
; >== Recherche le premier slot disponible pour un nouvel alien. Retourne l'adresse du slot dans HL. Si aucun slot   ==<
; >== n'est disponible, retourne le pointeur nul dans HL.                                                            ==<
; >====================================================================================================================<
find_free_slot:
	LD B, max_nb_aliens ; On charge le nombre maximum d'aliens (nombre de slots existant)
	LD C, 4             ; Saut pour aller de slot en slot
	LD HL, ennemis      ; HL reçoit l'adresse du premier slot (chaque slot fait quatre octets)
.loop:
	LD A, (HL)          ; Charge état de l'alien du slot courant :
	AND 0b11000000      ; On vérifie si le bit 7 et 6 sont à 0 (l'alien est disponible)
	RET Z               ; Si c'est le cas, on retourne avec HL pointant sur le slot libre
	LD A, C             ;
	ADD A, L            ;
	LD L, A             ; On ajoute le décalage pour passer au prochain slot
	JR NC, .next_iter   ;
	INC H
.next_iter:
	DJNZ	.loop       ; Et on boucle tant qu'il reste des slots à tester
	LD HL , 0           ; Pas de slot trouvé
	RET
; >====================================================================================================================<
; >== Génération des aliens                                                                                          ==<
; >==   La génération va dépendre du score du joueur de la manière suivante :                                        ==<
; >==          ■ Type d'alien généré (cumulatif)                                                                     ==<
; >==               ● Score <   32 : Seulement alien type 1                                                          ==<
; >==               ● Score >=  32 : Alien de type 2 possible                                                        ==<
; >==               ● Score >=  64 : Alien de type 3 possible                                                        ==<
; >==               ● Score >= 128 : Alien de type 4 possible                                                        ==<
; >==          ■ Fréquence des aliens                                                                                ==<
; >==               ● On tire un alien tous les 64 - min(score/2, 32) cycles avec 6 aliens au maximum à l'écran      ==<
; >== Note : Un alien non chargé abattu rapport un point ! et un alien contenant un colon fait perdre 5 points !     ==<
; >====================================================================================================================<
generate_alien:
	; /===/ On génère ici des aliens pour des scores encore bas :
	LD A, (alien_clock)             ; On récupère l'horloge de génération des aliens
	OR A                            ; alien_clock == 0 ?
	JR NZ, .dec_clock               ; Si non, on décrémente l'horloge
	CALL find_free_slot             ; Cherche un slot libre pour un alien.
	LD A, H                         ;
	OR A                            ; HL est-il nul (test sur H suffit car adresse > 256 pour le slot :-) )
	RET Z                           ; Si aucun slot de libre, on retourne sans générer d'alien
	LD A, (score+1)                 ; Test poids fort du score
	OR A                            ; Si il est non nul
	JP NZ, .generate_halien          ; On passe à la génération de type par défaut pour des hauts scores
	LD A, (score)                   ; Charge poid faible du score
	CP 32                           ; Score >= 32 ?
	JR NC, .generate_alien1         ; Génèration étape 2
	; Génère un alien de type 0 :
	LD A, 0x4A                      ; Type alien 0 avec compteur = 10
	LD (HL), A
	INC HL                          ; HL pointe sur les coordonnées de l'alien
	LD A, 72
	CALL rand                       ; Génère un nombre aléatoire entre 0 et 72 (non compris)
	LD (HL), A                      ; X = rand(72)
	INC HL                          ; HL pointe sur les coordonnées de l'alien (y)
	LD (HL), 0                      ;
	LD A, (score)                   ; A vaut le score
	RRA
	LD B, A
	LD A, 96
	SUB B                           ; A = 96 - score/2
	LD (alien_clock), A             ; L'horloge est initialisé
	RET                             ; Fin génération alien pour score < 32
.generate_alien1:
	LD A, (score)
	CP 64                           ; A >= 64 ?
	JR NC, .generate_alien2         ; Si oui, on saute à la troisième génération
	LD A, R                         ; 
	AND 0x10                        ; Pour avoir un alien de type 0 ou 1
	OR 0x4A                         ;
	LD (HL), A                      ; Donc, Actif de type 0 ou 1 avec compteur = 10
	INC HL                          ; HL pointe sur les coordonnées de l'alien
	LD A, 72
	CALL rand                       ; Génère un nombre aléatoire entre 0 et 72 (non compris
	LD (HL), A                      ; X = rand(72)
	INC HL                          ; HL pointe sur les coordonnées de l'alien (y)
	LD (HL), 0                      ; y = 0
	LD A, (score)
	RRA                             ; A = score / 2 (dont entre 0 et 31)
	LD B, A
	LD A, 64
	SUB B                           ; A = 64 - score/2
	LD (alien_clock), A             ; Initialisation de l'horloge
	RET
.dec_clock:
	DEC A
	LD (alien_clock), A
	RET
.generate_alien2:
	LD A, (score)
	CP 128
	JR NC, .generate_halien
	LD A, R                         ; 
	AND 0x30                        ; Pour avoir un alien de type 0, 1 ou 2
	CP 0x30                         ; Si on a un alien de type 3 par erreur
	JR NZ, .c_ok 
	LD A, 0x10
.c_ok:	
	OR 0x4A                         ;
	LD (HL), A                      ; Donc, Actif de type 0,1 ou 2 avec compteur = 10
	INC HL                          ; HL pointe sur les coordonnées de l'alien
	LD A, 72
	CALL rand                       ; Génère un nombre aléatoire entre 0 et 72 (non compris
	LD (HL), A                      ; X = rand(72)
	INC HL                          ; HL pointe sur les coordonnées de l'alien (y)
	LD (HL), 0                      ;
	LD A, (score)
	RRA                             ; A = score / 2 (dont entre 0 et 31)
	LD B, A
	LD A, 80
	SUB B                           ; A = 64 - score/2
	LD (alien_clock), A             ; Initialisation de l'horloge
	RET
.generate_halien:
	LD A, H                         ;
	OR A                            ; HL est-il nul (test sur H suffit car adresse > 256 pour le slot :-) )
	RET Z                           ; Si aucun slot de libre, on retourne
	LD A, R                         ; 
	AND 0x30                        ; Pour avoir un alien de type 0, 1 ou 2
	OR 0x4A                         ;
	LD (HL), A                      ; Donc, Actif de type 0,1 ou 2 avec compteur = 10
	INC HL                          ; HL pointe sur les coordonnées de l'alien
	LD A, 72
	CALL rand                       ; Génère un nombre aléatoire entre 0 et 72 (non compris
	LD (HL), A                      ; X = rand(72)
	INC HL                          ; HL pointe sur les coordonnées de l'alien (y)
	LD (HL), 0                      ;
	LD A, 31
	LD (alien_clock), A             ; Horloge toujours à 31
	RET
alien_clock: db 0
; >====================================================================================================================<
; >==                 Déplacement des aliens selon leurs types et état                                               ==<
; >====================================================================================================================<
deplacement_aliens:
	LD B, max_nb_aliens
	LD HL, ennemis
.loop:
	LD A, (HL)                      ; Charge l'état de l'alien courant dans A
	AND 0x40                        ; Si ce bit est nul, on n'a pas à bouger cet alien :
	JR NZ, .est_actif                     ; On passe au prochain alien 
	LD A, (HL)
	AND 0x80                        ; Si bit actif, on est en explosion :
	JR NZ, .do_explosion
	JR .next
.est_actif:
	LD A, (HL)
	AND 0x30
	OR A                            ; Test si alien de type 0
	JR NZ, .type1
	PUSH HL
	PUSH BC
	CALL alien_depl1                ; Alien de type 0, dont premier type de déplacement
	POP BC
	POP HL
	JR .next
.type1:
	CP 0x10                         ; Alien de type 1 ?
	JR NZ, .type2
	PUSH HL
	PUSH BC
	CALL alien_depl2
	POP BC
	POP HL
	JR .next
.type2:
	CP 0x20
	JR NZ, .type3
	PUSH HL
	PUSH BC
	CALL alien_depl3
	POP BC
	POP HL
	JR .next
.type3:
	PUSH HL
	PUSH BC
	CALL alien_depl4
	POP BC
	POP HL
.next:
	PUSH HL
	PUSH BC
	CALL alien_state
	POP BC
	POP HL
	INC HL
	INC HL
	INC HL
	INC HL
	DJNZ .loop
	RET
.do_explosion:
	PUSH BC
	CALL draw_explosion
	POP BC
	LD A,(HL)
	DEC A
	LD (HL), A
	AND 0x0F
	JR NZ, .next
	PUSH BC
	CALL clear_teleport
	POP BC
	XOR A
	LD (HL), A                    ; Clear alien
	JR .next
; >====================================================================================================================<
; >== Teste la boîte englobante d'un alien avec le pixel représentant le missile                                     ==<
; >== En entrée :                                                                                                    ==<
; >==         DE = Coordonnée du missile sous la forme [0|y₇-y₁][y₀|x₆-x₀]                                           ==<
; >==         HL = Pointeur sur l'alien en train d'être traité                                                       ==<
; /==/ Remarque : Plus un goto qu'un gosub (pas de ret mais un jump après test)                                      ==/
; >====================================================================================================================<
test_bbox:
	;/===/ Second test rapide : regarde si leurs zones rectangulaire s'intersectent
	INC HL                          ; HL pointe maintenant sur la coordonnée x de l'alien (poids faible)
	LD A, (HL)                      ; Charge la coordonnée x min de l'alien
	AND 0x7F                        ; Pour enlever le y0 qui traîne là	
	LD C, A                         ; C contient le xₐ du bord haut-gauche de l'alien
	LD A, E                         ; Coordonnée xₘ du missile
	AND 0x7F                        ; Pour enlever le y₀ qui traîne là	
	CP C                            ; Compare leurs x respectifs :
	JP C, missile_collision.no_collision             ; Si xₘ < xₐ, le missile est à gauche de l'alien dont pas d'intersection, on passe au suivant
	CP 12                           ; Dans le cas où xₘ < 12
	JR NC, .ssub
	EX AF, AF'
	LD A, C
	ADD 12
	LD C, A
	EX AF, AF'
	JR .continue
.ssub:
	SUB 12                          ; Sinon on prend A = xₘ - 12 (Sprite 16 pixels mais en vérité 12 pixels d'affichage)
.continue
	CP C                            ; max(xₘ - 12,0) < xₐ ? Si oui, on a xₐ ≤ xₘ < xₐ + 12, donc collision possible
	JP NC, missile_collision.no_collision            ; Si xₘ ≥ xₐ + 12, le missile est à droite de l'alien, pas d'intersection, on passe au suivant
	; /===/ Cas où xₐ ≤ xₘ ≤ xₐ + 11. On doit dont faire un test sur les ordonnées :
	LD A, (HL)                      ; A = [y₀|x₆-x₀]
	INC HL                          ; Passage à l'octet de poids fort des coordonnées de l'alien
	RLA                             ; Pour le y₀ si il n'est pas nul, le mettre dans le carry
	LD A, (HL)                      ; A = [0|y₇-y₁]
	RLA                             ; A ← [y₇-y₁|y₀]
	LD C, A                         ; C  = yₐ de l'alien
	LD A, E                         ; A = [y₀|x₆-x₀] du missile
	RLA                             ; Pour le y₀ si il n'est pas nul, le mettre dans le carry
	LD A, D                         ; A = [0|y₇-y₁] du missile
	RLA                             ; A ← [y₇-y₁|y₀]
	CP C                            ; Compare leurs y respectifs
	JP C, missile_collision.no_collision             ; Si yₘ < yₐ, le missile est au dessus de l'alien (Rappel, y=0 est en haut), pas d'intersection
	CP 16   
	JR NC, .sub
	XOR A
	JR .comp
.sub:
	SUB 16                          ; A ← yₘ - 16
.comp:
	CP C                            ; max(yₘ - 16,0) < yₐ ?
	JP NC, missile_collision.no_collision            ; Si yₘ ≥ yₐ + 16, le missile est en dessous de l'alien
	; /==/ Fallthrough sur test_mask ?
	DEC HL
	JP missile_collision.do_collision 
; >====================================================================================================================<
; >==                                Détection d'une collision d'un missile avec les aliens                          ==<
; >== En entrée :                                                                                                    ==<
; >==      DE = Coordonnée du missile sous la forme [0|y₇-y₁][y₀|x₆-x₀]                                              ==<
; >== En sortie :                                                                                                    ==<
; >==      B  = Si B est nul, aucune collistion du missile avec un alien, sinon collision !                          ==<
; >====================================================================================================================<
missile_collision:
	LD HL, ennemis
	LD B, max_nb_aliens
; ## La première étape, après vérification de l'état de l'alien est de voir si le missile intersecte la boîte englobante
; ## de l'alien. Cela permet d'éliminer rapidement des candidats les aliens "éloignés" du missile.
.loop:
	PUSH BC                         ; > Sauvegarde BC
	PUSH HL                         ; > Sauvegarde HL
	; /===/ Premier test : est ce que l'alien est dans un état qui lui permet d'être touché par un missile
	LD A, (HL)                      ; Charge l'état de l'alien
	AND 0b01000000                  ; Si ce bit est nul, on ne traite pas car soit en explosion soit inactif
	JR Z, .no_collision
	JP test_bbox                    ; Test rapide de la bouding box de l'alien avec le missile
.no_collision
	POP HL                          ; < On restaure HL sur le début de l'état de l'alien
	POP BC                          ; < Retauration BC
	INC HL
	INC HL
	INC HL
	INC HL
	DJNZ .loop
	LD B, 0
	RET
.do_collision:
    ; ### La collision a lieu, il faut dont mettre à jour l'état de l'alien et du missile :
	POP HL                           ; < Restauration HL
	PUSH HL
	CALL clear_alien
	POP HL
	LD A, (HL)
    AND 0b00111111    
    ;OR  0b10000000
	;AND 0b00111111                    ; Pour l'instant, reset de l'alien
	LD (HL), A                       ; Màj état de l'alien
	;PUSH HL
	;CALL draw_explosion
	;POP HL
	POP BC                           ; < Restauration BC

	LD HL, score                     ; Incrémentation du score
	LD A, (HL)
	INC A
	LD (HL), A
	OR A
	JR NZ, .next                     ;
	INC HL                           ; 
	INC (HL)                         ; Fin incrémentation score
.next:
	LD B, 0xFF
	RET
; -------------------------- Tableau des ennemis ------------------------------
; Huits ennemis simultanés, chaque ennemi est défini par 4 octets :
; Octet 1   : [E1|E0|T1|T0|C3|C2|C1|C0] : E état (00 : Inactif, 01 : actif, 10 : En explosion, 11 : actif avec colon), C : compteur, T : Type (4 types possibles)
; Octet 2-3 : [0|y7|y6|y5|y4|y3|y2|y1][y0|x6|x5|x4|x3|x2|x1|x0]
; Octet 4   : [S1|S0|F5|F4|F3|F2|F1|F0] : S0 : 1 => droite, 0 => gauche, S1 : 
