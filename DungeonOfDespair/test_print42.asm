;# Programme pour tester la fonction print42
    include "macros.asm"
    include "constantes.asm"

    ORG 0XC009
start:
    set_screen SCREEN_4_MASK, SCREEN_4_SET
    CALL cls
    LD HL, fontes_zx
    LD DE, fontes
    CALL dzx0_standard
    DI
    LD HL, texte
    CALL print42
.loop:
    JR .loop

    include "dzx0_standard.asm"
    include "graphism.asm"
    include "print42.asm"

texte:
    db AT, 0, 10, "Le donjon du desespoir"
    db AT, 2, 0, "Alors que vous traversez  la foret de l'om"
    db           "bre,vous etes attaque par un groupe d'orcs"
    db           "qui vous font prisonnier.", ENDL
    db           " Sans menagement, vous etes jete  dans les" 
    db           "profondeurs du donjon du desespoir. Heureu"
    db           "sement, vous arrivez a vous liberer de vos"
    db           "chaines et vous avez mis la main  sur  une"
    db           "arme.", ENDL
    db           "VOTRE BUT : Sortir  du donjon en remontant"
    db           "tous les etages qui menent a votre liberte", ENDSTR


    end
