SECTION "VBlank Handler", ROM0
VBlankHandler::
    ; Do OAM DMA if requested
    ldh a, [hStartAddrOAM]
    and a
    jr z, .noOAMDMA
    call hOAMDMA
    xor a
    ldh [hStartAddrOAM], a
.noOAMDMA

    ; Print string if requested
    ldh a, [hStringDrawFlag]
    and a
    jr z, .noStringDraw
    ld a, [hStringLocationAddr]
    ld h, a
    ld a, [hStringLocationAddr+1]
    ld l, a
    ld a, [hStringPointerAddr]
    ld d, a
    ld a, [hStringPointerAddr+1]
    ld e, a
    rst CopyString
    xor a
    ldh [hStringDrawFlag], a
.noStringDraw

    ; Fetch inputs
    ld c, LOW(rP1)
	ld a, $20
	ldh [c], a
rept 6
	ldh a, [c]
endr
	or $F0
	ld b, a
    swap b
    ld a, $10
	ldh [c], a
rept 6
	ldh a, [c]
endr
	and $0F
    or $F0
	xor b
	ld b, a
	ld a, $30
	ldh [c], a
	ldh a, [hHeldButtons]
	cpl
	and b
	ldh [hPressedButtons], a
	ld a, b
	ldh [hHeldButtons], a

    reti