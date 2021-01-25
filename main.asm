INCLUDE "include/hardware.inc"
INCLUDE "include/variables.inc"
INCLUDE "include/sprites.inc"


SECTION "Entry", ROM0[$100]
    nop
    jp Start

REPT $150 - $104
    db 0
ENDR


SECTION "Main", ROM0

Start:
    call SetDefaultPalette
    call DisableSound

    call WaitVBlank
    call TurnOffLcd

    call LoadTilesIntoVram
    call ClearScreen

    call TurnOnLcd

    call ClearOam
    call SetScreenPosition
    call SetStartingState

MainLoop:
    call WaitVBlank
    call TurnOffLcd
    call MoveResultToVram
    call TurnOnLcd
    call ResetTilePosition

CountTile:
    xor a
    ld [varSum], a

    call CountNeighbors

    ld a, [newCellHigh]
    ld h, a
    ld a, [cellLow]
    ld l, a

    ld a, [hl]
    and $01

    ld a, [oldCellHigh]
    ld h, a

    ; if [de] = 0 || count = 0, goto rule 2
    jr z, .cellIsDead

; else, goto rule 1
; check rule 1
; in this rule the cell is alive
    ld a, [varSum]
    cp $02

    jr z, .survive

; check rule 1 cell == 3
    ld a, [varSum]
    cp $03

    jr z, .survive

; check rule 3
.killCell
    ld [hl], $00
    jr NextTilePosition

; check rule 2
; if cell is dead and there is 3 neighbors, create live cell
; if count = 0, goto 3
.cellIsDead
    ld a, [varSum]
    cp $03

    ; if count != 0, goto rule 3
    jr nz, .killCell
    ; else, create live cell

.survive
    ld [hl], $01
    jr NextTilePosition

NextTilePosition:
    ;inc WRAM and VRAM addresses
    ld a, [cellLow]
    add $01
    ld [cellLow], a
    jr nc, .nocarry

    ld a, [oldCellHigh]
    inc a
    ld [oldCellHigh], a
    ld a, [newCellHigh]
    inc a
    ld [newCellHigh], a
.nocarry
    ld hl, currentCol
    inc [hl]
    ld a, [hl]

    cp MAX_COLS
    jr nz, CountTile

    ; reset col
    xor a
    ld [currentCol], a
    ; inc row
    ld hl, currentRow
    inc [hl]
    ld a, [hl]
    ; check row
    cp MAX_ROWS

    jr nz, .goToNextLine
    jp MainLoop

.goToNextLine
    ; reset col
    xor a
    ld [currentCol], a

    ; add cell, 02
    ld a, [cellLow]
    add $02
    ld [cellLow], a
    jr nc, CountTile

    ld a, [newCellHigh]
    inc a
    ld [newCellHigh], a
    ld a, [oldCellHigh]
    inc a
    ld [oldCellHigh], a

    jp CountTile


SECTION "Functions", ROM0

WaitVBlank:
    ldh a, [rLY]
    cp 145
    jr nz, WaitVBlank
    ret

TurnOffLcd:
    xor a ; ld a, 0
    ld [rLCDC], a
    ret

TurnOnLcd:
    ld a, %10010001
    ld [rLCDC], a
    ret

SetDefaultPalette:
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a
    ret

DisableSound:
    xor a
    ld [rNR52], a
    ret

CopyToMemory:
    ld a, [de]
    ld [hli], a ; ld [de], a ; inc de
    inc de
    dec bc
    ld a, b
    or c
    jr nz, CopyToMemory
    ret

ResetMemory:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, ResetMemory
    ret

; fill the screen with zeros
ClearScreen:
    xor a
    ld hl, _SCRN0 ; screen starts at $9B00
    ld c, $FF  ; screen ends at $9BFF
.loop
    ld [hli], a
    dec c
    jr nz, .loop
    ret

ClearOam:
    ld hl, _OAMRAM
.loop
    xor a
    ld [hli], a
    ld a, h
    cp $FF ; OAMRAM ends at $FF00
    jr nz, .loop
    ret

CountNeighbors:
    ld a, [newCellHigh]
    ld h, a
    ld a, [cellLow]
    ld l, a

    xor a
    ld b, a

    call CountTopLeft
    call CountTopCenter
    call CountTopRight

    call CountMiddleLeft
    call CountMiddleRight

    call CountBottomLeft
    call CountBottomCenter
    call CountBottomRight

    ret

; de contains the address to the center tile
CountTopLeft:
    ld c, $17
    call SubDeBcToHl
    call UpdateSumCounter
    ret

CountTopCenter:
    ld c, $16
    call SubDeBcToHl
    call UpdateSumCounter
    ret

CountTopRight:
    ld c, $15
    call SubDeBcToHl
    call UpdateSumCounter
    ret

CountMiddleLeft:
    ld c, $01
    call SubDeBcToHl
    call UpdateSumCounter
    ret

CountMiddleRight:
    ld c, $01
    call AddDeAndBcToHl
    call UpdateSumCounter
    ret

CountBottomLeft:
    ld c, $15
    call AddDeAndBcToHl
    call UpdateSumCounter
    ret

CountBottomCenter:
    ld c, $16
    call AddDeAndBcToHl
    call UpdateSumCounter
    ret

CountBottomRight:
    ld c, $17
    call AddDeAndBcToHl
    call UpdateSumCounter
    ret

AddDeAndBcToHl:
    ld a, [cellLow]
    add c
    ld l, a

    ld a, [newCellHigh]
    adc $00
    ld h, a

    ret

SubDeBcToHl:
    ld a, [cellLow]
    sub c
    ld l, a

    ld a, [newCellHigh]
    sbc $00
    ld h, a

    ret

UpdateSumCounter:
    ; increment sum counter
    ld a, [varSum]
    add [hl]
    ld [varSum], a
    ret

ResetTilePosition:
    xor a
    ld [currentRow], a
    ld [currentCol], a

    ld a, [isStateSwaped]
    xor $01 ; inverts 0 and 1
    ld [isStateSwaped], a
    jr z, .swapStates

    ld b, newStateStart
    ld c, oldStateStart
    jr .updateStatePtrs
.swapStates
    ld b, oldStateStart
    ld c, newStateStart
.updateStatePtrs
    ld a, b
    ld [newCellHigh], a
    ld a, c
    ld [oldCellHigh], a
    ld a, stateStart
    ld [cellLow], a
    ret

SetStartingState:
    ; aqui
    ld h, newStateStart
    ld l, stateStart - $17
    ld de, initialStateStart
    ld bc, stateSize
    call CopyToMemory

    ld h, oldStateStart
    ld l, stateStart - $17
    ld bc, stateSize
    call ResetMemory

    xor a
    ld [isStateSwaped], a

    ret

MoveResultToVram:
    ld h, newStateStart
    ld l, stateStart
    ld de, vramCell
    ld b, MAX_ROWS
.loopRow
    ld c, MAX_COLS
.loopCol
    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, .loopCol

    dec b
    ret z

    inc hl
    inc hl

    ; nextLine
    ; add de, $0C
    ld a, e
    add a, $000C
    ld e, a
    jr nc, .loopRow

    inc d
    jr .loopRow

LoadTilesIntoVram:
    ld hl, $8000
    ld de, whiteTileStart
    ld bc, whiteTileSize
    call CopyToMemory

    ld hl, $8010
    ld de, blackTileStart
    ld bc, blackTileSize
    call CopyToMemory

    ret

SetScreenPosition:
    ld a, $08
    ld [rSCX], a
    ld [rSCY], a
    ret
