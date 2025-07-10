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
// Method:  Pattern-based write/read verification across all memory pages
//          Uses 20 different test patterns to detect various failure modes
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
                // Initialize test parameters
                // X = Pattern index (counting backwards from 20 to 0)
                // Y = Memory offset within each page (0-255)
                ldx #$15                // Start at pattern 21 ($15) to allow pre-decrement
                ldy #$00                // Start at offset 0 in each page

        memPatternSetLoop:
                // Write current test pattern to all memory pages simultaneously
                // This approach tests all RAM chips with the same pattern,
                // making it easier to identify which specific chip failed
                lda MemTestPattern,x    // Get current test pattern byte
                
                // Write to all 15 pages ($0100-$0F00)
                // Each page tests different address lines
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
                bne memPatternSetLoop   // Continue until page filled (256 bytes)

                // Critical delay to ensure memory cells stabilize
                // Dynamic RAM needs time to charge/discharge capacitors
                // This delay helps detect:
                // - Weak cells that lose charge quickly
                // - Capacitor failures
                // - Timing-related issues
                LongDelayLoop(0,0)

                // Verify all memory locations match expected pattern
                // Y still = 0 from overflow after writing 256 bytes
        memPatternCompLoop:
                // Read back and verify each memory location
                // If any bit differs from expected, we can identify
                // which RAM chip failed based on the bit position
                lda $0100,y
                cmp MemTestPattern,x
                bne memTestFailed       // Jump if mismatch found
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
                iny                     // Next memory offset
                beq memTestPassed       // Y wrapped to 0 = all 256 bytes verified
                jmp memPatternCompLoop  // Continue checking

        memTestFailed:
                // A memory location didn't match the expected pattern
                // The accumulator contains the actual (failed) value
                // Jump to failure handler to identify which chip failed
                jmp memFailureFlash

        memTestPassed:
                // All 256 bytes matched for current pattern
                // Move to next test pattern
                dex                     // Previous pattern (counting backwards)
                bmi memTestDone         // X < 0 means all 21 patterns tested
                ldy #$00                // Reset page offset for next pattern
                jmp memPatternSetLoop   // Test with next pattern

        memTestDone:
                // All memory tested successfully with all patterns!
                // Safe to proceed with visual initialization
                jmp mainLoop.memBankTestDone     // Continue to next test
                // CRITICAL: Using JMP not JSR - stack still not verified!

        memFailureFlash: {
                // Identify which RAM chip failed based on bit differences
                // Each data bit is handled by a specific RAM chip:
                // Bit 0 = U21 (Bank 8)  Bit 4 = U23 (Bank 4)
                // Bit 1 = U9  (Bank 7)  Bit 5 = U11 (Bank 3)
                // Bit 2 = U22 (Bank 6)  Bit 6 = U24 (Bank 2)
                // Bit 3 = U10 (Bank 5)  Bit 7 = U12 (Bank 1)
                
                // XOR actual vs expected to get difference bits
                // Result: 1 = bit differs, 0 = bit matches
                eor MemTestPattern,x    
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
}