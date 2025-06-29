;# Test sur la génération du donjon et de son affichage sous forme de carte
    include "macros.asm"
    include "constantes.asm"

    ORG 0XC009
start:
    set_screen SCREEN_4_MASK, SCREEN_4_SET
    CALL cls
    DI
    LD HL, fontes_zx
    LD DE, fontes
    CALL dzx0_standard
    LD HL, Text_wait
    CALL print42

    CALL init_donjon
    CALL genere_donjon
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!
    EXX
    LD HL, dbg_quitte
    EXX
    PUSH AF
    CALL print_regs
    CALL wait_for_space
    POP AF
    ;!!!!!!!!!!!!!!! DEBOGUE !!!!!!!!!!!!!!!!


    CALL cls
    LD HL, Text_done
    CALL print42
    CALL wait_for_space

    LD HL, map_zx
    LD DE, DonjonMap
    CALL dzx0_standard

    LD A, 0            ; On commance à l'étage de base
    LD (etage), A
.loop:
    CALL cls
    LD HL, Text_etage
    CALL print42
    LD HL, (etage)
    INC HL
    CALL convert_to_digits
    LD HL, BUF
    CALL print42
    LD A, (etage)
    CALL display_map
    CALL wait_for_space
    LD A, (etage)
    INC A
    AND 7
    LD (etage), A
    JR .loop

dbg_quitte:
    db AT, 4, 15, "Debug quiite", 0
Txt_decompressing:
    db AT, 7, 12, "Decompressing !", 0
Text_wait:
    db AT, 12, 1, "Le donjon est en cours de generation...", 0
Text_done:
    db AT, 12, 7, "Fini !!! Appuyez sur espace", 0
Text_etage:
    db AT, 9, 0, "Etage n.", 0

    include "dzx0_standard.asm"
    include "print42.asm"
    include "donjon.asm"
    include "graphism.asm"
    include "stdlib.asm"
    include "keys.asm"

    include "data.asm"
etage:
    db 0x0, 0x0

    END