; /=/===============================================================================================================/=/
; /=/                               Gestion des missiles dans la boucle de jeu                                      /=/
; /=/===============================================================================================================/=/
NB_MISSILES EQU max_nb_missiles ; Nombre de missiles à gérer
; >===================================================================================================================<
; >==                                                    Bouge missiles                                             ==<
; >===================================================================================================================<
bouge_missile:
	LD HL, vaisseau+2 ; Pointe sur l'état du premmier missile dans le tableau
	LD B, NB_MISSILES ; Six missiles à gérer en tout
.loop:
    PUSH BC
    PUSH HL
	LD A, (HL)        ; Charger le status du missile courant provenant du pods fort
    CP 128            ; Test en fait si le dernier bits est à 1 (le missile est actif)
	JR NC, .bouge     ; Si le missile est actif, affiche-le
.endloop
    POP HL
    POP BC
    INC HL
    INC HL
    DJNZ .loop
    RET 
.bouge:
    PUSH HL    ; On conserve cette adresse pointant sur l'octet de poid fort d'un missile pour la suite
    ; A ce niveau, A contient le y du missile courant avec le status
    ;/===/ On efface l'ancienne position
    AND 0x7F   ; On efface le bit de statut du missile pour le déplacer et l'afficher
    LD D, A    ; On range ce bit dans D
    DEC HL     ; On décrémente  HL pour lire la valeur de x du missile (et un bit de y)
    LD A, (HL) ; On stockage dans A
    LD L, A    ; et dans L
    LD H, D    ; et H pour le poids fort
    SRL H 
	RR  L 
	SRL H 
	RR  L             ; HL <- HL / 4 afin d'obtenir l'adresse de l'adresse mémoire du missile - 0x6000
    LD BC, SCREEN_ADDR
    ADD HL, BC        ; HL pointe sur la bonne adresse écran
    LD (HL), BACKGROUND      ; On met tout en bleu à cet endroit
    POP HL            ; On restaure HL qui repointe sur le missile courant (le poids fort pour être exact)
    LD D, (HL)        ; DE contient le statut et la coordonnée du missile
    LD A, D           ; 
    AND 0x7F          ; Faut enlever le bit 7 qui indique que le missile est actif
    JR NZ, .decremente ; Si le résultat est nul, c'est que le missile est en haut de l'écran
    ; On est en haut de l'écran, donc on désactive le missile :
    LD (HL), A ; NB : A contient déjà D avec le bit 7 en moins grâce au AND 0x7F
    JR .endloop
.decremente
    DEC HL        ; Pour que HL pointe sur le début du missile courant (sur le poids faible)
    LD E, (HL)    ; DE contient l'état du missile
    LD BC, HL     ; On sauvegarde le pointeur sur le missile courant dans BC
    EX DE, HL     ; DE maintenant pointe sur le début du missile courant et HL la position du missile
    LD DE, -128
    ADD HL, DE    ; Maintenant HL est positionné sur le pixel juste au dessus de la position précédente
    EX DE, HL     ; Et hop, HL vaut -128 et DE possède ses coordonnées et état
    LD HL, BC     ; HL répointe sur le missile courant
    LD (HL), DE   ; Et on reécrit sa nouvelle coordonnée
;/===/ On affiche le missile à sa nouvelle postion :
    PUSH HL           ; On sauvegarde le pointeur sur le missile courant contenu dans HL
    ; La nouvelle coordonnée est dans DE, donc pas besoin de la relire !
    LD A, D           ; et A maintenant contient y + status
    AND 0X7F          ; On élimine le status pour avoir la coordonnée y du missle
	LD D, A           ; Qu'on stocke dans D
    LD A, E
    AND 3             ; On garde le décalage pixel dans A
    LD B, A           ; Enfin plutôt dans B
    OR A
    LD A, 192         ; Point rouge tout à gauche du paquet de 4 pixels
    JR Z, .plot       ; Pas de décalage à calculer
.decal1:
    RRCA
    RRCA              ; Décalage de un pixel vers la droite
    DJNZ .decal2
    JR .plot
.decal2:
    RRCA
    RRCA              ; Décalage de deux pixels vers la droite
    DJNZ .decal3
    JR .plot
.decal3:
    RRCA
    RRCA             ; Décalage de trois pixels vers la droite
.plot:
    EX DE, HL        ; HL contient maintenant la position en pixel du missile
    SRL H 
	RR  L 
	SRL H 
	RR  L             ; HL <- HL / 4 afin d'obtenir l'adresse de l'adresse mémoire du missile - 0x6000
    LD BC, SCREEN_ADDR
    ADD HL, BC        ; HL pointe sur le bonne portion de la mémoire écran
    LD B, A           ; Sauvegarde de A dans B
    LD A, (HL)        ; On lit les quatres pixels à cette position
    OR B              ; On rajoute le pixel à ce paquet
    LD (HL), A        ; Qu'on reécrit en mémoire écran
    POP HL
    JR .endloop
; >===================================================================================================================<
; >==                                            Active un nouveau missile                                          ==<
; >== En entrée : A doit contenir en pixel la coordonnée x où démarre le missile                                    ==<
; >== L'idée ici est de parcourir la table des missiles pour trouver un missile non activé et l'initialiser         ==<
; >== Si tous les missiles sont activés, cette routine ne fera rien.                                                ==<
; >===================================================================================================================<
active_missile:
    LD HL, vaisseau+1 ; Pointe sur l'état du premmier missile dans le tableau
    LD B, NB_MISSILES
    EX AF, AF'    
.loop:
    INC HL
	LD A, (HL)        ; Charger le status du missile courant
    AND 128           ; Vérifie si le missile est actif (bit 7 à 1)
    JR Z, .active       ; Si il est non activé, on va le faire
    INC HL
    DJNZ .loop  
    RET 
.active:
    EX AF, AF'
    AND 0x7F
    LD (HL), 87+128    ; Active le missile (128) à l'ordonnée y=2*87=174 pixel
    DEC HL
    LD (HL), A         ; et à l'abcisse x donné par A (et on met y0 à zéro puisque ordonnée paire)
    RET
; >===================================================================================================================<
; >== Test tous les missiles pour voir si ils impactent un alien
; >===================================================================================================================<
test_missiles:
    LD HL, vaisseau+1 ; Pointe sur l'état du premmier missile dans le tableau
    LD B, NB_MISSILES
.loop:
    INC HL                       ; HL pointe sur l'octet de poids fort des coordonnées du missile (m+1)
    LD A, (HL)
    BIT 7, A                     ; Le missile est-il activé ?
    JR Z, .next                  ; Si missile non activé, on va au suivant :
    AND 0x7F                     ; On récupère le y du missile
    LD D, A                      ; On le charge dans D
    PUSH BC                      ; > Sauvegarde BC
    PUSH HL                      ; > Sauvegarde HL quand il est sur l'octet où il y a l'état (m+1)
    DEC HL                       ; Avant de le décrémenter pour qu'il pointe sur le x (m)
    LD E, (HL)                   ; On charge le x dans E
    PUSH DE                      ; > Sauvegarde de DE
    CALL missile_collision
    LD A, B                      ; Test si la collision a eu lieu
    OR A
    JR Z, .not_hit               ; Non, on passe au suivant
    POP DE                       ; < Restauration de DE
    POP HL                       ; < Restauration de HL pointant sur l'octet contenant l'état (m+1)
    LD A, (HL)
    AND 0x7F                     ; On efface l'activité du missile
    LD (HL), A
    XOR A
    LD (fire_delay), A

    PUSH HL    ; > On conserve cette adresse pointant sur l'octet de poid fort d'un missile pour la suite (m+1)
    LD L, E    ; et dans L
    LD H, D    ; et H pour le poids fort
    SRL H 
	RR  L 
	SRL H 
	RR  L             ; HL <- HL / 4 afin d'obtenir l'adresse de l'adresse mémoire du missile - 0x6000
    LD BC, SCREEN_ADDR
    ADD HL, BC        ; HL pointe sur la bonne adresse écran
    LD (HL), BACKGROUND      ; On met tout en bleu à cet endroit
    POP HL                   ; < Restauration HL (m+1)
    POP BC                   ; < Restauration BC
    JR .next                 ; Du coup, un seul incrément suffit pour aller au prochain missile
.not_hit:
    POP DE                   ; < Restauration DE
    POP HL                   ; < Restauration HL (m+1)
    POP BC                   ; < Restauration BC
.next:
    INC HL
    DJNZ .loop
    RET
; octets 2-13   : 6*[A|y7|y6|y5|y4|y3|y2|y1][y0|x6|x5|x4|x3|x2|x1|x0] où A missile activé, 0<=y<=255, 0<=x<=127
