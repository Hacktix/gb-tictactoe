SECTION "Reset Vectors", ROM0[$00]
;==============================================================
; Waits for VBlank to occur utilizing interrupts, meaning
; IME *has* to be enabled. Halt bug will occur otherwise.
; Called by 'rst $00'.
;==============================================================
WaitVBlank::
    ldh a, [rIE]
    or 1
    ldh [rIE], a
    halt
    ret
    ds $08 - @

;==============================================================
; Copies BC bytes reading from DE and following to HL
; and following. Called by 'rst $08'.
;==============================================================
Memcpy::
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, Memcpy
    
    ; 'rst $10' vector starts here
    ret
    ds $18 - @


;==============================================================
; Copies a string pointed to by DE to HL
;==============================================================
CopyString::
    ld a, [de]
    and a
    ret z
    ld [hli], a
    inc de
    jr CopyString
    ds $40 - @

SECTION "VBlank Interrupt", ROM0[$40]
    jp VBlankHandler
    ds $100 - @