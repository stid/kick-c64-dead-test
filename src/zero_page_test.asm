#importonce
#import "./zeropage.asm"
#import "./main.asm"
#import "./u_failure.asm"

///////      ZERO PAGE TEST
zeroPageTest: {
                ldx #$08
        !:      lda strZero,x   // Print Zero Page String
                sta $0450,x
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
                sta $045d
                lda #$0b         //"k"
                sta $045e
                jmp main.goStackPageTest

                // Zero Page Pattern Test BAD
        zeroPagePatternFailed:
                eor MemTestPattern,x
                tax
                lda #$02         //"b"
                sta $045d
                lda #$01         //"a"
                sta $045e
                lda #$04         //"d"
                sta $045f
                jmp testU
}
