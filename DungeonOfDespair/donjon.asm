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
;## ====================================================================================================================
;##     Recherche une case visitée possédant encore une sortie potentielle vers une case non visitée                  ==
;##          En sortie :                                                                                              ==
;##              - HL contient sur la case  dont l'indice est sous la forme [0..0z2][z1|z0|y2|y1|y0|x2|x1|x0] qui     ==
;##                correspond en même temps à l'indice de la salle                                                    ==
;##     Si aucune case vide n'est trouvée, HL retourne le pointeur nul                                                ==
;## ====================================================================================================================
trace_cherche_case_vide:
    db AT, 4, 15, "Cherche case vide   ", 0
aff_sortie_pot:
    db AT, 4, 15, "Sorties potentielles", 0
aff_decompt:
    db AT, 4, 15, "Compteurs boucles   ", 0
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
;## Affiche la carte de l'étage courant à l'écran en affichant uniquement que les pièces déjà visitées (en s'aidant de==
;## VisitedRooms)                                                                                                     ==
;##      En entrée :                                                                                                  ==
;##           A : n° de l'étage courant (où se trouve le joueur)                                                      ==
;## ====================================================================================================================
display_map:
    ; Calcul de l'adresse de l'étage à afficher :
    LD HL, DonjonData + 63 ; +63 pour commencer à la dernière salle de l'étage
    LD DE, 64              ; Chaque étage fait 64 octets
    LD B, A                ; B contient l'étage à afficher
    OR A
    JR Z, .no_loop
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
;### La graine du donjon est stockée ici. Si elle est nulle (par défaut), on va prendre une graine aléatoire
DonjonSeed:
    dw 0x0000
