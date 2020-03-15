#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"
#import "./main.asm"
#import "./constants.asm"


///////      STACK TRACE TEST
stackPageTest: {
                ldx #$09
        !:      lda strStack,x      // stack page label
                sta VIDEO_RAM+$78,x
                dex
                bpl !-

                ldx #$13
        stackPagePatternLoop:
                lda MemTestPattern,x
                ldy #$00
        !:      sta STACK_MEM, y
                iny
                bne !-

                LongDelayLoop(0,0)

                // Test Stack Pattern consistency
                tax
                lda MemTestPattern,x
        !:      cmp STACK_MEM, y
                bne stackPageFailed
                iny
                bne !-
                dex
                bpl stackPagePatternLoop
                lda #$0f         //"o"
                sta VIDEO_RAM+$85
                lda #$0b         //"k"
                sta VIDEO_RAM+$86
                jmp mainLoop.testSetB       // Done with stack - progress to nect chunk of tests

        stackPageFailed:
                eor MemTestPattern,x      //memtest pattern
                tax
                lda #$02         //"b"
                sta VIDEO_RAM+$85
                lda #$01         //"a"
                sta VIDEO_RAM+$86
                lda #$04         //"d"
                sta VIDEO_RAM+$87
                jmp testU
}