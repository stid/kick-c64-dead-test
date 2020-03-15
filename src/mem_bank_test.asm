#importonce
#import "./macros.asm"
#import "./zeropage_map.asm"
#import "./data.asm"
#import "./main_loop.asm"

        * = * "mem bank test"

///////      MEMORY BANK TEST
memBankTest: {
                // prepare memory
                ldx #$15                // MemPattern Lenght is 20 - start at 21 here to dec later
                ldy #$00                // reset loop counter

        memPatternSetLoop:
                lda MemTestPattern,x    // Load pattern byte
                sta $0100,y             // Store in mem chunks, will fill
                sta $0200,y
                sta $0300,y
                sta $0400,y
                sta $0500,y
                sta $0600,y
                sta $0700,y
                sta $0800,y
                sta $0900,y
                sta $0a00,y
                sta $0b00,y
                sta $0c00,y
                sta $0d00,y
                sta $0e00,y
                sta $0f00,y
                iny
                bne memPatternSetLoop   // Loop to FF

                LongDelayLoop(0,0)

                // Compare previous stored mem pattern
                // Against related mem chunks
        memPatternCompLoop:
                lda $0100,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0200,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0300,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0400,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0500,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0600,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0700,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0800,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0900,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0a00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0b00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0c00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0d00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0e00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0f00,y
                cmp MemTestPattern,x
                bne memTestFailed
                iny
                beq memTestPassed       // Test done, no issues
                jmp memPatternCompLoop  // Loop over FF range

        memTestFailed:
                jmp memFailureFlash     // Memory Pattern Test failed

        memTestPassed:
                dex                     // Dec X to loade next pattern byte
                bmi memTestDone         // Done? - exit loop
                ldy #$00                // Reset Y counter
                jmp memPatternSetLoop   // back to pattern loop with new x pointer

        memTestDone:
                jmp mainLoop.memBankTestDone     //memtest ok, go to next stage
                                                // we can't use stack here - not tested yet

        memFailureFlash: {
                                        // Given actual pattern, indentify what's failed
                // Bank 8 Failed
                        eor MemTestPattern,x
                        tax
                        and #$fe
                        bne bank7Fail
                        ldx #$08
                        jmp flash        //mem error flash

                bank7Fail:
                        txa
                        and #$fd
                        bne bank6Fail
                        ldx #$07
                        jmp flash        //mem error flash

                bank6Fail:
                        txa
                        and #$fb
                        bne bank5Fail
                        ldx #$06
                        jmp flash        //mem error flash

                bank5Fail:
                        txa
                        and #$f7
                        bne bank4Fail
                        ldx #$05
                        jmp flash        //mem error flash

                bank4Fail:
                        txa
                        and #$ef
                        bne bank3Fail
                        ldx #$04
                        jmp flash        //mem error flash

                bank3Fail:
                        txa
                        and #$df
                        bne bank2Fail
                        ldx #$03
                        jmp flash        //mem error flash

                bank2Fail:
                        txa
                        and #$bf
                        bne bank1Fail
                        ldx #$02
                        jmp flash        //mem error flash

                bank1Fail:
                        ldx #$01         //mem error flash
        }


        flash: {
                        txs
                flashLoop:              // Infinite Flash Loop
                        lda #$01        // set Screen to White
                        sta VIC2_BORDERCOLOUR
                        sta VIC2_BGCOLOUR

                        LongDelayLoop($7f,0)

                        lda #$00        // set Screen to Black
                        sta VIC2_BORDERCOLOUR
                        sta VIC2_BGCOLOUR

                        LongDelayLoop($7f,0)

                !:      dey
                        bne !-
                        dex
                        bne !-
                        tax
                        dex
                        beq endLoopDelay       // Flash Loop End
                        jmp flashLoop

                        // End flash cycle Long Delay
                endLoopDelay:
                        ldx #$00
                        ldy #$00
                !:      dey
                        bne !-
                        dex
                        bne !-
                !:      dey
                        bne !-
                        dex
                        bne !-
                !:      dey
                        bne !-
                        dex
                        bne !-
                !:      dey
                        bne !-
                        dex
                        bne !-
                        tsx
                        jmp flashLoop           // Back to main loop
        }
}