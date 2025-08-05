;/=/ Gestion du donjon
    include "macros.asm"
    include "stdlib.asm" 
    include "sprites.asm"
    include "debug.asm"
;## ====================================================================================================================
;/==/  Génère le donjon en mémoire à partir de la graîne aléatoire donnée dans DonjonSeed                             ==
;## ====================================================================================================================
;## == Initialisation du donjon. En particuliers, met à zéro toutes les cases du donjon.                              ==
;## ====================================================================================================================
init_donjon:
    ; Mise à zéro des salles :
    memset DonjonData, 512, 0
    ;memset StateRooms, 512, 0
    RET
;## ====================================================================================================================
;## Calcule le nombre de nouvelles sorties potentielles autour d'une salle donnée                                     ==
;## Remplit un tableau avec les sorties potentielles                                                                  ==
;##    En entrée :                                                                                                    ==
;##      HL pointe sur la salle dont on veut connaître le nombre de sorties potentielles                              ==
;##      DE contient le numéro de la salle                                                                            ==
;## ====================================================================================================================
comp_pot_exit:
    PUSH BC                            ; > Sauvegarde BC
    PUSH HL                            ; > Sauvegarde HL
    PUSH DE                            ; > Sauvegarde DE
    LD B, 0
    LD IX, sorties_potentielles
    ; Test sortie vers le bas :
    LD A, E
    AND 0b11000000
    LD C, A
    LD A, D
    AND 0X01   
    OR C
    JR Z, .test_sortie_sud           ; Si z = 0, pas de sortie possible vers le bas
    LD DE, -64
    ADD HL, DE
    LD A, (HL)
    OR A
    JR NZ, .test_sortie_sud          ; Salle en bas déjà visitée, donc pas un candidat souhaité
    INC B
    LD (IX), BAS
    INC IX
.test_sortie_sud:
    POP DE                           ; < Restauration DE
    POP HL                           ; < Restauration HL
    PUSH HL                          ; > Sauvegarde HL
    PUSH DE                          ; > Sauvegarde DE
    LD A, E
    AND 0b00111000
    JR Z, .test_sortie_ouest        ; Si y est nul, pas de sortie au sud
    LD DE, -8
    ADD HL, DE
    LD A, (HL)
    OR A
    JR NZ, .test_sortie_ouest
    INC B
    LD (IX), SUD 
    INC IX 
.test_sortie_ouest:
    POP DE                           ; < Restauration DE
    POP HL                           ; < Restauration HL
    PUSH HL                          ; > Sauvegarde HL
    PUSH DE                          ; > Sauvegarde DE
    LD A, E
    AND 0b00000111
    JR Z, .test_sortie_est          ; Si x est nul, pas de sortie à l'ouest
    DEC HL
    LD A, (HL)
    OR A 
    JR NZ, .test_sortie_est
    INC B
    LD (IX), OUEST
    INC IX
.test_sortie_est:
    POP DE                           ; < Restauration DE
    POP HL                           ; < Restauration HL
    PUSH HL                          ; > Sauvegarde HL
    PUSH DE                          ; > Sauvegarde DE
    LD A, E
    AND 0b00000111
    CP  0b00000111                    ; x = 7 ?
    JR Z, .test_sortie_nord         ; Si x = 7, on ne peut pas avoir de sortie à l'Est
    INC HL
    LD A, (HL)
    OR A
    JR NZ, .test_sortie_nord
    INC B
    LD (IX), EST  
    INC IX
.test_sortie_nord:
    POP DE                           ; < Restauration DE
    POP HL                           ; < Restauration HL
    PUSH HL                          ; > Sauvegarde HL
    PUSH DE                          ; > Sauvegarde DE
    LD A, E
    AND 0b00111000
    CP  0b00111000                   ; y = 7 ?
    JR Z, .test_sortie_haut          ; Et si x vaut 7, 
    LD DE, 8 
    ADD HL, DE
    LD A, (HL)
    OR A
    JR NZ, .test_sortie_haut
    INC B
    LD (IX), NORD
    INC IX
.test_sortie_haut:
    POP DE                           ; < Restauration DE
    POP HL                           ; < Restauration HL
    PUSH HL                          ; > Sauvegarde HL
    PUSH DE                          ; > Sauvegarde DE
    LD A, D
    AND 0x01
    JR Z, .set_sortie_haut           ; Si le bit 0 de D est nul, pas de risque que z = 7
    LD A, E                          ; Là, on sait que z > 0
    AND 0b11000000
    CP  0b11000000                    ; Si la comparaison nous donne 11000000, alors z = 7
    JR Z, .fin
.set_sortie_haut:
    LD DE, 64
    ADD HL, DE
    LD A, (HL)
    OR A
    JR NZ, .fin
    INC B
    LD (IX), HAUT
    INC IX
.fin
    LD A, B
    LD (nb_sorties_pot), A
    POP DE                          ; < Restauration DE
    POP HL                          ; < Restauration HL
    POP BC                          ; < Restauration BC
    RET
nb_sorties_pot:
    db 0xAA
sorties_potentielles:
    db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA
;! =====================================================================================================================
;! POUR LE DEBOGAGE
;! =====================================================================================================================
    IFDEF DEBUG
nb_sorties_msg:
    db AT, 15, 0, "Nombre de sorties : ", ENDSTR
sorties_msg:
    db AT, 16, 0, "Sorties potentielles : ", ENDSTR
espace:
    db " ", ENDSTR
print_pot_sorties:
    PUSH HL
    PUSH DE
    PUSH BC
    PUSH AF
    LD HL, nb_sorties_msg
    CALL print42
    LD A, (nb_sorties_pot)
    LD H, 0
    LD L, A
    CALL convert_to_digits
    CALL print42 
    LD HL, sorties_msg
    CALL print42  
    LD A, (nb_sorties_pot)
    OR A
    JR Z, .end
    LD B, A
    LD HL, sorties_potentielles
.loop:
    LD A, (HL)
    INC HL 
    PUSH HL
    LD L, A
    LD H, 0
    PUSH BC
    CALL convert_to_digits
    CALL print42
    LD HL, espace
    CALL print42
    POP BC
    POP HL
    DJNZ .loop    
.end:
    POP AF
    POP BC
    POP DE
    POP HL
    RET
    ENDIF
;## ====================================================================================================================
;##     Recherche une case visitée possédant encore une sortie potentielle vers une case non visitée                  ==
;##          En sortie :                                                                                              ==
;##              - HL contient sur la case  dont l'indice est sous la forme [0..0z2][z1|z0|y2|y1|y0|x2|x1|x0] qui     ==
;##                correspond en même temps à l'indice de la salle                                                    ==
;##     Si aucune case vide n'est trouvée, HL retourne le pointeur nul                                                ==
;## ====================================================================================================================
    IFDEF DEBUG
trace_cherche_case_vide:
    db AT, 4, 15, "Cherche case vide   ", 0
aff_sortie_pot:
    db AT, 4, 15, "Sorties potentielles", 0
aff_decompt:
    db AT, 4, 15, "Compteurs boucles   ", 0
    ENDIF
cherche_case_vide:
    LD HL, DonjonData
    LD BC, DONJON_SIZE
    LD DE, 0
.loop:
    CALL comp_pot_exit
    IFDEF DEBUG
    CALL print_pot_sorties ;! DEBOGUE
    ENDIF
    LD A, (nb_sorties_pot)
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, trace_cherche_case_vide
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    OR A
    JR NZ, .found                     ; Si une sortie potentielle exite, on s'arrête là
.loop2                                ; Sinon recherche prochaine case déjà visitée
    INC HL                            ; Prochaine case
    INC DE
    DEC BC                             ; On décrémente BC
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, aff_decompt
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    LD A, C
    OR B                              ; BC nul ?
    JR Z, .not_found
    LD A, (HL) 
    OR A                              ; Pièce déjà visitée ?
    JR Z, .loop2                      ; Non, on cherche une pièce déjà visitée !

    JR .loop
.not_found:
    XOR A
    LD H, A                 ; Mis à 0 de HL pour avoir le pointeur nul
    LD L, A
    RET
.found:
    RET
;## ====================================================================================================================
;## Tire une sortie au hasard compatible avec la situation de la pièce dans le donjon                                 ==
;##        En entrée :                                                                                                ==
;##            HL pointe sur la pièce dans le donjon                                                                  ==
;##            DE contient l'indice de la pièce                                                                       ==
;##        En sortie :                                                                                                ==
;##            A contient la sortie compatible tirée au hasard                                                        ==
;##  Note : A la sortie de la routine, seule le registre A est modifié                                                ==
;## ====================================================================================================================
    IFDEF DEBUG
rand_value:
    db AT, 19, 1, "Valeur tiree : ", ENDSTR
dbg_msg:
    db AT, 20, 1, "numero salle traitee : ", ENDSTR
ouvre_msg:
    db AT, 4, 15, "   Ouvre passage    ", ENDSTR
oppose_msg:
    db AT, 4, 15, "     Entre par      ", ENDSTR
bas_dir:
    db AT, 4, 15, "        bas         ", ENDSTR
haut_dir:
    db AT, 4, 15, "        haut        ", ENDSTR
est_dir:
    db AT, 4, 15, "        est         ", ENDSTR
ouest_dir:
    db AT, 4, 15, "        ouest       ", ENDSTR
nord_dir:
    db AT, 4, 15, "        nord        ", ENDSTR
sud_dir:
    db AT, 4, 15, "        sud         ", ENDSTR
    ENDIF
tire_sortie:
    PUSH HL              ; > 1] Sauvegarde de HL
    PUSH DE              ; > 1] Sauvegarde de DE
    PUSH BC              ; > 1] Sauvegarde de BC
    IFDEF DEBUG
    ;! debogue
    PUSH HL              ; > 2] Sauvegarde de HL
    PUSH BC              ; > 2] Sauvegarde de BC
    PUSH DE              ; > 2] Sauvegarde de DE
    LD HL, dbg_msg
    CALL print42
    POP DE               ; < 2] Restauration de DE
    PUSH DE              ; > 2] Sauvegarde de DE
    EX DE, HL            ; > Echange DE et HL
    CALL convert_to_digits
    CALL print42 
    POP DE               ; < 2] Restauration de DE
    POP BC               ; < 2] Restauration de BC
    POP HL               ; < 2] Restauration de HL
    ;! Fin debogue
    ENDIF
.until:
    PUSH HL              ; > 2] Sauvegarde de HL
    PUSH DE              ; > 2] Sauvegarde de DE
    CALL rand    
    LD A, (nb_sorties_pot)
    LD E, A
    LD A, L
    XOR H
    LD D, 0
	CALL mult_16x8         ; Multiplication du nombre aléatoire par le nombre max donné 
    LD A, H                ; ### A contient une valeur entre 0 et nb_sorties-1
    PUSH BC
.pp:
    LD IX, sorties_potentielles
    LD B, A
    OR A
    JR Z, .pasglop          ; FAut quand même tenir compte que A peut être nul, non ?
.possortie:
    INC IX
    DJNZ .possortie
.pasglop:
    POP BC
    POP DE               ; < 2] Restauration de DE
    POP HL               ; < 2] Restauration de HL
    LD A, (IX)
    IFDEF DEBUG
  ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, ouvre_msg
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    ;/==/  Pour chaque direction possible, on regarde si cette direction est possible
    OR A                   ; Pour tester si A est nul ce qui indique une sortie vers le bas !
    JR NZ, .sortie_sud
    EX AF, AF'             ; > Echange AF et AF' pour sauvegarder A
    LD A, E
    AND 0b11000000         ; On ne garde que les deux premiers bits de z (z1z0)
    LD C, A                ; On garde ça dans C
    LD A, D
    AND 0x01               ; Et ne garde que le premier bit de E (qui correspond à z2)
    OR C                   ; Et on test si un des trois bits est non nul
    JR NZ, .continue0
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    JR .until           ; Si nul, on ne peut pas descendre, on recommence
.continue0:
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    LD C, BAS_VALUE
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, bas_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    JP .end
.sortie_sud:
    CP SUD                   ; A vaut-il un ?
    JR NZ, .sortie_ouest   ; Si non, on va tester la sortie ouest
    EX AF, AF'             ; > Echange AF et AF' pour sauvegarder A
    LD A, E
    AND 0b00111000         ; On test si  y est nul
    JR NZ, .no_until1           ; Si oui, on ne peut pas aller vers le sud, on retire !
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    JP .until
.no_until1:
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    LD C, SUD_VALUE    
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, sud_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    JP .end
.sortie_ouest:
    CP OUEST               ; A vaut-il 2 ?
    JR NZ, .sortie_est     ; Si non, on va tester la sortie Est
    EX AF, AF'             ; > Echange AF et AF' pour sauvegarder A
    LD A, E
    AND 7                  ; Test si x est nul
    JR NZ, .no_until2
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    JP  .until           ; Si oui, on ne peut pas aller vers l'ouest, on retire !
.no_until2:
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    LD C, OUEST_VALUE
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, ouest_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    JR .end
.sortie_est:
    CP EST                 ; A correspond-t'il à la direction EST ?
    JR NZ, .sortie_nord    ; Sinon on va tester la sortie nord
    EX AF, AF'             ; > Echange AF et AF' pour sauvegarder A
    LD A, E
    AND 7  
    JR Z, .cont11          ; Cas où x est égal à 0
    XOR 7                  ; Test si x est égal à 7
    JR NZ, .cont11    
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    JP .until           ; Si oui, on ne peut pas aller vers l'Est, on retire !
.cont11:
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
.cont1:
    LD C, EST_VALUE
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, est_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    JR .end
.sortie_nord:
    CP NORD                ; A correspond-t'il à la direction NORD ?
    JR NZ, .sortie_haut    ; Sinon on va tester la sortie haut
    EX AF, AF'             ; > Echange AF et AF' pour sauvegarder A
    LD A, E
    AND 0b00111000
    JR Z, .cont2           ; Cas où y est égal à 0
    XOR 0b00111000         ; On teste si y vaut 7
    JR NZ, .cont2           ; Si oui, on ne peut pas aller vers le Nord, on retire !
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    JP .until
.cont2:
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
.cont22:
    LD C, NORD_VALUE
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, nord_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    JR .end
.sortie_haut:
    CP HAUT                ; A correspond-t'il à la direction HAUT ?
    JP NZ, .until          ; Non ? Mmmh sans doute un bogue, bon on retire pour la sortie
    EX AF, AF'             ; > Echange AF et AF' pour sauvegarder A
    LD A, E
    AND 0b11000000
    JR Z, .end1            ; Cas nul
    XOR 0b11000000         ; Si les deux bits faibles de z ne soont pas tous les deux à un
    JR NZ, .end1           ; On est sûr de ne pas être au dernier étage, donc on valide !
.cont3:
    LD A, D                ; Sinon, va falloir tester la valeur de z2
    AND 0x1                
    JR Z, .end1
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    JP .until          ; qui si il vaut 1 indique qu'on est au dernier étage, donc pas possible
.end1:
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
.end2:

    LD C, HAUT_VALUE
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, haut_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
.end:
    EX AF, AF'             ; > Echange AF et AF' pour sauvegarder A
    LD A, (HL)
    OR C
    LD (HL), A
    EX AF, AF'             ; > Echange AF et AF' => On en profite pour restaurer A
    POP BC
    POP DE
    POP HL
    RET
;## ====================================================================================================================
;## A partir de la valeur de sortie de A, applique le masque correspondant dans la cellule pointée par HL             ==
;##       En entrée :                                                                                                 ==
;##           A : valeur de la direction de sortie                                                                    ==
;##          HL : pointeur sur la cellule à modifier pour y rajouter la sortie                                        ==
;## Note : Aucun registre ne sera modifié en sortie !                                                                 ==
;## ====================================================================================================================
set_sortie:
    PUSH BC                ; > Sauvegarde de BC
    PUSH AF                ; > Sauvegarde de AF
    LD B, A
    OR A                   ; Test si A est nul
    LD A, 1
    JR Z, .nopow2
.pow2:
    ADD A                  ; A *= 2
    DJNZ .pow2
.nopow2:
    LD B, A                ; Stocke le résultat dans B
    LD A, (HL)             ; On récupère la valeur des sorties de la case courante
    OR B                   ; On rajoute la nouvelle sortie
    LD (HL), A
    POP AF                 ; < On restaure AF
    POP BC                 ; < Restauration de BC
    RET
;## ====================================================================================================================
;## A partie d'une valeur de sortie et une pièce donnée, on trouve la pièce dans laquelle débouche notre sortie       ==
;##     En entrée :                                                                                                   ==
;##        A : valeur de la sortie                                                                                    ==
;##       HL : pointeur sur la pièce courante                                                                         ==
;##     En sortie :                                                                                                   ==
;##       HL : pointeur sur la nouvelle pièce                                                                         ==
;## Tous les autres registres sont sauvegardés sauf A                                                                 ==
;## ====================================================================================================================
trouve_cell_opposee:
    IFDEF DEBUG
   ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, oppose_msg
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF

    PUSH DE                ; > Sauvegarde de DE
    OR  A                  ; A vaut-il zéro ? Dans ce cas, on va vers le bas
    JR NZ, .go_south       ; Si non, on va tester si on va au sud
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, bas_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    LD DE, -64
    ADD HL, DE             ; On pointe sur la pièce se trouvant plus bas
    LD A, (HL)
    OR HAUT_VALUE
    LD (HL), A
    POP DE                 ; < Restauration de DE
    RET
.go_south:
    CP SUD                 ; valeur sortie correspond au sud ?
    JR NZ, .go_west        ; Si non, test si on va vers l'ouest
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, sud_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    LD DE, -8
    ADD HL, DE
    LD A, (HL)
    OR NORD_VALUE
    LD (HL), A
    POP DE                 ; < Restauration de DE
    RET
.go_west:
    CP OUEST               ; Valeur sortie correspond à l'Ouest
    JR NZ, .go_east        ; Si non, on va tester si on va vers l'Est
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, ouest_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    DEC HL
    LD A, (HL)
    OR EST_VALUE
    LD (HL), A
    POP DE                 ; < Restauration de DE
    RET
.go_east:                  
    CP EST                 ; Valeur sortie correspond à l'Est ?
    JR NZ, .go_north       ; Si non, test si on va haut nord
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, est_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    INC HL
    LD A, (HL)
    OR OUEST_VALUE
    LD (HL), A
    POP DE                 ; < Restauration de DE
    RET
.go_north:
    CP NORD                ; Valeur sortie correspond à la direction Nord ?
    JR NZ, .go_up          ; Sinon on va vers le haut
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, nord_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    LD DE, 8
    ADD HL, DE
    LD A, (HL)
    OR SUD_VALUE
    LD (HL), A
    POP DE                ; < Restauration de DE
    RET
.go_up:
    CP HAUT               ; Valeur sortie correspond à la direction haut ?
    JR NZ, .end           ; Mmmh, valeur incorrecte, on quite
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, haut_dir
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    LD DE, 64
    ADD HL, DE
    LD A, (HL)
    OR BAS_VALUE
    LD (HL), A 
.end:
    POP DE                ; < Restauration de DE
    RET
;## ====================================================================================================================
;## Génère un donjon de 8 x 8 x 8 en utilisant une graine fixée (si non nulle) ou une graîne aléatoire si nulle       ==
;## ====================================================================================================================
genere_donjon:
    LD HL, (DonjonSeed)
    CALL set_seed
.until0:
    CALL cherche_case_vide
    IFDEF DEBUG
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, trace_cherche_case_vide
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    ENDIF
    LD A, H                ; Test si HL est le pointeur nul
    OR L
    RET Z                  ; Si pointeur nul, on a fini d'initialiser le donjon
.until:
    PUSH HL                ; > On sauvegarde HL
    LD DE, -DonjonData
    ADD HL, DE             ; Donne l'indice de la case qu'on va traiter
    EX DE, HL              ; Contenu dans DE
    POP HL                 ; < On restaure HL
.retry:
    CALL comp_pot_exit
    IFDEF DEBUG
    ;! DEBOGUE
    PUSH HL
    PUSH DE
    PUSH BC
    PUSH AF
    CALL cls
    CALL print_pot_sorties ;! Debogue
    POP AF
    POP BC
    POP DE
    POP HL
    ENDIF
    LD A, (nb_sorties_pot)
    OR A
    JR Z, .until0
    CALL tire_sortie         ; On tire une sortie (valide par rapport aux bornes du donjon) stockée dans A au retour
    CALL trouve_cell_opposee ; On recherche la cellule où débouche la nouvelle sortie, qu'on range dans HL
    JR .until                ; Non, donc on va continuer avec la nouvelle pièce d'où débouchait notre sortie
;## ====================================================================================================================
;## Affiche la carte de l'étage courant à l'écran en affichant uniquement que les pièces déjà visitées                ==
;##      En entrée :                                                                                                  ==
;##           A : n° de l'étage courant (où se trouve le joueur)                                                      ==
;## ====================================================================================================================
display_map:
    PUSH AF
    LD HL, .etage_msg
    CALL print42
    POP AF
    PUSH AF
    LD H, 0
    LD L, A
    INC L
    CALL convert_to_digits
    LD HL, BUF
    CALL print42
    POP AF
    ; Calcul de l'adresse de l'étage à afficher :
    LD HL, DonjonData + 63 ; +63 pour commencer à la dernière salle de l'étage
    LD B, A                ; B contient l'étage à afficher
    OR A
    JR Z, .no_loop
    LD DE, 64
.loop1:
    ADD HL, DE             ; On passe à l'étage suivant
    DJNZ .loop1            ; On répète jusqu'à l'étage voulu
    ; On a maintenant HL qui pointe sur l'étage à afficher
    ; On va afficher la carte de l'étage courant
.no_loop:
    LD C, DONJON_WIDTH     ; Nombre de lignes de pièces à afficher
    LD D, 0
.loop2:
    LD E, 8
    LD B, DONJON_LENGTH    ; Nombre de pièces à afficher par ligne
.loop3:
    ; Affichage de la base de toutes les pièces :
    LD A, (HL)
    PUSH HL                ; > Sauvegarde de HL
    AND 128                ; Si bit 128 non mis, la pièce n'a pas encore été visitée. On ne l'affichage pas !
    JR Z, .skip_haut
    LD A, (HL)
    LD HL, DonjonMap
    EX AF, AF'             ; > Echange AF avec AF' pour sauvegarder AF
    CALL draw_sprite_8x8
    EX AF, AF'             ; > Echange AF avec AF' pour restaurer AF
    BIT BAS, A
    JR Z, .skip_bas
    LD HL, DonjonMap+8
    EX AF, AF'             ; > Echange AF avec AF' pour sauvegarder AF
    CALL draw_sprite_8x8
    EX AF, AF'             ; > Echange AF avec AF' pour restaurer AF
.skip_bas:
    BIT SUD, A
    JR NZ, .skip_sud
    LD HL, DonjonMap+40
    EX AF, AF'             ; > Echange AF avec AF' pour sauvegarder AF
    CALL draw_sprite_8x8
    EX AF, AF'             ; > Echange AF avec AF' pour restaurer AF
.skip_sud:
    BIT OUEST, A
    JR NZ, .skip_ouest
    LD HL, DonjonMap + 48
    EX AF, AF'             ; > Echange AF avec AF' pour sauvegarder AF
    CALL draw_sprite_8x8
    EX AF, AF'             ; > Echange AF avec AF' pour restaurer AF
.skip_ouest:
    BIT EST, A
    JR NZ, .skip_est 
    LD HL, DonjonMap + 32
    EX AF, AF'             ; > Echange AF avec AF' pour sauvegarder AF
    CALL draw_sprite_8x8
    EX AF, AF'             ; > Echange AF avec AF' pour restaurer AF
.skip_est:   
    BIT NORD, A
    JR NZ, .skip_nord    
    LD HL, DonjonMap + 24
    EX AF, AF'             ; > Echange AF avec AF' pour sauvegarder AF
    CALL draw_sprite_8x8
    EX AF, AF'             ; > Echange AF avec AF' pour restaurer AF
.skip_nord:    
    BIT HAUT, A
    JR Z, .skip_haut
    LD HL, DonjonMap + 16
    EX AF, AF'             ; > Echange AF avec AF' pour sauvegarder AF
    CALL draw_sprite_8x8
    EX AF, AF'             ; > Echange AF avec AF' pour restaurer AF
.skip_haut:   
    ; Passage à la prochaine pièce :
    POP HL                 ; < Restauration de HL
    DEC HL                 ; Pièce précédente !
    DEC E                  ; Position précédente
    DJNZ .loop3
    INC D                  ; Ligne suivante (8 x 32 pour la ligne suivante de caractère en fait)
    DEC C                  ; Compteur pour le nombre de case sud-nord
    JP NZ, .loop2
    RET
.etage_msg:
    DB AT, 10, 0, "Carte etage ", ENDSTR
;## ====================================================================================================================
;##                           Affichage à la première personne de ce que voit le joueur                               ==
;## En entrée :                                                                                                       ==
;##      DE contient la position du joueur dans le labyrinthe (son décalage en octet)                                 ==
;##       A contient l'orientation du joueur (nord, sud, est ou ouest)                                                ==
;## ====================================================================================================================
rendu:
    PUSH DE            ; > Sauvegarde DE
    CALL draw_ceil
    POP DE             ; < Restauration DE
    LD HL, DonjonData
    ADD HL, DE
; ## Rendu selon la direction (HL pointe sur la cellule où se trouve le joueur)
rendu_dir:
    PUSH HL         ; Sauvegarde du pointeur sur la cellule du joueur
    LD IX, rendu_data+2
    ; Test si trois cases devant ne dépasse pas la taille du labyrinthe:
    LD A, E         ; A contient la position du perso
    AND (IX+4)      ; et on ne conserve que le x ou y concerné
    LD  C, (IX+8)   ; C contient la valeur de borne à tester (0 ou 7)
    CP  C           ; Si A vaut la borne testée
    JP Z, .case0    ; On n'affiche que ce qui est devant le joueur
    LD B, (IX+0)    ; B contient le pas en octet pour avancer d'une case
    ADD B           ; On rajoute ce pas à A
    CP  C           ; A a atteint sa borne ?
    JP Z, .case1    ; On ne peut afficher que une case devant le joueur
    ADD B           ; A += step
    CP C            ; A a atteint sa borne ?
    JR Z, .case2    ; On ne peut afficher que deux cases devant le joueur
    ; Sinon, on peut tout afficher !
    ; ...................................................................
    ; .. Première étape : on affiche ce qui est devant le joueur, trois
    ; ..                  cases devant
    ; .. L'affichage ne se fait que si il n'y pas de mur face au joueur,
    ; .. à distance 0, 1 ou 2
    ; ...................................................................
    ; On se positionne une case en avance pour les deux premiers tests :
    LD A, (rendu_data)
    CALL add_16_8      ; HL pointe une case en avance
    LD A, (HL)
    LD B, (IX+2)       ; Test si mur juste devant le joueur (opposé à la direction) :
    AND B
    JR Z, .case2      ; Si un mur juste devant le joueur, on saute cette étape
    LD A, (HL)
    LD B, (IX+0)       ; Test mur une case devant (même direction que joueur)
    AND B              ; On saute aussi cette étape si un mur en face à une case du joueur
    JR Z, .case2
    LD A, (rendu_data)
    CALL add_16_8      ; Maintenant HL pointe deux cases devant le joueur
    LD A, (HL)
    AND B              ; Si il y a un mur en face à 2 pas du joueur
    JR Z, .case2      ; Il n'y a rien à afficher en face à deux pas du joueur
    LD A, (rendu_data)
    CALL add_16_8       ; HL trois cases devant le joueur
    LD A, (HL)
    AND (IX+3)          ; Test si un mur sur la gauche :
    JR NZ, .murd3        ; Non, on va alors tester le mur droite
    PUSH DE            ; >     Sauvegarde DE
    PUSH HL            ; >         Sauvegarde HL
    CALL mur_gauche3
    POP HL             ; <         Restauration HL
    POP DE             ; <     Restauration DE
.murd3:
    LD A, (HL)
    AND (IX+1)         ; Test mur droite
    JR NZ, .haut3       ; Si non, on va tester si échelle vers le haut
    PUSH DE            ; >     Sauvegarde DE
    PUSH HL            ; >         Sauvegarde HL
    CALL mur_droite3
    POP HL             ; <         Restauration HL
    POP DE             ; <     Restauration DE
.haut3:
    LD A, (HL)
    AND HAUT_VALUE
    JR Z, .bas3        ; Sinon, on va tester si échelle vers le bas
    PUSH DE
    PUSH HL
    CALL echelle3
    POP HL
    POP DE
.bas3:
    LD A, (HL)
    AND BAS_VALUE
    JR Z, .case2
    PUSH DE
    CALL echelle_bas3
    POP DE
    ; ===================================================================================
.case2:
    POP HL
    PUSH HL        ; On restaure le HL sur la position du joueur
    ; -----------------------------------------------------------------------------------
    ; -- On va tester en premier quoi afficher deux cases devant à gauche du joueur    --
    ; -----------------------------------------------------------------------------------
    ; Le mur à gauche, 2 cases en face du joueur.
    ;  < N'est pas visible si (face0g ET face0) OU (face1g ET mur2g)
    ;  < OU BORNE GAUCHE
    ; Test BORNE GAUCHE    
    LD A, E
    AND (IX+7)       ; Masque pour le bord gauche
    CP (IX+11)       ; On teste si on est sur le bord gauche du labyrinthe
    JR Z, .case2_droite ; Si c'est le cas, on passe au côté droit
    ; == Test si mur en face du joueur + en face à gauche du joueur
    LD A, (rendu_data)
    CALL add_16_8    ; HL pointe sur la case juste devant le joueur
    LD A, (HL)
    AND (IX+2)       ; Teste si mur juste en face du joueur
    PUSH AF          ; Sauvegarde du test
    LD A, (rendu_data+1)  ; Le pas en octet pour aller sur la droite
    CALL sub_16_8    ; Pour aller sur la gauche ! HL une case devant et à gauche
    POP AF           ; On restaure le test, mais HL est préparé pour pointer sur la bonne cellule
    JR NZ, .test2_face1g_mur2g ; Si pas de mur en face, on teste la 2ème condition
    LD A, (HL)       ; vu que HL pointe sur la bonne adresse ^^
    AND (IX+2)
    JR Z, .case2_droite ; Si face0g et face0, aucun affichage à faire
.test2_face1g_mur2g: ; < Test (face1g) ET (mur2g)
    LD A, (rendu_data)
    CALL add_16_8    ; HL deux cases devant et à gauche
    LD A, (HL)
    AND (IX+2)       ; Mur à gauche en face à une case ?
    JR NZ, .display_face2g    ; Pas de mur, on affiche le mur face à gauche deux cases devant
    LD A, (HL)
    AND (IX+1)       ; Mur droite deux cases devant et à gauche ?
    JR Z, .case2_droite ; Si Mur également, pas d'affichage à faire
.display_face2g:
    LD A, (HL)
    AND (IX+0)       ; Le mur existe ?
    JR NZ, .case2_droite    ; Si non, on voit si on doit afficher une échelle
    PUSH DE
    CALL mur_face2g
    POP DE
    ; -----------------------------------------------------------------------------------
    ; -- On va tester en second quoi afficher deux cases devant à droite du joueur     --
    ; -----------------------------------------------------------------------------------
.case2_droite:
    POP HL
    PUSH HL        ; On restaure le HL sur la position du joueur
    ; Le mur à droite, deux case devant le joueur est invisible si :
    ;       1/ face0 ET face0d
    ;               OU
    ;       2/ face1d ET mur2d
    ;
    ;       3/ SUR BORNE
    ; Test BORNE
    LD A, E
    AND (IX+5)
    CP  (IX+9)
    JR Z, .face_case2
    ; Les autres tests d'invisibilité
    ; < Test face0 ET face0d
    LD A, (rendu_data)
    CALL add_16_8            ; HL une case devant
    LD A, (HL)
    AND (IX+2)               ; Mur juste devant le joueur ?
    PUSH AF                  ; Sauvegarde du test
    LD A, (rendu_data+1)
    CALL add_16_8            ; HL pointe sur la cellule à droite, et devant le joueur
    POP AF
    JR NZ, .test2_face1d_mur2d; Si pas de mur juste devant le joueur, on effectue le second test
    LD A, (HL)
    AND (IX+2)               ; Mur face juste à droite devant ?
    JR Z, .face_case2       ; Si oui, on n'affiche pas le côté droit à deux cases du joueur
.test2_face1d_mur2d: ; < Test face1d ET mur2d
    LD A, (rendu_data)
    CALL add_16_8    ; HL pointe sur la cellule à droite et à deux cases devant le joueur
    LD A, (HL)
    AND (IX+2)       ; Mur face à une case devant et à droite du joueur ?
    JR NZ, .display_face2d ; Si pas de mur, possible qu'on doit afficher ce mur et le reste
    LD A, (HL)
    AND (IX+3)       ; Mur gauche sur cette cellule ?
    JR Z, .face_case2 ; Si oui, rien à afficher de cette cellule
.display_face2d:
    LD A, (HL)
    AND (IX+0)
    JR NZ, .face_case2
    PUSH DE
    CALL mur_face2d
    POP DE
.face_case2:
    POP HL
    PUSH HL          ; restauration de HL sur le joueur
    ; Mur en face à deux cases du joueur
    ; Invisible si face0 OU face1
    LD A, (rendu_data)
    CALL add_16_8     ; HL une case devant le joueur
    LD A, (HL)
    AND (IX+2)        ; Mur juste devant le joueur ?
    JR Z, .case1 ; Si oui, rien à afficher
    LD A, (HL)
    AND (IX+0)        ; Mur à une case devant le joueur ?
    JR Z, .case1 ; Si oui, rien à afficher
    LD A, (rendu_data)
    CALL add_16_8     ; HL pointe deux cases devant le joueur    
    LD A, (HL)
    AND (IX+0)        ; Mur à afficher ?
    JR NZ, .mur2g      ; Si non, on va voir si il faut afficher un mur gauche
    PUSH HL
    PUSH DE
    CALL mur_face2
    POP DE
    POP HL
.mur2g:
    LD A, (HL)
    AND (IX+3)
    JR NZ, .mur2d
    PUSH HL
    PUSH DE
    CALL mur_gauche2
    POP DE
    POP HL
.mur2d:
    LD A, (HL)
    AND (IX+1)
    JR NZ, .echelle_haut2
    PUSH HL
    PUSH DE
    CALL mur_droite2
    POP DE
    POP HL
.echelle_haut2:
    LD A, (HL)
    AND HAUT_VALUE
    JR Z, .echelle_bas2
    PUSH HL
    PUSH DE
    CALL echelle2 
    POP DE
    POP HL
.echelle_bas2:
    LD A, (HL)
    AND BAS_VALUE
    JR Z, .case1
    PUSH DE
    CALL echelle_bas2
    POP DE
; .......................
.case1:
    POP HL
    PUSH HL     ; Restauration de HL sur la cellule où se trouve le joueur
    ; -----------------------------------------------------------------------------------
    ; -- On s'occupe de la partie gauche à une case devant le joueur                   --
    ; -----------------------------------------------------------------------------------
    ; < Ce mur est invisible si (face0 ET faceg0) OU (faceg0 ET murg1)
    ; <                      OU (face0 ET murg1) ou BORNE
    ; ... Test BORNE ...
    LD A, E
    AND (IX+7)            ; Masque pour borne gauche
    CP (IX+11)            ; Et test valeur borne gauche
    JR Z, .case1_droite   ; Si borne, on regarde partie droite
    ; < Test face0 ET murg1
    LD A, (rendu_data)
    CALL add_16_8         ; HL une case devant le joueur
    LD A, (HL)
    AND (IX+2)            ; Mur juste devant le joueur ?
    JR NZ, .test1_faceg0_murg1 ; Si non, second test
    LD A, (HL)
    AND (IX+3)            ; Mur gauche à une case devant le joueur ?
    JR Z, .case1_droite
    ; < Test face0 (déjà fait) ET faceg0
    PUSH HL               ; Sauvegarde HL devant le joueur
    LD A, (rendu_data+1)
    CALL sub_16_8        ; HL à gauche devant le joueur
    LD A, (HL)
    AND (IX+2)           ; Mur face à gauche juste devant le joueur ? 
    POP HL
    JR Z, .case1_droite
.test1_faceg0_murg1: ; < Test faceg0 et murg1
    LD A, (rendu_data+1)
    CALL sub_16_8        ; HL est à gauche une case devant le joueur
    LD A, (HL)
    AND (IX+2)           ; faceg0 ?
    JR NZ, .display_face1g
    LD A, (HL)
    AND (IX+1)           ; Mur droite (gauche pour le joueur) ?
    JR Z, .case1_droite ; Si oui, pas d'affichage à faire
.display_face1g:
    LD A, (HL)
    AND (IX+0)
    JR NZ, .case1_droite
    PUSH DE
    CALL mur_face1g
    POP DE
.case1_droite:
    POP HL
    PUSH HL     ; Restauration de HL sur la cellule où se trouve le joueur
    ; -----------------------------------------------------------------------------------
    ; -- On s'occupe de la partie droite à une case devant le joueur                   --
    ; -----------------------------------------------------------------------------------
    ; < Ce mur est invisible si (face0 et faced0) ou (faced0 et murd1)
    ; <                      OU (face0 et murd1) ou BORNE
    ; ... Test BORNE ...
    LD A, E
    AND (IX+5)
    CP  (IX+9)
    JR Z, .face_case1
    ; < Test face0 ET (faced0 OU murd1)
    LD A, (rendu_data)
    CALL add_16_8          ; HL pointe sur la case juste devant le joueur
    LD A, (HL)
    AND (IX+2)             ; Mur juste devant le joueur ?
    JR NZ, .test1_faced0_murd1 ; Non, on essaie donc le second test
    AND (IX+1)             ; Mur de droite ?
    JR Z, .face_case1     ; Si oui, pas d'affichage à faire
    PUSH HL
    LD A, (rendu_data+1)
    CALL add_16_8          ; On décale sur la droite, une case en avant
    LD A, (HL)
    AND (IX+2)             ; Mur face à droite juste devant le joueur
    POP HL                 ; Pour s'assurer que HL pointe juste devant le joueur
    JR Z, .face_case1
.test1_faced0_murd1:
    LD A, (rendu_data+1)
    CALL add_16_8          ; HL pointe sur la case à droite, devant le joueur
    LD A, (HL)
    AND (IX+2)             ; faced0 ?
    JR NZ, .display_face1d
    LD A, (HL)
    AND (IX+3)             ; murd1 ? (à gauche de cette cellule)
    JR Z, .face_case1
.display_face1d:
    ; Si il y a un mur, il faut l'afficher
    LD A, (HL)
    AND (IX+0)
    JR NZ, .face_case1
    PUSH DE
    CALL mur_face1d
    POP DE
    ; -----------------------------------------------------------------------------------
    ; -- On s'occupe de ce qu'il y a devant le joueur                                  --
    ; -----------------------------------------------------------------------------------
.face_case1:
    POP HL
    PUSH HL             ; Restauration de HL
    ; < Le mur en face à une case du joueur est invisible que si face0
    LD A, (HL)
    AND (IX+0)
    JR Z, .case0
    LD A, (rendu_data)
    CALL add_16_8       ; HL une case devant le joueur
    LD A, (HL)
    AND (IX+0)
    JR NZ, .mur1g 
    PUSH HL
    PUSH DE
    CALL mur_face1
    POP  DE
    POP  HL
.mur1g:
    LD A, (HL)
    AND (IX+3)
    JR NZ, .mur1d
    PUSH HL
    PUSH DE
    CALL mur_gauche1
    POP  DE
    POP  HL
.mur1d:
    LD A, (HL)
    AND (IX+1)
    JR NZ, .haut1
    PUSH HL
    PUSH DE
    CALL mur_droite1
    POP  DE
    POP  HL
.haut1:
    LD A, (HL)
    AND HAUT_VALUE
    JR Z, .bas1 
    PUSH HL
    PUSH DE
    CALL echelle1   
    POP  DE
    POP  HL
.bas1:
    LD A, (HL)
    AND BAS_VALUE
    JR Z, .case0
    PUSH DE
    CALL echelle_bas1
    POP  DE
; ....................................
.case0:
    POP  HL
    PUSH HL                 ; Restauration de HL
    ; Affichage mur face gauche si possible (impossible si BORNE)
    LD A, E
    AND (IX+7)
    CP  (IX+11)
    JR Z, .face0d
    LD A, (rendu_data+1)
    CALL sub_16_8
    LD A, (HL)
    AND (IX+0)
    JR NZ, .face0d
    PUSH HL
    PUSH DE
    CALL mur_face0g
    POP  DE
    POP  HL
.face0d:
    LD A, E
    AND (IX+5)
    CP  (IX+9)
    JR Z, .face0
    POP  HL
    PUSH HL
    LD A, (rendu_data+1)
    CALL add_16_8
    LD A, (HL)
    AND (IX+0)
    JR NZ, .face0
    PUSH DE
    CALL mur_face0d
    POP  DE
.face0:
    POP HL
    ; Plus du push puisque derniers tests
    LD A, (HL)
    AND (IX+0)
    JR NZ, .murg0
    PUSH HL
    PUSH DE
    CALL mur_face0
    POP  DE
    POP  HL
.murg0:
    LD A, (HL)
    AND (IX+3)
    JR NZ, .murd0
    PUSH HL
    PUSH DE
    CALL mur_gauche0
    POP  DE
    POP  HL
.murd0:
    LD A, (HL)
    AND (IX+1)
    JR NZ, .haut0
    PUSH HL
    PUSH DE
    CALL mur_droite0
    POP  DE
    POP  HL
.haut0:
    LD A, (HL)
    AND HAUT_VALUE
    JR Z, .bas0
    PUSH HL
    PUSH DE
    CALL echelle0
    POP  DE
    POP  HL
.bas0:
    LD A, (HL)
    AND BAS_VALUE
    JR Z, .item0
    PUSH HL
    PUSH DE
    CALL echelle_bas0    
    POP  DE
    POP  HL
.item0:
    LD A, (HL)
    AND ITEM_VALUE
    JR Z, .monster0
    PUSH HL
    PUSH DE
    CALL item0
    POP  DE
    POP  HL
.monster0:
    LD A, (HL)
    AND MONSTRE_VALUE
    JR Z, .end_rendu_sud
    PUSH HL
    PUSH DE
    ; CALL monstre0
    POP  DE
    POP  HL
.end_rendu_sud:
    RET
rendu_data:
    ; Devant, Droite, saut en bytes pour une case
    DB 0xFF, 0xFF
    ; Dir devant, droite, derriere, gauche en Nord, ouest, est, sud
    DB 0xFF, 0xFF, 0xFF, 0xFF
    ; Masque pour test borne quatre directions
    DB 0xFF, 0xFF, 0xFF, 0xFF
    ; Borne pour les quatre directions (devant, droite, derriere, gauche)
    DB 0xFF, 0xFF, 0xFF, 0xFF
; ............... Cas où le joueur est tourné vers le Sud ...........................
sud_rendu_data:
    ; Steps
    DB -8, -1
    ; Conversion en direction :
    DB SUD_VALUE, OUEST_VALUE, NORD_VALUE, EST_VALUE
    ; Masque bornes
    DB 56, 7, 56, 7
    ; Valeur des bornes
    DB  0, 0,  7, 7
nord_rendu_data:
    ; Steps
    DB 8, 1
    ; Conversion en direction :
    DB NORD_VALUE, EST_VALUE, SUD_VALUE, OUEST_VALUE
    ; Masque bornes:
    DB 56, 7, 56, 7
    ; Valeur des bornes:
    DB 7, 7, 0, 0
est_rendu_data:
    ; steps:
    DB 1, -8
    ; Conversion en directions :
    DB EST_VALUE, SUD_VALUE, OUEST_VALUE, NORD_VALUE
    ; Masque bornes:
    DB 7, 56, 7, 56
    ; Valeur des bornes :
    DB 7, 0, 0, 7
ouest_rendu_data:
    ; steps
    DB -1, 8
    ; Conversion en direction
    DB OUEST_VALUE, NORD_VALUE, EST_VALUE, SUD_VALUE
    ; Masque des bornes
    DB 7, 56, 7, 56
    ; Valeur des bornes
    DB 0, 7, 7, 0
;## #####################################################################################
;##  ## Change la direction de vue du joueur selon le changement de direction donné par##
;##  ## le joueur                                                                      ##
;##  ##      En entrée :                                                               ##
;##  ##         B : 1 : tourne sur la gauche                                           ##
;##  ##             2 : tourne à droite                                                ##
;##  ##             4 : fait demi-tour                                                 ##
;##  ##             8 : avance joueur                                                  ##
;##  ##            16 : monte
;##  ##            32 : descend
;## #####################################################################################
bouge_joueur:
    LD DE, (joueur_position)
    LD HL, DonjonData
    ADD HL, DE
    BIT 4, B
    JP NZ, .monte 
    BIT 5, B
    JP NZ, .descend
    LD A, (joueur_direction)
    CP SUD_VALUE
    JR Z, .sud
    CP EST_VALUE
    JR Z, .est
    CP OUEST_VALUE
    JP Z, .ouest
    ; Cas Nord:
    BIT 0, B
    JR Z, .nord_droite
    LD A, OUEST_VALUE
    JP .update_data
.nord_droite:
    BIT 1, B
    JR Z, .nord_demitour
    LD A, EST_VALUE
    JP .update_data
.nord_demitour:
    BIT 2, B
    JR Z, .nord_avance
    LD A, SUD_VALUE
    JP .update_data
.nord_avance:
    BIT 3, B
    RET Z
    LD A, (HL)
    AND NORD_VALUE
    RET Z
    EX DE, HL
    LD A, 8
    CALL add_16_8
    LD (joueur_position), HL
    RET
.sud:
    BIT 0, B
    JR Z, .sud_droite
    LD A, EST_VALUE
    JR .update_data
.sud_droite:
    BIT 1, B
    JR Z, .sud_demitour
    LD A, OUEST_VALUE
    JR .update_data
.sud_demitour:
    BIT 2, B
    JR Z, .sud_avance
    LD A, NORD_VALUE
    JR .update_data
.sud_avance:
    BIT 3, B
    RET Z
    LD A, (HL)
    AND SUD_VALUE
    RET Z
    EX DE, HL
    LD A, -8
    CALL add_16_8
    LD (joueur_position), HL
    RET
.est:
    BIT 0, B
    JR Z, .est_droite
    LD A, NORD_VALUE
    JR .update_data
.est_droite:
    BIT 1, B
    JR Z, .est_demitour
    LD A, SUD_VALUE
    JR .update_data
.est_demitour:
    BIT 2, B
    JR Z, .est_avance
    LD A, OUEST_VALUE
    JR .update_data
.est_avance:
    BIT 3, B
    RET Z
    LD A, (HL)
    AND EST_VALUE
    RET Z
    INC DE
    LD (joueur_position), DE
    RET
.ouest:
    BIT 0, B
    JR Z, .ouest_droite
    LD A, SUD_VALUE
    JR .update_data
.ouest_droite:
    BIT 1, B
    JR Z, .ouest_demitour
    LD A, NORD_VALUE
    JR .update_data
.ouest_demitour:
    BIT 2, B
    JR Z, .ouest_avance
    LD A, EST_VALUE
    JR .update_data
.ouest_avance:
    BIT 3, B
    RET Z
    LD A, (HL)
    AND OUEST_VALUE
    RET Z
    DEC DE
    LD (joueur_position), DE
    RET
.update_data:
    LD (joueur_direction), A
    CP SUD_VALUE
    JR NZ, .est_test
    LD HL, sud_rendu_data
    JR .make_update
.est_test:
    CP EST_VALUE
    JR NZ, .ouest_test
    LD HL, est_rendu_data
    JR .make_update
.ouest_test:
    CP OUEST_VALUE
    JR NZ, .nord_test
    LD HL, ouest_rendu_data
    JR .make_update
.nord_test:
    LD HL, nord_rendu_data
.make_update:
    LD DE, rendu_data
    LD BC, 14
    LDIR
    RET
.monte:
    LD A, (HL)
    AND HAUT_VALUE
    RET Z
    LD HL, (joueur_position)
    LD DE, 64
    ADD HL, DE
    LD (joueur_position), HL
    RET
.descend:
    LD A, (HL)
    AND BAS_VALUE
    RET Z
    LD HL, (joueur_position)
    LD DE, -64
    ADD HL, DE
    LD (joueur_position), HL
    RET

;## Met à jour les pièces visitées (bit 128 de l'état des pièces) 
update_visited_rooms:
    LD DE, (joueur_position)
    LD HL, DonjonData
    ADD HL, DE
    LD A, (HL)
    OR MONSTRE_VALUE
    LD (HL), A
    RET

;## Affiche l'état du joueur à droite de l'écran de visualisation
affiche_etat_joueur:
    LD HL, .titre
    CALL print42
.update_energie:
    CALL wait_vsync
    LD HL, .energie
    CALL print42
    LD HL, .del_num
    CALL print42
    LD HL, joueur_energie
    LD A, (HL)
    LD H, 0
    LD L, A
    CALL convert_to_digits    
    CALL print42
    RET
.titre:
    DB AT, 0, 32, "  JOUEUR  ", ENDSTR
.energie:
    DB AT, 3, 32, "Energ ", ENDSTR
.del_num:
    DB "   ", DEL, DEL, DEL, ENDSTR
display:
.joueur:
    LD HL, .position
    CALL print42
    LD HL, joueur_position
    CALL .update_pos
    LD HL, .direction
    CALL print42
    JR .update_dir
.update_pos:
    CALL wait_vsync
    LD HL, printAt42Coords
    LD (HL), 4
    INC HL
    LD (HL), 16
    LD HL, joueur_position
    LD A, (HL)
    AND 7
    LD H, 0
    LD L, A
    CALL convert_to_digits
    CALL print42
    LD HL, .virgule
    CALL print42
    LD HL, joueur_position
    LD A, (HL)
    AND 63
    SRL A
    SRL A
    SRL A
    LD H, 0
    LD L, A
    CALL convert_to_digits
    CALL print42
    LD HL, .etage
    CALL print42    
    LD DE, (joueur_position)
    LD A, D
    AND 1
    SLA E
    RLA
    SLA E
    RLA
    INC A
    LD H, 0
    LD L, A
    CALL convert_to_digits
    CALL print42    
    RET
.update_dir:
    CALL wait_vsync
    LD HL, printAt42Coords
    LD (HL), 18
    INC HL
    LD (HL), 16
    LD HL, joueur_direction
    LD A, (HL)
    CP NORD_VALUE
    JR Z, .disp_nord
    CP SUD_VALUE
    JR Z, .disp_sud
    CP EST_VALUE
    JR Z, .disp_est
    LD HL, .ouest
    CALL print42
    RET
.disp_nord:
    LD HL, .nord
    CALL print42
    RET
.disp_sud:
    LD HL, .sud
    CALL print42
    RET
.disp_est:
    LD HL, .est
    CALL print42
    RET
.position:
    DB AT, 16, 0, "Pos ", ENDSTR
.virgule:
    DB ", ", ENDSTR
.etage:
    DB " Et ", ENDSTR
.direction:
    DB AT, 16, 14, "Dir ", ENDSTR
.nord:
    DB "N", ENDSTR
.sud:
    db "S", ENDSTR
.ouest:
    DB "O", ENDSTR
.est:
    DB "E", ENDSTR

DonjonSeed:
    dw 0x0000
joueur_direction:
    DB NORD_VALUE
joueur_position:
    DB 0, 0
joueur_energie:
    DB 127

DonjonMap:
	BLOCK 60-33, 0xAA
map_zx:
	incbin "map.zx0"

