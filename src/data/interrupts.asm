SECTION "VBlank Handler", ROM0
VBlankHandler::
    ; Do OAM DMA if requested
    ldh a, [StartAddrOAM]
    and a
    jr z, .noOAMDMA
    call OAMDMA
    xor a
    ldh [StartAddrOAM], a
.noOAMDMA

    ; Print string if requested
    ldh a, [StringDrawFlag]
    and a
    jr z, .noStringDraw
    ld a, [StringLocationAddr]
    ld h, a
    ld a, [StringLocationAddr+1]
    ld l, a
    ld a, [StringPointerAddr]
    ld d, a
    ld a, [StringPointerAddr+1]
    ld e, a
    rst CopyString
    xor a
    ldh [StringDrawFlag], a
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
	ldh a, [HeldButtons]
	cpl
	and b
	ldh [PressedButtons], a
	ld a, b
	ldh [HeldButtons], a

    reti