#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"
#import "./constants.asm"


        * = * "screen ram test"

///////      SCREEN RAM TEST
screenRamTest: {
                ldx #$09
        !:      lda strScreen,x      //screen ram label
                sta VIDEO_RAM+$a0,x
                dex
                bpl !-

                ldx #<VIDEO_RAM
                ldy #>VIDEO_RAM
                stx tmpSourceAddressLow
                sty tmpSourceAddressHigh
        screenRamTestLoop:
                ldy #$00
                lda (tmpSourceAddressLow),y
                pha
                ldx #$13
        screenRamPatternTestLoop:
                lda MemTestPattern,x
                sta (tmpSourceAddressLow),y

                ShortDelayLoop(0)

                lda (tmpSourceAddressLow),y
                cmp MemTestPattern,x
                bne screenRamTestFailed
                dex
                bpl screenRamPatternTestLoop
                pla
                sta (tmpSourceAddressLow),y
                inc tmpSourceAddressLow
                bne !+
                inc tmpSourceAddressHigh         // > 255

        !:  lda tmpSourceAddressHigh
                cmp #$08
                bne screenRamTestLoop
                lda #$0f         //"o"
                sta VIDEO_RAM+$ad
                lda #$0b         //"k"
                sta VIDEO_RAM+$ae
                rts

        screenRamTestFailed:
                eor MemTestPattern,x
                tax
                lda #$02         //"b"
                sta VIDEO_RAM+$ad
                lda #$01         //"a"
                sta VIDEO_RAM+$ae
                lda #$04         //"d"
                sta VIDEO_RAM+$af
                jsr testU
}
