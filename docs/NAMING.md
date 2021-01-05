## Code style

### Global Labels
 - *External labels are exported and can be called from a different source file*
 - PascalCase
 - Double colon
 - Ex: `ExternalLabel::`

### Internal Global Labels:
 - *Internal labels can only be called in the same source file*
 - PascalCase
 - Single colon
 - Ex: `GlobalLabel:`

### Local Labels:
 - camelCase
 - No colon
 - Ex: `.localLabel`

## Constants
 - UPPER_UNDERSCORE
 - Ex: `FIRST_CONST EQU $01`

## Variable Addresses
 - camelCase
 - Ex: `varAddress EQU $C008`

### Comments
 - Plaint text
 - Single semicolon
 - Ex: `; this is a simple comment`

### Documentation
 - Plain text
 - Double semicolon
 - Ex: 
```
;; brief description of what the function does
;; @input input registers description
;; @output output registers description
```
