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
    ld hl, wShadowOAM
    ld a, 120
    ld [hli], a
    ld a, 56
    ld [hli], a
    ld a, 12
    ld [hli], a
    ld a, HIGH(wShadowOAM)
    call hOAMDMA

    ; Initialize CGB palettes if necessary
    ld a, [wCGBFlag]
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
    ldh [rBCPD], a
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
    ldh [rOCPD], a
    dec b
    jr nz, .objLoop
.noInitCGB

    ; Initialize DMG palettes for fadein
    xor a
    ld [rBGP], a
    ld [rOBP0], a

    ; Initialize menu variables
    ld [wSelectedGamemode], a
    ld [wMenuFadeInState], a
    ld a, MENU_FADEIN_TIMEOUT
    ld [wMenuFadeInCooldown], a

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

    ; ---------------------------------------------------------
    ; Update menu fade in animation
    ; ---------------------------------------------------------
    
    ; Check if fade in is already completed
    ld a, [wMenuFadeInState]
    cp 4
    jr z, .skipFadeInAnim

    ; Check if timeout is 0 yet
    ld hl, wMenuFadeInCooldown
    dec [hl]
    jr nz, MenuLoop           ; Disallow input during fade in

    ; Reload timeout
    ld a, MENU_FADEIN_TIMEOUT
    ld [hl], a

    ; Update BGP
    ld hl, wMenuFadeInState
    ld a, [rBGP]
    or [hl]
    rrca 
    rrca 
    ld [rBGP], a
    ld [rOBP0], a
    inc [hl]
    jr MenuLoop
.skipFadeInAnim

    ; ---------------------------------------------------------
    ; Check for UP/DOWN input and change selected option
    ; ---------------------------------------------------------

    ; Check if either up/down was pressed
    ld a, [hPressedButtons]
    and PADF_DOWN | PADF_UP
    jr z, .noCursorMove       ; Skip cursor update code if neither pressed

    ; Update selection
    ld hl, wSelectedGamemode
    dec [hl]
    jr z, .updateSprite
    inc [hl]
    inc [hl]

    ; Update cursor sprite position
.updateSprite
    ld a, [hl]
    and a
    jr nz, .updateSprite2Player
    ld a, MENU_1PLAYER_Y
    jr .endLoadCursorY
.updateSprite2Player
    ld a, MENU_2PLAYER_Y
.endLoadCursorY
    ld [wShadowOAM], a

    ; Request OAM DMA
    ld a, HIGH(wShadowOAM)
    ldh [hStartAddrOAM], a

    ; Play sound
    ld de, MenuMoveBeep
    call PlaySound
.noCursorMove

    ; ---------------------------------------------------------
    ; Check for game to be started on START press
    ; ---------------------------------------------------------

    ; Check if START was pressed
    ld a, [hPressedButtons]
    and PADF_START
    jr z, MenuLoop            ; Loop back to MenuLoop label if not pressed

    ; Play sound
    ld de, MenuConfirmBeep
    call PlaySound
    
    ; Disable LCD
    xor a
    ld [rLCDC], a

    ; Initialize main gameplay loop
    call InitPlayingField
    jp GameplayLoop