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

                // Test entire stack page with all patterns
                // Stack memory is just regular RAM at $0100-$01FF
                ldx #$13                        // Start with pattern 19
        stackPagePatternLoop:
                lda MemTestPattern,x            // Get test pattern
                ldy #$00                        // Start at $0100
        !:      sta STACK_MEM, y                // STACK_MEM = $0100
                iny                             // Next location
                bne !-                          // Fill all 256 bytes

                // Delay for memory stabilization
                // Same timing requirements as other RAM
                LongDelayLoop(0,0)

                // Verify stack memory matches pattern
                // Y = 0 from overflow after writing 256 bytes
                tax                             // Restore pattern index
                lda MemTestPattern,x            // Expected value
        !:      cmp STACK_MEM, y                // Compare with actual
                bne stackPageFailed             // Mismatch found
                iny
                bne !-                          // Check all 256 bytes
                
                dex                             // Previous pattern
                bpl stackPagePatternLoop        // Continue if more patterns
                // Stack test passed! This is a major milestone
                lda #$0f                        // 'O' in screen code
                sta VIDEO_RAM+$85
                lda #$0b                        // 'K' in screen code
                sta VIDEO_RAM+$86
                
                // LAST USE OF JMP INSTEAD OF JSR!
                // After this point, stack operations are safe
                jmp mainLoop.stackPageTestDone  // Continue to JSR-enabled tests

        stackPageFailed:
                // Stack test failed - system cannot use subroutines
                // Still identify which RAM chip failed
                eor MemTestPattern,x            // XOR to find differing bits
                tax                             // Save for chip identification
                
                // Display "BAD" result
                lda #$02                        // 'B' in screen code
                sta VIDEO_RAM+$85
                lda #$01                        // 'A' in screen code
                sta VIDEO_RAM+$86
                lda #$04                        // 'D' in screen code
                sta VIDEO_RAM+$87
                
                // Halt system - cannot proceed without stack
                jmp UFailed
}