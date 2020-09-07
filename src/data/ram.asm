;==============================================================
; WRAM for global and state-specific variables.
;==============================================================
SECTION "WRAM", WRAM0
wCGBFlag: db                  ; 0 if running on CGB, non-zero value otherwise

wSelectedGamemode: db         ; 0=1 Player, 1=2 Player

StartPlayRAM:
wPlayerTurn: db               ; 1=X (Player 1), 2=O (Player 2)
wPlayerWin: db                ; 0=None, 1=X (Player 1), 2=O (Player 2)
wCursorAnimCooldown: db       ; Cooldown in frames until cursor animates
wCursorPosAnimAdd: db         ; $01 if cursor moves up next animation, $FF if down
wCursorPos: db                ; 0-8 Starting top left, going right
wFieldMap: ds 9               ; 0=Empty, 1=O, 2=X
wPlacedSymbols: db            ; Amount of symbols placed by players
wWinPositions: ds 3           ; Positions of symbols that caused a player to win
wWinAnimCooldown: db          ; Cooldown in frames until win message state changes
wWinAnimState: db             ; Only lowest bit relevant, 1 for shown, 0 for hidden
wSWinAnimCooldown: db         ; Cooldown in frames until position of symbols is changed
wSWinAnimSpeedX: db           ; X-Speed of symbol animation
wSWinAnimSpeedY: db           ; Y-Speed of symbol animation
wSWinAnimSpeedChangeX: db     ; Value X-Speed is changed by per animation cycle
wSWinAnimSpeedChangeY: db     ; Value Y-Speed is changed by per animation cycle
EndPlayRAM:

;==============================================================
; "Shadow OAM" to be copied to actual OAM by DMA Transfer.
;==============================================================
SECTION "Shadow OAM", WRAM0, ALIGN[8]
wShadowOAM: ds 160

;==============================================================
; Stack Space
;==============================================================
SECTION "Stack", WRAM0[$E000 - STACK_SIZE]
    ds STACK_SIZE
wStackBottom:

;==============================================================
; RAM accessible during OAM DMA, for OAM DMA routine as
; well as VBlank handler variables.
;==============================================================
SECTION "HRAM", HRAM
hStartAddrOAM: db
hPressedButtons: db
hHeldButtons: db
hStringDrawFlag: db
hStringPointerAddr: ds 2
hStringLocationAddr: ds 2
hOAMDMA:: ds OAMDMARoutine.end - OAMDMARoutine