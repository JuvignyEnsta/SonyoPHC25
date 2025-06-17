;# ################################################################################################################### #
;#                                                Gestion du jeu en lui-même                                           #
;## ################################################################################################################# ##
; >====================================================================================================================<
; >== Affiche les colons à l'initialisation du jeu                                                                   ==<
; >====================================================================================================================<
affiche_colons:
	LD HL, pos_colons_row1
	LD B,  max_nb_colons/2
.loop1:
	PUSH HL
	PUSH BC
	LD   DE, sprites8x16
	CALL draw_image_8x16
	POP BC
	POP HL
    INC HL
    INC HL
	DJNZ .loop1
	LD HL, pos_colons_row2
	LD B,  max_nb_colons/2
.loop2:
	PUSH HL
	PUSH BC
	LD   DE, sprites8x16
	CALL draw_image_8x16
	POP BC
	POP HL
    INC HL
    INC HL
	DJNZ .loop2
    RET
; >====================================================================================================================<
; >== Enlève un colon de l'écran et décrémente le compteur de colon                                                  ==<
; >====================================================================================================================<
enleve_colon:
    LD HL, nb_vie_colon
    LD A, (HL)
    DEC A
    LD (HL), A
    AND 0x0F 
    CP 5
    JR NC, .second_row
    ; Le nombre de colons restant est < 5, donc le colon a enlevé est dans la première rangée
    LD HL, pos_colons_row1
.efface:
    OR A                     ; Nombre de colons restant est nul ?
    JP Z, clear_image_8x16   ; On efface le colon restant
    LD B, A
.loop1:
    INC HL                 ; Rajoute 2 à HL. Mieux que ADD HL, DE car sinon faut faire LD DE, 2 (10 cycles) + ADD HL, DE (11 cycles par boucle)     
    INC HL                 ; Ici 12 cycles par iteration mais pas d'overhead à cause de LD DE, 2 donc au total plus rapide (max 4 iterations)
    DJNZ .loop1
    JP clear_image_8x16    ; On profitera du RET de clear_image_8x16 comme cela, et moins de cycles :-)
.second_row:
    ; Le nombre de colon restant est >=  5 donc le colon a enlevé est dans la seconde rangée
    SUB 5                 ; Cinq colons non effacés sur la première ligne
    LD HL, pos_colons_row2; Pour afficher sur la seconde ligne
    JP .efface            ; Même code que pour la 1ere ligne mais avec un HL différent
; >====================================================================================================================<
; >== Affiche les vies à l'écran au début du jeu                                                                     ==<
; >====================================================================================================================<
affiche_vies:
	LD B , 3 
	LD HL, VIE_SCR_ADDR
.loop:
	PUSH HL 
	PUSH BC 
	CALL draw_spaceship
	POP BC 
	POP HL
	LD DE, 13
	ADD HL, DE 
	DJNZ .loop
    RET
; >====================================================================================================================<
; >== Décrémente le nombre de vie et supprime un vaisseau du nombre de vie à l'écran                                 ==<
; >====================================================================================================================<
supprime_vie:
    LD HL, nb_vie_colon
    LD A, (HL)
    SUB 16                         ; Enlève une vie (si si ^^) car deuxième moitié de l'octet qui contient le nb de vie et de colons
    LD (HL), A                     ; Met à jour la valeur dans la mémoire
    AND 0xF0                       ; Masquage pour ne avoir que la vie
    LD HL, VIE_SCR_ADDR
    JP Z, clear_ship               ; Si vie == 0 on efface le dernier vaisseau
    LD DE, 13                      ; Pour l'incrément
    OR A                           ; Clear C flags
    RRA
    RRA
    RRA
    RRA
    LD B, A
.loop:
    ADD HL, DE                     ; On incrémente pour la prochaine position de vie
    DJNZ .loop
    SRL H
    RR L 
    SRL H
    RR L 
    LD BC, SCREEN_ADDR
    ADD HL, BC
    JP clear_ship
; >====================================================================================================================<
; >== Affiche les trois bombes au début du jeu                                                                       ==<
; >====================================================================================================================<
affiche_bombe:
	LD HL, BOMBS_SCR_ADDR
	LD B , max_bombes
.loop4:
	LD DE, sprites8x16 + BOMB_SPRT_IND      ; DE pointe sur le sprite bombe
	PUSH HL 
	PUSH BC 
	CALL draw_image_8x16
	POP BC 
	POP HL 
    INC HL
    INC HL                                  ; HL = HL + 2 (2 caractères plus loin)
	DJNZ .loop4
; >====================================================================================================================<
; >== Utilise une bombe                                                                                              ==<
; >====================================================================================================================<
utilise_bombe:
    LD HL, vaisseau+13
    LD A, (HL)                              ; Lit nombre de bombes restantes + bombe active ou non (?) + compteur
    AND BOMB_CNTER_MASK                     ; Masque pour ne garder que le nombre de bombes restantes
    RET Z
    ; ### On met tous les aliens actifs en état d'explosion :
    LD HL, ennemis
    LD B, max_nb_aliens
.loop_alien:
    LD A, (HL)
    AND IS_ACTIVE
    JR Z, .next_alien
    LD A, (HL)
    BIT 7, A
    JR Z, .destroy_alien
.destroy_alien:
    LD A, (HL)
    AND 0b00111111    
    ;OR  0b10000000
    LD (HL), A
    PUSH HL
	CALL clear_alien
	POP HL
.next_alien:
    INC HL
    INC HL
    INC HL
    INC HL
    DJNZ .loop_alien

    LD HL, vaisseau+13
    LD A, (HL)                              ; Lit nombre de bombes restantes + bombe active ou non (?) + compteur
    SUB 64
    LD (HL), A                              ; Décrémente le nombre de bombes

    AND BOMB_CNTER_MASK                     ; Masque pour ne garder que le nombre de bombes restantes
    LD HL, BOMBS_SCR_ADDR
    JP Z, clear_image_8x16                  ; On efface la bombe restante
.loop:
    INC HL
    INC HL
    SUB 64
    JR NZ, .loop
    JP clear_image_8x16
; >====================================================================================================================<
; >== Efface tous les aliens                                                                                         ==<
; >====================================================================================================================<
clear_aliens:
    ; ### On met tous les aliens actifs en état d'explosion :
    LD HL, ennemis
    LD B, max_nb_aliens
.loop_alien:
    LD A, (HL)
    AND IS_ACTIVE
    JR Z, .next_alien
    PUSH HL
    PUSH BC
    CALL clear_alien
    POP BC
    POP HL
    XOR A
    LD (HL), A
.next_alien:
    INC HL
    INC HL
    INC HL
    INC HL
    DJNZ .loop_alien
    RET
; >====================================================================================================================<
; >== Fonction qui initialise les variables du jeu pour une nouvelle partie                                          ==<
; >====================================================================================================================<
init_game:
	LD A, SPACESHIP_X_DEB
	LD (vaisseau), A ; Vaisseau en état ok, x = 52
	memset vaisseau+1, 12, 0 ; 6 missiles  désactivés
	LD A, 0xC0
	LD (vaisseau+13), A ; 3 bombes restantes, compteur explosion vaisseau = 0
	LD A, 0x3A
	LD (nb_vie_colon), A ; 3 vies, 10 colons
	memset ennemis, 32, 0 ; 8 ennemis (inactifs)
	XOR A                 ; A = 0
	LD (score  ), A ; Score à 0
	LD (score+1), A; Score à 0
    LD (fire_delay), A
    LD (bomb_delay), A
    LD (alien_clock), A
	RET
; >====================================================================================================================<
; >== Affiche les high-scores à l'écran                                                                              ==<
; >====================================================================================================================<
display_highscore:
	LD HL, 0x6000 + 78*32 + 10
	LD A, 0
	LD B, 12
.horizontal_line1:
	LD (HL), A
	INC HL
	DJNZ .horizontal_line1
	set_position_screen_3 HIGHSCORE_X/4, HIGHSCORE_Y
	LD HL, highscore_txt
	CALL print
	LD HL, 0x6000 + 88*32 + 10
	LD A, 0
	LD B, 12
.horizontal_line2:
	LD (HL), A
	INC HL
	DJNZ .horizontal_line2

    LD HL, highscore
    LD DE, buf_hg
    LD A, (HL)
    LD (DE), A
    INC DE
    INC DE
    INC HL
    LD A, (HL)
    LD (DE), A
    INC DE
    INC DE
    INC HL
    LD A, (HL)
    LD (DE), A

    LD HL, buf_hg
    set_position_screen_3 (TABHIGHSCORE_X/4), TABHIGHSCORE_Y
    CALL print
    LD HL, highscore+3
    LD DE, (HL)
    EX DE, HL
    CALL convert_to_digits
	set_position_screen_3 (TABHIGHSCORE_X/4 + 7), TABHIGHSCORE_Y
	CALL print

    LD HL, highscore + 5
    LD DE, buf_hg
    LD A, (HL)
    LD (DE), A
    INC DE
    INC DE
    INC HL
    LD A, (HL)
    LD (DE), A
    INC DE
    INC DE
    INC HL
    LD A, (HL)
    LD (DE), A

    LD HL, buf_hg
    set_position_screen_3 (TABHIGHSCORE_X/4), (TABHIGHSCORE_Y + 16)
    CALL print
    LD HL, highscore+8
    LD DE, (HL)
    EX DE, HL
    CALL convert_to_digits
	set_position_screen_3 (TABHIGHSCORE_X/4 + 7), (TABHIGHSCORE_Y + 16)
	CALL print

    LD HL, highscore + 10
    LD DE, buf_hg
    LD A, (HL)
    LD (DE), A
    INC DE
    INC DE
    INC HL
    LD A, (HL)
    LD (DE), A
    INC DE
    INC DE
    INC HL
    LD A, (HL)
    LD (DE), A

    LD HL, buf_hg
    set_position_screen_3 (TABHIGHSCORE_X/4), (TABHIGHSCORE_Y + 32)
    CALL print
    LD HL, highscore+13
    LD DE, (HL)
    EX DE, HL
    CALL convert_to_digits
	set_position_screen_3 (TABHIGHSCORE_X/4 + 7), (TABHIGHSCORE_Y + 32)
	CALL print
    RET
buf_hg: db 0xFF, '.', 0xFF, '.', 0xFF, 0x00
; >====================================================================================================================<
; >== Attendre que le joueur sélectionne une lettre donnée                                                           ==<
; >== En entrée :                                                                                                    ==<
; >==      HL pointe sur le caractère à sélectionner                                                                 ==<
; >==      DE pointe sur l'adresse écran où ce caractère sera affiché et sélectionné                                 ==<
; >====================================================================================================================<
choose_car:
    LD IX, DE
    LD A, FLASH_DELAY
    LD (flash_counter), A
.beg_loop
    LD A, (HL)
    SUB 0x20     ; On enlève 20H pour obtenir l'index du caractère dans la table de caractères
    PUSH HL                 ; > Sauvegarde HL
    CALL put_char           ; Note : IX est sauvegardé par put_char
    POP  HL                 ; < Restaure HL
.wait_key:
    CALL wait_vsync
    IN A, (134)             ; Touche o (gauche) pressée ?
    CP 0xFF
    JR Z, .next1            ; Non, on passe au test suivant :
.loop1:
    IN A, (134)             ; Touche o (gauche) relachée ?
    CP 0xFF
    JR NZ, .loop1
    LD A, (HL)
    CP 32                   ; Premier caractère ASCII affichable ?
    JR C, .next1            ; On ne décrémente pas et on teste les autres touches
    DEC A
    LD (HL),A
    JR .beg_loop
.next1:
    IN A, (132)             ; Touche p (droite) pressée ?
    CP 0xFF
    JR Z, .next2 
.loop2:
    IN A, (132)
    CP 0XFF
    JR NZ, .loop2
    LD A, (HL)
    CP 127      
    JR NC, .next2           ; On n'incrémente pas car au dernier caractère ASCII affichable.
    INC A
    LD (HL), A
    JR .beg_loop
.next2:
    IN A, 131  ; Lecture du port 131 (clavier) où l'on attend l'appui sur la touche espace
	BIT 7,A    ; Teste si la touche espace est pressée
	JR NZ, .next3
.wait_loop:    ; Et on attend que la touche espace soit relachée !
	IN A, 131 
	BIT 7, A
	JR Z, .wait_loop
    LD A, (HL)
    SUB 0x20     ; On enlève 20H pour obtenir l'index du caractère dans la table de caractères
    PUSH HL                 ; > Sauvegarde HL
    CALL put_char           ; Note : IX est sauvegardé par put_char
    POP  HL                 ; < Restaure HL
    RET 
.next3
    CALL wait_vsync
    LD A, (flash_counter)
    DEC A 
    JR Z, .do_effet
    LD (flash_counter), A
    JR .wait_key
.do_effet:
    LD A, FLASH_DELAY
    LD (flash_counter), A
    PUSH DE                 ; > Sauvegarde DE
    PUSH IX                 ; > Sauvegarde IX
    LD B, 8
    LD DE, 32
.effet:
    LD A, (IX)
    CPL
    LD (IX), A
    ADD IX, DE
    DJNZ .effet
    POP IX                  ; < Restaure IX
    POP DE                  ; < Restaure DE
    JP .wait_key
flash_counter: db 0xFF
; >====================================================================================================================<
; >== Demande au joueur de rentrer à l'aide des touches O et P ses initiales pour le High-score                      ==<
; >== En entrée :                                                                                                    ==<
; >==        HL : Pointe sur le premier caractère à rentrer                                                          ==<
; >==         B : Position du high-score dans le tableau                                                             ==<
; >====================================================================================================================<
enter_name:
    LD DE, SCREEN_ADDR + (TABHIGHSCORE_X/4) + 32 * (TABHIGHSCORE_Y)
    LD A, B
    OR A
    JR Z, .fin_pos
.loop_pos
    INC D
    INC D                     ; On passe deux lignes au dessus pour se positionner sur le bon highscore
    DJNZ .loop_pos
.fin_pos:                     ; DE contient la position de highscore sur l'écran
    PUSH HL
    PUSH DE
    CALL choose_car
    POP DE
    POP HL
    INC DE 
    INC DE
    INC HL
    PUSH HL
    PUSH DE
    CALL choose_car
    POP DE
    POP HL
    INC DE
    INC DE
    INC HL
    PUSH HL
    PUSH DE
    CALL choose_car
    POP DE
    POP HL
    RET
; >====================================================================================================================<
; >== Mise à jour des highscores                                                                                     ==<
; >====================================================================================================================<
update_highscore:
    LD HL, highscore + 13                ; Pointe sur le dernier score du tableau
    LD DE, (score)                       ; Charge le score actuel dans DE
    LD B, 3                              ; Compare le score actuel avec les 3 meilleurs scores
.loop:
    PUSH HL                              ; > Sauvegarde la valeur de HL
    INC HL                               ; Pour pointer sur le poids fort du highscore
    LD A, (HL)                           ; Qu'on charge dans A
    CP D                                 ; Comparaison avec l'octet de poids fort du score actuel
    JR C, .end_loop                      ; Si le highscore est plus petit strictement que le score, on passe au prochain highscore
    ; L'octet de poids fort est donc plus grand où égal à celui du score actuel
    JR NZ, .break_loop                   ; Poids fort différent, donc highscore > score, on sort de la boucle
    ; Poids forts égaux, on doit tester les pods faibles :
    DEC HL                               ; On pointe sur l'octet de poids faible du highscore
    LD A, (HL)
    CP E                                 ; qu'on compare avec l'octet de poids faible du score
    JR NC, .break_loop                   ; Si le highscore est plus grand ou égal au score actuel, on sort de la boucle
.end_loop:
    POP HL                               ; < Restaure position HL
    DEC HL                               ; On décrémente cinq fois pour pointer sur le prochain highscore
    DEC HL
    DEC HL
    DEC HL
    DEC HL
    DJNZ .loop
    JR .continue                        ; Si j'arrive ici, c'est que j'ai le highscore suprême !
.break_loop:                            ; A la sortie de la boucle, si B = 3, rien à faire, sinon, rentrer nouveau highscore
    POP HL                              ; < Restaure HL
.continue:
    LD A, B
    CP 3                                ; A = B = 3 ?
    JR Z, .end_update                   ; Oui, pas besoin de mise à jour
    CP 2                                ; Dernier highscore. Pas besoin de déplacement mémoire
    JP Z, .update
    ; Faut déplacer les highscores pour la màj
    PUSH DE
    PUSH HL
    OR A
    PUSH BC
    JR NZ, .move1
    ; Ici on a le vrai highscore :    
    LD BC, 10
    LD HL, highscore+9
    LD DE, highscore+14
    LDDR
    JR .end_move
.move1:
    LD BC, 5
    LD HL, highscore+5
    LD DE, highscore+10
    LDIR
.end_move    
    POP BC
    POP HL
    POP DE
.update:    
    INC HL
    INC HL
    INC HL
    INC HL
    INC HL       ; Pour revenir sur le bon highscore à modifier
    INC HL
    LD (HL), D
    DEC HL
    LD (HL), E
    DEC HL
    DEC HL
    DEC HL
    PUSH HL
    PUSH BC
    CALL display_highscore
    POP BC
    POP HL
    JP enter_name
.end_update:
    RET
; >====================================================================================================================<
; >== Initialisation et boucle de jeu                                                                                ==<
; >====================================================================================================================<
game:
	CALL init_game 
	LD A, BACKGROUND
	CALL cls
	CALL draw_column
	LD HL, SCORE_TXT
	set_position_screen_3 25,1
	CALL print
	; Affichage des 10 colons
	CALL affiche_colons
	; Affichage des vies
	CALL affiche_vies
	; Affichage des 3 bombes :
	CALL affiche_bombe

    ; ! Pour déboguer le déplacement de l'alien de type 4
    ;;LD HL, score
    ;LD A, 128
    ;ld (HL), A

    ; Affiche le joueur :
    LD HL, 128*SPACESHIP_Y + SPACESHIP_X_DEB
    CALL draw_spaceship
.game_loop:
    CALL wait_vsync                        ; Synchronisation avec le rayon de balayage
    CALL deplacement_aliens                ; Déplacement des aliens actifs
    CALL bouge_missile                     ; Gestion des  tirs faits par le joueur
	CALL player_action                     ; Affichage et gestion du joueur

    CALL test_missiles                     ; Détection des missiles qui touchent des aliens
    CALL generate_alien                    ; On génère un ennemi (si possible)
    CALL ship_collision                    ; Détection collision alien avec vaisseau
    ; Màj du score
    LD HL, (score)
    CALL convert_to_digits
	set_position_screen_3 25, 12
	CALL print

.wait2:
	IN A, (0x40)
	AND   0x10
	JR NZ, .wait2
    ; On doit maintenant voir si le jeu doit être quitté ou non (plus de vie ou de colon)
    LD HL, nb_vie_colon
    LD A, (HL)
    AND 0xF0
    JR Z, .end_game
    LD A, (HL)
    AND 0x0F
    JR Z, .end_game
    JR .game_loop
.end_game
	LD A, BACKGROUND
	CALL cls
    ; On va comparer le score obtenu par le joueur avec les highscores actuels :
    CALL display_highscore
    CALL update_highscore
	RET
