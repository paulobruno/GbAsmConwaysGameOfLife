vTiles0     EQU $8000
vTiles1     EQU $8800
vTiles2     EQU $9000

vBGMap0     EQU $9800
vBGMap1     EQU $9C00

; OAM address
OAMRAM      EQU $FE00 ; $FE00 -> $FE9F

; Input register
rINP        EQU $FF00

rLCDC       EQU $FF40

rSCY        EQU $FF42 ; scroll y
rSCX        EQU $FF43 ; scroll x

rLY         EQU $FF44
rBGP        EQU $FF47
rOBP0       EQU $FF48
rOBP1       EQU $FF49

; Work RAM Bank 0: $C000-$CFFF
WRAM        EQU $C000

; variables
varSum          EQU     $C000
currentRow      EQU     $C001
currentCol      EQU     $C002
swapStates      EQU     $C003
newCell0        EQU     $C004
newCell1        EQU     $C005
oldCell0        EQU     $C006
oldCell1        EQU     $C007
oldStateStart   EQU     $C01F
newStateStart   EQU     $C1D7

vramCell        EQU     $9821

MAX_ROWS        EQU     $12
MAX_COLS        EQU     $14


SECTION "Entry", ROM0[$100]
    nop
    jp Start

REPT $150 - $104
    db 0
ENDR


SECTION "Main", ROM0

Start:
    ; initialization
    call waitVBlank
    call turnOffLcd
    call setDefaultPalette

    ld hl, $8800
    ld de, WhiteTileStart
    ld bc, WhiteTileEnd - WhiteTileStart
    call copyToMemory
    
    ld hl, $8810
    ld de, BlackTileStart
    ld bc, BlackTileEnd - BlackTileStart
    call copyToMemory

    ld b, $80
    call fillScreen

    call clearOam
    
    ld a, $08
    ld [rSCX], a
    ld [rSCY], a

    call turnOnLcd
    call setStartingState

mainLoop:
    call waitVBlank
    call turnOffLcd
    call moveResultToVram
    call turnOnLcd
    call resetTilePosition
    
countTile:
    xor a
    ld [varSum], a
    
    call countNeighbors

    ld a, [newCell1]
    ld h, a
    ld a, [newCell0]
    ld l, a

    ld a, [hl]
    and $01

    ; if [de] = 0 || count = 0, goto rule 2
    jr z, .cellIsDead

; else, goto rule 1
; check rule 1
; in this rule the cell is alive
    ld a, [varSum]
    cp $02

    jp z, survive

; check rule 1 cell == 3
    ld a, [varSum]
    cp 03

    jp z, survive
    jr .killCell

; check rule 2
; if cell is dead and there is 3 neighbors, create live cell
; if count = 0, goto 3
.cellIsDead:
    ld a, [varSum]
    cp $03

    ; if count != 0, goto rule 3
    jr nz, .killCell
    ; else, create live cell
    jp survive

; check rule 3
.killCell:
    ld a, [oldCell1]
    ld h, a
    ld a, [oldCell0]
    ld l, a
    ld [hl], $00
    jp nextTilePosition

survive:
    ld a, [oldCell1]
    ld h, a
    ld a, [oldCell0]
    ld l, a
    ld [hl], $01
    jp nextTilePosition
    

SECTION "Sprites", ROM0

WhiteTileStart:
    db $00, $00, $00, $00
    db $00, $00, $00, $00
    db $00, $00, $00, $00
    db $00, $00, $00, $00
WhiteTileEnd:

BlackTileStart:
    db $FF, $FF, $FF, $FF
    db $FF, $FF, $FF, $FF
    db $FF, $FF, $FF, $FF
    db $FF, $FF, $FF, $FF
BlackTileEnd:


SECTION "Functions", ROM0

waitVBlank:
    ld a, [rLY]
    cp 144
    jr c, waitVBlank
    ret

turnOffLcd:
    xor a ; ld a, 0
    ld [rLCDC], a
    ret
    
turnOnLcd:
    ld a, %10010001
    ld [rLCDC], a
    ret

setDefaultPalette:
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a
    ret

copyToMemory:
    ld a, [de]
    ld [hli], a ; ld [de], a ; inc de
    inc de
    dec bc
    ld a, b
    or c
    jr nz, copyToMemory
    ret

resetMemory:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, resetMemory
    ret

; fill the screen with the tile at address in register b
fillScreen:
    ld hl, vBGMap0
.clear
    ld a, b
    ld [hli], a
    ld a, h
    cp $9C ; screen ends at $9BFF
    jr nz, .clear
    ret

clearOam:
    ld hl, OAMRAM
.clear
    xor a
    ld [hli], a
    ld a, h
    cp $FF ; OAMRAM ends at $FF00
    jr nz, .clear
    ret


countNeighbors:
    ld a, [newCell1]
    ld h, a
    ld a, [newCell0]
    ld l, a

    xor a
    ld b, a

    call countTopLeft
    call countTopCenter
    call countTopRight

    call countMiddleLeft
    call countMiddleRight

    call countBottomLeft
    call countBottomCenter
    call countBottomRight

    ret

; de contains the address to the center tile
countTopLeft:
    ld a, $17
    ld c, a

    call subDeBcToHl
    call updateSumCounter
    ret

countTopCenter:
    ld a, $16
    ld c, a

    call subDeBcToHl
    call updateSumCounter
    ret

countTopRight:
    ld a, $15
    ld c, a

    call subDeBcToHl
    call updateSumCounter
    ret

countMiddleLeft:
    ld a, $01
    ld c, a

    call subDeBcToHl
    call updateSumCounter
    ret

countMiddleRight:
    ld a, $01
    ld c, a

    call addDeAndBcToHl
    call updateSumCounter
    ret

countBottomLeft:
    ld a, $15
    ld c, a

    call addDeAndBcToHl
    call updateSumCounter
    ret

countBottomCenter:
    ld a, $16
    ld c, a

    call addDeAndBcToHl
    call updateSumCounter
    ret

countBottomRight:
    ld a, $17
    ld c, a

    call addDeAndBcToHl
    call updateSumCounter
    ret

addDeAndBcToHl:
    ld a, [newCell0]
    add c
    ld l, a

    ld a, [newCell1]
    adc $00
    ld h, a

    ret

subDeBcToHl:
    ld a, [newCell0]
    sub c
    ld l, a

    ld a, [newCell1]
    sbc $00
    ld h, a

    ret

updateSumCounter:
    ; increment sum counter
    ld a, [varSum]
    add [hl]
    ld [varSum], a

    ret

nextTilePosition:
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

    ld a, [currentCol]
    inc a
    ld [currentCol], a
    
    cp MAX_COLS

    jp nz, countTile

    ; reset col
    xor a
    ld [currentCol], a
    ; inc row
    ld a, [currentRow]
    inc a
    ld [currentRow], a
    ; check row
    cp MAX_ROWS

    jr nz, .goToNextLine

    jp mainLoop

.goToNextLine:
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

    jp countTile

resetTilePosition:
    xor a
    ld [currentRow], a
    ld [currentCol], a
    
    ld a, [swapStates]
    cp $01
    jr z, .swapStates

    ld bc, newStateStart
    ld de, oldStateStart

    ld a, $01
    ld [swapStates], a
    jr .updateStatePtrs

.swapStates
    ld bc, oldStateStart
    ld de, newStateStart

    xor a
    ld [swapStates], a

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

setStartingState:
    ; aqui
    ld hl, newStateStart - $17
    ld de, initialStateStart
    ld bc, initialStateEnd - initialStateStart
    call copyToMemory

    ld hl, oldStateStart - $17
    ld bc, initialStateEnd - initialStateStart
    call resetMemory

    xor a
    ld [swapStates], a

    ret

moveResultToVram:
    ld de, newStateStart
    ld bc, vramCell

    xor a
    ld [currentRow], a
    ld [currentCol], a

.movingToVram
    ld h, d
    ld l, e
    ld a, [hl]
    add $80
    
    ; ld hl, bc
    ld h, b
    ld l, c
    ld [hl], a
    
    inc bc
    inc de

    ld a, [currentCol]
    inc a
    ld [currentCol], a
    ; check end column
    cp MAX_COLS
    jr nz, .movingToVram

    ; nextLine
    ; add bc, $0C
    ld a, c
    add $0C
    ld c, a
    ld a, b
    adc $00
    ld b, a

    ; add de, $02
    inc de
    inc de

    xor a
    ld [currentCol], a

    ld a, [currentRow]
    inc a
    ld [currentRow], a    

    cp MAX_ROWS
    jr nz, .movingToVram

    ret


initialStateStart:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
initialStateEnd:
