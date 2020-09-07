; Symbol Definitions
INCLUDE "inc/hardware.inc"
INCLUDE "src/definitions/defines.asm"

; Data definitions
INCLUDE "src/data/data.asm"
INCLUDE "src/data/ram.asm"
INCLUDE "src/data/vectors.asm"
INCLUDE "src/data/interrupts.asm"

; Game Code
INCLUDE "src/code/functions.asm"
INCLUDE "src/code/init.asm"
INCLUDE "src/code/gameplay.asm"
INCLUDE "src/code/win.asm"
INCLUDE "src/code/menu.asm"

;=========================================================================================================================================================================

SECTION "Entry Point", ROM0[$100]
    di             ; Disabling interrupts explicitly for emulators that have them enabled by default
    jp InitGame
    ds $150 - @

;==============================================================
; Main entry point jumped to on initial start of the game.
;==============================================================
InitGame::
    ld sp, $e000
    call BaseInit

    call InitMenu
    jp MenuLoop