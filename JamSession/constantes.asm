; # LES DIFFERENTES VALEURS CONSTANTES UTILISEES DANS LE CODE SOURCE
; /=/ Constantes pour les caractéristiques du jeu
; /==/ Nombre maximum d'alien à l'écran
max_nb_aliens   EQU 6
; /==/ Nombre de colons au démarrage du jeu
max_nb_colons   EQU 10
; /==/ Nombre de vies au démarrage du jeu
max_vie         EQU 3
; /==/ Nombre de bombes initial 
max_bombes      EQU 3
; /==/ Nombre de missiles maximum à l'écran :
max_nb_missiles EQU 3
; /==/ Couleur de fond de l'écran (0 = VERT, 85 = JAUNE, 170 = BLEU, 255 = ROUGE)
BACKGROUND      EQU 170 
; /=/ Les différentes positions des éléments fixes à afficher dans le jeu
; /==/ Position sur l'écran de l'affichage du score
SCORE_X 	    EQU 104
SCORE_MSG_Y     EQU 4
; /==/ Position du titre Highscore à l'écran :
HIGHSCORE_X     EQU 44
HIGHSCORE_Y     EQU 80
; /==/ Position de la table des highscores :
TABHIGHSCORE_X  EQU 40 
TABHIGHSCORE_Y  EQU 96
; /==/ Position des bombes affichées à l'écran (en pixel)
BOMBS_X         EQU 92
BOMBS_Y         EQU 126
; /===/ Décalage à effectuer dans le tableau des sprites 8x16 pour avoir l'image de la bombe
BOMB_SPRT_IND   EQU 32
; /==/ Position de l'affichage des vies à l'écran (en pixel)
LIFE_X          EQU 88
LIFE_Y          EQU 175
; /==/ Position d'affichage de la première et seconde ligne des colons à l'écran
COLONS_X        EQU 88
COLON1_Y        EQU 70
COLON2_Y        EQU 90
; /==/ Ordonnée (constante) du vaisseau du joueur
SPACESHIP_Y     EQU 175
SPACESHIP_X_DEB EQU 52
; /=/ VALEURS FIXES OU CALCULEES PAR RAPPORT AUX CONSTANTES PRECEDENTES
SCREEN_ADDR 	EQU	0x6000
SCORE_MSG_ADDR  EQU SCREEN_ADDR + (SCORE_X>>2)+32*SCORE_MSG_Y
BOMBS_SCR_ADDR  EQU SCREEN_ADDR + (BOMBS_X>>2)+32*BOMBS_Y 
BOMB_CNTER_MASK EQU 0b11000000
VIE_SCR_ADDR    EQU LIFE_X + 128*LIFE_Y
pos_colons_row1 EQU SCREEN_ADDR + (COLONS_X>>2) + 32*COLON1_Y
pos_colons_row2 EQU SCREEN_ADDR + (COLONS_X>>2) + 32*COLON2_Y
TABHGHSC_ADDR   EQU SCREEN_ADDR + (TABHIGHSCORE_X>>2) + 32*TABHIGHSCORE_Y
; Bit indiquant si un alien est actif ou non (actif ou actif avec colon)
IS_ACTIVE       EQU 0b01000000
NOT_ONLY_ACTIVE EQU 0b10000000 
FLASH_DELAY     EQU 32