#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"


///////      COLOR RAM TEST
colorRamTest: {
                ldx #$08
        !:      lda srtColor,x      // Print color ram test
                sta $04c8,x
                dex
                bpl !-

                ldx #<$d800
                ldy #>$d800
                stx tmpSourceAddressLow
                sty tmpSourceAddressHigh
                ldy #$00
        colorRamTestLoop:
                ldy #$00
                lda (tmpTargetPointer),y
                pha
                ldx #$0b
        colorRamPattermTestLoop:
                lda colorRamPattern,x
                sta (tmpTargetPointer),y

                ShortDelayLoop(0)

                lda (tmpTargetPointer),y
                and #$0f
                cmp colorRamPattern,x
                bne colorRamTestFailed
                dex
                bpl colorRamPattermTestLoop
                pla
                sta (tmpTargetPointer),y
                inc tmpSourceAddressLow
                bne !+          // > 255
                inc tmpSourceAddressHigh
        !:      lda tmpSourceAddressHigh
                cmp #$dc
                bne colorRamTestLoop
                lda #$0f         //"o"
                sta $04d5
                lda #$0b         //"k"
                sta $04d6
                rts

        colorRamTestFailed:
                eor colorRamPattern,x
                tax
                lda #$02         //"b"
                sta $04d5
                lda #$01         //"a"
                sta $04d6
                lda #$04         //"d"
                sta $04d7
                jmp testU
}