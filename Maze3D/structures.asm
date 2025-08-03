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
;/==/ Structure décrivant un monstre (16 octets)
    STRUCT Monster
name              TEXT 9                          ; Nom du monstre (max 8 caractères + 0)
dim_sprite        BYTE 0                          ; Dimension du sprite en bloc ( 4 bits pour x, 4 bits pour y)
ind_sprite_1      BYTE 0                          ; Les indices des blocs composant le sprite
ind_sprite_2      BYTE 0                          ; Les indices des blocs composant le sprite
ind_sprite_3      BYTE 0                          ; Les indices des blocs composant le sprite
ind_sprite_4      BYTE 0                          ; Les indices des blocs composant le sprite
ind_sprite_5      BYTE 0                          ; Les indices des blocs composant le sprite
ind_sprite_6      BYTE 0                          ; Les indices des blocs composant le sprite
hit_point         BYTE 0                          ; Nombre de points de vie max du monstre (points de vie du monstre entre max/2 et max)
affinity          BYTE 0                          ; Affinités élémentaires (2 bits pour feu, air, terre, eau) : 0 = neutre, 1 = faiblesse, 2 = immunisé, 3 = forte
caracteristic     BYTE 0                          ; 4 bits pour bonus précision, 4 bits pour esquive
max_damage        BYTE 0                          ; Dégâts max que le monstre peut infliger (bits 0-6), bit 7 : attaque à distance
armor             BYTE 0                          ; Nombre de points absorbés par l'armure du monstre (bits 0-5), bit 7 : arme magique nécessaire pour être touché, bit 6 ?
    ENDS
;/==/ Structure pour les données de base d'un objet :
    STRUCT ITEMDATA
type              BYTE                            ; Type de l'objet (arme, armure, etc.)  
icon              DW   0xFFFF                     ; Pointeur sur l'image illustrant l'arme
    ENDS
    
    STRUCT WeaponData
damage            DB 0x01                         ; Dégât max (bits 0-6), bit 7 : arme à distance si 1
caracteristic     DB 0x01                         ; Caractéristiques requise (valeur : bit 0-5; bit 6-7 : type caractéristique (bit 6 =  force,  bit 7  =  précision (les deux peuvent être requises) )
    ENDS

    STRUCT ArmorData
protection        DB 0x01                         ; Bit 0-3 : valeur de réduction dégâts de base Bits 4-7 : force requise de base
esquive           DB 0x01                         ; Bit 0-3 : bonus esquive max de base; Bits 4-5 : malus déplacement hors combat; bits 6-7 : malus précision combat à distance
    ENDS
;/==/ Structure pour un objet instancié :
    STRUCT ITEMINSTANCE
name              TEXT 17                         ; Nom de l'objet (max 16 caractères (sans le type))
type              DB   0x01                       ; Type d'objet (< 16 -> arme, 16-31 : armure, 32 : anneau, 33 : parchemin, etc.)
identification    DB   0x01                       ; Nombre de tours d'utilisation avant identification de l'objet (=0 est identifié)
icon              DW   0xFFFF                     ; Pointeur sur l'image illustrant l'arme
    ENDS
;/==/ Structure pour une arme instanciée ( 0 <= type <= 15 ):
    STRUCT WeaponInstance
damage            DB 0x01                         ; Dégât max (bits 0-6), bit 7 : arme à distance si 1
precision         DB 0X01                         ; Bonus de précision (bits 0-5), bit 7 : arme magique si 1, bit 6 : malus de précision
elemental         DB 0x01                         ; Affinité élémentaire : bits 0-3 : dégâts supplémentaires (possible 0), bit 4 : maudit (malus plutôt que bonus), bits 5-7 : type élément (0 : aucun, 1 : feu, 2 : glace (eau), 3 : électrique (air), 4 : poison (terre))
caracteristic     DB 0x01                         ; Caractéristiques requise (valeur : bit 0-5; bit 6-7 : type caractéristique (bit 6 =  force,  bit 7  =  précision (les deux peuvent être requises) )
    ENDS
;/==/ Structure pour une armure instanciée ( 16 <= type <= 31 ):
    STRUCT ArmorInstance
protection        DB 0x01                         ; Bit 0-6 : valeur de réduction/augmentation, bit 7 : 0 = réduction, 1 = augmentation
esquive           DB 0x01                         ; Bit 0-5 : valeurs bonus esquive, bit 6 bonus/malus, bit 7 : demande arme magique pour être touché
elemental         DB 0x01                         ; Réduction de dégât élémentaire (bit 6 : réduction/absorption, bit 7 : bonus/malus)
effects           DB 0x01                         ; Autre effets possible (invisibilité, paralysie, etc.)
    ENDS
    ENDIF
