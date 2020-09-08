SECTION "Win Screen Code", ROM0
;==============================================================
; Loop when a player wins.
;==============================================================
WinLoop::
    ; Make sure that VBlank handler ran first
    rst WaitVBlank

    ; ---------------------------------------------------------
    ; Check for game to be restarted on START press
    ; ---------------------------------------------------------
    
    ; Check if Start is pressed
    ld a, [hPressedButtons]
    bit PADB_START, a
    jr z, .noRestart

    ; Disable interrupts & LCD
    di
    xor a
    ld [rLCDC], a

    ; Call setup functions and jump to gameplay loop
    call ClearOAM
    call InitPlayingField
    jp GameplayLoop
.noRestart

    ; ---------------------------------------------------------
    ; Update animations for 'PRESS START' Text
    ; ---------------------------------------------------------

    ; Check if animation should be updated
    ld hl, wWinAnimCooldown
    dec [hl]
    jr nz, .noUpdateWinAnim

    ; Update animation state registers
    ld [hl], WIN_ANIM_TIMEOUT
    ld a, [wWinAnimState]
    inc a
    ld [wWinAnimState], a

    ; Load string pointer to draw
    and $01
    jr nz, .loadTextString
    ld a, HIGH(strEmptyLine)
    ld [hStringPointerAddr], a
    ld a, LOW(strEmptyLine)
    ld [hStringPointerAddr+1], a
    jr .endLoadString
.loadTextString
    ld a, HIGH(strReset)
    ld [hStringPointerAddr], a
    ld a, LOW(strReset)
    ld [hStringPointerAddr+1], a
.endLoadString

    ; Request string to be drawn
    ld a, $9c
    ld [hStringLocationAddr], a
    ld a, $60
    ld [hStringLocationAddr+1], a
    ld [hStringDrawFlag], a
.noUpdateWinAnim

    ; ---------------------------------------------------------
    ; Update animation for win symbols
    ; ---------------------------------------------------------

    ; Check if draw
    ld a, [wPlayerWin]
    and a
    jr z, .noUpdateSymAnim

    ; Check if animation should be updated
    ld hl, wSWinAnimCooldown
    dec [hl]
    jr nz, .noUpdateSymAnim

    ; Update cooldown
    ld [hl], WIN_SYM_ANIM_TIMEOUT

    ; Update sprite positions
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
    ld a, [wSWinAnimSpeedY]
    add [hl]
    ld [hli], a
    ld a, [wSWinAnimSpeedX]
    add [hl]
    ld [hld], a
    ld a, $04
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [wSWinAnimSpeedY]
    add [hl]
    ld [hli], a
    ld a, [wSWinAnimSpeedX]
    add [hl]
    ld [hld], a
    dec b
    jr nz, .spriteUpdateLoop

    ; Request OAM DMA
    ld a, HIGH(wShadowOAM)
    ldh [hStartAddrOAM], a

    ; Update X-Speed Variables
    ld a, [wSWinAnimSpeedX]
    ld hl, wSWinAnimSpeedChangeX
    add [hl]
    ld [wSWinAnimSpeedX], a
    cp SYM_ANIM_MAX_SPEED + 1
    jr c, .posSpeedX
    cpl 
    inc a
.posSpeedX
    cp SYM_ANIM_MAX_SPEED
    jr nz, .skipSpeedSwapX
    xor a
    sub [hl]
    ld [hl], a
.skipSpeedSwapX

    ; Update Y-Speed Variables
    ld a, [wSWinAnimSpeedY]
    ld hl, wSWinAnimSpeedChangeY
    add [hl]
    ld [wSWinAnimSpeedY], a
    cp SYM_ANIM_MAX_SPEED + 1
    jr c, .posSpeedY
    cpl 
    inc a
.posSpeedY
    cp SYM_ANIM_MAX_SPEED
    jr nz, .skipSpeedSwapY
    xor a
    sub [hl]
    ld [hl], a
.skipSpeedSwapY
.noUpdateSymAnim

    ; Repeat
    jp WinLoop