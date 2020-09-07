SECTION "Main Menu", ROM0
;==============================================================
; Initializes everything required for displaying the main
; menu.
;==============================================================
InitMenu::
    ; Load sprite tile data
    ld hl, $8000
    ld bc, EndTilesSprites - TilesSprites
    ld de, TilesSprites
    rst Memcpy

    ; Load BG tile data
    ld hl, $9000
    ld bc, EndTilesMenu - TilesMenu
    ld de, TilesMenu
    rst Memcpy

    ; Load BG tilemap
    ld hl, $9800
    ld de, MapTitle
    ld bc, EndMapTitle - MapTitle
    rst Memcpy

    ; Clear OAM
    call ClearOAM

    ; Load cursor sprite
    ld hl, ShadowOAM
    ld a, 120
    ld [hli], a
    ld a, 56
    ld [hli], a
    ld a, 12
    ld [hli], a
    ld a, HIGH(ShadowOAM)
    call OAMDMA

    ; Initialize CGB palettes if necessary
    ld a, [CGBFlag]
    and a
    jr nz, .noInitCGB
    
    ; Setup BGP palette writing
    ld a, $80
    ldh [rBCPS], a
    ld hl, cMenuBGP0
    ld b, 8

    ; Write color values
.bgp0Loop
    ld a, [hli]
    ld [rBCPD], a
    dec b
    jr nz, .bgp0Loop

    ; Setup OBJ palette writing
    ld a, $80
    ldh [rOCPS], a
    ld hl, cGameplayOBJ2
    ld b, EndGameplayObjectPalettes - cGameplayOBJ0

    ; Write color values
.objLoop
    ld a, [hli]
    ld [rOCPD], a
    dec b
    jr nz, .objLoop

.noInitCGB
    ; Initialize menu variables
    xor a
    ld [SelectedGamemode], a

    ; Start LCD
    ld a, LCDCF_ON | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_WINOFF | LCDCF_OBJ8 | LCDCF_OBJON | LCDCF_BGON
    ld [rLCDC], a

    ; Enable Interrupts
    xor a
    ld [rIF], a
    ei

    ret 

;==============================================================
; Main loop for displaying the main menu screen.
;==============================================================
MenuLoop::
    ; Make sure that VBlank handler ran first
    rst WaitVBlank

    ; Check if either up/down was pressed
    ld a, [PressedButtons]
    and %11000000
    jr z, .noCursorMove

    ; Update selection
    ld hl, SelectedGamemode
    dec [hl]
    jr z, .updateSprite
    inc [hl]
    inc [hl]

    ; Update cursor sprite position
.updateSprite
    ld a, [hl]
    and a
    jr nz, .updateSprite2Player
    ld a, 120
    jr .endLoadCursorY
.updateSprite2Player
    ld a, 136
.endLoadCursorY
    ld [ShadowOAM], a

    ; Request OAM DMA
    ld a, HIGH(ShadowOAM)
    ldh [StartAddrOAM], a

.noCursorMove
    ; Check if either A/START was pressed
    ld a, [PressedButtons]
    and %00001000
    jr z, MenuLoop
    
    ; Disable LCD
    xor a
    ld [rLCDC], a

    ; Initialize main gameplay loop
    call InitPlayingField
    jp GameplayLoop