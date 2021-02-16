.import __PRACTISE_WRAMCODE_LOAD__, __PRACTISE_WRAMCODE_RUN__, __PRACTISE_WRAMCODE_SIZE__
InitBankSwitchingCode:
    ldx #0
@KeepCopying:
    lda __PRACTISE_WRAMCODE_LOAD__, x
    sta __PRACTISE_WRAMCODE_RUN__, x
    lda __PRACTISE_WRAMCODE_LOAD__+$100, x
    sta __PRACTISE_WRAMCODE_RUN__+$100, x
    inx
    bne @KeepCopying
    rts


; this code is copied into WRAM and used to jump between
; the game and 
.pushseg
.segment "PRACTISE_WRAMCODE"
.export BANK_PractiseNMI
.export BANK_PractiseReset
.export BANK_PractiseWriteBottomStatusLine
.export BANK_PractiseWriteTopStatusLine
.export BANK_PractisePrintScore
.export BANK_PractiseEnterStage

RELOCATE_GetAreaDataAddrs:
    jmp GetAreaDataAddrs
RELOCATE_LoadAreaPointer:
    jmp LoadAreaPointer
RELOCATE_PlayerEndWorld:
    jmp PlayerEndWorld
RELOCATE_NonMaskableInterrupt:
    jmp NonMaskableInterrupt
RELOCATE_GL_ENTER:
    jmp GL_ENTER

BANK_PractiseNMI:
jsr BANK_TITLE_RTS
jsr PractiseNMI
jmp BANK_GAME_RTS

BANK_PractiseReset:
jsr BANK_TITLE_RTS
jmp HotReset

BANK_PractiseWriteBottomStatusLine:
jsr BANK_TITLE_RTS
jsr PractiseWriteBottomStatusLine
jmp BANK_GAME_RTS

BANK_PractiseWriteTopStatusLine:
jsr BANK_TITLE_RTS
jsr PractiseWriteTopStatusLine
jmp BANK_GAME_RTS

BANK_PractisePrintScore:
jsr BANK_TITLE_RTS
jsr PractisePrintScore
jmp BANK_GAME_RTS

BANK_PractiseEnterStage:
jsr BANK_TITLE_RTS
jsr PractiseEnterStage
jmp BANK_GAME_RTS
rts

; this will attempt to figure out how many worlds there are in the ROM
; it does this by loading the byte in PlayerEndWorld that sends the
; player back to the title screen.
BANK_LoadWorldCount:
    jsr BANK_GAME_RTS
    lda #0
    sta WorldNumber
    sta WorldSelectEnableFlag
    sta SavedJoypad1Bits
    sta SavedJoypad2Bits
@FindFinalWorld:
    jsr RELOCATE_PlayerEndWorld
    bne @FindFinalWorld
@Found:
    inc WorldNumber
    jmp BANK_TITLE_RTS
    rts

FindAxe:
    ldy #0
@NextItem:
    lda (AreaData), y
    cmp #$FD
    beq @Exit
    cmp (AreaData),y
    iny
    and #$0F
    cmp #$0D ; item needs to be placed a little off screen
    bne @NextItem2
    lda (AreaData), y
    and #%01111111
    cmp #$42 ; axe item id
    beq @Finish
@NextItem2:
    iny
    bne @NextItem
@Exit:
    lda #1
@Finish:
    rts

; scan through levels skipping over any autocontrol stages
BANK_AdvanceToLevel:
    jsr BANK_GAME_RTS
    ldx #0
    stx $0
    stx AreaNumber
    ldx LevelNumber
    beq @LevelFound
@NextArea:
    jsr RELOCATE_LoadAreaPointer
    jsr BANK_LEVELBANK_RTS ; Refresh the game bank in case of GreatEd
    jsr RELOCATE_GetAreaDataAddrs
    inc AreaNumber
    lda PlayerEntranceCtrl
    and #%00000110
    cmp #%00000110
    bne @AreaOK
    inc $0
    bvc @NextArea
@AreaOK:
    dex 
    bne @NextArea
@LevelFound:
    clc
    lda LevelNumber
    adc $0
    sta AreaNumber
    lda #0
    sta SND_DELTA_REG+1
    jsr RELOCATE_LoadAreaPointer
    jsr RELOCATE_GetAreaDataAddrs
    lda #$a5
    jmp RELOCATE_GL_ENTER

.popseg
