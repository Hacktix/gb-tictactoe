;==============================================================
; Section containing actual graphics data.
;==============================================================
SECTION "Tiles", ROM0
TilesBG:
incbin "res/bg.bin"
EndTilesBG:
TilesMenu:
incbin "res/title.bin"
EndTilesMenu:
TilesSprites:
incbin "res/sprites.bin"
EndTilesSprites:

;==============================================================
; Section containing tilemaps.
;==============================================================
SECTION "Tilemaps", ROM0
MapBG:
incbin "res/bgmap.bin"
EndMapBG:
MapWindow:
incbin "res/winmap.bin"
EndMapWindow:
MapTitle:
incbin "res/titlemap.bin"
EndMapTitle:

;==============================================================
; Section containing string data.
;==============================================================
SECTION "Strings", ROM0
strTurnPlayer1:
    db "       Xs TURN     ", 0
strTurnPlayer2:
    db "       Os TURN     ", 0
strWinPlayer1:
    db "       X WINS!     ", 0
strWinPlayer2:
    db "       O WINS!     ", 0
strDraw:
    db "        DRAW!      ", 0
strReset:
    db "     PRESS START   ", 0
strEmptyLine:
    db "                   ", 0

;==============================================================
; Section containing color data for CGB mode.
;==============================================================
SECTION "Colors", ROM0
; Gameplay Palettes
cGameplayBGP0:
    db $ff, $7f
    db $e8, $23
    db $06, $1a
    db $44, $11
cGameplayOBJ0:
    db $00, $00
    db $ff, $33
    db $ef, $01
    db $4a, $01
cGameplayOBJ1:
    db $00, $00
    db $5f, $29
    db $5f, $08
    db $10, $00
cGameplayOBJ2:
    db $00, $00
    db $08, $7d
    db $c0, $48
    db $00, $3c
EndGameplayObjectPalettes:

; Menu Palettes
cMenuBGP0:
    db $f4, $53
    db $00, $03
    db $80, $01
    db $80, $01

; Menu Fade-In Parameters
;
; FORMAT:
;  1 byte subtraction count (amount of times to subtract to get desired value)
;  2 bytes subtraction value (Little Endian)
;  Starting color $7FFF is assumed
cFadeInParamBGP0:
    ; TODO: Fix this shiz
    db 5, $cf, $08
    db 11, $5d, $0b
    db 13, $bb, $09
    db 13, $bb, $09

;==============================================================
; Section containing sound register values for SFX.
;==============================================================
SECTION "Sounds", ROM0
;                             Square Channel 1 - Register Values
;                    -PPPNSSS   DDLLLLLL   VVVVAPPP   FFFFFFFF   TL---FFF
MenuMoveBeep:    db %00010111, %10000000, %11000001, %00000000, %10000111
MenuConfirmBeep: db %00110111, %10000000, %11110001, %00000000, %10000111
GameMoveBeep:    db %00000000, %10000000, %11000001, %00000000, %10000111
SymbolPlaceBeep: db %01110100, %10000000, %11000001, %00000000, %10000111
WinBeep:         db %01110111, %10000000, %11110011, %00000000, %10000111

;==============================================================
; Hardcoded Shadow OAM for beginning of gameplay
;==============================================================
SECTION "Initial OAM", ROM0
InitGameOAM:
; Cursor
db 30, 60, 8, 0
; Top Left
db 36, 56, 10, 0
db 36, 64, 10, 0
; Top Middle
db 36, 80, 10, 0
db 36, 88, 10, 0
; Top Right
db 36, 104, 10, 0
db 36, 112, 10, 0
; Middle Left
db 60, 56, 10, 0
db 60, 64, 10, 0
; Middle Middle
db 60, 80, 10, 0
db 60, 88, 10, 0
; Middle Right
db 60, 104, 10, 0
db 60, 112, 10, 0
; Bottom Left
db 84, 56, 10, 0
db 84, 64, 10, 0
; Bottom Middle
db 84, 80, 10, 0
db 84, 88, 10, 0
; Bottom Right
db 84, 104, 10, 0
db 84, 112, 10, 0
EndInitGameOAM:

;==============================================================
; Routine which should be copied to HRAM on startup. Starts
; OAM DMA at $<A><A>00.
;==============================================================
SECTION "OAM DMA routine", ROM0
OAMDMARoutine:
	ldh [rDMA], a
	ld a, 40
.wait
	dec a
	jr nz, .wait
	ret
.end