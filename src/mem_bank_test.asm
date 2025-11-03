#importonce
#import "./macros.asm"
#import "./zeropage_map.asm"
#import "./data.asm"
#import "./main_loop.asm"

        * = * "mem bank test"

//=============================================================================
// MEMORY BANK TEST - Critical First Test
// Tests main RAM banks $0100-$0FFF before any visual output
//
// Purpose: Verify basic RAM functionality to establish foundation for all
//          subsequent tests. Without working RAM, nothing else can function.
//
// Method:  AA/55/PRN pattern testing (suggested by Sven Petersen)
//          Superior to walking bits for detecting address bus problems
//
// Test Patterns:
//   1. $AA (10101010) - Detects stuck-low bits on odd positions
//   2. $55 (01010101) - Detects stuck-high bits on even positions
//   3. 247-byte PRN sequence - Detects address bus problems and page confusion
//
// CRITICAL CONSTRAINTS:
// - NO STACK OPERATIONS (JSR/RTS/PHA/PLA) - Stack at $0100-$01FF not verified
// - NO ZERO PAGE beyond test variables - Zero page not yet tested
// - Screen remains BLACK during test - No visual RAM verified yet
// - Only registers A,X,Y and JMP instructions available
//
// Failure Mode: Screen flashes white/black N times for failed chip N (1-8)
//               Then enters infinite loop - system halted
//=============================================================================
memBankTest: {
                //=============================================================
                // PHASE 1: Write and verify $AA pattern
                //=============================================================
                ldy #$00                // Start at offset 0 in each page

        writeAALoop:
                lda #$aa                // $AA pattern

                // Write to all 15 pages ($0100-$0F00)
                sta $0100,y             // Stack page (will be tested separately too)
                sta $0200,y             // Page 2
                sta $0300,y             // Page 3
                sta $0400,y             // Screen RAM page
                sta $0500,y             // Page 5
                sta $0600,y             // Page 6
                sta $0700,y             // Page 7
                sta $0800,y             // Page 8 - Character/sprite data
                sta $0900,y             // Page 9
                sta $0a00,y             // Page 10
                sta $0b00,y             // Page 11
                sta $0c00,y             // Page 12
                sta $0d00,y             // Page 13
                sta $0e00,y             // Page 14
                sta $0f00,y             // Page 15 - Last testable page

                iny                     // Next offset in page
                bne writeAALoop         // Continue until page filled (256 bytes)

                // Critical delay to ensure memory cells stabilize
                LongDelayLoop(0,0)

                // Verify $AA pattern
                ldy #$00
        verifyAALoop:
                lda $0100,y
                cmp #$aa
                bne !fail+
                lda $0200,y
                cmp #$aa
                bne !fail+
                lda $0300,y
                cmp #$aa
                bne !fail+
                lda $0400,y
                cmp #$aa
                bne !fail+
                lda $0500,y
                cmp #$aa
                bne !fail+
                lda $0600,y
                cmp #$aa
                bne !fail+
                lda $0700,y
                cmp #$aa
                bne !fail+
                lda $0800,y
                cmp #$aa
                bne !fail+
                lda $0900,y
                cmp #$aa
                bne !fail+
                lda $0a00,y
                cmp #$aa
                bne !fail+
                lda $0b00,y
                cmp #$aa
                bne !fail+
                lda $0c00,y
                cmp #$aa
                bne !fail+
                lda $0d00,y
                cmp #$aa
                bne !fail+
                lda $0e00,y
                cmp #$aa
                bne !fail+
                lda $0f00,y
                cmp #$aa
                bne !fail+
                iny
                bne verifyAALoop
                jmp !next+
        !fail:  jmp memTestFailed_AA
        !next:

                //=============================================================
                // PHASE 2: Write and verify $55 pattern
                //=============================================================
                ldy #$00

        write55Loop:
                lda #$55                // $55 pattern

                sta $0100,y
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
                bne write55Loop

                LongDelayLoop(0,0)

                // Verify $55 pattern
                ldy #$00
        verify55Loop:
                lda $0100,y
                cmp #$55
                bne !fail+
                lda $0200,y
                cmp #$55
                bne !fail+
                lda $0300,y
                cmp #$55
                bne !fail+
                lda $0400,y
                cmp #$55
                bne !fail+
                lda $0500,y
                cmp #$55
                bne !fail+
                lda $0600,y
                cmp #$55
                bne !fail+
                lda $0700,y
                cmp #$55
                bne !fail+
                lda $0800,y
                cmp #$55
                bne !fail+
                lda $0900,y
                cmp #$55
                bne !fail+
                lda $0a00,y
                cmp #$55
                bne !fail+
                lda $0b00,y
                cmp #$55
                bne !fail+
                lda $0c00,y
                cmp #$55
                bne !fail+
                lda $0d00,y
                cmp #$55
                bne !fail+
                lda $0e00,y
                cmp #$55
                bne !fail+
                lda $0f00,y
                cmp #$55
                bne !fail+
                iny
                bne verify55Loop
                jmp !next+
        !fail:  jmp memTestFailed_55
        !next:

                //=============================================================
                // PHASE 3: Write and verify PRN sequence
                // PRN is 247 bytes, so it repeats: [0-246],[0-8] for 256 bytes
                //=============================================================
                ldx #$00                // PRN pattern index
                ldy #$00                // Page offset

        writePRNLoop:
                lda PrnTestPattern,x    // Get PRN byte

                sta $0100,y
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

                // Increment PRN index with wrap at 247
                inx
                cpx #247                // PRN sequence length
                bne !+
                ldx #$00                // Wrap to start
        !:
                iny                     // Next page offset
                bne writePRNLoop

                LongDelayLoop(0,0)

                // Verify PRN pattern
                ldx #$00
                ldy #$00
        verifyPRNLoop:
                lda $0100,y
                cmp PrnTestPattern,x
                bne !fail+
                lda $0200,y
                cmp PrnTestPattern,x
                bne !fail+
                lda $0300,y
                cmp PrnTestPattern,x
                bne !fail+
                lda $0400,y
                cmp PrnTestPattern,x
                bne !fail+
                jmp !continue+
        !fail:  jmp memTestFailed_PRN
        !continue:
                lda $0500,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0600,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0700,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0800,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0900,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0a00,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0b00,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0c00,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0d00,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0e00,y
                cmp PrnTestPattern,x
                bne !fail-
                lda $0f00,y
                cmp PrnTestPattern,x
                bne !fail-

                // Increment PRN index with wrap at 247
                inx
                cpx #247
                bne !+
                ldx #$00
        !:
                iny
                bne !+
                jmp walkingBitsPhase
        !:      jmp verifyPRNLoop

                //=============================================================
                // PHASE 4: Walking bits tests (from original Dead Test)
                // Tests individual bit positions for chip identification
                //=============================================================
        walkingBitsPhase:
                // Test patterns: walking ones + walking zeros from MemTestPattern
                // Index 4-11 = walking ones ($01, $02, $04, $08, $10, $20, $40, $80)
                // Index 12-19 = walking zeros ($FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F)
                ldx #$04                // Start at index 4 (first walking one)

        walkingBitsLoop:
                lda MemTestPattern,x    // Get current test pattern
                ldy #$00                // Reset page offset

        writeWalkingLoop:
                sta $0100,y
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
                bne writeWalkingLoop

                // Delay for memory stabilization
                LongDelayLoop(0,0)

                // Verify pattern
                lda MemTestPattern,x    // Get expected value
                ldy #$00
        verifyWalkingLoop:
                cmp $0100,y
                bne !fail+
                cmp $0200,y
                bne !fail+
                cmp $0300,y
                bne !fail+
                cmp $0400,y
                bne !fail+
                cmp $0500,y
                bne !fail+
                cmp $0600,y
                bne !fail+
                cmp $0700,y
                bne !fail+
                cmp $0800,y
                bne !fail+
                cmp $0900,y
                bne !fail+
                cmp $0a00,y
                bne !fail+
                cmp $0b00,y
                bne !fail+
                cmp $0c00,y
                bne !fail+
                cmp $0d00,y
                bne !fail+
                cmp $0e00,y
                bne !fail+
                cmp $0f00,y
                bne !fail+
                iny
                bne verifyWalkingLoop
                jmp !next+
        !fail:  jmp memTestFailed_Walking
        !next:

                // Move to next pattern
                inx
                cpx #$14                // Test through index 19 (last walking zero)
                bne !+
                jmp memTestDone
        !:      jmp walkingBitsLoop

        memTestDone:
                // All memory tested successfully with all patterns!
                // Safe to proceed with visual initialization
                jmp mainLoop.memBankTestDone     // Continue to next test
                // CRITICAL: Using JMP not JSR - stack still not verified!

        memTestFailed_AA:
                // Failed during $AA pattern test
                // Accumulator contains actual value, XOR with expected $AA
                eor #$aa
                jmp memFailureFlash

        memTestFailed_55:
                // Failed during $55 pattern test
                // Accumulator contains actual value, XOR with expected $55
                eor #$55
                jmp memFailureFlash

        memTestFailed_PRN:
                // Failed during PRN pattern test - ADDRESS BUS FAILURE
                // This indicates crossed address lines or page mirroring
                // NOT a chip failure - do continuous fast flash instead
                jmp memBusFailureFlash

        memTestFailed_Walking:
                // Failed during walking bits test
                // Accumulator contains actual value
                // X contains index into MemTestPattern (the expected value)
                // XOR actual with expected to get failing bits
                eor MemTestPattern,x
                jmp memFailureFlash

        memFailureFlash: {
                // Identify which RAM chip failed based on bit differences
                // Each data bit is handled by a specific RAM chip:
                // Bit 0 = U21 (Bank 8)  Bit 4 = U23 (Bank 4)
                // Bit 1 = U9  (Bank 7)  Bit 5 = U11 (Bank 3)
                // Bit 2 = U22 (Bank 6)  Bit 6 = U24 (Bank 2)
                // Bit 3 = U10 (Bank 5)  Bit 7 = U12 (Bank 1)

                // A contains XOR result (difference bits)
                tax                     // Save difference pattern

                // Check each bit to identify failed chip
                // Start with bit 0 (Bank 8/U21)
                and #$fe                // Mask all except bit 0
                bne bank7Fail           // If other bits set, not just bank 8
                ldx #$08                // Bank 8 = flash 8 times
                jmp flash

                bank7Fail:
                        // Check bit 1 (Bank 7/U9)
                        txa                     // Get difference pattern
                        and #$fd                // Mask all except bit 1
                        bne bank6Fail           // Other bits set, check next
                        ldx #$07                // Bank 7 = flash 7 times
                        jmp flash

                bank6Fail:
                        // Check bit 2 (Bank 6/U22)
                        txa
                        and #$fb                // Mask all except bit 2
                        bne bank5Fail
                        ldx #$06                // Bank 6 = flash 6 times
                        jmp flash

                bank5Fail:
                        // Check bit 3 (Bank 5/U10)
                        txa
                        and #$f7                // Mask all except bit 3
                        bne bank4Fail
                        ldx #$05                // Bank 5 = flash 5 times
                        jmp flash

                bank4Fail:
                        // Check bit 4 (Bank 4/U23)
                        txa
                        and #$ef                // Mask all except bit 4
                        bne bank3Fail
                        ldx #$04                // Bank 4 = flash 4 times
                        jmp flash

                bank3Fail:
                        // Check bit 5 (Bank 3/U11)
                        txa
                        and #$df                // Mask all except bit 5
                        bne bank2Fail
                        ldx #$03                // Bank 3 = flash 3 times
                        jmp flash

                bank2Fail:
                        // Check bit 6 (Bank 2/U24)
                        txa
                        and #$bf                // Mask all except bit 6
                        bne bank1Fail
                        ldx #$02                // Bank 2 = flash 2 times
                        jmp flash

                bank1Fail:
                        // Bit 7 (Bank 1/U12) - last possibility
                        ldx #$01                // Bank 1 = flash 1 time
        }


        flash: {
                // Visual failure indication through screen flashing
                // Number of flashes = failed chip number (1-8)
                // This provides diagnostic info even without working display RAM

                txs                             // X = flash count, save to stack pointer

                flashLoop:                      // Main flash cycle
                        // Flash WHITE
                        lda #$01                // White color
                        sta VIC2.BORDERCOLOUR   // Set border
                        sta VIC2.BGCOLOUR       // Set background

                        LongDelayLoop($7f,0)    // Visible duration

                        // Flash BLACK
                        lda #$00                // Black color
                        sta VIC2.BORDERCOLOUR
                        sta VIC2.BGCOLOUR

                        LongDelayLoop($7f,0)    // Visible duration

                        // Flash counter logic
                        // Uses nested delay loops to control flash timing
                !:      dey
                        bne !-
                        dex
                        bne !-

                        tax                     // Get flash count from stack
                        dex                     // Decrement flash counter
                        beq endLoopDelay        // Done flashing? Long pause
                        jmp flashLoop           // Continue flashing

                endLoopDelay:
                        // Long pause between flash sequences
                        // Makes it clear when sequence repeats
                        ldx #$00
                        ldy #$00

                        // Four nested 256x256 loops for long delay
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

                        tsx                     // Restore flash count
                        jmp flashLoop           // Repeat sequence forever
        }

        // ADDRESS BUS FAILURE FLASH - Continuous fast flashing
        // No chip count pattern - indicates bus fault, not chip fault
        memBusFailureFlash: {
                busFlashLoop:
                        // Flash WHITE
                        lda #$01                // White color
                        sta VIC2.BORDERCOLOUR
                        sta VIC2.BGCOLOUR

                        ShortDelayLoop($1f)     // Short delay for fast flash

                        // Flash BLACK
                        lda #$00                // Black color
                        sta VIC2.BORDERCOLOUR
                        sta VIC2.BGCOLOUR

                        ShortDelayLoop($1f)     // Short delay for fast flash

                        jmp busFlashLoop        // Continuous loop - no pattern
        }
}
