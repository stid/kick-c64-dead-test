#importonce
#import "./zeropage.asm"
#import "./main_loop.asm"
#import "./u_failure.asm"
#import "./constants.asm"

///////      ZERO PAGE TEST
zeroPageTest: {
                ldx #$08
        !:      lda strZero,x   // Print Zero Page String
                sta VIDEO_RAM+$50,x
                dex
                bpl !-

                // Start filling Zero Page with mem pattern's byte
                ldx #$13
        zeroPagePatternLoop:
                lda MemTestPattern,x
                ldy #$12
        !:      sta $0000,y
                iny
                bne !-

                LongDelayLoop(0,0)

                // Check Zero Page mem consistency
                lda MemTestPattern,x
                ldy #$12
        !:      cmp $0000,y
                bne zeroPagePatternFailed
                iny
                bne !-
                dex
                bpl zeroPagePatternLoop

                // Zero Page Pattern Test OK
                lda #$0f         //"o"
                sta VIDEO_RAM+$5d
                lda #$0b         //"k"
                sta VIDEO_RAM+$5e
                jmp mainLoop.goStackPageTest

                // Zero Page Pattern Test BAD
        zeroPagePatternFailed:
                eor MemTestPattern,x
                tax
                lda #$02         //"b"
                sta VIDEO_RAM+$5d
                lda #$01         //"a"
                sta VIDEO_RAM+$5e
                lda #$04         //"d"
                sta VIDEO_RAM+$5f
                jmp testU
}
