;/=/     Utilitaires pour déboguer
    IFNDEF DEBUG_ASM
    DEFINE DEBUG_ASM true
;## ####################################################################################################################
;## Affichage des valeurs des registres.                                                                              ##
;##    En entrée:                                                                                                     ##
;##       H'L' : Pointeur sur l'étiquette à afficher                                                                  ##
;## ####################################################################################################################
hl_msg : 
    db AT, 6, 15, "HL:", ENDSTR
h_msg : 
    db AT, 6, 25, "H:", ENDSTR
l_msg : 
    db AT, 6, 34, "L:", ENDSTR
de_msg:
    db AT, 7, 15, "DE:", ENDSTR
d_msg : 
    db AT, 7, 25, "D:", ENDSTR
e_msg : 
    db AT, 7, 34, "E:", ENDSTR
bc_msg:
    db AT, 8, 15, "BC:", ENDSTR
b_msg : 
    db AT, 8, 25, "B:", ENDSTR
c_msg : 
    db AT, 8, 34, "C:", ENDSTR
a_msg:
    db AT, 9, 25, "A:", ENDSTR
reg_buffer:
    db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA
print_regs:
    LD (reg_buffer), HL
    LD (reg_buffer + 2), DE
    LD (reg_buffer + 4), BC
    LD (reg_buffer + 6), A
    PUSH AF                        ;> AF
    PUSH BC                        ;> BC
    PUSH DE                        ;> DE
    PUSH HL                        ;> HL
    EXX
    CALL print42 
    EXX
    LD HL, hl_msg
    CALL print42 
    LD HL, (reg_buffer)
    CALL convert_to_digits
    CALL print42
    LD HL, h_msg
    CALL print42
    LD H, 0
    LD A, (reg_buffer+1)
    LD L, A
    CALL convert_to_digits
    CALL print42
    LD HL, l_msg
    CALL print42
    LD A, (reg_buffer)
    LD L, A
    LD H, 0
    CALL convert_to_digits
    CALL print42
    LD HL, de_msg
    CALL print42 
    LD HL, (reg_buffer+2)
    CALL convert_to_digits
    CALL print42
    LD HL, d_msg
    CALL print42
    LD H, 0
    LD A, (reg_buffer+3)
    LD L, A
    CALL convert_to_digits
    CALL print42
    LD HL, e_msg
    CALL print42
    LD H, 0
    LD A, (reg_buffer+2)
    LD L, A
    CALL convert_to_digits
    CALL print42
    LD HL, bc_msg
    CALL print42
    LD HL, (reg_buffer+4)
    CALL convert_to_digits
    CALL print42
    LD HL, b_msg
    CALL print42 
    LD A, (reg_buffer+5)
    LD L, A
    LD H, 0
    CALL convert_to_digits
    CALL print42
    LD HL, c_msg
    CALL print42 
    LD H, 0
    LD A, (reg_buffer+4)
    LD L, A
    CALL convert_to_digits
    CALL print42
    LD HL, a_msg
    CALL print42 
    LD A, (reg_buffer+6)
    LD H, 0
    LD L, A
    CALL convert_to_digits
    CALL print42
    POP HL
    POP DE
    POP BC
    POP AF
    RET

    ENDIF