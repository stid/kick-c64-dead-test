#importonce
#import "./main.asm"
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"
#import "./constants.asm"

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
            rts
}