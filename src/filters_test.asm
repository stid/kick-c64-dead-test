#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./mem_map.asm"
#import "./zeropage_map.asm"


        * = * "filters test"

.const SID_WF       = 64

// Based on BASIC SID TESTER by Andrew Challis
// http://hackjunk.com/2017/11/07/commodore-64-sid-tester/

filterTest: {
                ldx #11
        !:      lda strFilters,x      //label sound test
                sta VIDEO_RAM+$140,x
                dex
                bpl !-

                jsr     clearSid

                lda     #15
                sta     ZP.tmpFilterSound
                jsr     filtersLoop
                lda     #45
                sta     ZP.tmpFilterSound
                jsr     filtersLoop

                rts

    filtersLoop: {
                ldx     #5*16+1+2+4
                stx     SID.FILTER_RES_ROUT
                lda     #16
        !:
                pha
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                pla
                tax
                clc
                adc     #15
                sta     SID.FILTER_VOL
                txa

                jsr     mainSoundLoop

                cmp     #64
                beq     done
                asl
                jmp     !-

        done:
                rts
    }


    mainSoundLoop: {
                pha
                ldy     #0

        loop:
                pha
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                pla
                lda     ZP.tmpFilterSound
                sta     SID.VOICE_1_FREQ_H, y
                lda     #0
                sta     SID.VOICE_1_ATK_DEC, y
                lda     #240
                sta     SID.VOICE_1_SUS_VOL_REL, y
                lda     #8
                sta     SID.VOICE_1_PULSE_H, y
                lda     #SID_WF+1
                sta     SID.VOICE_1_CTRL, y

                jsr     filterCutOff
                lda     #SID_WF
                sta     SID.VOICE_1_CTRL, y

                pha
                tya
                clc
                adc     #7
                tay
                pla
                cpy     #21
                bne     loop
                pla
                rts
    }


    filterCutOff: {
                txa
                pha
                ldx     #0
        !:
                pha
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                pla

                stx     SID.FILTER_CUTOFF_H
                inx
                bne     !-
                pla
                tax
                rts
    }

    clearSid: {
                lda     #0
                sta     SID.FILTER_VOL
                ldy     #0
        !:
                pha
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                pla

                sta     $D400, y
                iny
                cpy     #$19
                bne     !-
                rts
    }
}
