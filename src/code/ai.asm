SECTION "Singleplayer AI", ROM0
;==============================================================
; Sets wCursorPosAI to the square in which the AI will place
; its symbol.
;==============================================================
CalculateTurnAI::
    ld hl, wCursorPosAI
    inc [hl]
    ret