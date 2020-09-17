SECTION "Singleplayer AI", ROM0
;==============================================================
; Sets wCursorPosAI to the square in which the AI will place
; its symbol.
;==============================================================
CalculateTurnAI::

    ; ---------------------------------------------------------
    ; Check rows for possible wins
    ; ---------------------------------------------------------
    
    ; Set registers for checks
    ld hl, wFieldMap
    ld e, 3

.rowLoop
    ld bc, $0000       ; B = Empty Count, C = Occupied Count
    ld d, 3
.rowScanLoop
    ld a, [hli]
    cp 1               ; Set Z if occupied by player, set C if empty
    jr nz, .rowSquareNotOccupied
    inc c
    jr .rowSquareNotEmpty
.rowSquareNotOccupied
    jr nc, .rowSquareNotEmpty
    inc b
.rowSquareNotEmpty
    dec d
    jr nz, .rowScanLoop
    ; Check if win on currently scanned row
    ld a, c
    and a
    jr nz, .noWinRow
    ld a, b
    cp 1
    jr nz, .noWinRow
    ; Possible win on current row
    dec hl
    ld b, 3
.rowFindWinSquareLoop
    dec b
    ld a, [hld]
    and a
    jr nz, .rowFindWinSquareLoop
    ld c, b     ; Preserve offset on row
    ld a, 9
.rowWinOffsetCalcLoop
    sub 3
    dec e
    jr nz, .rowWinOffsetCalcLoop
    add c
    ld [wCursorPosAI], a
    ret
.noWinRow
    dec e
    jr nz, .rowLoop

    ; ---------------------------------------------------------
    ; Select random square (last resort)
    ; ---------------------------------------------------------

    ; Read random number from DIV
    ld a, [rDIV]
    and 7
    ld b, a

    ; Increment until square is empty
.randIncLoop
    ld hl, wFieldMap
    ld a, b
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    and a
    jr z, .randFound
    ld a, b
    inc a
    and 7
    ld b, a
    jr .randIncLoop

.randFound
    ; Load selected value into RAM and return
    ld a, b
    ld [wCursorPosAI], a
    ret