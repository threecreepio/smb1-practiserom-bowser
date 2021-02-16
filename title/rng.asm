.include "rng-resume.asm"

StatusITCDelay: .byte $00, $04, $06

DelayForVBlank:
    bit PPU_STATUS
    bpl DelayForVBlank
    rts

RNGQuickResume:
    jsr DelayForVBlank
    ; quickly advance the rng to the nearest precomputed window
    lda MathFrameruleDigitStart + 3 ; thousands
    asl a
    asl a
    asl a
    asl a
    adc MathFrameruleDigitStart + 2 ; hundreds
    and #$7F
    tax
    jsr SetupBaseITC
    lda resume_0, x
    sta PseudoRandomBitReg+0
    lda resume_1, x
    sta PseudoRandomBitReg+1
    lda resume_2, x
    sta PseudoRandomBitReg+2
    lda resume_3, x
    sta PseudoRandomBitReg+3
    lda resume_4, x
    sta PseudoRandomBitReg+4
    lda resume_5, x
    sta PseudoRandomBitReg+5
    lda resume_6, x
    sta PseudoRandomBitReg+6
    ; we add a single frame for every cycle of the rng we go through..
    ; this probably makes sense.
    ldy RNGExtraCycle
    beq @AdjustFrame
    jsr StepRNGByY
@AdjustFrame:
    ; then step to the correct frame
    lda MathFrameruleDigitStart + 1 ; tens
    asl a
    asl a
    asl a
    asl a
    adc MathFrameruleDigitStart + 0 ; ones
    tay
    beq @AdjustPUP
    jsr StepRNGByY
@AdjustPUP:
    ; we're always going to play the same frame
    ; but the ITC is different depending on powerup states.
    ldy SettablePUP
    lda StatusITCDelay,y
    tay
    beq @Done
    jsr StepITCByY
@Done:
    ; make sure we get correct cointoss frames
    lda #$17
    sta FrameCounter
    rts

SetupBaseITC:
    lda resume_itc, x
    sta IntervalTimerControl

    lda MathFrameruleDigitStart+3
    cmp #$8
    lda MathFrameruleDigitStart+4
    rol a
    sta RNGExtraCycle
    ;and #%00000011
    tay
    lda #0
    cpy #0
    beq @Done
@Continue:
    jsr StepITC
    jsr StepITC
    jsr StepITC
    jsr StepITC
    jsr StepITC
    jsr StepITC
    jsr StepITC
    dey
    bne @Continue
@Done:
    clc
    rts


StepITC:
    sec
    lda IntervalTimerControl
    bne @PRNG
    lda #$15
@PRNG:
    sbc #1
    sta IntervalTimerControl
    rts

StepITCByY:
    pha
:   jsr StepITC
    dey
    bne :-
    pla
    rts

StepRNGByYWithoutITC:
    pha
:   jsr SingleStepRNG
    dey
    bne :-
    pla
    rts

StepRNGByY:
    pha
:   jsr StepITC
    jsr SingleStepRNG
    dey
    bne :-
    pla
    rts

SingleStepRNG:
    lda PseudoRandomBitReg    ;get first memory location of LSFR bytes
    and #%00000010            ;mask out all but d1
    sta $00                   ;save here
    lda PseudoRandomBitReg+1  ;get second memory location
    and #%00000010            ;mask out all but d1
    eor $00                   ;perform exclusive-OR on d1 from first and second bytes
    clc                       ;if neither or both are set, carry will be clear
    beq RotPRandomBit
    sec                       ;if one or the other is set, carry will be set
RotPRandomBit:
    ror PseudoRandomBitReg+0  ;rotate carry into d7, and rotate last bit into carry
    ror PseudoRandomBitReg+1  ;rotate carry into d7, and rotate last bit into carry
    ror PseudoRandomBitReg+2  ;rotate carry into d7, and rotate last bit into carry
    ror PseudoRandomBitReg+3  ;rotate carry into d7, and rotate last bit into carry
    ror PseudoRandomBitReg+4  ;rotate carry into d7, and rotate last bit into carry
    ror PseudoRandomBitReg+5  ;rotate carry into d7, and rotate last bit into carry
    ror PseudoRandomBitReg+6  ;rotate carry into d7, and rotate last bit into carry
    rts

DecRNG:
    ldx #$FF
    txs
    lda #0
    tay
    sta PPU_CTRL_REG1
    sta PPU_CTRL_REG2
    ; ugly special case for going left on 00000, should go to 17FFC
    lda MathFrameruleDigitStart+0
    ora MathFrameruleDigitStart+1
    ora MathFrameruleDigitStart+2
    ora MathFrameruleDigitStart+3
    ora MathFrameruleDigitStart+4
    bne @loop
    lda #1
    sta MathFrameruleDigitStart+4
    lda #7
    sta MathFrameruleDigitStart+3
    lda #$F
    sta MathFrameruleDigitStart+2
    lda #$F
    sta MathFrameruleDigitStart+1
    lda #$C
    sta MathFrameruleDigitStart+0
    bne @done
@loop:
    ; okay now we can just decrement by one..
    sec
    lda MathFrameruleDigitStart,y
    sbc #1
    and #%00001111
    sta MathFrameruleDigitStart,y
    bcs @done
    iny
    cpy #7
    bne @loop
@done:
    jsr DelayForVBlank
    jsr InitializeMemory
    jmp TStartGame

IncRNG:
    ldx #$FF
    txs
    lda #0
    tay
    sta PPU_CTRL_REG1
    sta PPU_CTRL_REG2
    ldy #0
@loop:
    clc
    lda MathFrameruleDigitStart,y
    adc #1
    and #%00001111
    sta MathFrameruleDigitStart,y
    bne @done
    iny
    cpy #7
    bne @loop
@done:
    jsr DelayForVBlank
    jsr InitializeMemory
    jmp TStartGame


