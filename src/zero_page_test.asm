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
// CRITICAL CONSTRAINTS:
// - NO STACK OPERATIONS - Stack at $0100-$01FF not verified yet
// - Must preserve locations $00-$11 (our test variables)
// - Still cannot use JSR/RTS, only JMP for flow control
//
// Test Range: $12-$FF (preserving $00-$11 for test variables)
//=============================================================================
zeroPageTest: {
                // Display "zero page" label on screen
                // Can now use screen RAM - it passed the memory bank test
                ldx #$08
        !:      lda strZero,x   
                sta VIDEO_RAM+$50,x     // Row 2, column 16
                dex
                bpl !-

                // Test zero page with same comprehensive patterns
                // Start at location $12 to preserve test variables
                ldx #$13                        // Start with pattern 19 (counting down)
        zeroPagePatternLoop:
                lda MemTestPattern,x            // Get test pattern
                ldy #$12                        // Start at $12, preserve $00-$11
        !:      sta $0000,y                     // Write pattern to zero page
                iny                             // Next location
                bne !-                          // Continue through $FF

                // Delay for memory cell stabilization
                // Zero page uses same dynamic RAM as main memory
                LongDelayLoop(0,0)

                // Verify pattern matches what was written
                lda MemTestPattern,x            // Expected value
                ldy #$12                        // Start at $12 again
        !:      cmp $0000,y                     // Compare with actual
                bne zeroPagePatternFailed       // Mismatch found
                iny
                bne !-                          // Test through $FF
                
                // Pattern verified, try next
                dex                             // Previous pattern
                bpl zeroPagePatternLoop         // Continue if more patterns

                // Zero Page Pattern Test OK
                // Display "OK" result
                lda #$0f                        // 'O' in screen code
                sta VIDEO_RAM+$5d
                lda #$0b                        // 'K' in screen code
                sta VIDEO_RAM+$5e
                
                // CRITICAL: Use JMP not JSR - stack still not tested!
                jmp mainLoop.zeroPageTestDone

                // Zero Page Test Failed
                // Even though zero page failed, we can still identify which chip
                // because the failure detection logic uses registers only
        zeroPagePatternFailed:
                eor MemTestPattern,x            // XOR to find differing bits
                tax                             // Save for chip identification
                
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
