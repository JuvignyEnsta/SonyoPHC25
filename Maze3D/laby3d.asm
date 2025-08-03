    include "macros.asm"
    include "constantes.asm"

    ORG 0XC009
start:
    ;  ## Décompression des fontes 6x8
    LD HL, fontes_zx
    LD DE, fontes
    CALL dzx0_standard
    ; ## Affichage
    set_screen SCREEN_4_MASK, SCREEN_4_SET
    CALL cls
    DI

    LD HL, map_zx
    LD DE, DonjonMap
    CALL dzx0_standard

.loop_init:
    LD HL, Text_wait
    CALL print42

    ; ## Initialisation du donjon
    CALL init_donjon
    CALL genere_donjon

    ; Rajout de la nourriture dans le donjon au hasard:
    LD B, 50
.loop_food:
    CALL rand
    EX DE, HL
    LD A, D
    AND 1
    LD D, A
    LD HL, DonjonData
    ADD HL, DE
    LD A, (HL)
    BIT ITEM, A     ; Pour ne pas mettre deux fois de la nourriture au même endroit
    JR NZ, .loop_food    
    OR ITEM_VALUE
    LD (HL), A
    DJNZ .loop_food

    CALL cls
    LD HL, Espace_msg
    CALL print42
    CALL wait_for_space

    LD A, 0            ; On commance à l'étage de base
    LD (etage), A
    LD (joueur_position), A
    LD (joueur_position+1), A
    LD A, NORD_VALUE
    LD (joueur_direction), A
    LD A, 63
    LD (joueur_energie), A

    CALL cls

    LD HL, nord_rendu_data
    LD DE, rendu_data
    LD BC, 14
    LDIR

    CALL cls_frame
    CALL draw_frame
    LD A, (joueur_position  )
    LD E, A
    LD A, (joueur_position+1)
    LD D, A
    CALL rendu
    CALL blit
    CALL display.joueur
    CALL affiche_etat_joueur
.infinite:
    IN A, 130
    BIT 4, A    ; Touche flèche gauche pressée ?
    JR NZ, .fleche_droite ; Si non, test flèche droite
    LD B, 1
    CALL bouge_joueur
    CALL display.update_dir
    JP .update
.fleche_droite:
    IN A, 131
    BIT 4, A
    JR NZ, .fleche_haut ; Si non, test pour avancer
    LD B, 2
    CALL bouge_joueur
    CALL display.update_dir
    JP .update
.fleche_haut:
    IN A, 128
    BIT 4, A
    JR NZ, .demi_tour
    LD HL, joueur_energie
    DEC (HL)
    XOR A
    OR (HL)
    JP Z, .fin_jeu
    CALL affiche_etat_joueur.update_energie
    LD B, 8 
    CALL bouge_joueur
    CALL update_visited_rooms
    CALL display.update_pos
    ; On vérifie si on n'est pas arrivé à la sortie :
    LD DE, (joueur_position)
    LD A, 7
    CP E
    JP NZ, .update
    LD A, 1
    CP D    
    JP NZ, .update
    CALL cls
    LD HL, Gagne_msg
    CALL print42
    LD HL, Espace_msg
    CALL print42
    CALL wait_for_space
    JP .loop_init
.demi_tour:
    IN A, 129
    BIT 4, A
    JR NZ, .monte
    LD B, 4
    CALL bouge_joueur
    CALL display.update_dir
    JP .update
.monte:
    IN A, 134
    BIT 1, A
    JR NZ, .descend
    LD B, 16
    CALL bouge_joueur
    CALL update_visited_rooms
    CALL display.update_pos
    JR .update
.descend:
    IN A, 131
    BIT 2, A
    JR NZ, .get_food
    LD B, 32
    CALL bouge_joueur
    CALL update_visited_rooms
    CALL display.update_pos
    JR .update
.get_food:
    IN A, 133
    BIT 2, A
    JR NZ,.map
    LD DE, (joueur_position)
    LD HL, DonjonData
    ADD HL, DE
    LD A, (HL)
    BIT ITEM, A
    JR Z, .map
    RES ITEM, A
    LD (HL), A
    LD HL, joueur_energie
    LD A, (HL)
    CP 53
    JR C, .rajoute
    LD (HL), 63
    JR .maj_energie
.rajoute:
    LD A, 10
    ADD (HL)
    LD (HL), A
.maj_energie:
    CALL affiche_etat_joueur.update_energie
    JR .update
.map:
    IN A, 134
    BIT 3, A
    JP NZ, .infinite
    CALL cls_frame
    CALL blit
    LD DE, (joueur_position)
    SLA E
    RL D
    SLA E
    RL D
    LD A, D
    AND 7
    CALL display_map
    LD HL, Espace_msg
    CALL print42
    CALL wait_for_space
    LD HL, joueur_energie
    DEC (HL)
    PUSH HL
    CALL affiche_etat_joueur.update_energie
    POP HL
    XOR A
    OR (HL)
    JP Z, .fin_jeu
.update:
    CALL cls_frame
    LD DE, (joueur_position)
    CALL rendu
    CALL blit
    JP .infinite
.fin_jeu:
    CALL cls
    LD HL, text_faim
    CALL print42
    LD HL, Espace_msg
    CALL print42
    CALL wait_for_space
    JP .loop_init
    include "dzx0_standard.asm"
    include "graphism.asm"
    include "donjon.asm"
    include "print42.asm"
    include "keys.asm"

text_faim:
    DB AT, 10, 1, "Vous etes mort de faim !", ENDSTR
Text_wait:
    db AT, 10, 1, "Donjon en cours de generation", 0
Espace_msg:
    db AT, 11, 0, "Appuyez sur espace", ENDSTR
Gagne_msg:
    db AT, 10, 0, "Bravo, vous etes arrive a sortir du donjon !", ENDSTR
etage:
    db 0x0, 0x0

    include "data.asm"
