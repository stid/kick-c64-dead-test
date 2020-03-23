#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./mem_map.asm"


        * = * "sound test"


soundTest: {
                ldx #$09
        !:      lda strSound,x      //label sound test
                sta VIDEO_RAM+$118,x
                dex
                bpl !-

                lda #$14
                sta SID.FILTER_VOL
                lda #$00
                sta SID.FILTER_RES_ROUT
                lda #$3e
                sta SID.VOICE_1_ATK_DEC
                lda #$ca
                sta SID.VOICE_1_SUS_VOL_REL
                lda #$00
                sta SID.VOICE_3_CTRL
                lda #$02
        mainLoop:
                pha
                ldx #$06
        loopA:  lda sound1,x
                sta SID.VOICE_1_FREQ_H
                lda sound2,x
                sta SID.VOICE_1_FREQ_L
                pla
                tay
                lda sound8,y
                sta SID.VOICE_1_PULSE_L
                lda sound9,y
                sta SID.VOICE_1_PULSE_H
                lda sound7,y
                sta SID.VOICE_1_CTRL
                tya
                pha
                lda #$6a
                jsr pauseOrExit
                lda #$00
                sta SID.VOICE_1_CTRL
                lda #$00
                jsr pauseOrExit
                dex
                bne loopA
                lda #$00
                sta SID.FILTER_RES_ROUT
                lda #$18
                sta SID.FILTER_VOL
                lda #$3e
                sta SID.VOICE_2_ATK_DEC
                lda #$ca
                sta SID.VOICE_2_SUS_VOL_REL
                ldx #$06
        loopB:  lda sound3,x
                sta SID.VOICE_2_FREQ_H
                lda sound4,x
                sta SID.VOICE_2_FREQ_L
                pla
                tay
                lda sound8,y
                sta SID.VOICE_2_PULSE_L
                lda sound9,y
                sta SID.VOICE_2_PULSE_H
                lda sound7,y
                sta SID.VOICE_2_CTRL
                tya
                pha
                lda #$6a
                jsr pauseOrExit
                lda #$00
                sta SID.VOICE_2_CTRL
                lda #$00
                jsr pauseOrExit
                dex
                bne loopB
                lda #$00
                sta SID.FILTER_RES_ROUT
                lda #$1f
                sta SID.FILTER_VOL
                lda #$3e
                sta SID.VOICE_3_ATK_DEC
                lda #$ca
                sta SID.VOICE_3_SUS_VOL_REL
                ldx #$06
        loopC:  lda sound5,x
                sta SID.VOICE_3_FREQ_H
                lda sound6,x
                sta SID.VOICE_3_FREQ_L
                pla
                tay
                lda sound8,y
                sta SID.VOICE_3_PULSE_L
                lda sound9,y
                sta SID.VOICE_3_PULSE_H
                lda sound7,y
                sta SID.VOICE_3_CTRL
                tya
                pha
                lda #$6a
                jsr pauseOrExit
                lda #$00
                sta SID.VOICE_3_CTRL
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