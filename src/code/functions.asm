SECTION "Common Functions", ROM0
;==============================================================
; Sets all values in OAM to zero.
;==============================================================
ClearOAM::
    ld hl, ShadowOAM
    ld b, OAM_COUNT * 4
    xor a
.clearOAM
    ld [hli], a
    dec b
    jr nz, .clearOAM
    ld a, HIGH(ShadowOAM)
    call OAMDMA
    ret

;==============================================================
; Sets all values in VRAM tilemap data to zero.
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