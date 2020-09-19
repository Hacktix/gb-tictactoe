SECTION "Singleplayer AI", ROM0
;==============================================================
; Sets wCursorPosAI to the square in which the AI will place
; its symbol.
;==============================================================
CalculateTurnAI::
    ; Initialize Block-turn buffer
    ld a, $ff
    ld [wAITurnBlockBuffer], a

    ; ---------------------------------------------------------
    ; Check rows for win- and block-moves
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
    cp 1
    jr z, .noWinRow
    ld [wAITurnBlockFlag], a
.noBlockRow
    ld a, b
    cp 1
    jr nz, .noWinRow
    ; Possible win on current row
    push hl
    dec hl
    ld b, 3
.rowFindWinSquareLoop
    dec b
    ld a, [hld]
    and a
    jr nz, .rowFindWinSquareLoop
    ld c, b     ; Preserve offset on row
    ld a, 9
    push de
.rowWinOffsetCalcLoop
    sub 3
    dec e
    jr nz, .rowWinOffsetCalcLoop
    pop de
    pop hl
    add c
    ld b, a
    ld a, [wAITurnBlockFlag]
    and a
    ld a, b
    jr z, .rowLoadWinMove
    ld [wAITurnBlockBuffer], a
    jr .noWinRow
.rowLoadWinMove
    ld [wCursorPosAI], a
    ret
.noWinRow
    dec e
    jr nz, .rowLoop

    ; ---------------------------------------------------------
    ; Check columns for win- and block-moves
    ; ---------------------------------------------------------
    
    ; Set registers for checks
    ld e, 3

.colLoop
    ld hl, wFieldMap-1
    ld a, 4
    sub e
.colInitOffsetLoop
    inc hl
    dec a
    jr nz, .colInitOffsetLoop
    ld bc, $0000       ; B = Empty Count, C = Occupied Count
    ld d, 3
.colScanLoop
    ld a, [hli]
    inc hl
    inc hl
    cp 1               ; Set Z if occupied by player, set C if empty
    jr nz, .colSquareNotOccupied
    inc c
    jr .colSquareNotEmpty
.colSquareNotOccupied
    jr nc, .colSquareNotEmpty
    inc b
.colSquareNotEmpty
    dec d
    jr nz, .colScanLoop
    ; Check if win on currently scanned column
    ld a, c
    cp 1
    jr z, .noWinCol
    ld [wAITurnBlockFlag], a
    ld a, b
    cp 1
    jr nz, .noWinCol
    ; Possible win on current column
    push hl
    dec hl
    dec hl
    dec hl
    ld b, 9
.colFindWinSquareLoop
    ld a, b
    sub 3
    ld b, a
    ld a, [hld]
    dec hl
    dec hl
    and a
    jr nz, .colFindWinSquareLoop
    ld c, b     ; Preserve offset on row
    ld a, 3
    push de
.colWinOffsetCalcLoop
    dec a
    dec e
    jr nz, .colWinOffsetCalcLoop
    pop de
    pop hl
    add c
    ld b, a
    ld a, [wAITurnBlockFlag]
    and a
    ld a, b
    jr z, .colLoadWinMove
    ld [wAITurnBlockBuffer], a
    jr .noWinCol
.colLoadWinMove
    ld [wCursorPosAI], a
    ret
.noWinCol
    dec e
    jr nz, .colLoop

    ; ---------------------------------------------------------
    ; Check left-to-right diagonal for possible win
    ; ---------------------------------------------------------
    
    ; Set registers for checks
    ld hl, wFieldMap
    ld e, 3
    ld bc, $0000       ; B = Empty Count, C = Occupied Count

    ; Check fields
.ltrDiagonalLoop
    ld a, [hli]
    inc hl
    inc hl
    inc hl
    cp 1               ; Set Z if occupied by player, set C if empty
    jr nz, .ltrDiagonalSquareNotOccupied
    inc c
    jr .ltrDiagonalSquareNotEmpty
.ltrDiagonalSquareNotOccupied
    jr nc, .ltrDiagonalSquareNotEmpty
    inc b
.ltrDiagonalSquareNotEmpty
    dec e
    jr nz, .ltrDiagonalLoop
    
    ; Check if win on diagonal
    ld a, c
    and a
    jr nz, .noWinLtrDiagonal
    ld a, b
    cp 1
    jr nz, .noWinLtrDiagonal
    ; Possible win on diagonal
    dec hl
    dec hl
    dec hl
    dec hl
    ld b, 12
.ltrDiagonalFindWinSquareLoop
    ld a, b
    sub 4
    ld b, a
    ld a, [hld]
    dec hl
    dec hl
    dec hl
    and a
    jr nz, .ltrDiagonalFindWinSquareLoop
    ld a, b
    ld [wCursorPosAI], a
    ret
.noWinLtrDiagonal

    ; ---------------------------------------------------------
    ; Check right-to-left diagonal for possible win
    ; ---------------------------------------------------------
    
    ; Set registers for checks
    ld hl, wFieldMap+2
    ld e, 3
    ld bc, $0000       ; B = Empty Count, C = Occupied Count

    ; Check fields
.rtlDiagonalLoop
    ld a, [hli]
    inc hl
    cp 1               ; Set Z if occupied by player, set C if empty
    jr nz, .rtlDiagonalSquareNotOccupied
    inc c
    jr .rtlDiagonalSquareNotEmpty
.rtlDiagonalSquareNotOccupied
    jr nc, .rtlDiagonalSquareNotEmpty
    inc b
.rtlDiagonalSquareNotEmpty
    dec e
    jr nz, .rtlDiagonalLoop
    
    ; Check if win on diagonal
    ld a, c
    and a
    jr nz, .noWinRtlDiagonal
    ld a, b
    cp 1
    jr nz, .noWinRtlDiagonal
    ; Possible win on diagonal
    dec hl
    dec hl
    ld b, 8
.rtlDiagonalFindWinSquareLoop
    ld a, b
    sub 2
    ld b, a
    ld a, [hld]
    dec hl
    and a
    jr nz, .rtlDiagonalFindWinSquareLoop
    ld a, b
    ld [wCursorPosAI], a
    ret
.noWinRtlDiagonal

    ; ---------------------------------------------------------
    ; Check for blocking move
    ; ---------------------------------------------------------
    ld a, [wAITurnBlockBuffer]
    inc a
    jr z, .noBlockMove
    dec a
    ld [wCursorPosAI], a
    ret
.noBlockMove

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