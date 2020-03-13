#importonce
#import "./main.asm"
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"

fontTest: {
    ///////      FONT TESTS
            lda #<font
            ldx #>font
            sta tmpSourceAddressLow
            stx tmpSourceAddressHigh
            lda #<$0800
            ldx #>$0800
            sta tmpDestAddressLow
            stx tmpDestAddressHigh
            ldx #$01
            ldy #$00
    copyFontLoop:
            lda (tmpTargetPointer),y
            sta (tmpDestPointer),y
            iny
            bne copyFontLoop
            inc tmpSourceAddressHigh
            inc tmpDestAddressHigh
            dex
            bpl copyFontLoop
            jsr updateCia1Time

            jsr soundTest        // sound test

            sed
            lda #$01
            clc
            adc counterLow
            sta counterLow
            lda #$00
            adc counterHigh
            sta counterHigh
            cld
            lda #$e7
            sta ZProcessPortBit
            lda #$37
            sta ZProcessDataDir
            lda #$00
            sta $d418
            ldx #$00
            lda #$20
    !:      sta $0400,x
            sta $0500,x
            inx
            bne !-
            ldx #$2e
            lda #$20
    !:      sta $0600,x
            dex
            bpl !-
            rts

}