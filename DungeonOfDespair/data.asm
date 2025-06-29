	IFNDEF DATA_ASM    
	DEFINE DATA_ASM true
;/=/ Définition des zones mémoires associées à la gestion du jeu
DonjonMap:
	BLOCK 60-33, 0xAA
map_zx:
	incbin "map.zx0"
beg_data_games:
	define_uninit_begin beg_data_games
	define_uninit monstres, 344
    ;/==/ 8x8x8 = 512 salles de un octet chacun :
	define_uninit DonjonData, 512
	;/==/ 8x8 (x8) : Flag pour savoir si une salle a déjà été visitée ou non
	define_uninit VisitedRooms, 64
uninit_size equ uninit_pointer - beg_data_games

	ENDIF