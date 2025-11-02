#importonce
#import "./data.asm"
#import "./mem_map.asm"
#import "./macros.asm"
#import "./zeropage_map.asm"

        * = * "low ram test"


//=============================================================================
// LOW RAM TEST - Tests Previously Untested $0200-$03FF Region
// Tests the 512 bytes between stack page and screen RAM
//
// Purpose: Complete RAM coverage of all Ultimax-accessible memory
//          Using superior test patterns to detect address bus issues
//
// Memory Range: $0200-$03FF (512 bytes)
// - This region was previously skipped by other tests
// - Essential for completeness in diagnostic cartridge
// - Used by BASIC and Kernal for various purposes
//
// Test Pattern Philosophy (suggested by Sven):
// 1. $AA pattern: Detects even-bit stuck failures
// 2. $55 pattern: Detects odd-bit stuck failures
// 3. PRN sequence (247 bytes): Detects address bus problems and page confusion
//
// Why 247-byte PRN sequence?
// - Prime-like odd length ensures pattern "drifts" relative to page boundaries
// - After 247 bytes, pattern repeats but at different offset
// - Catches mirrored or confused address lines that 256-aligned tests miss
// - If pages are swapped or address lines crossed, PRN will be out of phase
//
// Method: For entire memory range:
//          1. Write $AA to all locations, then verify
//          2. Write $55 to all locations, then verify
//          3. Write 247-byte PRN sequence repeatedly, then verify
//          4. Any mismatch indicates RAM or address bus failure
//
// On Success: Displays "OK" on screen
// On Failure: Displays "BAD" with failing address information
//=============================================================================
lowRamTest: {
                // Display "LOW RAM" label on screen
                // This appears at position $00A0 in video RAM (row 4)
                ldx #$06
        !:      lda strLowRam,x
                sta VIDEO_RAM+$a0,x
                dex
                bpl !-

                //=====================================================
                // TEST PHASE 1: $AA Pattern (10101010)
                // Tests all even bit positions
                //=====================================================

                // Write $AA to entire region
                lda #$aa
                ldx #$00
        writeAALoop:
                sta $0200,x
                sta $0300,x
                inx
                bne writeAALoop

                // Add delay for memory settling
                ShortDelayLoop($3f)

                // Verify $AA pattern
                lda #$aa
                ldx #$00
        verifyAALoop:
                cmp $0200,x
                bne !fail+
                cmp $0300,x
                bne !fail+
                inx
                bne verifyAALoop
                jmp !next+
        !fail:
                jmp testFailed
        !next:

                //=====================================================
                // TEST PHASE 2: $55 Pattern (01010101)
                // Tests all odd bit positions
                //=====================================================

                // Write $55 to entire region
                lda #$55
                ldx #$00
        write55Loop:
                sta $0200,x
                sta $0300,x
                inx
                bne write55Loop

                // Add delay for memory settling
                ShortDelayLoop($3f)

                // Verify $55 pattern
                lda #$55
                ldx #$00
        verify55Loop:
                cmp $0200,x
                bne !fail+
                cmp $0300,x
                bne !fail+
                inx
                bne verify55Loop
                jmp !next+
        !fail:
                jmp testFailed
        !next:

                //=====================================================
                // TEST PHASE 3: PRN Sequence (247-byte pattern)
                // Detects address bus and page confusion issues
                //=====================================================

                // Initialize address pointer to start of test region
                lda #<$0200
                sta ZP.tmpDestAddressLow
                lda #>$0200
                sta ZP.tmpDestAddressHigh

                // Initialize PRN pattern index
                ldx #$00

                // Write PRN sequence byte-by-byte to entire 512-byte region
                // Pattern repeats every 247 bytes, ensuring non-alignment
        writePRNLoop:
                lda PrnTestPattern,x            // Get pattern byte
                ldy #$00
                sta (ZP.tmpDestAddressLow),y    // Write to current address

                // Advance PRN pattern index (wraps at 247)
                inx
                cpx #247
                bne !+
                ldx #$00                        // Wrap to start of pattern

        !:      // Increment address pointer
                inc ZP.tmpDestAddressLow
                bne !+
                inc ZP.tmpDestAddressHigh

        !:      // Check if we've reached $0400 (screen RAM)
                lda ZP.tmpDestAddressHigh
                cmp #>$0400
                bne writePRNLoop                // Continue if not at $04xx
                lda ZP.tmpDestAddressLow
                cmp #<$0400
                bne writePRNLoop                // Continue if not at $0400

        writePRNDone:
                // Add delay for memory settling
                ShortDelayLoop($7f)

                // Verify PRN sequence
                // Reset address pointer
                lda #<$0200
                sta ZP.tmpDestAddressLow
                lda #>$0200
                sta ZP.tmpDestAddressHigh

                // Reset PRN pattern index
                ldx #$00

                // Verify PRN sequence byte-by-byte
        verifyPRNLoop:
                lda PrnTestPattern,x            // Get expected pattern byte
                ldy #$00
                cmp (ZP.tmpDestAddressLow),y    // Compare with memory
                bne !fail+                      // Mismatch = failure

                // Advance PRN pattern index (wraps at 247)
                inx
                cpx #247
                bne !+
                ldx #$00                        // Wrap to start of pattern

        !:      // Increment address pointer
                inc ZP.tmpDestAddressLow
                bne !+
                inc ZP.tmpDestAddressHigh

        !:      // Check if we've reached $0400 (screen RAM)
                lda ZP.tmpDestAddressHigh
                cmp #>$0400
                bne verifyPRNLoop               // Continue if not at $04xx
                lda ZP.tmpDestAddressLow
                cmp #<$0400
                bne verifyPRNLoop               // Continue if not at $0400
                jmp allTestsPassed

        !fail:
                jmp testFailed

        allTestsPassed:
                // All patterns passed!
                // Display "OK" at screen positions $00AD-$00AE (row 4, +13 offset)
                lda #$0f                        // Screen code for "O"
                sta VIDEO_RAM+$ad
                lda #$0b                        // Screen code for "K"
                sta VIDEO_RAM+$ae
                rts

        testFailed:
                // TEST FAILED - Memory corruption or address bus issue detected
                // Display "BAD" error message at screen positions $00AD-$00AF
                lda #$02                        // Screen code for "B"
                sta VIDEO_RAM+$ad
                lda #$01                        // Screen code for "A"
                sta VIDEO_RAM+$ae
                lda #$04                        // Screen code for "D"
                sta VIDEO_RAM+$af

                // Could add failing address display here if desired
                // The pointer values indicate where failure occurred
                rts
}
