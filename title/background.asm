.macro ASCII text
$00
.endmacro

MenuBackground:
.word BGDATA
.word BGDATA+$100
.word BGDATA+$200
.word BGDATA+$300
.word $0000

BGDATA:
.incbin "../scripts/graphics/menu.bin"

; attributes
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $FF, $FF, $FF, $FF, $FF, $FF
.byte $00, $00, $FF, $FF, $FF, $FF, $FF, $FF
.byte $00, $00, $FF, $FF, $FF, $FF, $FF, $FF
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $05, $05, $05, $05, $8F, $AA
.byte $00, $00, $00, $00, $00, $00, $08, $AA

MenuPalette:
.byte $0F, $30, $10, $00
.byte $0F, $11, $01, $02
.byte $0F, $30, $16, $00
.byte $0F, $30, $2D, $0F

.byte $0F, $30, $11, $01
.byte $0F, $11, $11, $16
.byte $0F, $0F, $10, $0F
.byte $0F, $0F, $10, $0F
MenuPaletteEnd:
