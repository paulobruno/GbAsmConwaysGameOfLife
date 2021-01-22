varSum          EQU     $C000
currentRow      EQU     $C001
currentCol      EQU     $C002
isStateSwaped   EQU     $C003
newCell0        EQU     $C004
newCell1        EQU     $C005
oldCell0        EQU     $C006
oldCell1        EQU     $C007
oldStateStart   EQU     $C01F
newStateStart   EQU     $C21F

vramCell        EQU     $9821

MAX_ROWS        EQU     $12
MAX_COLS        EQU     $14