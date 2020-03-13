#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"


///////      RAM TEST
ramTest: {

                ldx #$07
        !:      lda strRam,x      // ram test label
                sta $04f0,x
                dex
                bpl !-

                ldx #<$0800
                ldy #>$0800
                stx tmpSourceAddressLow
                sty tmpSourceAddressHigh
        RamTestLoop:
                ldy #$00
                ldx #$13
        RamTestPatternLoop:
                lda MemTestPattern,x
                sta (tmpTargetPointer),y

                ShortDelayLoop($7f)

                lda (tmpTargetPointer),y
                cmp MemTestPattern,x
                bne RamTestFailed
                dex
                bpl RamTestPatternLoop
                inc tmpSourceAddressLow
                bne !+
                inc tmpSourceAddressHigh         // > 255
        !:      lda tmpSourceAddressHigh
                cmp #$10
                bne RamTestLoop
                lda #$0f         //"o"
                sta $04fd
                lda #$0b         //"k"
                sta $04fe
                rts

        RamTestFailed:
                eor MemTestPattern,x
                tax
                lda #$02         //"b"
                sta $04fd
                lda #$01         //"a"
                sta $04fe
                lda #$04         //"d"
                sta $04ff
}