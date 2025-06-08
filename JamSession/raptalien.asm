	include "macros.asm"
SCREEN_ADDR:	EQU	0x6000
SCORE_X: 	    EQU 104
SCORE_MSG_Y:    EQU 4
SCORE_MSG_ADDR: EQU SCREEN_ADDR + (SCORE_X>>2)+32*SCORE_MSG_Y

	ORG 0XC009
start:
    set_screen SCREEN_3_MASK, SCREEN_3_SET
	LD A, 170
	CALL cls
	LD HL, compressed_sprites
	LD DE, sprites16x16
	CALL dzx0_standard
	LD HL, compressed_fonte
	LD DE, fonte
	CALL dzx0_standard
	LD HL, PREAMBLE
	set_position_screen_3 4, 90
	CALL print
	LD HL, compressed_mask
	LD DE, mask
	CALL dzx0_standard
	CALL presentation
	DI
	CALL affiche_joueur
.loop:
	CALL wait_vsync
	CALL player_action
	CALL bouge_missile
	CALL convert_to_digits
	set_position_screen_3 25, 12
	CALL print
	JP .loop
	RET
; =============================================================================
; == Sous programme de  multiplication  entière  d'un  nombre  16 bits par un = 
; == nombre 8 bits.                                                           =
; == En entrée : DE contient le multiplicande  (16 bits)                      =
; ==              A contient le multiplicateur (8 bits )                      =
; == En sortie : HL contient le résultat de la multiplication (16 bits)       =
; =============================================================================
mult_16x8:
	LD HL, 0
	LD  B, 8
H0: ADD HL,HL
	SLA A
	JR NC, H1 
	ADD HL,DE
H1: DJNZ H0
	RET
; =============================================================================
; == Sous programmes de génération de nombres pseudo-aléatoires               =
; =============================================================================
; == Graine aléaoire                                                          =
; =============================================================================
SEED: db $00
; =============================================================================
; == Initialisation du générateur aléatoire                                   =
; =============================================================================
init_rand:
	LD A, R
	LD (SEED), A	
	RET
; =============================================================================
; == Génération d'un nombre pseudo-aléatoire                                  =
; == En entrée : A contient la limite maximale non comprise du nombre aléatoire
; == En sortie : A contient un nombre aléatoire entre 0 et le max-1           =
; ==                                                                          =
; == Remarque : Tous les registres sont sauvegardés sauf AF                   =
; =============================================================================
rand:
	PUSH DE
	PUSH HL 
	LD D, 0  ; Nombre maximal mis dans DE
	LD E, A 
	LD A, R ; Lecture d'un nombre aléatoire
	LD L, A ; Qu'on sauvegarde dans L
	LD A, (SEED) ; Lecture de la graine aléatoire 
	XOR L   ; Calcule de la graine suivante
	RLA     ; A varie entre 0 et 254 
	LD L, A ; Sauvegarde dans A 
	LD A, R ; Nombre aléatoire 
	XOR L   ; Calcul seed suivant 
	LD (SEED), A ; Nouveau seed stocké
	CALL mult_16x8 ; Multiplication du nombre aléatoire par le nombre max donné 
	LD A, H ; nombre aléatoire entre 0 et max-1
	POP HL 
	POP DE 
	RET 
; =============================================================================
; == Transformation d'un entier non signé codé sur  16  bits en une suite de ==
; == chiffres allant représentant le nombre correspondant.                   ==
; ==                                                                         ==
; == En entrée : HL contient le nombre à convertir                           ==
; == En sortie : HL contient l'adresse du tableau contenant les chiffres.    ==
; == Il est alors possible d'utiliser affiche_nombre pour afficher le nombre ==
; == passé dans HL.                                                          ==
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

; =============================================================================
; == Fonction affichant un message à l'écran pointé par HL.                  ==
; == En entrée : HL contient l'adresse du message à afficher                 ==
; ==             IX contient l'adresse où afficher le message                ==                 
; =============================================================================
print:
.loop:
	LD A, (HL)      ; Lecture du caractère à afficher
	INC HL          ; Prochain caractere
	OR A            ; Si c'est le caractère de fin de chaîne
	RET Z           ; On quitte la fonction
	CP 0x0A         ; Si c'est le retour chariot
	JR NZ, .is_char
	LD (cur_pos), IX
	LD A, (cur_pos)
	AND 0xE0        ; replace x en zéro
	LD (cur_pos), A 
	LD IX, (cur_pos)
	LD DE, 224
	ADD IX, DE
	JR .loop
.is_char:
	SUB 0x20     ; On enlève 20H pour obtenir l'index du caractère dans la table de caractères
	PUSH HL
	CALL put_char   ; On affiche le caractère
	POP  HL
	INC IX          ; Case suivante de l'écran
	JR .loop        ; On recommence
	RET
cur_pos: 
	byte 0x0, 0x0
; =============================================================================
; == Fonction pour afficher un caractère à l'écran.                          ==
; == En entrée : A = caractère à afficher (entre 0 et 255)                   ==
; ==            HL = adresse de l'écran où afficher le caractère             ==
; =============================================================================
put_char:
	PUSH IX
	LD BC, fonte
	LD H, 0
	LD L, A
	ADD HL, HL ; Multiplie par 2 pour obtenir l'offset dans la table de caractères
	ADD HL, HL ; Multiplie par 4 pour obtenir l'offset dans la table de caractères
	ADD HL, HL ; Multiplie par 8 pour obtenir l'offset dans la table de caractères
	ADD HL, BC ; On ajoute l'adresse de la table de caractères
	LD DE, 128
	;LD E, 32 ; On affiche 8 caractères (8x4=32)
	LD C, 0
	LD B, 2 ; Nombre de caractères à afficher
.loop:
	LD A, (HL) ; Lecture du caractère à afficher
	LD (IX + 0), A ; On l'affiche à l'écran
	INC HL
	LD A, (HL) ; Lecture du caractère à afficher
	LD (IX + 32), A ; On l'affiche à l'écran
	INC HL
	LD A, (HL) ; Lecture du caractère à afficher
	LD (IX + 64), A ; On l'affiche à l'écran
	INC HL
	LD A, (HL) ; Lecture du caractère à afficher
	LD (IX + 96), A ; On l'affiche à l'écran
	INC HL
	ADD IX, DE
	DJNZ .loop ; On boucle jusqu'à afficher les 8 caractères
	POP IX
	RET
	include "dzx0_standard.asm"
; =============================================================================
; == Fonction pour effacer l'écran avec une couleur spécifique               ==
; == En entrée : A = pattern à utiliser pour effacer (entre 0 et 3)          ==
; == Le pattern est de la forme [hc3|lc3|hc2|lc2|hc1|lc1|hc0|lc0]            ==
; == Par exemple, avec la palette par défaut, pour mettre l'écran en bleu(10)==
; == A =  b10101010 = 170                                                    ==
; =============================================================================
cls:
	LD HL, SCREEN_ADDR   ; Adresse mémoire du début de l'écran
	LD DE, SCREEN_ADDR+1 ; Adresse mémoire du début de l'écran + 1
	LD BC, 6143          ; Taille écran graphique - 1 
	LD (HL), A
	LDIR 
	RET 
; =============================================================================
; == Fonction pour attendre la fin du balayage vidéo                         ==
; =============================================================================
wait_vsync:
	IN A, (0x40)
	AND   0x10
	JR Z, .end
	IN A, (0x40)
	AND   0x10
	JR NZ, wait_vsync
.end:
	RET 
; =============================================================================
; == Fonction pour dessiner un sprite de 8x16 pixels à l'écran à partir de   ==
; == l'adresse donnée par HL, le n° de sprite étant donné par IX.            ==
; == En entrée : HL = adresse de l'écran où dessiner le sprite               ==
; ==             IX = adresse du sprite dans la table de sprites             ==
; =============================================================================
draw_sprite_8x16:
	LD B, 16           ; Nombre de lignes du sprite
	LD DE, 31
.loop:
	LD A, (IX)         ; Lecture du premier octet du sprite
	LD (HL), A         ; On l'affiche à l'écran
	INC HL             ; On passe au pixel suivant
	INC IX			   ; On passe au prochain octet du sprite
	LD A, (IX)       ; Lecture du deuxième octet du sprite
	LD (HL), A         ; On l'affiche à l'écran
	ADD HL, DE         ; On passe à la ligne suivante de l'écran
	INC IX             ; On passe au prochain octet du sprite
	DJNZ .loop       ; On boucle jusqu'à afficher les 16 lignes du sprite
	RET
; =============================================================================
; == Dessine un pilier à la 21 colonne                                       ==
; =============================================================================
draw_column:
	LD HL, SCREEN_ADDR+21
	LD  A, 106
	LD DE, 32
	LD B, 24
loop_draw_column:
	LD (HL), A 
	ADD HL, DE
	LD (HL), A 
	ADD HL, DE
	LD (HL), A 
	ADD HL, DE
	LD (HL), A 
	ADD HL, DE
	LD (HL), A 
	ADD HL, DE
	LD (HL), A 
	ADD HL, DE
	LD (HL), A 
	ADD HL, DE
	LD (HL), A 
	ADD HL, DE
	DJNZ loop_draw_column
	RET
	include "missiles.asm"
	include "vaisseau.asm"
	include "alien.asm"
	; =============================================================================
	; == Fonction qui initialise les variables du jeu pour une nouvelle partie   ==
	; =============================================================================
init_game:
	LD A, 52
	LD (vaisseau), A ; Vaisseau en état ok, x = 52
	memset vaisseau+1, 12, 0 ; 6 missiles  désactivés
	LD A, 0xE0
	LD (vaisseau+13), A ; 3 bombes restantes, compteur explosion vaisseau = 0
	LD A, 0xA3
	LD (nb_vie_colon), A ; 3 vies, 10 colons
	memset ennemis, 32, 0 ; 8 ennemis (inactifs)
	LD A, 0
	LD (score  ), A ; Score à 0
	LD (score+1), A; Score à 0
	RET
	; ==============================================================================
	; == Partie principale pour le jeu lui-même                                   ==
	; ==============================================================================
game:
	CALL init_game 
	LD A, 170
	CALL cls
	CALL draw_column
	LD HL, SCORE_TXT
	set_position_screen_3 25,1
	CALL print
	; Affichage des 10 colons
	LD IX, sprites8x16
	LD HL, (.pos_colons)
	LD B, 5
.loop1:
	PUSH HL
	PUSH IX
	PUSH BC
	CALL draw_sprite_8x16
	POP BC
	POP IX
	POP HL
	LD DE, 2
	ADD HL, DE
	DJNZ .loop1
	LD HL, (.pos_colons+2)
	LD B, 5
.loop2:
	PUSH HL
	PUSH IX
	PUSH BC
	CALL draw_sprite_8x16
	POP BC
	POP IX
	POP HL
	LD DE, 2
	ADD HL, DE
	DJNZ .loop2
	; Affichage des vies
	LD B , 3 
	LD HL, 175*128 + 22*4
.loop3:
	PUSH HL 
	PUSH BC 
	CALL draw_spaceship
	POP BC 
	POP HL
	LD DE, 13
	ADD HL, DE 
	DJNZ .loop3
	; Affichage des 3 bombes :
	LD HL, 126*32 + 23 + SCREEN_ADDR
	LD B , 3 
.loop4:
	LD IX, sprites8x16 + 32
	PUSH HL 
	PUSH BC 
	CALL draw_sprite_8x16
	POP BC 
	POP HL 
	LD DE, 2
	ADD HL, DE 
	DJNZ .loop4
.game_loop:
	CALL clear_ship
	CALL clear_aliens

	LD HL, 128*10 + 50 
	LD A , 1 
	CALL draw_alien
	LD HL, 128*12 + 58 
	LD A, 2
	CALL draw_alien
	RET
.pos_colons:
	dw SCREEN_ADDR + 22 + 32*70, SCREEN_ADDR + 22 + 32*90
	; ==============================================================================
	; == Ecran de présentation du jeu avec titre et menu de démarrage             ==
	; ==============================================================================
presentation:
	LD A, 170
	CALL cls	
	set_position_screen_3 10, 180
	LD B, 179
.scroll_title:
	LD HL, TITLE
	PUSH IX
	PUSH BC
	CALL print
	POP BC
	POP IX
	LD DE, -32
	ADD IX, DE
	DJNZ .scroll_title
	LD HL, 0x6000 + 320 + 10
	LD A, 0xFF
	LD B, 11
.horizontal_line:
	LD (HL), A
	INC HL
	DJNZ .horizontal_line
	set_position_screen_3 6, 80
	LD HL, start_txt
	CALL print
.wait_for_space:
	IN A, 131  ; Lecture du port 131 (clavier) où l'on attend l'appui sur la touche espace
	BIT 7,A    ; Teste si la touche espace est pressée
	JR NZ, .wait_for_space
.wait_loop:
	IN A, 131 
	BIT 7, A
	JR Z, .wait_loop
	CALL game
	RET
end_of_text:
highscore:
	db "ZX ", 0x00,0x51
	db "PHC", 0x00,0x19
	db "MSX", 0x00,0x02
; Début des données fixes du jeu
PREAMBLE:
	db "Decompressing...", 0
TITLE:
	db "RAPT-A-LIEN", 0
start_txt:
	db "espace pour commencer", 0
SCORE_TXT:
	db "SCORE", 0
highscore_txt:
	db "HIGHSCORE", 0
sprites8x16:
	include "sprite8x16.asm"
compressed_sprites:
	incbin "sprite16x16.zx0"
compressed_fonte:
	incbin "font.zx0"
	BLOCK 440, 0xAA
compressed_mask:
	incbin "mask_sprite.zx0"
fonte: EQU compressed_sprites
mask:  EQU compressed_sprites + 760
sprites16x16: EQU mask + 1282
end_of_init:
	define_uninit_begin end_of_init
	define_uninit sprite, 1540
; ------------------- données sur le vaisseau du joueur -----------------------
; Premier octet : [S|x6|x5|x4|x3|x2|x1|x0] où S état du vaisseau (0 ok, 1 touché), 0 <= x <= 127
; octets 2-13   : 6*[A|y7|y6|y5|y4|y3|y2|y1][y0|x6|x5|x4|x3|x2|x1|x0] où A missile activé, 0<=y<=255, 0<=x<=127
; octets 14     : Nombre bombes restantes : 3 bits, 1 bit bombe activée ou non, Compteur affichage explosion vaisseau (4 bits)
; ----------------------------------------------$(DEPS)-------------------------------
	define_uninit vaisseau, 14  ; 1 bit pour etat (0 ok, 1 en destruction); 7 bits pour x (y constant)
; [v4|v3|v2|v1|c4|c3|c2|c1]
	define_uninit  nb_vie_colon, 1 ; 4 bits nb colons et 4 bits nb vie
; -------------------------- Tableau des ennemis ------------------------------
; Huits ennemis simultanés, chaque ennemi est défini par 4 octets :
; Octet 1   : [E1|E0|C3|C2|C1|C0|T1|t0] : E état (00 : Inactif, 01 : actif, 11 : En explosion), C : compteur, T : Type (4 types possibles)
; Octet 2-3 : [0|0|0|y6|y5|y4|y3|y2][y1|y0|x5|x4|x3|x2|x1|x0]
; Octet 4   : utilisateur
	define_uninit ennemis, 32
; -----------------------------------------------------------------------------
	define_uninit score, 2 
	define_uninit frame_counter, 2 ; Compteur de frames pour le jeu
uninit_size equ uninit_pointer - end_of_init
end
