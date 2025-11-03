#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"
#import "./main.asm"

        * = * "stack page test"

//=============================================================================
// STACK PAGE TEST - The Final Pre-Stack Test
// Tests memory locations $0100-$01FF (256 bytes)
//
// Purpose: Verify stack memory functionality which is essential for:
//          - Subroutine calls (JSR pushes return address)
//          - Subroutine returns (RTS pulls return address)
//          - Register preservation (PHA/PLA, PHP/PLP)
//          - Interrupt handling (automatic stack usage)
//
// Method:  AA/55/PRN pattern testing (suggested by Sven Petersen)
//          Superior to walking bits for detecting address bus problems
//
// Test Patterns:
//   1. $AA (10101010) - Detects stuck-low bits on odd positions
//   2. $55 (01010101) - Detects stuck-high bits on even positions
//   3. 247-byte PRN sequence - Detects address bus problems
//   4. Walking ones/zeros - Identifies specific failing chips
//
// CRITICAL MILESTONE:
// - This is the LAST test that must avoid JSR/RTS
// - After this test passes, we can finally use subroutines!
// - Stack pointer was initialized to $FF in main loop
//
// Stack grows downward: $01FF -> $0100 (full to empty)
//=============================================================================
stackPageTest: {
                // Display "stack page" label on screen
                ldx #$09
        !:      lda strStack,x
                sta VIDEO_RAM+$78,x     // Row 3, column 24
                dex
                bpl !-

                //=============================================================
                // PHASE 1: Write and verify $AA pattern
                //=============================================================
                lda #$aa
                ldy #$00                        // Start at $0100
        writeAALoop:
                sta STACK_MEM,y                 // STACK_MEM = $0100
                iny
                bne writeAALoop

                LongDelayLoop(0,0)

                ldy #$00
        verifyAALoop:
                lda STACK_MEM,y
                cmp #$aa
                bne !fail+
                iny
                bne verifyAALoop
                jmp !next+
        !fail:  jmp stackPageFailed_AA
        !next:

                //=============================================================
                // PHASE 2: Write and verify $55 pattern
                //=============================================================
                lda #$55
                ldy #$00
        write55Loop:
                sta STACK_MEM,y
                iny
                bne write55Loop

                LongDelayLoop(0,0)

                ldy #$00
        verify55Loop:
                lda STACK_MEM,y
                cmp #$55
                bne !fail+
                iny
                bne verify55Loop
                jmp !next+
        !fail:  jmp stackPageFailed_55
        !next:

                //=============================================================
                // PHASE 3: Write and verify PRN sequence
                // Tests all 256 bytes with PRN pattern
                //=============================================================
                ldx #$00                        // PRN pattern index
                ldy #$00
        writePRNLoop:
                lda PrnTestPattern,x
                sta STACK_MEM,y
                inx
                cpx #247                        // Wrap at 247
                bne !+
                ldx #$00
        !:      iny
                bne writePRNLoop

                LongDelayLoop(0,0)

                ldx #$00
                ldy #$00
        verifyPRNLoop:
                lda STACK_MEM,y
                cmp PrnTestPattern,x
                bne !fail+
                inx
                cpx #247
                bne !+
                ldx #$00
        !:      iny
                bne verifyPRNLoop
                jmp !next+
        !fail:  jmp stackPageFailed_PRN
        !next:

                //=============================================================
                // PHASE 4: Walking bits tests
                // Tests individual bit positions for chip identification
                //=============================================================
                ldx #$04                        // Start with walking ones
        walkingBitsLoop:
                lda MemTestPattern,x
                ldy #$00
        writeWalkingLoop:
                sta STACK_MEM,y
                iny
                bne writeWalkingLoop

                LongDelayLoop(0,0)

                lda MemTestPattern,x
                ldy #$00
        verifyWalkingLoop:
                cmp STACK_MEM,y
                bne !fail+
                iny
                bne verifyWalkingLoop
                jmp !next+
        !fail:  jmp stackPageFailed_Walking
        !next:

                inx
                cpx #$14                        // Test through index 19
                bne walkingBitsLoop

                // Stack test passed! This is a major milestone
                lda #$0f                        // 'O' in screen code
                sta VIDEO_RAM+$85
                lda #$0b                        // 'K' in screen code
                sta VIDEO_RAM+$86

                // LAST USE OF JMP INSTEAD OF JSR!
                // After this point, stack operations are safe
                jmp mainLoop.stackPageTestDone  // Continue to JSR-enabled tests

                //=============================================================
                // Failure handlers - Different messages for different failures
                //=============================================================
        stackPageFailed_AA:
                eor #$aa
                tax
                // Display "BIT" - stuck bit failure
                lda #$02                        // 'B' in screen code
                sta VIDEO_RAM+$85
                lda #$09                        // 'I' in screen code
                sta VIDEO_RAM+$86
                lda #$14                        // 'T' in screen code
                sta VIDEO_RAM+$87
                jmp UFailed                     // Show which bits failed

        stackPageFailed_55:
                eor #$55
                tax
                // Display "BIT" - stuck bit failure
                lda #$02                        // 'B' in screen code
                sta VIDEO_RAM+$85
                lda #$09                        // 'I' in screen code
                sta VIDEO_RAM+$86
                lda #$14                        // 'T' in screen code
                sta VIDEO_RAM+$87
                jmp UFailed                     // Show which bits failed

        stackPageFailed_PRN:
                // Display "BUS" - address bus failure
                lda #$02                        // 'B' in screen code
                sta VIDEO_RAM+$85
                lda #$15                        // 'U' in screen code
                sta VIDEO_RAM+$86
                lda #$13                        // 'S' in screen code
                sta VIDEO_RAM+$87
                // Don't call UFailed - this is not a chip failure
                jmp UFailed.deadLoop                    // Halt (address bus issue)

        stackPageFailed_Walking:
                eor MemTestPattern,x
                tax
                // Display "BAD" - specific chip failure
                lda #$02                        // 'B' in screen code
                sta VIDEO_RAM+$85
                lda #$01                        // 'A' in screen code
                sta VIDEO_RAM+$86
                lda #$04                        // 'D' in screen code
                sta VIDEO_RAM+$87
                jmp UFailed                     // Show which chip failed
}