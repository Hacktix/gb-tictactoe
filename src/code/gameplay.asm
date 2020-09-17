SECTION "Main Gameplay Code", ROM0
;==============================================================
; Initializes everything required for running the playing
; field section of the game.
;==============================================================
InitPlayingField::
    ; Load sprite tile data
    ld hl, $8000
    ld bc, EndTilesSprites - TilesSprites
    ld de, TilesSprites
    rst Memcpy

    ; Load BG tile data
    ld hl, $9000
    ld bc, EndTilesBG - TilesBG
    ld de, TilesBG
    rst Memcpy

    ; Load BG tilemap
    ld hl, $9800
    ld de, MapBG
    ld bc, EndMapBG - MapBG
    rst Memcpy

    ; Load Window tilemap
    ld hl, $9C00
    ld de, MapWindow
    ld bc, EndMapWindow - MapWindow
    rst Memcpy

    ; Initialize CGB palettes if necessary
    ld a, [wCGBFlag]
    and a
    jr nz, .noInitCGB
    
    ; Setup BGP palette writing
    ld a, $80
    ldh [rBCPS], a
    ld hl, cGameplayBGP0
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
    ld hl, cGameplayOBJ0
    ld b, EndGameplayObjectPalettes - cGameplayOBJ0

    ; Write color values
.objLoop
    ld a, [hli]
    ld [rOCPD], a
    dec b
    jr nz, .objLoop

.noInitCGB
    ; Init sprite positions
    ld hl, wShadowOAM
    ld de, InitGameOAM
    ld bc, EndInitGameOAM - InitGameOAM
    rst Memcpy
    ld a, HIGH(wShadowOAM)
    call hOAMDMA

    ; Init game variables
    ld hl, StartPlayRAM
    ld b, EndPlayRAM - StartPlayRAM
    xor a
.zeroFill
    ld [hli], a
    dec b
    jr nz, .zeroFill

    ; Initialize cursor animation registers
    ld a, CURSOR_ANIM_TIMEOUT
    ld [wCursorAnimCooldown], a
    ld a, $ff
    ld [wCursorPosAnimAdd], a
    ld a, 1
    ld [wPlayerTurn], a

    ; Set SCX to cheat around de-centered playing field
    ld a, -4
    ld [rSCX], a

    ; Set WX and WY
    ld a, 4
    ld [rWX], a
    ld a, 100
    ld [rWY], a

    ; Start LCD
    ld a, LCDCF_ON | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_WIN9C00 | LCDCF_WINON | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
    ld [rLCDC], a

    ; Enable Interrupts
    xor a
    ld [rIF], a
    ei

    ret

;==============================================================
; Main loop for actual gameplay
;==============================================================
GameplayLoop::
    ; Make sure that VBlank handler ran first
    rst WaitVBlank

    ; ---------------------------------------------------------
    ; Check if singleplayer and handle AI if so
    ; ---------------------------------------------------------

    ; Check if singleplayer
    ld a, [wSelectedGamemode]
    and a
    jr nz, .skipAI

    ; Check if AI cooldown is zero (Player's turn)
    ld hl, wAITurnCooldown
    ld a, [hl]
    and a
    jr z, .skipAI

    ; Decrement cooldown and skip user input if not done
    dec [hl]
    jp nz, .noPressA

    ; Place AI symbol after preserving cursor position
    ld a, [wCursorPos]
    push af
    ld a, [wCursorPosAI]
    ld [wCursorPos], a
    call PlaceSymbol
    ld b, a
    pop af
    ld [wCursorPos], a
    ld a, b
    and a
    jp z, WinLoop

.skipAI

    ; ---------------------------------------------------------
    ; Check DPad input and move cursor accordingly
    ; ---------------------------------------------------------

    ; Check for DPad input
    ld hl, hPressedButtons
    ld a, [hl]
    and PADF_UP | PADF_DOWN | PADF_LEFT | PADF_RIGHT
    jr z, .noCursorMove

    ; Handle DPad input
    ld a, [wCursorPos]
    ld b, a
    bit PADB_DOWN, [hl]
    jr z, .noDown
    add 3
    jr .noUp
.noDown
    bit PADB_UP, [hl]
    jr z, .noUp
    sub 3
.noUp
    bit PADB_LEFT, [hl]
    jr z, .noLeft
    dec a
    ; Check for wrapping between rows
    cp 2
    jr nz, @ + 3
    inc a
    cp 5
    jr nz, @ + 3
    inc a
    jr .noRight
.noLeft
    bit PADB_RIGHT, [hl]
    jr z, .noRight
    inc a
    ; Check for wrapping between rows
    cp 3
    jr nz, @ + 3
    dec a
    cp 6
    jr nz, @ + 3
    dec a
.noRight
    cp 9                 ; If new cursor pos > 8 : invalid
    jr nc, .noCursorMove

    ; Move cursor
    ld [wCursorPos], a
    ld d, a
    ld b, CURSOR_BASE_POS_Y
    ld c, CURSOR_BASE_POS_X
    and a
    jr z, .endPosCalc
.posCalcLoop
    ld a, FIELD_SQUARE_WIDTH
    add c
    ld c, a
    cp CURSOR_BASE_POS_X + (2 * FIELD_SQUARE_WIDTH) + 1   ; Check if Cursor X overflows current row of squares
    jr c, .noPosNewline
    ld c, CURSOR_BASE_POS_X
    ld a, FIELD_SQUARE_WIDTH
    add b
    ld b, a
.noPosNewline
    dec d
    jr nz, .posCalcLoop
.endPosCalc
    ld a, [wCursorPosAnimAdd]
    dec a
    jr nz, .noAnimOffset
    dec b
.noAnimOffset
    ld a, b
    ld [wShadowOAM], a
    ld a, c
    ld [wShadowOAM+1], a
    ld a, HIGH(wShadowOAM)
    ld [hStartAddrOAM], a

    ; Play sound
    ld de, GameMoveBeep
    call PlaySound
.noCursorMove

    ; ---------------------------------------------------------
    ; Check for A button press to place symbol
    ; ---------------------------------------------------------

    ; Check if A button was pressed
    ld hl, hPressedButtons
    bit PADB_A, [hl]
    jr z, .noPressA

    ; Place symbol and check for win
    call PlaceSymbol
    and a
    jp z, WinLoop
.noPressA

    ; ---------------------------------------------------------
    ; Update cursor animation
    ; ---------------------------------------------------------

    ; Check if cursor animation needs to be updated
    ld hl, wCursorAnimCooldown
    dec [hl]
    jr nz, .noCursorAnimUpdate

    ; Update cursor animation
    ld [hl], CURSOR_ANIM_TIMEOUT
    ld a, [wCursorPosAnimAdd]
    ld b, a
    ld a, [wShadowOAM]
    add b
    ld [wShadowOAM], a
    ld a, HIGH(wShadowOAM)
    ld [hStartAddrOAM], a
    dec b
    jr nz, .reloadOne
    ld a, $ff
    ld [wCursorPosAnimAdd], a
    jr .noCursorAnimUpdate
.reloadOne
    ld a, 1
    ld [wCursorPosAnimAdd], a
.noCursorAnimUpdate

    ; Repeat
    jp GameplayLoop

;==============================================================
; Places the symbol of the player whose turn it is in the
; selected box and checks if the move caused a win.
; If so, A=0, otherwise A=1.
;==============================================================
PlaceSymbol::
    ; Calculate RAM address for selected box
    ld hl, wFieldMap
    ld a, [wCursorPos]
    add l
    ld l, a
    adc h
    sub l
    ld h, a

    ; Check if already set
    ld a, [hl]
    and a
    ld a, 1
    ret nz

    ; Set value in RAM
    ld a, [wPlayerTurn]
    ld [hl], a

    ; Get OAM pointer
    ld hl, wShadowOAM + 6      ; Load box 0 tile number pointer
    ld a, [wCursorPos]
    and a
    jr z, .skipBoxSearch
    ld d, a
.boxSearchLoop
    ld a, 8
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    dec d
    jr nz, .boxSearchLoop
.skipBoxSearch

    ; Update sprites
    ld a, [wPlayerTurn]
    dec a
    add a
    add a
    ld b, a
    ld [hli], a
    inc b
    inc b
    ld a, [wPlayerTurn]
    ld [hld], a
    ld a, 4
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, b
    ld [hli], a
    ld a, [wPlayerTurn]
    ld [hl], a

    ; Switch player turn
    ld a, [wPlayerTurn]
    dec a
    jr nz, .endSwitchPlayer
    ld a, 2
.endSwitchPlayer
    ld [wPlayerTurn], a

    ; Request window text update
    jr nz, .loadPlayer1
    ld a, HIGH(strTurnPlayer2)
    ld [hStringPointerAddr], a
    ld a, LOW(strTurnPlayer2)
    ld [hStringPointerAddr+1], a
    jr .endTurnStringLoad
.loadPlayer1
    ld a, HIGH(strTurnPlayer1)
    ld [hStringPointerAddr], a
    ld a, LOW(strTurnPlayer1)
    ld [hStringPointerAddr+1], a
    jr .endTurnStringLoad
.endTurnStringLoad
    ld a, $9c
    ld [hStringLocationAddr], a
    ld a, $20
    ld [hStringLocationAddr+1], a
    ld [hStringDrawFlag], a

    ; Increment amount of placed symbols
    ld a, [wPlacedSymbols]
    inc a
    ld [wPlacedSymbols], a

    ; Request OAM DMA
    ld a, HIGH(wShadowOAM)
    ldh [hStartAddrOAM], a

    ; Play sound
    ld de, SymbolPlaceBeep
    call PlaySound

    ; Check if singleplayer
    ld a, [wSelectedGamemode]
    and a
    jp nz, CheckForWin

    ; Check if move was made by AI
    ld a, [wAITurnFlag]
    and a
    jr nz, .resetAI

    ; Load AI Turn Timeout and calculate move
    ld a, AI_TURN_TIMEOUT
    ld [wAITurnCooldown], a
    ld [wAITurnFlag], a
    call CalculateTurnAI

    jp CheckForWin

.resetAI
    ; Reset AI Move Flag
    xor a
    ld [wAITurnFlag], a
    jp CheckForWin

;==============================================================
; Checks if there are three of the same symbol in a row and
; triggers the win animation if there are.
;==============================================================
CheckForWin::
    ; Set registers for checks
    ld hl, wFieldMap
    ld bc, $0000
    ld de, $0003

    ; Check for wins in rows
.rowLoop
    ld a, [hli]
    ld b, a
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld d, a
    ld a, b
    and a
    jr z, .noRowWin
    and c
    jr z, .noRowWin
    and d
    jr z, .noRowWin
    ; If 3 in a row
    ld [wPlayerWin], a
    ld a, l
    scf
    sbc LOW(wFieldMap)
    ld hl, wWinPositions
    ld [hli], a
    dec a
    ld [hli], a
    dec a
    ld [hl], a
    jp TriggerWin
.noRowWin
    dec e
    jr nz, .rowLoop
    
    ; Reset registers for checks
    ld hl, wFieldMap
    ld bc, $0000
    ld de, $0003

    ; Check for wins in columns
.colLoop
    ld a, [hli]
    ld b, a
    inc hl
    inc hl
    ld a, [hli]
    ld c, a
    inc hl
    inc hl
    ld a, [hli]
    ld d, a
    ld a, b
    and a
    jr z, .noColWin
    and c
    jr z, .noColWin
    and d
    jr z, .noColWin
    ; If 3 in a column
    ld [wPlayerWin], a
    ld a, l
    scf
    sbc LOW(wFieldMap)
    ld hl, wWinPositions
    ld [hli], a
    sub 3
    ld [hli], a
    sub 3
    ld [hl], a
    jp TriggerWin
.noColWin
    ld hl, wFieldMap
    ld a, 4
    sub e
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    dec e
    jr nz, .colLoop

    ; Check left-to-right diagonal
    ld a, [wFieldMap+0]
    ld b, a
    ld a, [wFieldMap+4]
    ld c, a
    ld a, [wFieldMap+8]
    ld d, a
    ld a, b
    and a
    jr z, .noWinDiag1
    and c
    jr z, .noWinDiag1
    and d
    jr z, .noWinDiag1
    ld [wPlayerWin], a
    ld hl, wWinPositions
    xor a
    ld [hli], a
    ld a, $04
    ld [hli], a
    ld a, $08
    ld [hli], a
    jp TriggerWin
.noWinDiag1

    ; Check right-to-left diagonal
    ld a, [wFieldMap+2]
    ld b, a
    ld a, [wFieldMap+4]
    ld c, a
    ld a, [wFieldMap+6]
    ld d, a
    ld a, b
    and a
    jr z, .noWinDiag2
    and c
    jr z, .noWinDiag2
    and d
    jr z, .noWinDiag2
    ld [wPlayerWin], a
    ld hl, wWinPositions
    ld a, $02
    ld [hli], a
    ld a, $04
    ld [hli], a
    ld a, $06
    ld [hli], a
    jp TriggerWin
.noWinDiag2

    ; Check for draw
    ld a, [wPlacedSymbols]
    cp 9
    ld a, 1                  ; Load 1 into A if no win conditions are met
    ret nz
    xor a                    ; Load 0 into A for Draw (No player won)
    ld [wPlayerWin], a
    jp TriggerWin

;==============================================================
; Initializes registers for the WinLoop subroutine. Sets
; A to 0 so the main loop knows to jump to WinLoop.
;==============================================================
TriggerWin::
    ; Check if draw
    ld a, [wPlayerWin]
    and a
    jr nz, .noDraw
    
    ; Draw 'DRAW!' string
    ld a, HIGH(strDraw)
    ld [hStringPointerAddr], a
    ld a, LOW(strDraw)
    ld [hStringPointerAddr+1], a
    jr .endWinTrigger
.noDraw

    ; Play sound
    ld de, WinBeep
    call PlaySound

    ; Load 'PLAYER X WINS!' string
    ld a, [wPlayerWin]
    dec a
    jr nz, .winPlayer2
    ld a, HIGH(strWinPlayer1)
    ld [hStringPointerAddr], a
    ld a, LOW(strWinPlayer1)
    ld [hStringPointerAddr+1], a
    jr .endWinTrigger
.winPlayer2
    ld a, HIGH(strWinPlayer2)
    ld [hStringPointerAddr], a
    ld a, LOW(strWinPlayer2)
    ld [hStringPointerAddr+1], a

.endWinTrigger
    ; Request string to be drawn
    ld a, $9c
    ld [hStringLocationAddr], a
    ld a, $20
    ld [hStringLocationAddr+1], a
    ld [hStringDrawFlag], a

    ; Set up animation registers
    ld a, WIN_ANIM_TIMEOUT
    ld [wWinAnimCooldown], a

    ; Hide cursor sprite
    xor a
    ld [wShadowOAM+1], a
    ld a, HIGH(wShadowOAM)
    ldh [hStartAddrOAM], a

    ; Initialize animation variables
    ld a, -1
    ld [wSWinAnimSpeedChangeX], a
    ld a, 1
    ld [wSWinAnimSpeedChangeY], a
    ld a, SYM_ANIM_MAX_SPEED
    ld [wSWinAnimSpeedX], a
    xor a
    ld [wSWinAnimSpeedY], a
    ld a, WIN_SYM_ANIM_TIMEOUT
    ld [wSWinAnimCooldown], a

    ; Initialize win sprite positions
    ld a, [wPlayerWin]
    and a
    jp z, WinLoop
    ld b, 3
    ld de, wWinPositions
.spriteUpdateLoop
    ld a, [de]
    inc de
    add a
    add a
    add a
    add LOW(wShadowOAM+4)
    ld l, a
    adc HIGH(wShadowOAM+4)
    sub l
    ld h, a
    ld a, -SYM_ANIM_OFF_Y
    add [hl]
    ld [hli], a
    ld a, -SYM_ANIM_OFF_X
    add [hl]
    ld [hld], a
    ld a, $04
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, -SYM_ANIM_OFF_Y
    add [hl]
    ld [hli], a
    ld a, -SYM_ANIM_OFF_X
    add [hl]
    ld [hl], a
    dec b
    jr nz, .spriteUpdateLoop

    ; Set A to 0 and return to main loop
    xor a
    ret