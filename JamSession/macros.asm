; Macro for the PHC-25 demo program

KEY_LOWER_CASE: equ 0x4F2C
KEY_SCAN:       equ 0xF912
PORT_40_CACHE:  equ 0xF91F
STR_BUFFER:     equ 0xFBC0


    ; Fills memory starting at 'dest' with 'size' times 'byte'.
    MACRO memset memset_dest, memset_size, memset_byte
        ld  hl, memset_dest
        ld  bc, memset_size
        ld  a, memset_byte

        call memset_impl

        IFNDEF memset_defined
        DEFINE memset_defined true
        jr  memset_skip

memset_impl:
        ld  (hl), a
        ld  de,hl
        inc de
        dec bc
        ldir

        ret

memset_skip:

        ENDIF
    ENDM

    ; Sets the screen mode. Uses the original ROM variable to keep compatibililty
    MACRO set_screen set_screen_mask, set_screen_set
        ld  a,(PORT_40_CACHE)
        and set_screen_mask
        or  set_screen_set
        ld  (PORT_40_CACHE), a
        out (0x40), a
    ENDM

SCREEN_1_MASK:  equ 0b01001111
SCREEN_1_SET:   equ 0b00000000
; SCREEN 2 is the same as SCREEN 1

SCREEN_3_MASK:  equ 0b01001111
SCREEN_3_SET:   equ 0b10010000

SCREEN_3L_MASK:  equ 0b01001111
SCREEN_3L_SET:   equ 0b10000000

SCREEN_4_MASK:  equ 0b01001111
SCREEN_4_SET:   equ 0b10110000

SCREEN_CSS_MASK equ 0b10111111

    ; Macro to set the next location for text in SCREEN 1
    MACRO set_position_screen_1 x, y
        ld  hl, 0x6000 + 32 * y + x
        ld  (location), hl
    ENDM

    ; Combo of set position and print for SCREEN 1
    MACRO print_at_screen_1 str_ptr, pos_x, pos_y
        set_position_screen_1 pos_x, pos_y
        ld  hl,str_ptr
        call print
    ENDM

    ; Macro to set the next location for text in SCREEN 3
    MACRO set_position_screen_3 x, y
        ld ix, 0x6000 + 32 * y + x
        ;ld  (location), hl
    ENDM

    ; Macro to set the next location for text in SCREEN 4
    MACRO set_position_screen_4 x, y
        ld  hl, 0x6000 + (256 * y + x) / 8
        ld  (location), hl
    ENDM

    ; Macro to help define the uninitialized variables
    MACRO define_uninit_begin address
uninit_pointer = address
    ENDM

    MACRO define_uninit name, size
name    equ uninit_pointer
uninit_pointer = uninit_pointer + size
    ENDM
