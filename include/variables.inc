varSum          EQU     $C000
currentRow      EQU     $C001
currentCol      EQU     $C002
isStateSwaped   EQU     $C003
cellLow         EQU     $C004
newCellHigh     EQU     $C005
oldCellHigh     EQU     $C006

vramCell        EQU     $9821

MAX_ROWS        EQU     $12
MAX_COLS        EQU     $14

oldStateStart   EQU     $C0
newStateStart   EQU     $C2
stateStart      EQU     $1F