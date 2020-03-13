#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"

///////      SCREEN RAM TEST
screenRamTest: {
                ldx #$09
        !:      lda strScreen,x      //screen ram label
                sta $04a0,x
                dex
                bpl !-

                ldx #<$0400
                ldy #>$0400
                stx tmpSourceAddressLow
                sty tmpSourceAddressHigh
        screenRamTestLoop:
                ldy #$00
                lda (tmpTargetPointer),y
                pha
                ldx #$13
        screenRamPatternTestLoop:
                lda MemTestPattern,x
                sta (tmpTargetPointer),y

                ShortDelayLoop(0)

                lda (tmpTargetPointer),y
                cmp MemTestPattern,x
                bne screenRamTestFailed
                dex
                bpl screenRamPatternTestLoop
                pla
                sta (tmpTargetPointer),y
                inc tmpSourceAddressLow
                bne !+
                inc tmpSourceAddressHigh         // > 255

        !:  lda tmpSourceAddressHigh
                cmp #$08
                bne screenRamTestLoop
                lda #$0f         //"o"
                sta $04ad
                lda #$0b         //"k"
                sta $04ae
                rts

        screenRamTestFailed:
                eor MemTestPattern,x
                tax
                lda #$02         //"b"
                sta $04ad
                lda #$01         //"a"
                sta $04ae
                lda #$04         //"d"
                sta $04af
                jsr testU
}
