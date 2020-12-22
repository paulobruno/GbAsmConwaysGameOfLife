varSum      EQU     $C000
currentRow  EQU     $C001
currentCol  EQU     $C002
firstTile   EQU     $C003

MAX_ROWS    EQU     $12
MAX_COLS    EQU     $14


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

    ld b, $00
    call fillScreen

    ld hl, $8800
    ld de, BlackTileStart
    ld bc, BlackTileEnd - BlackTileStart
    call copyToMemory

    call turnOnLcd

    call resetTilePosition

.countTile:
    call checkTilePosition

    xor a
    ld [varSum], a

    call countNeighbors

    ld a, [varSum]
    and [hl]

    ; if [hl] = 0 || count = 0, goto rule 2
    jr z, .rule2

; else, goto rule 1
; check rule 1
; in this rule the cell is alive
    ld a, [varSum]
    cp $02

    jr nz, .test3


.test3:
    ld a, [varSum]
    cp 03

    jr nz, .rule3

    jp goToNextTile
    
; check rule 2
; if cell is dead and there is 3 neighbors, create live cell
; if count = 0, goto 3
.rule2:
    ld a, [varSum]
    cp $03

    ; if count != 0, goto rule 3
    jr nz, .rule3
    ; else, create live cell
    ld a, $01
    ld [hl], a

    jp goToNextTile

; check rule 3
.rule3:
    xor a
    ld [hl], a

    ; check row
    ; check column

    jp goToNextTile


SECTION "Sprites", ROM0

BlackTileStart:
    db $00, $00, $00, $00
    db $00, $00, $00, $00
    db $00, $00, $00, $00
    db $00, $00, $00, $00
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
    ld a, %10010011
    ld [rLCDC], a
    ret

setDefaultPalette:
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a
    ret

copyToMemory:
    ld a, [de]
    ld [hli], a ; ld [hl], a ; inc hl
    inc de
    dec bc
    ld a, b
    or c
    jr nz, copyToMemory
    ret

; fill the screen with the tile at address in register b
fillScreen:
    ld hl, vBGMap0
.clear
    ld a, b
    ld [hli], a
    ld a, h
    cp $9C ; screen ends at $9C00
    jr nz, .clear
    ret
    
countNeighbors:
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


; hl contains the address to the center tile
countTopLeft:
    ld a, $21
    ld c, a

    call subHlBc
    call updateSumCounter
    ret

countTopCenter:
    ld a, $20
    ld c, a

    call subHlBc
    call updateSumCounter
    ret

countTopRight:
    ld a, $19
    ld c, a

    call subHlBc
    call updateSumCounter
    ret

countMiddleLeft:
    ld a, $01
    ld c, a

    call subHlBc
    call updateSumCounter
    ret

countMiddleRight:
    ld a, $01
    ld c, a

    call addHlBc
    call updateSumCounter
    ret

countBottomLeft:
    ld a, $19
    ld c, a

    call addHlBc
    call updateSumCounter
    ret

countBottomCenter:
    ld a, $20
    ld c, a

    call addHlBc
    call updateSumCounter
    ret

countBottomRight:
    ld a, $21
    ld c, a

    call addHlBc
    call updateSumCounter
    ret

addHlBc:
    ld a, l
    add c
    ld e, a

    ld a, h
    adc b
    ld d, a

    ret

subHlBc:
    ld a, l
    sub c
    ld e, a

    ld a, h
    sbc b
    ld d, a

    ret

updateSumCounter:
    ; increment sum counter
    ld a, [de]
    add [varSum]
    ld [varSum], a

    ret

goToNextTile:
    ld a, [currentCol]
    inc a
    ld [currentCol], a
    inc hl

    call checkTilePosition

    jp countTile

checkTilePosition:
    ld a, [currentCol]
    cp MAX_COLS

    ret nz

    ; inc row
    ld a, [currentRow]
    inc a
    ld [currentRow], a
    ; check row
    cp MAX_ROWS

    jr nz, goToNextLine

    call resetTilePosition

.goToNextLine:
    ; reset col
    xor a
    ld [currentCol], a
    ; change tile row
    ld a, l
    add $0C
    ld l, a
    ld a, h
    adc $00
    ld h, a
    
    ret

resetTilePosition:
    xor a
    ld [currentRow], a
    ld [currentCol], a

    ld hl, startAddress

    ; TODO: verificar se eh aqui msm q eu qro fazer isso
    call waitVBlank

    ret