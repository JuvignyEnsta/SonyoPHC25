    IFNDEF STRUCTURES_ASM
    DEFINE STRUCTURES_ASM true 
/**
 * @file structures.asm
 * @brief Some structures used for this project.
 */
;/==/ Structure pour des coordonnées entières en 2D
    STRUCT Coord2D 
x   BYTE 1
y   BYTE 1
    ENDS
;/==/ Structure pour une dimension 3D
    STRUCT Dimension
width    BYTE 1
length   BYTE 1
height   BYTE 1
    ENDS
    
    ENDIF
