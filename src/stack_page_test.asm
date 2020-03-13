#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"
#import "./main.asm"


///////      STACK TRACE TEST
stackPageTest: {
                ldx #$09
        !:      lda strStack,x      // stack page label
                sta $0478,x
                dex
                bpl !-

                ldx #$13
        stackPagePatternLoop:
                lda MemTestPattern,x
                ldy #$00
        !:      sta $0100,y
                iny
                bne !-

                LongDelayLoop(0,0)

                // Test Stack Pattern consistency
                tax
                lda MemTestPattern,x
        !:      cmp $0100,y
                bne stackPageFailed
                iny
                bne !-
                dex
                bpl stackPagePatternLoop
                lda #$0f         //"o"
                sta $0485
                lda #$0b         //"k"
                sta $0486
                jmp main.testSetB       // Done with stack - progress to nect chunk of tests

        stackPageFailed:
                eor MemTestPattern,x      //memtest pattern
                tax
                lda #$02         //"b"
                sta $0485
                lda #$01         //"a"
                sta $0486
                lda #$04         //"d"
                sta $0487
                jmp testU
}