#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"

        * = * "color ram test"


//=============================================================================
// COLOR RAM TEST
// Tests the 2114 static RAM chip that provides color memory from $D800-$DBFF
// 
// Purpose: Verify the integrity of the color RAM chip before visual output
// Method:  Non-destructive pattern-based verification of all color memory
//          locations using 4-bit test patterns designed for nibble-wide RAM
// 
// Hardware Details:
// - Color RAM is a separate 1K x 4 bit static RAM chip (2114)
// - Only the lower 4 bits (0-3) are connected - upper 4 bits read as garbage
// - Located at memory range $D800-$DBFF (1024 locations)
// - Each location stores one of 16 possible colors (0-15)
//
// Test Approach:
// - Save original color value before testing each location
// - Write and verify 12 different 4-bit patterns to detect all failure modes
// - Restore original value after testing to preserve screen appearance
// - Test patterns include boundary values, walking bits, and alternating bits
//
// Test Pattern Details (from colorRamPattern in data.asm):
// - $00 (0000): All bits off - detects stuck-at-1 failures
// - $05 (0101): Alternating bits - detects adjacent bit shorts
// - $0A (1010): Inverse alternating - detects opposite adjacency issues  
// - $0F (1111): All bits on - detects stuck-at-0 failures
// - $01,$02,$04,$08: Walking ones - isolates individual bit failures
// - $0E,$0D,$0B,$07: Walking zeros - detects bit-to-bit shorts
//
// On Failure: Display "BAD" and jump to failure handler
// On Success: Display "OK" and continue to next test
//=============================================================================
colorRamTest: {
                // Display "COLOR RAM" test label on screen
                ldx #$08
        !:      lda srtColor,x      // Print color ram test
                sta VIDEO_RAM+$c8,x
                dex
                bpl !-

                // Initialize pointer to start of color RAM at $D800
                // Color RAM occupies $D800-$DBFF (1024 bytes)
                ldx #<$d800
                ldy #>$d800
                stx ZP.tmpSourceAddressLow
                sty ZP.tmpSourceAddressHigh
                ldy #$00
        colorRamTestLoop:
                // Non-destructive test: save original color value
                ldy #$00
                lda (ZP.tmpSourceAddressLow),y
                pha                             // Preserve original color on stack
                
                // Test with all 12 patterns (0-11) designed for 4-bit RAM
                ldx #$0b                        // Start with pattern 11 (test in reverse)
        colorRamPattermTestLoop:
                // Write test pattern to current color RAM location
                lda colorRamPattern,x
                sta (ZP.tmpSourceAddressLow),y

                // Brief delay to ensure RAM has time to settle
                // Critical for detecting weak memory cells
                ShortDelayLoop(0)

                // Read back and mask to lower 4 bits
                // Upper 4 bits are not connected in the 2114 chip
                lda (ZP.tmpSourceAddressLow),y
                and #$0f                        // Mask off garbage in upper nibble
                
                // Verify the 4-bit value matches what we wrote
                cmp colorRamPattern,x
                bne colorRamTestFailed          // Jump if mismatch detected
                
                // Test next pattern
                dex
                bpl colorRamPattermTestLoop
                
                // All patterns passed - restore original color value
                pla
                sta (ZP.tmpSourceAddressLow),y
                // Move to next color RAM location
                inc ZP.tmpSourceAddressLow
                bne !+                          // Skip high byte increment if no overflow
                inc ZP.tmpSourceAddressHigh
                
                // Check if we've tested all color RAM ($D800-$DBFF)
        !:      lda ZP.tmpSourceAddressHigh
                cmp #$dc                        // Stop at $DC00 (tested through $DBFF)
                bne colorRamTestLoop            // Continue if more locations to test
                
                // All color RAM tested successfully - display "OK"
                lda #$0f                        // "O"
                sta VIDEO_RAM+$d5
                lda #$0b                        // "K"
                sta VIDEO_RAM+$d6
                rts

        colorRamTestFailed:
                // XOR failed value with expected pattern to identify bad bits
                // Result shows which of the 4 bits are faulty
                eor colorRamPattern,x
                tax                             // Save bit failure pattern
                
                // Display "BAD" error message
                lda #$02                        // "B"
                sta VIDEO_RAM+$d5
                lda #$01                        // "A"
                sta VIDEO_RAM+$d6
                lda #$04                        // "D"
                sta VIDEO_RAM+$d7
                
                // Jump to universal failure handler
                // X register contains the XOR result showing failed bits
                jmp UFailed
}