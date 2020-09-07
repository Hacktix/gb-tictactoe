SECTION "Initialization", ROM0
;==============================================================
; Initializes all registers to a playable state after
; initial startup of the game.
;==============================================================
BaseInit::
    ; Check if running on CGB
    xor BOOTUP_A_CGB
    ld [CGBFlag], a

    ; Kill sound, clear pending interrupts
    xor a
    ld [rNR52], a
    ld [rIF], a

    ; Wait for VBlank
.waitVBlank
	ldh a, [rLY]
	cp SCRN_Y
	jr c, .waitVBlank

    ; Disable LCD
    xor a
    ld [rLCDC], a

    ; Copy OAM DMA routine to HRAM
    ld hl, OAMDMARoutine
    ld b, OAMDMARoutine.end - OAMDMARoutine
    ld c, LOW(OAMDMA)
.copyOAMDMA
    ld a, [hli]
    ldh [c], a
    inc c
    dec b
    jr nz, .copyOAMDMA

    ; Initialize Palettes
    ld a, DEFAULT_DMG_PALETTE
    ldh [rBGP], a
    ldh [rOBP0], a
    ldh [rOBP1], a

    ; Initialize HRAM Variables
    xor a
    ldh [StartAddrOAM], a
    ldh [PressedButtons], a
    ldh [HeldButtons], a

    ; Clear OAM Memory and VRAM
    call ClearOAM
    ld a, GAMEPLAY_TILE_EMPTY
    call ClearTilemaps

    ret