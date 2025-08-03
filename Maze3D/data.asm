	IFNDEF DATA_ASM    
	DEFINE DATA_ASM true
;/=/ Définition des zones mémoires associées à la gestion du jeu
beg_data_games:
	define_uninit_begin beg_data_games
	;define_uninit monstres, 344
    ;/==/ 8x8x8 = 512 salles de un octet chacun :
	define_uninit DonjonData, 512
	;/==/ Double buffering :
	define_uninit DoubleBuffering, 2760
uninit_size equ uninit_pointer - beg_data_games

	ENDIF
