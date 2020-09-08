SECTION "Common Functions", ROM0
;==============================================================
; Sets all values in OAM to zero.
;==============================================================
ClearOAM::
    ld hl, wShadowOAM
    ld b, OAM_COUNT * 4
    xor a
.clearOAM
    ld [hli], a
    dec b
    jr nz, .clearOAM
    ld a, HIGH(wShadowOAM)
    call hOAMDMA
    ret

;==============================================================
; Sets all values in VRAM tilemap data to the value in the
; A register.
;==============================================================
ClearTilemaps::
    ld hl, $9800
    ld bc, $9fff - $9800
    ld d, a
.clearTilemaps
    ld a, d
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clearTilemaps
    ret

;==============================================================
; Plays a sound defined by the data bytes DE points to.
;==============================================================
PlaySound::
    ; Load sound data into registers
    ld hl, rNR10
    ld b, 5
.soundLoadLoop
    ld a, [de]
    ld [hli], a
    inc de
    dec b
    jr nz, .soundLoadLoop

    ret