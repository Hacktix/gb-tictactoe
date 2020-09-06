;==============================================================
; WRAM for global and state-specific variables.
;==============================================================
SECTION "WRAM", WRAM0
CGBFlag: db                  ; 0 if running on CGB, non-zero value otherwise

SelectedGamemode: db         ; 0=1 Player, 1=2 Player

StartPlayRAM:
PlayerTurn: db               ; 1=X (Player 1), 2=O (Player 2)
PlayerWin: db                ; 0=None, 1=X (Player 1), 2=O (Player 2)
CursorAnimCooldown: db       ; Cooldown in frames until cursor animates
CursorPosAnimAdd: db         ; $01 if cursor moves up next animation, $FF if down
CursorPos: db                ; 0-8 Starting top left, going right
FieldMap: ds 9               ; 0=Empty, 1=O, 2=X
PlacedSymbols: db            ; Amount of symbols placed by players
WinPositions: ds 3           ; Positions of symbols that caused a player to win
WinAnimCooldown: db          ; Cooldown in frames until win message state changes
WinAnimState: db             ; Only lowest bit relevant, 1 for shown, 0 for hidden
SWinAnimCooldown: db         ; Cooldown in frames until position of symbols is changed
SWinAnimSpeedX: db           ; X-Speed of symbol animation
SWinAnimSpeedY: db           ; Y-Speed of symbol animation
SWinAnimSpeedChangeX: db     ; Value X-Speed is changed by per animation cycle
SWinAnimSpeedChangeY: db     ; Value Y-Speed is changed by per animation cycle
EndPlayRAM:

;==============================================================
; "Shadow OAM" to be copied to actual OAM by DMA Transfer.
;==============================================================
SECTION "Shadow OAM", WRAM0, ALIGN[8]
ShadowOAM: ds 160

;==============================================================
; RAM accessible during OAM DMA, for OAM DMA routine as
; well as VBlank handler variables.
;==============================================================
SECTION "HRAM", HRAM
StartAddrOAM: db
PressedButtons: db
HeldButtons: db
StringDrawFlag: db
StringPointerAddr: ds 2
StringLocationAddr: ds 2
OAMDMA:: ds OAMDMARoutine.end - OAMDMARoutine