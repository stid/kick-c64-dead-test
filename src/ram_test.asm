#importonce
#import "./data.asm"
#import "./mem_map.asm"
#import "./macros.asm"
#import "./zeropage_map.asm"

        * = * "ram test"


///////      RAM TEST
ramTest: {
                ldx #$07
        !:      lda strRam,x      // ram test label
                sta VIDEO_RAM+$f0,x
                dex
                bpl !-

                ldx #<$0800
                ldy #>$0800
                stx ZP.tmpSourceAddressLow
                sty ZP.tmpSourceAddressHigh
        RamTestLoop:
                ldy #$00
                ldx #$13
        RamTestPatternLoop:
                lda MemTestPattern,x
                sta (ZP.tmpSourceAddressLow),y

                ShortDelayLoop($7f)

                lda (ZP.tmpSourceAddressLow),y
                cmp MemTestPattern,x
                bne RamTestFailed
                dex
                bpl RamTestPatternLoop
                inc ZP.tmpSourceAddressLow
                bne !+
                inc ZP.tmpSourceAddressHigh         // > 255
        !:      lda ZP.tmpSourceAddressHigh
                cmp #$10
                bne RamTestLoop
                lda #$0f         //"o"
                sta VIDEO_RAM+$fd
                lda #$0b         //"k"
                sta VIDEO_RAM+$fe
                rts

        RamTestFailed:
                eor MemTestPattern,x
                tax
                lda #$02         //"b"
                sta VIDEO_RAM+$fd
                lda #$01         //"a"
                sta VIDEO_RAM+$fe
                lda #$04         //"d"
                sta VIDEO_RAM+$ff
}