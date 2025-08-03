;/=/      Gestion des différents événements clavier

;## ####################################################################################################################
;##                       Routine qui attend que l'utilisateur appuie sur la touche espace                            ##
;## ####################################################################################################################
wait_for_space:
	IN A, 131  ; Lecture du port 131 (clavier) où l'on attend l'appui sur la touche espace
	BIT 7,A    ; Teste si la touche espace est pressée
	JR NZ, wait_for_space
.release:      ; Et on attend que la touche espace soit relachée !
	IN A, 131 
	BIT 7, A
	JR Z, .release
    RET
