; /=/################################################################################################################/=/
; /=/## Librairie de gestion des sprites de divers formats qui contient les divers affichages en mode 3            ##/=/
; /=/################################################################################################################/=/
; >====================================================================================================================<
; >== Renvoie la couleur d'un pixel de coordonnée (x,y) lu dans la mémoire vidéo                                     ==<
; >== En entrée :                                                                                                    ==<
; >==      HL = [0|y7-y1][y0|x6-x0]                                                                                  ==<
; >== En sortie :                                                                                                    ==<
; >==       A = couleur du pixel (valeurs entre 0 et 3)                                                              ==<
; >====================================================================================================================<
test_pixel:
    LD A, L
    AND 3             ; On garde le décalage pixel dans A
    LD B, A           ; et B pour compter
    LD D, A
    OR A
    LD A, 192         ; Un masque = 3 tout à fait à droite 
    JR Z, .plot       ; Pas de décalage à calculer (A = 0 pour le décalage)
.decal1:
    RRCA
    RRCA              ; Décalage de un pixel vers la droite
    DJNZ .decal1
.plot:
    SRL H 
	RR  L 
	SRL H 
	RR  L             ; HL <- HL / 4 afin d'obtenir l'adresse de l'adresse mémoire du pixel - 0x6000
    LD BC, SCREEN_ADDR
    ADD HL, BC        ; HL pointe sur le bonne portion de la mémoire écran
    LD E, A
    LD A, (HL)        ; On lit les quatres pixels à cette position
    AND E              ; On teste le bon pixel de ce paquet
    OR A
    RET Z
    ; Sinon, faut le redécaler vers la gauche
    EX AF, AF'
    LD A, D
    OR A        ; Décalage nul ?
    JR NZ, .decalage
    EX AF, AF'
    RET
.decalage:
    EX AF, AF'
    LD B, D
.recal1:
    RLCA 
    RLCA
    DJNZ .recal1
    RET
; >====================================================================================================================<
; >== Fonction pour dessiner une image de 8x16 pixels à l'écran à partir d'une adresse écran et un n° de sprite      ==<
; >== En entrée :                                                                                                    ==<
; >==        HL = adresse de l'écran où dessiner le sprite                                                           ==<
; >==        DE = adresse du sprite dans la table de sprites                                                         ==<
; >====================================================================================================================<
draw_image_8x16:
	LD B, 16           ; Nombre de lignes du sprite
    LD C, 31
.loop:
	LD A, (DE)         ; Lecture du premier octet du sprite
	LD (HL), A         ; On l'affiche à l'écran
	INC HL             ; On passe au pixel suivant
	INC DE			   ; On passe au prochain octet du sprite
	LD A, (DE)         ; Lecture du deuxième octet du sprite
	LD (HL), A         ; On l'affiche à l'écran

    LD A, C            ; Nombre d'octets à sauter pour arriver à la prochaine ligne
    ADD L              ; On rajoute à l'adresse écran (ici sur l'octet de poids faible)
    LD L, A            ; 
    JP NC, .no_carry:   ; Et si il y a une retenue
    INC H              ; On incrémente l'octet de poids fort (Remarque : le code n'est pas relocalisable pour optimisation)
.no_carry:
	INC DE             ; On passe au prochain octet du sprite
	DJNZ .loop       ; On boucle jusqu'à afficher les 16 lignes du sprite
	RET
; >====================================================================================================================<
; >== Efface une image de taille 8x16 pixels sur l'écran.                                                            ==<
; >== En entrée :                                                                                                    ==<
; >==        HL = adresse de l'écran où effacer le sprite                                                            ==<
; >====================================================================================================================<
clear_image_8x16:
	LD B, 16           ; Nombre de lignes du sprite
    LD C, 31
    LD D, BACKGROUND
.loop:
	LD (HL), D         ; On l'affiche à l'écran
	INC HL             ; On passe au pixel suivant
	LD (HL), D         ; On l'affiche à l'écran

    LD A, C            ; Nombre d'octets à sauter pour arriver à la prochaine ligne
    ADD L              ; On rajoute à l'adresse écran (ici sur l'octet de poids faible)
    LD L, A            ; 
    JP NC, .no_carry:   ; Et si il y a une retenue
    INC H              ; On incrémente l'octet de poids fort (Remarque : le code n'est pas relocalisable pour optimisation)
.no_carry:
	DJNZ .loop       ; On boucle jusqu'à afficher les 16 lignes du sprite
	RET
; >====================================================================================================================<
; >== Calcule l'adresse du masque associé à un alien en fonction de son numéro et de son abcisse en pixel            ==<
; >== En entrée :                                                                                                    ==<
; >==       HL = début de l'état de l'alien considéré                                                                ==<
; >== En sortie :                                                                                                    ==<
; >==       BC = Décalage par rapport au masque/sprite de l'alien                                                    ==<
; /==/ Note : HL est automatiquement sauvegardé                                                                      ==<
; >====================================================================================================================<
mask_decal:
    PUSH HL
    LD A, (HL)               ; On récupère l'état de l'alien A = [E₁E₀T₁T₀C₃C₂C₁C₀] où E est l'état, T le type d'Alien
    RRA                      ; A ←  [XE₁E₀T₁T₀C₃C₂C₁]
    RRA                      ; A ←  [XXE₁E₀T₁T₀C₃C₂]
    RRA                      ; A ←  [XXXE₁E₀T₁T₀C₃]
    RRA                      ; A ←  [XXXXE₁E₀T₁T₀]
    AND 0x03                 ; A contient maintenant le n° du type d'alien : A ← [000000T₁T₀]
    LD C, 0
    LD B, A                  ; D ← D + A (revient à faire DE = DE + 256 * A)
    ; /===/ Il reste à calculer le décalage par rapport à x mod 4 (x abcisse de l'alien)
    INC HL
    LD A, (HL)               ; A = [y₀|x₆-x₀]
    AND 0x03                 ; A ← xₐ mod 3
    RRCA                     ; Deux décalages cycliques vers la droite
    RRCA                     ; ce qui revient à multiplier A par 64
    ADD C                    ; Addition de DE par A
    LD C, A                  ; 
    JR NC, .not_carry
    INC B                    ; Fin addition
.not_carry:                  ; DE contient : mask + 256 * n° sprite + 64 * (x mod 3)
    POP HL
    RET
; >====================================================================================================================<
; >== Efface un sprite 16x16 de l'écran en utilisant le masque associé                                               ==<
; >== En entrée :              ;                                                                                     ==<
; >==        HL = adresse vidéo où commencer à afficher le sprite                                                    ==<
; >==        BC = décalage en octet pour trouver l'adresse du masque ou du sprite                                    ==<
; >====================================================================================================================<
clear_sprite:
    ; /==/ Application du masque
    EX DE, HL       ; Echange DE avec HL pour pouvoir calculer l'adresse du masque à appliquer
    LD HL, mask     ; Adresse de base des masques
    ADD HL, BC      ; On rajoute le décalage pour pointé sur le bon masque
    EX DE, HL       ; DE pointe maintenant sur le bon masque
    LD B, 16           ; Nombre de lignes du sprite
.loop:
    LD A, (DE)         ; Prend le masque
    AND (HL)           ; On applique le masque au quatre pixels
    LD C, A            ; Sauvegarde dans C
    LD A, (DE)         ; On reprend le masque 
    CPL                ; On inverse les bits  
    AND BACKGROUND     ; On remplace la partie occupée par le sprite par le fond de l'écran
    OR C               ; On combine avec les pixels sauvés par les masques
    LD (HL), A         ; On enregistre le résultat dans la vidéo
    INC HL             ; pixels suivants
    INC DE             ; partie du masque suivant
    LD A, (DE)         ; Prend le masque
    AND (HL)           ; On applique le masque au quatre pixels
    LD C, A            ; Sauvegarde dans C
    LD A, (DE)         ; On reprend le masque 
    CPL                ; On inverse les bits  
    AND BACKGROUND     ; On remplace la partie occupée par le sprite par le fond de l'écran
    OR C               ; On combine avec les pixels sauvés par les masques
    LD (HL), A         ; On enregistre le résultat dans la vidéo
    INC HL             ; pixels suivants
    INC DE             ; partie du masque suivant
    LD A, (DE)         ; Prend le masque
    AND (HL)           ; On applique le masque au quatre pixels
    LD C, A            ; Sauvegarde dans C
    LD A, (DE)         ; On reprend le masque 
    CPL                ; On inverse les bits  
    AND BACKGROUND     ; On remplace la partie occupée par le sprite par le fond de l'écran
    OR C               ; On combine avec les pixels sauvés par les masques
    LD (HL), A         ; On enregistre le résultat dans la vidéo
    INC HL             ; pixels suivants
    INC DE             ; partie du masque suivant
    LD A, (DE)         ; Prend le masque
    AND (HL)           ; On applique le masque au quatre pixels
    LD C, A            ; Sauvegarde dans C
    LD A, (DE)         ; On reprend le masque 
    CPL                ; On inverse les bits  
    AND BACKGROUND     ; On remplace la partie occupée par le sprite par le fond de l'écran
    OR C               ; On combine avec les pixels sauvés par les masques
    LD (HL), A         ; On enregistre le résultat dans la vidéo
    LD A, 29           ; 
    ADD L
    LD L, A
    JR NC, .no_carry
    INC H
.no_carry:
    INC DE             ; partie du masque suivant
    DJNZ .loop
    RET
; >====================================================================================================================<
; >== Affiche un sprite à l'écran en appliquant le masque puis afficher le sprite lui-même                           ==<
; >== En entrée :                                                                                                    ==<
; >==        HL = adresse vidéo où commencer à afficher le sprite                                                    ==<
; >==        BC = décalage en octet pour trouver l'adresse du masque ou du sprite                                    ==<
; >====================================================================================================================<
draw_sprite:
    ; /==/ Application du masque
    EX DE, HL       ; Echange DE avec HL pour pouvoir calculer l'adresse du masque à appliquer
    LD HL, mask     ; Adresse de base des masques
    ADD HL, BC      ; On rajoute le décalage pour pointé sur le bon masque
    EX DE, HL       ; DE pointe maintenant sur le bon masque
    PUSH BC
    PUSH HL
    LD B, 16
    LD C, 29
.loop_mask:
    LD A, (DE)        ; On lit le masque
    AND (HL)          ; On applique le masque au sprite
    LD (HL), A
    INC HL
    INC DE
    LD A, (DE)        ; On lit le masque
    AND (HL)          ; On applique le masque au sprite
    LD (HL), A
    INC HL
    INC DE
    LD A, (DE)        ; On lit le masque
    AND (HL)          ; On applique le masque au sprite
    LD (HL), A
    INC HL
    INC DE
    LD A, (DE)        ; On lit le masque
    AND (HL)          ; On applique le masque au sprite
    LD (HL), A
    LD A, C
    ADD L
    LD L, A
    JR  NC, .no_carry1
    INC H
.no_carry1
    INC DE
    DJNZ .loop_mask
    ;/==/ Fin application masque. On affiche maintenant le sprite
    POP HL
    POP BC  
    EX DE, HL             ; Echange DE avec HL pour pouvoir calculer l'adresse du masque à appliquer
    LD HL, alien_sprite   ; Adresse de base des sprites alien
    ADD HL, BC            ; On rajoute le décalage pour pointé sur le bon sprite
    EX DE, HL             ; DE pointe maintenant sur le bon sprite
    LD B, 16
    LD C, 29
.loop_sprite:
    LD A, (DE)        ; On lit le sprite
    OR (HL)          ; On applique le sprite sur la zone déjà masquée
    LD (HL), A
    INC HL
    INC DE
    LD A, (DE)        ; On lit le sprite
    OR (HL)          ; On applique le sprite sur la zone déjà masquée
    LD (HL), A
    INC HL
    INC DE
    LD A, (DE)        ; On lit le sprite
    OR (HL)          ; On applique le sprite sur la zone déjà masquée
    LD (HL), A
    INC HL
    INC DE
    LD A, (DE)        ; On lit le masque
    OR (HL)          ; On applique le sprite sur la zone déjà masquée
    LD (HL), A
    LD A, C
    ADD L
    LD L, A
    JR  NC, .no_carry2
    INC H
.no_carry2
    INC DE
    DJNZ .loop_sprite
    RET 

