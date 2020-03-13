#importonce
#import "./data.asm"


// CIA 1
updateCia1Time: {
                lda $dc0b
                clc
                asl
                bcc setAm
                lda #$10         //"p"
                sta $07db
                lda #$0d         //"m"
                sta $07dc
                clc
                bcc !+
        setAm:  lda #$01         //"a"
                sta $07db
                lda #$0d         //"m"
                sta $07dc
        !:      lda $dc0b
                and #$7f
                ldy #$01
                bne calcTime
        setHour:
                sta $07d3        //xx-00-00
                stx $07d4
                lda #$2d         //"-"
                sta $07d5
                lda $dc0a
                ldy #$02
                bne calcTime
        setMinute:
                sta $07d6        //00-xx-00
                stx $07d7
                lda #$2d         //"-"
                sta $07d8
                lda $dc09
                ldy #$03
                bne calcTime
        setSecond:
                sta $07d9        //00-00-xx
                stx $07da
                lda $dc08

                clc
                bcc UpdateCia2Time
                ldy #$00
}



calcTime:  {
                pha
                sty tmpY
                ldy #$04
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
        !:      cpy #$01
                beq updateCia1Time.setHour
                cpy #$02
                beq updateCia1Time.setMinute
                cpy #$03
                beq updateCia1Time.setSecond
                cpy #$04
                beq loop
                cpy #$05
                beq UpdateCia2Time.setHour
                cpy #$06
                beq UpdateCia2Time.setMinue
                cpy #$07
                beq UpdateCia2Time.setSecond
                rts
}


// CIA 2
UpdateCia2Time: {
                lda $dd0b
                clc
                asl
                bcc setAm
                lda #$10         //"p"
                sta $07e6
                lda #$0d         //"m"
                sta $07e7
                clc
                bcc !+
        setAm:  lda #$01         //"a"
                sta $07e6
                lda #$0d         //"m"
                sta $07e7
        !:  lda $dd0b
                and #$7f
                ldy #$05
        ie790:  bne calcTime
        setHour:
                sta $07de        //xx-00-00
                stx $07df
                lda #$2d         //"-"
                sta $07e0
                lda $dd0a
                ldy #$06
                bne ie790
        setMinue:
                sta $07e1        //00-xx-00
                stx $07e2
                lda #$2d         //"-"
                sta $07e3
                lda $dd09
                ldy #$07
                bne ie790
        setSecond:
                sta $07e4        //00-00-xx
                stx $07e5
                lda $dd08
                rts
}
