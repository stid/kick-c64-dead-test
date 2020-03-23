#importonce
#import "./data.asm"
#import "./zeropage_map.asm"

        * = * "font test"


fontTest: {
                lda #<font
                ldx #>font
                sta ZP.tmpSourceAddressLow
                stx ZP.tmpSourceAddressHigh
                lda #<$0800
                ldx #>$0800
                sta ZP.tmpDestAddressLow
                stx ZP.tmpDestAddressHigh
                ldx #$01
                ldy #$00
    !:
                lda (ZP.tmpSourceAddressLow),y
                sta (ZP.tmpDestAddressLow),y
                iny
                bne !-
                inc ZP.tmpSourceAddressHigh
                inc ZP.tmpDestAddressHigh
                dex
                bpl !-
                rts
}