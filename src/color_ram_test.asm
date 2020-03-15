#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"
#import "./constants.asm"

        * = * "color ram test"


///////      COLOR RAM TEST
colorRamTest: {
                ldx #$08
        !:      lda srtColor,x      // Print color ram test
                sta VIDEO_RAM+$c8,x
                dex
                bpl !-

                ldx #<$d800
                ldy #>$d800
                stx tmpSourceAddressLow
                sty tmpSourceAddressHigh
                ldy #$00
        colorRamTestLoop:
                ldy #$00
                lda (tmpSourceAddressLow),y
                pha
                ldx #$0b
        colorRamPattermTestLoop:
                lda colorRamPattern,x
                sta (tmpSourceAddressLow),y

                ShortDelayLoop(0)

                lda (tmpSourceAddressLow),y
                and #$0f
                cmp colorRamPattern,x
                bne colorRamTestFailed
                dex
                bpl colorRamPattermTestLoop
                pla
                sta (tmpSourceAddressLow),y
                inc tmpSourceAddressLow
                bne !+          // > 255
                inc tmpSourceAddressHigh
        !:      lda tmpSourceAddressHigh
                cmp #$dc
                bne colorRamTestLoop
                lda #$0f         //"o"
                sta VIDEO_RAM+$d5
                lda #$0b         //"k"
                sta VIDEO_RAM+$d6
                rts

        colorRamTestFailed:
                eor colorRamPattern,x
                tax
                lda #$02         //"b"
                sta VIDEO_RAM+$d5
                lda #$01         //"a"
                sta VIDEO_RAM+$d6
                lda #$04         //"d"
                sta VIDEO_RAM+$d7
                jmp testU
}