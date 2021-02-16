SettablesCount = $2

.pushseg
.segment "MENUWRAM"
Settables:
SettablePUP: .byte $00
Settable2:   .byte $00
.popseg

MenuTitles:
.byte "P-UP"
.byte "RNG "

.define MenuTitleLocations \
    $20CA + ($40 * 0), \
    $20CA + ($40 * 1)

.define MenuValueLocations \
    $20D3 + ($40 * 0) - 3, \
    $20D3 + ($40 * 1) - 4

UpdateMenuValueJE:
    tya
    jsr JumpEngine
    .word UpdateValuePUps        ; p-up
    .word UpdateValueFramerule   ; frame

DrawMenuValueJE:
    tya
    jsr JumpEngine
    .word DrawValueString_PUp    ; p-up
    .word DrawValueFramerule ; frame

DrawMenuTitle:
    clc
    lda VRAM_Buffer1_Offset
    tax
    adc #3 + 4
    sta VRAM_Buffer1_Offset
    lda MenuTitleLocationsHi, y
    sta VRAM_Buffer1+0, x
    lda MenuTitleLocationsLo, y
    sta VRAM_Buffer1+1, x
    lda #4
    sta VRAM_Buffer1+2, x
    tya
    rol a
    rol a
    tay
    lda MenuTitles,y
    sta VRAM_Buffer1+3, x
    lda MenuTitles+1,y
    sta VRAM_Buffer1+4, x
    lda MenuTitles+2,y
    sta VRAM_Buffer1+5, x
    lda MenuTitles+3,y
    sta VRAM_Buffer1+6, x
    lda #0
    sta VRAM_Buffer1+7, x
    rts


MenuReset:
    jsr DrawMenu
    rts

DrawMenu:
    ldy #(SettablesCount-1)
    sty $10
@KeepDrawing:
    jsr DrawMenuTitle
    ldy $10
    jsr DrawMenuValueJE
    ldy $10
    dey
    sty $10
    bpl @KeepDrawing
    rts

MenuNMI:
    jsr DrawSelectionMarkers
    lda PressedButtons
    clc
    cmp #0
    bne @READINPUT
    rts
@READINPUT:
    and #%00001111
    beq @SELECT
    ldy MenuSelectedItem
    jsr UpdateMenuValueJE
    jmp RenderMenu
@SELECT:
    lda PressedButtons
    cmp #%00100000
    bne @START
    ldx #0
    stx MenuSelectedSubitem
    inc MenuSelectedItem
    lda MenuSelectedItem
    cmp #SettablesCount
    bne @SELECT2
    stx MenuSelectedItem
@SELECT2:
    jmp RenderMenu
@START:
    cmp #%00010000
    bne @DONE
    ldx HeldButtons
    cpx #%10000000
    lda #0
    bcc @START2
    lda #1
@START2:
    sta PrimaryHardMode
    jmp TStartGame
@DONE:
    rts
RenderMenu:
    ldy MenuSelectedItem
    jsr DrawMenu
    rts

DrawSelectionMarkers:
    ; set y position
    lda #$1E
    ldy MenuSelectedItem
@Increment:
    clc
    adc #$10
    dey
    bpl @Increment
    sta Sprite_Y_Position + (1 * SpriteLen)
    sta Sprite_Y_Position + (2 * SpriteLen)
    ; set x position
    lda #$A9
    sta Sprite_X_Position + (1 * SpriteLen)
    sbc #$8
    ldy MenuSelectedSubitem
@Decrement:
    clc
    sbc #$7
    dey
    bpl @Decrement
    sta Sprite_X_Position + (2 * SpriteLen)
    lda #$00
    sta Sprite_Attributes + (1 * SpriteLen)
    lda #$21
    sta Sprite_Attributes + (2 * SpriteLen)

    lda #$2E ; main selection sprite
    sta Sprite_Tilenumber + (1 * SpriteLen)
    lda #$27 ; sub selection sprite
    sta Sprite_Tilenumber + (2 * SpriteLen)
    rts

UpdateValueITC:
    ldx #$FF
    lda HeldButtons
    and #%10000000
    bne @Skip
    ldx #3
    @Skip:
    stx $0
    jmp UpdateValueShared

UpdateValuePUps:
    lda #3
    sta $0
    jmp UpdateValueShared

UpdateValueShared:
    clc
    lda PressedButtons
    and #%000110
    bne @Decrement
@Increment:
    lda Settables, y
    adc #1
    cmp $0
    bcc @Store
    lda #0
    bvc @Store
@Decrement:
    lda Settables, y
    beq @Wrap
    sbc #0
    bvc @Store
@Wrap:
    lda $0
    sbc #0
@Store:
    sta Settables, y
    rts

DrawValueNormal:
    clc
    lda VRAM_Buffer1_Offset
    tax
    adc #4
    sta VRAM_Buffer1_Offset
    lda MenuValueLocationsHi, y
    sta VRAM_Buffer1+0, x
    lda MenuValueLocationsLo, y
    sta VRAM_Buffer1+1, x
    lda #1
    sta VRAM_Buffer1+2, x
    lda Settables, y
    adc #1
    sta VRAM_Buffer1+3, x
    lda #0
    sta VRAM_Buffer1+4, x
    rts

DrawValueString_PUp:
    lda Settables,y
    asl a
    tax
    lda PUpStrings,x
    sta MenuTextPtr
    lda PUpStrings+1,x
    sta MenuTextPtr+1
    lda #5
    sta MenuTextLen
    jmp DrawValueString

MenuTextPtr = $C3
MenuTextLen = $C2
DrawValueString:
    clc
    lda VRAM_Buffer1_Offset
    tax
    adc MenuTextLen
    adc #3
    sta VRAM_Buffer1_Offset
    lda MenuValueLocationsHi, y
    sta VRAM_Buffer1+0, x
    lda MenuValueLocationsLo, y
    sta VRAM_Buffer1+1, x
    lda MenuTextLen
    sta VRAM_Buffer1+2, x
    ldy #0
@CopyNext:
    lda (MenuTextPtr),y
    sta VRAM_Buffer1+3, x
    inx
    iny
    cpy MenuTextLen
    bcc @CopyNext
    lda #0
    sta VRAM_Buffer1+4, x
    rts

UpdateValueFramerule:
    clc
    ldx MenuSelectedSubitem
    lda PressedButtons
    and #%00000011
    beq @update_value

    lda PressedButtons
    cmp #%00000001 ; right
    bne @check_left
    dex
@check_left:
    cmp #%00000010 ; left
    bne @store_selected
    inx
@store_selected:
    txa
    bpl @not_under
    lda #4
@not_under:
    cmp #5
    bcc @not_over
    lda #0
@not_over:
    sta MenuSelectedSubitem
    rts
@update_value:
    lda MathFrameruleDigitStart, x
    tay
    lda PressedButtons
    cmp #%00001000
    beq @increase
    dey
    bpl @store_value
    ldy #$E
@increase:
    iny
    cpy #$10
    bne @store_value
    ldy #0
@store_value:
    tya
    sta MathFrameruleDigitStart, x
    rts

DrawValueFramerule:
    clc
    lda VRAM_Buffer1_Offset
    tax
    adc #8
    sta VRAM_Buffer1_Offset
    lda MenuValueLocationsHi, y
    sta VRAM_Buffer1+0, x
    lda MenuValueLocationsLo, y
    sta VRAM_Buffer1+1, x
    lda #5
    sta VRAM_Buffer1+2, x
    lda MathFrameruleDigitStart+0
    sta VRAM_Buffer1+3+4, x
    lda MathFrameruleDigitStart+1
    sta VRAM_Buffer1+3+3, x
    lda MathFrameruleDigitStart+2
    sta VRAM_Buffer1+3+2, x
    lda MathFrameruleDigitStart+3
    sta VRAM_Buffer1+3+1, x
    lda MathFrameruleDigitStart+4
    sta VRAM_Buffer1+3+0, x
    lda #0
    sta VRAM_Buffer1+3+5, x
    rts

MenuValueLocationsLo: .lobytes MenuValueLocations
MenuValueLocationsHi: .hibytes MenuValueLocations

MenuTitleLocationsLo: .lobytes MenuTitleLocations
MenuTitleLocationsHi: .hibytes MenuTitleLocations

PUpStrings:
.word PUpStrings_Non
.word PUpStrings_Fir
.word PUpStrings_SFir
PUpStrings_Non:
.byte "NONE "
PUpStrings_Fir:
.byte "FIRE "
PUpStrings_SFir:
.byte "FIRE!"

.pushseg
.segment "MENUWRAM"
MenuSelectedItem: .byte $00
MenuSelectedSubitem: .byte $00
RNGExtraCycle: .byte $00
MathDigits:
MathFrameruleDigitStart:
  .byte $00, $00, $00, $00, $00 ; selected framerule
MathFrameruleDigitEnd:
MathInGameFrameruleDigitStart:
  .byte $00, $00, $00, $00, $00 ; ingame framerule
MathInGameFrameruleDigitEnd:
.popseg
