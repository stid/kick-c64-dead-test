#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"


soundTest: {
                ldx #$09
        !:      lda strSound,x      //label sound test
                sta $0518,x
                dex
                bpl !-

                lda #$14
                sta $d418
                lda #$00
                sta $d417
                lda #$3e
                sta $d405
                lda #$ca
                sta $d406
                lda #$00
                sta $d412
                lda #$02
        mainLoop:
                pha
                ldx #$06
        loopA:  lda sound1,x
                sta $d401
                lda sound2,x
                sta $d400
                pla
                tay
                lda sound8,y
                sta $d402
                lda sound9,y
                sta $d403
                lda sound7,y
                sta $d404
                tya
                pha
                lda #$6a
                jsr pauseOrExit
                lda #$00
                sta $d404
                lda #$00
                jsr pauseOrExit
                dex
                bne loopA
                lda #$00
                sta $d417
                lda #$18
                sta $d418
                lda #$3e
                sta $d40c
                lda #$ca
                sta $d40d
                ldx #$06
        loopB:  lda sound3,x
                sta $d408
                lda sound4,x
                sta $d407
                pla
                tay
                lda sound8,y
                sta $d409
                lda sound9,y
                sta $d40a
                lda sound7,y
                sta $d40b
                tya
                pha
                lda #$6a
                jsr pauseOrExit
                lda #$00
                sta $d40b
                lda #$00
                jsr pauseOrExit
                dex
                bne loopB
                lda #$00
                sta $d417
                lda #$1f
                sta $d418
                lda #$3e
                sta $d413
                lda #$ca
                sta $d414
                ldx #$06
        loopC:  lda sound5,x
                sta $d40f
                lda sound6,x
                sta $d40e
                pla
                tay
                lda sound8,y
                sta $d410
                lda sound9,y
                sta $d411
                lda sound7,y
                sta $d412
                tya
                pha
                lda #$6a
                jsr pauseOrExit
                lda #$00
                sta $d412
                lda #$00
                jsr pauseOrExit
                dex
                bne loopC
                pla
                tay
                dey
                tya
                bmi !+
                jmp mainLoop
        !:      rts

        pauseOrExit:
                cmp #$00
                beq done
                tay
                txa
                pha
                tya
                tax
        delayLoop:
                ldy #$ff
        !:      dey
                bne !-
                dex
                bne delayLoop
                pla
                tax
        done:   rts
}