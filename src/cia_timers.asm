#importonce
#import "./data.asm"
#import "./constants.asm"

        * = * "cia timers"

.enum {
        CIA1_HOUR_STEP=$01,
        CIA1_MIN_STEP=$02,
        CIA1_SEC_STEP=$03,
        CIA_CALC_STEP=$04,
        CIA2_HOUR_STEP=$05,
        CIA2_MIN_STEP=$06,
        CIA2_SEC_STEP=$07
        }

// CIA 1
updateCia1Time: {
                lda CIA1_REAL_TIME_HOUR
                clc
                asl
                bcc setAm
                lda #$10         //"p"
                sta VIDEO_RAM+$03db
                lda #$0d         //"m"
                sta VIDEO_RAM+$03dc
                clc
                bcc !+
        setAm:  lda #$01         //"a"
                sta VIDEO_RAM+$03db
                lda #$0d         //"m"
                sta VIDEO_RAM+$03dc
        !:      lda CIA1_REAL_TIME_HOUR
                and #$7f
                ldy #CIA1_HOUR_STEP
                bne calcTime
        setHour:
                sta VIDEO_RAM+$03d3        //xx-00-00
                stx VIDEO_RAM+$03d4
                lda #$2d         //"-"
                sta VIDEO_RAM+$03d5
                lda CIA1_REAL_TIME_MIN
                ldy #CIA1_MIN_STEP
                bne calcTime
        setMinute:
                sta VIDEO_RAM+$03d6        //00-xx-00
                stx VIDEO_RAM+$03d7
                lda #$2d         //"-"
                sta VIDEO_RAM+$03d8
                lda CIA1_REAL_TIME_SEC
                ldy #CIA1_SEC_STEP
                bne calcTime
        setSecond:
                sta VIDEO_RAM+$03d9        //00-00-xx
                stx VIDEO_RAM+$03da
                lda CIA1_REAL_TIME_10THS

                clc
                bcc UpdateCia2Time
                ldy #$00
}


calcTime:  {
                pha
                sty tmpY
                ldy #CIA_CALC_STEP
                bne done
        loop:   ldy tmpY
                tax
                pla
                lsr
                lsr
                lsr
                lsr
        done:   and #$0f
                cmp #$0a
                bmi ie74c
                sec
                sbc #$09
                bne !+
        ie74c:  ora #$30
        !:      cpy #CIA1_HOUR_STEP
                beq updateCia1Time.setHour
                cpy #CIA1_MIN_STEP
                beq updateCia1Time.setMinute
                cpy #CIA1_SEC_STEP
                beq updateCia1Time.setSecond
                cpy #CIA_CALC_STEP
                beq loop
                cpy #CIA2_HOUR_STEP
                beq UpdateCia2Time.setHour
                cpy #CIA2_MIN_STEP
                beq UpdateCia2Time.setMinue
                cpy #CIA2_SEC_STEP
                beq UpdateCia2Time.setSecond
                rts
}


// CIA 2
UpdateCia2Time: {
                lda CIA2_REAL_TIME_HOUR
                clc
                asl
                bcc setAm
                lda #$10         //"p"
                sta VIDEO_RAM+$03e6
                lda #$0d         //"m"
                sta VIDEO_RAM+$03e7
                clc
                bcc !+
        setAm:  lda #$01         //"a"
                sta VIDEO_RAM+$03e6
                lda #$0d         //"m"
                sta VIDEO_RAM+$03e7
        !:      lda CIA2_REAL_TIME_HOUR
                and #$7f
                ldy #$05
        ie790:  bne calcTime
        setHour:
                sta VIDEO_RAM+$03de        //xx-00-00
                stx VIDEO_RAM+$03df
                lda #$2d         //"-"
                sta VIDEO_RAM+$03e0
                lda CIA2_REAL_TIME_MIN
                ldy #$06
                bne ie790
        setMinue:
                sta VIDEO_RAM+$03e1        //00-xx-00
                stx VIDEO_RAM+$03e2
                lda #$2d         //"-"
                sta VIDEO_RAM+$03e3
                lda CIA2_REAL_TIME_SEC
                ldy #$07
                bne ie790
        setSecond:
                sta VIDEO_RAM+$03e4        //00-00-xx
                stx VIDEO_RAM+$03e5
                lda CIA2_REAL_TIME_10THS
                rts
}
