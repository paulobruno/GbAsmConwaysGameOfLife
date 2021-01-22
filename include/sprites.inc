SECTION "Sprites", ROM0

whiteTileSize EQU $10

whiteTileStart::
    INCBIN "gfx/white_tile.2bpp"


blackTileSize EQU $10

blackTileStart::
    INCBIN "gfx/black_tile.2bpp"


stateSize EQU $01B8

initialStateStart::
    INCBIN "gfx/pulsar_3.2bpp"
