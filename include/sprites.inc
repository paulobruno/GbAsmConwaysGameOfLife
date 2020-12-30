SECTION "Sprites", ROM0

whiteTileSize EQU $10

whiteTileStart::
    INCBIN "images/white.2bpp"


blackTileSize EQU $10

blackTileStart::
    INCBIN "images/black.2bpp"


initialStateSize EQU $01B8

initialStateStart::
    INCBIN "images/pulsar3.2bpp"
