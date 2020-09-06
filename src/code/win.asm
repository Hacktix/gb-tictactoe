SECTION "Win Screen Code", ROM0
;==============================================================
; Loop when a player wins.
;==============================================================
WinLoop::
    ; Make sure that VBlank handler ran first
    rst WaitVBlank

    ; Call all win loop functions
    call CheckRestartGame
    call UpdateWinAnim
    call UpdateWinSymbolAnim

    ; Repeat
    jp WinLoop

;==============================================================
; Updates the animation of the symbols that caused a player
; to win.
;==============================================================
UpdateWinSymbolAnim::
    ; Check if draw
    ld a, [PlayerWin]
    and a
    ret z

    ; Check if animation should be updated
    ld hl, SWinAnimCooldown
    dec [hl]
    ret nz

    ; Update cooldown
    ld [hl], WIN_SYM_ANIM_TIMEOUT

    ; Update sprite positions
    ld b, 3
    ld de, WinPositions
.spriteUpdateLoop
    ld a, [de]
    inc de
    add a
    add a
    add a
    add LOW(ShadowOAM+4)
    ld l, a
    adc HIGH(ShadowOAM+4)
    sub l
    ld h, a
    ld a, [SWinAnimSpeedY]
    add [hl]
    ld [hli], a
    ld a, [SWinAnimSpeedX]
    add [hl]
    ld [hld], a
    ld a, $04
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [SWinAnimSpeedY]
    add [hl]
    ld [hli], a
    ld a, [SWinAnimSpeedX]
    add [hl]
    ld [hld], a
    dec b
    jr nz, .spriteUpdateLoop

    ; Request OAM DMA
    ld a, HIGH(ShadowOAM)
    ldh [StartAddrOAM], a

    ; Update X-Speed Variables
    ld a, [SWinAnimSpeedX]
    ld hl, SWinAnimSpeedChangeX
    add [hl]
    ld [SWinAnimSpeedX], a
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
    ld a, [SWinAnimSpeedY]
    ld hl, SWinAnimSpeedChangeY
    add [hl]
    ld [SWinAnimSpeedY], a
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

    ret

;==============================================================
; Checks whether or not Start is pressed and restarts the
; game if so.
;==============================================================
CheckRestartGame::
    ; Check if Start is pressed
    ld a, [PressedButtons]
    bit 3, a
    ret z

    ; Wait for VBlank and disable interrupts
    rst WaitVBlank
    di

    ; Disable LCD
    xor a
    ld [rLCDC], a

    ; Call setup functions
    call ClearOAM
    call InitPlayingField

    ; Clear return vectors and jump to gameplay loop
    pop de
    jp GameplayLoop

;==============================================================
; Updates the animation state of the "PRESS START" string
;==============================================================
UpdateWinAnim::
    ; Check if animation should be updated
    ld hl, WinAnimCooldown
    dec [hl]
    ret nz

    ; Update animation state registers
    ld [hl], WIN_ANIM_TIMEOUT
    ld a, [WinAnimState]
    inc a
    ld [WinAnimState], a

    ; Load string pointer to draw
    and $01
    jr nz, .loadTextString
    ld a, HIGH(strEmptyLine)
    ld [StringPointerAddr], a
    ld a, LOW(strEmptyLine)
    ld [StringPointerAddr+1], a
    jr .endLoadString
.loadTextString
    ld a, HIGH(strReset)
    ld [StringPointerAddr], a
    ld a, LOW(strReset)
    ld [StringPointerAddr+1], a
.endLoadString

    ; Request string to be drawn
    ld a, $9c
    ld [StringLocationAddr], a
    ld a, $60
    ld [StringLocationAddr+1], a
    ld [StringDrawFlag], a

    ret