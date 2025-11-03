#importonce
#import "./u_failure.asm"
#import "./macros.asm"
#import "./zeropage_map.asm"
#import "./mem_map.asm"
#import "./data.asm"
#import "./main_loop.asm"


        * = * "zero page test"

//=============================================================================
// ZERO PAGE TEST - Critical Foundation Memory
// Tests memory locations $00-$FF, the most important 256 bytes in the system
//
// Purpose: Verify zero page functionality which is essential for:
//          - Pointer operations (LDA ($nn),Y addressing mode)
//          - Fast variable access (2-cycle vs 3-cycle instructions)
//          - Operating system workspace
//          - Our own test variables ($00-$11)
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
// CRITICAL CONSTRAINTS:
// - NO STACK OPERATIONS - Stack at $0100-$01FF not verified yet
// - Must preserve locations $00-$11 (our test variables)
// - Still cannot use JSR/RTS, only JMP for flow control
//
// Test Range: $12-$FF (preserving $00-$11 for test variables, 238 bytes)
//=============================================================================
zeroPageTest: {
                // Display "zero page" label on screen
                // Can now use screen RAM - it passed the memory bank test
                ldx #$08
        !:      lda strZero,x
                sta VIDEO_RAM+$50,x     // Row 2, column 16
                dex
                bpl !-

                //=============================================================
                // PHASE 1: Write and verify $AA pattern
                //=============================================================
                lda #$aa
                ldy #$12                        // Start at $12, preserve $00-$11
        writeAALoop:
                sta $0000,y
                iny
                bne writeAALoop                 // Continue through $FF

                LongDelayLoop(0,0)

                ldy #$12
        verifyAALoop:
                lda $0000,y
                cmp #$aa
                bne !fail+
                iny
                bne verifyAALoop
                jmp !next+
        !fail:  jmp zeroPageFailed_AA
        !next:

                //=============================================================
                // PHASE 2: Write and verify $55 pattern
                //=============================================================
                lda #$55
                ldy #$12
        write55Loop:
                sta $0000,y
                iny
                bne write55Loop

                LongDelayLoop(0,0)

                ldy #$12
        verify55Loop:
                lda $0000,y
                cmp #$55
                bne !fail+
                iny
                bne verify55Loop
                jmp !next+
        !fail:  jmp zeroPageFailed_55
        !next:

                //=============================================================
                // PHASE 3: Write and verify PRN sequence
                // Only tests 238 bytes ($12-$FF) with PRN pattern
                //=============================================================
                ldx #$00                        // PRN pattern index
                ldy #$12                        // Start at $12
        writePRNLoop:
                lda PrnTestPattern,x
                sta $0000,y
                inx
                cpx #247                        // Wrap at 247
                bne !+
                ldx #$00
        !:      iny
                bne writePRNLoop

                LongDelayLoop(0,0)

                ldx #$00
                ldy #$12
        verifyPRNLoop:
                lda $0000,y
                cmp PrnTestPattern,x
                bne !fail+
                inx
                cpx #247
                bne !+
                ldx #$00
        !:      iny
                bne verifyPRNLoop
                jmp !next+
        !fail:  jmp zeroPageFailed_PRN
        !next:

                //=============================================================
                // PHASE 4: Walking bits tests
                // Tests individual bit positions for chip identification
                //=============================================================
                ldx #$04                        // Start with walking ones
        walkingBitsLoop:
                lda MemTestPattern,x
                ldy #$12
        writeWalkingLoop:
                sta $0000,y
                iny
                bne writeWalkingLoop

                LongDelayLoop(0,0)

                lda MemTestPattern,x
                ldy #$12
        verifyWalkingLoop:
                cmp $0000,y
                bne !fail+
                iny
                bne verifyWalkingLoop
                jmp !next+
        !fail:  jmp zeroPageFailed_Walking
        !next:

                inx
                cpx #$14                        // Test through index 19
                bne walkingBitsLoop

                // All tests passed!
                // Display "OK" result
                lda #$0f                        // 'O' in screen code
                sta VIDEO_RAM+$5d
                lda #$0b                        // 'K' in screen code
                sta VIDEO_RAM+$5e

                // CRITICAL: Use JMP not JSR - stack still not tested!
                jmp mainLoop.zeroPageTestDone

                //=============================================================
                // Failure handlers
                //=============================================================
        zeroPageFailed_AA:
                eor #$aa
                tax
                jmp showZeroPageFailure

        zeroPageFailed_55:
                eor #$55
                tax
                jmp showZeroPageFailure

        zeroPageFailed_PRN:
                eor PrnTestPattern,x
                tax
                jmp showZeroPageFailure

        zeroPageFailed_Walking:
                eor MemTestPattern,x
                tax
                // Fall through to showZeroPageFailure

        showZeroPageFailure:
                // Display "BAD" result
                lda #$02                        // 'B' in screen code
                sta VIDEO_RAM+$5d
                lda #$01                        // 'A' in screen code
                sta VIDEO_RAM+$5e
                lda #$04                        // 'D' in screen code
                sta VIDEO_RAM+$5f

                // Identify failed chip and halt
                jmp UFailed
}
