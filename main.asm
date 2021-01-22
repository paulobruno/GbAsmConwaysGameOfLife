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

    ld a, [newCell1]
    ld h, a
    ld a, [newCell0]
    ld l, a

    ld a, [hl]
    and $01
    
    ld a, [oldCell1]
    ld h, a
    ld a, [oldCell0]
    ld l, a

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
    ;inc WRAM address
    ld a, [oldCell0]
    add $01
    ld [oldCell0], a
    ld a, [oldCell1]
    adc $00
    ld [oldCell1], a

    ;inc VRAM address
    ld a, [newCell0]
    add $01
    ld [newCell0], a
    ld a, [newCell1]
    adc $00
    ld [newCell1], a

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

    ; add newCell, 02
    ld a, [newCell0]
    add $02
    ld [newCell0], a
    ld a, [newCell1]
    adc $00
    ld [newCell1], a
    
    ; add oldCell, 02
    ld a, [oldCell0]
    add $02
    ld [oldCell0], a
    ld a, [oldCell1]
    adc $00
    ld [oldCell1], a

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
    ld a, [newCell1]
    ld h, a
    ld a, [newCell0]
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
    ld a, $17
    ld c, a

    call SubDeBcToHl
    call UpdateSumCounter
    ret

CountTopCenter:
    ld a, $16
    ld c, a

    call SubDeBcToHl
    call UpdateSumCounter
    ret

CountTopRight:
    ld a, $15
    ld c, a

    call SubDeBcToHl
    call UpdateSumCounter
    ret

CountMiddleLeft:
    ld a, $01
    ld c, a

    call SubDeBcToHl
    call UpdateSumCounter
    ret

CountMiddleRight:
    ld a, $01
    ld c, a

    call AddDeAndBcToHl
    call UpdateSumCounter
    ret

CountBottomLeft:
    ld a, $15
    ld c, a

    call AddDeAndBcToHl
    call UpdateSumCounter
    ret

CountBottomCenter:
    ld a, $16
    ld c, a

    call AddDeAndBcToHl
    call UpdateSumCounter
    ret

CountBottomRight:
    ld a, $17
    ld c, a

    call AddDeAndBcToHl
    call UpdateSumCounter
    ret

AddDeAndBcToHl:
    ld a, [newCell0]
    add c
    ld l, a

    ld a, [newCell1]
    adc $00
    ld h, a

    ret

SubDeBcToHl:
    ld a, [newCell0]
    sub c
    ld l, a

    ld a, [newCell1]
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

    ld bc, newStateStart
    ld de, oldStateStart
    jr .updateStatePtrs
.swapStates
    ld bc, oldStateStart
    ld de, newStateStart
.updateStatePtrs
    ld a, b
    ld [newCell1], a
    ld a, c
    ld [newCell0], a

    ld a, d
    ld [oldCell1], a
    ld a, e
    ld [oldCell0], a

    ret

SetStartingState:
    ; aqui
    ld hl, newStateStart - $17
    ld de, initialStateStart
    ld bc, stateSize
    call CopyToMemory

    ld hl, oldStateStart - $17
    ld bc, stateSize
    call ResetMemory

    xor a
    ld [isStateSwaped], a

    ret

MoveResultToVram:
    ld hl, newStateStart
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
