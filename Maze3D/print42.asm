/**
 * @file print42.asm
 * @brief Code assembleur permettant d'afficher 42 caractères sur une seule ligne en mode 4 pour le Sanyo PHC 25
 * @author XPenguin
 * @date 21 Juin 2025
 * @note Adapté de la routine donnée pour le ZX Spextrum dans le Boriel zxbasic 
 *      ( Copyleft (K) 2008, Jose Rodriguez-Rosa (a.k.a. Boriel) <http://www.boriel.com>
 */
    ;include "structures.asm"
    include "constantes.asm"
    include "macros.asm"
    include "structures.asm"

;## ####################################################################################################################
;## Affiche un message à l'écran avec 42 colonnes sur une ligne (au lieu de 32)                                       ##
;## La chaine de caractère suit la convention ASCII et doit se terminer par un caractère nul comme en C               ##
;## Quelques caractères de contrôles qui remplace les caractères ASCII inférieurs à 32 :                              ##
;##     -  22, r, c : Repositionne le curseur en ligne r colonne c pour la suite du texte                             ##
;##     -  13       : Retour à la ligne                                                                               ##
;##     -   8       : Efface le caractère précédent (backspace)                                                       ##
;## # En entrée:                                                                                                      ##
;##      HL : adresse de la chaîne de caractère à afficher                                                            ##
;## ####################################################################################################################
print42:
    ; /==/ Teste en premier si le pointeur est nul ou non
    LD A, H
    OR L
    RET Z            ; On quitte la routine immédiatement si le pointeur contenu dans HL est nul
.examine_car
    LD A,(HL)        ; On lit le caractère pointé par le pointeur courant
    OR A             ; Caractère nul ?
    RET Z            ; On quitte la routine
    CP 128           ; Caractère non affichable ?
    JR NC, .next_car ; Alors on va au prochain caractère

    CP 22            ; Est-ce une commande pour repositionner la suite du texte
    JR NZ, .is_new_line ; Si ce n'est pas le cas, on saute au test pour voir si ce n'est pas une nouvelle ligne ?
.is_at:
    INC HL          ; Pointe sur le n° de ligne
    LD D,(HL)       ; Qu'on stocke dans D
    INC HL          ; On pointe sur le n° de colonne
    LD E,(HL)       ; Qu'on stocke dans E
    LD (printAt42Coords), DE
    JR .next_car

.is_new_line:
    CP 13           ; Est-ce un caractère de contrôle pour le retour à la ligne
    JR NZ, .check_del ; Si non, on teste pour le prochain caractère de contrôle
.new_line:
    LD DE, (printAt42Coords)
    CALL testcoords.nxtline       ; On saute à la prochaine ligne
    LD (printAt42Coords), DE
    JR .next_car

.check_del:
    CP 8
    JR NZ, .check_valid         ; Non, ce n'est pas un caractère de suppression
    ld DE, (printAt42Coords)
    DEC DE
    LD (printAt42Coords), DE
    LD A, 41
    CP E
    JR NC, .next_car           ; Si DE n'est pas plus grand que 41, ok valie et on passe au prochain caractère
    LD E, A                    ; Sinon, on repositionne le texte à la colonne 41
    LD (printAt42Coords), DE
    LD A, 23 
    CP D
    JR NC, .next_car           ; Si la nouvelle ligne est plus petite que 23, ok, on peut passer au prochaine caractère
    LD D, A                    ; Sinon, on replace le curseur à la 23e ligne
    LD (printAt42Coords), DE
    JR .next_car

.check_valid:
    CP 31            ; Caractère < 31, pas pris en compte si pas contrôle
    JR C, .next_car  ; Si non, aller au prochaine caractère

.prn:
    PUSH HL          ; > Sauvegarder notre position
    CALL printachar  ; On affiche le caractère pointé par HL
    POP HL           ; < Restaure notre position

.next_car:
    INC HL           ; On pointe sur le prochain caractère
    JR .examine_car  ; Et on boucle jusqu'à rencontrer le caractère nul

;## ####################################################################################################################
;## Cette routine forme les nouveaux caractères de 6-bit de large. L'espace de travail de 8 octets est localisé à la  ##
;## fin de cette section.                                                                                             ##
;##     En entrée :                                                                                                   ##
;##         A contient le code ASCII du caractère à afficher                                                          ##
;## ####################################################################################################################
printachar:
    EXX                ; /===/ Echange des registres
    PUSH HL            ; > Sauvegarde H'L' 
    EXX                ; /===/ Echange des registres

    LD H, 0   
    LD L, A            ; Copie dans L du code ASCCI de la lettre à afficher

    LD DE, fontes - 256     ; DE pointe sur les fontes -32*8 pour décalage ASCII
    CALL mult8         ; HL <-- 8 * L + DE

    LD B, H
    LD C, L            ;### Copie l'adresse de la fonte du caractère dans BC
.printdata:
    CALL testcoords    ; On vérifie notre position et on wrappe si nécessaire. Au retour, on a d = y et e = x
    INC E              ; On passe à la prochaine coordonnée pour le prochain caractère
    LD (printAt42Coords), DE ; On stocke nos coordonnées pour le prochain caractère
    DEC E              ; Et on revient à notre position (pour afficher le caractère)
    LD A, E            ; A contient x
    SLA A              ; A contient maitenant 2x
    LD L, A            ; On stocke 2x dans L
    SLA   A            ; A contient maintenant 4x
    ADD L              ; On ajoute 4x à 2x donc A contient 6x
    LD L, A            ; On stocke 6x dans L (ce qui correspond au n° du premier pixel sur la ligne concernée dont on s'intéresse)
    SRL A              ; A contient 6x/2
    SRL A              ; A contient 6x/4
    SRL A              ; A contient 6x/8
    LD E, A            ; Puisque un octet contient 8 pixels, on a dans E la colonne en caractère où on affiche notre premier pixel
    LD A, L            ; On restocke notre pixel de nouveau
    AND 7              ; Avec un modulo 8 (pour avoir le décalage en pixel dans le caractère écran)
    EX AF, AF'         ; /===/ Echange AF avec AF' pour sauvegarder le décalage en pixel
    LD H, D            ; HL = y * 256
    LD L, E            ; HL = y * 256 + x
    LD  A,  HIGH_SCREEN_ADDR 
    ADD H
    LD  H, A           ; HL contient l'adresse de l'écran où afficher le début du caractère
.hop1:
    PUSH HL            ; > Sauvegarde de HL (= adresse écran où afficher début du caractère)
    EXX                ; /===/ Echange des registres
    POP HL             ; < Restaure HL dans H'L' (H'L' contient adresse début affichage caractère)
    EXX                ; /===/ Echange des registres (Les 4 lignes reviennent à recopier HL dans H'L')
    LD A, 8
.hop4:
    PUSH AF            ; > On sauvegarde l'acumulateur (qui compte le nombre de lignes encore à afficher)
    LD A, (BC)         ;### On charge une ligne du caractère à afficher dans A
    EXX                ; /===/ Echange des registres
    PUSH  HL           ; > Sauvegarde de H'L' (qui contient l'adresse début affichage) et on récupère l'adresse écran qui est aussi dans HL
    LD DE, 1023        ; Pour le calcul du masque, on met 1023 dans D'E' (Tous les bits à 1 sauf les six les plus à gauche)
    LD C,  0           ; Mettre 0 dans C'
    EX AF, AF'         ; /===/ Echange des accumulateurs, on récupère le décalage en bit que l'on doit faire
    AND A              ; Pour vérifier si le décalage est nul ou non
    JR Z, .nodecal     ; Pas de décalage si A = 0, on saute directement au rendu

    LD B, A            ; On récupère le décalage dans B pour faire une boucle
    EX AF, AF'         ; /===/ Echange des accumulateurs. On récupère l'octet de la lettre qu'on est en train d'afficher
.decal: ; Décalage d'un octet pour la position à droite du bloc ( et met les bits restant dans le côté gauche de C)
    AND A              ; Pour effacer le drapeau de retenu
    RRA                ; Un décalage à droite du pattern contenu dans A. Le bit à droite est mis dans le drapeau de retenu.
    RR C               ; C récupère le bit mis à droite dans le drapeau de retenu
    SCF                ; Met à un le drapeau de retenu
    RR D               ; Décalage à droite de D avec mis sur le drapeau de retenue du bit le plus à droite pour D
    RR E               ; Décalage à droite de E (en fait, le décalage de D se reporte sur E)
    DJNZ .decal        ; On boucle tant que B n'est pas nul
    EX AF, AF'         ; /===/ Echange des accumulateurs, on récupère le décalage en bit que l'on doit faire
.nodecal:
    EX AF, AF'         ; /===/ Echange des accumulateurs. On récupère l'octet de la lettre qu'on est en train d'afficher (même avec le saut)
    LD B, A            ; On sauvegarde l'octet de la lettre (ou une partie de la lettre) à afficher dans B
    LD A, (HL)         ; On récupère l'état de l'écran à l'endroit où on doit afficher une partie gauche de la lettre
    AND D              ; Masquage par D
    OR  B              ; Affichage de la partie gauche de la lettre (peut être la lettre entière)
    LD (HL), A         ;
    INC HL             ; On passe à l'octet suivant pour afficher le reste de la lettre
    LD A, (HL)         ;
    AND E              ; Masque pour la partie droite de la lettre
    OR  C              ; Qu'on combine avec la partie droite de la lettre
    LD (HL), A         ; On affiche le résultat sur l'écran
    POP HL             ; < Restauration de HL qui contient l'adresse écran où afficher la partie gauche de la lettre
    LD DE, 32
    ADD HL, DE         ; Pour la prochaine ligne
    EXX                ; /===/ Echange des registres
    INC BC             ; Pour la prochaine ligne de la lettre à afficher
    POP AF             ; < Restauration de AF qui contient le nombre de lignes restant à afficher
    DEC A              ;
    JR NZ, .hop4       ; Boucle pour afficher le reste de la lettre

    // Restauration de la pile pour que tout soit clean
    EXX                ; /===/ Echange des registres
    POP  HL            ; < Restauration de la pile
    EXX                ; /===/ Echange des registres
    RET                ; On retourne
;## ####################################################################################################################
;## Multiplie L par huit -> HL et ajoute DE à HL                                                                      ##
;## ####################################################################################################################
mult8:
    LD H, 0
    ADD HL, HL
    ADD HL, HL
    ADD HL, HL
    ADD HL, DE
    RET
;## ####################################################################################################################
;## Teste les coordonnées 
testcoords:
    LD DE, (printAt42Coords) ; Récupère les coordonnées où afficher les coordonnées (d = y, e = x)
.nxt_car:
    LD A, E
    CP 42            ; On dépasse les 42 colonnes ?
    JR C, .ycoord    ; Si non, on continue
.nxtline:
    INC D            ; Si oui, on passe à la ligne suivante
    LD E, 0          ; en remettant x = 0
.ycoord:
    LD A, D
    CP 24              ; On dépasse les 24 lignes ?
    RET C              ; Si non, bin, c'est bon non ? Fin du test
    LD D, 0            ; Sinon, on wrap pour se retrouver à la ligne au dessus
    RET                ; Et on sort de la routine

printAt42Coords Coord2D

fontes:
    BLOCK (773 - 420), 0xAA
fontes_zx: 
    incbin "font6x8.zx0"	
    ;incbin "font.zx0"
