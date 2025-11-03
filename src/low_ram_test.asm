#importonce
#import "./data.asm"
#import "./mem_map.asm"
#import "./macros.asm"
#import "./zeropage_map.asm"
#import "./u_failure.asm"

//=============================================================================
// TEST MODE CONFIGURATION
// Enable this to simulate a RAM failure for validation testing
// When enabled, simulates a bit 0 (U21 chip) failure in the $AA pattern test
//
// Usage: Build with 'make test-mode' (passes -define TEST_MODE_ENABLED from command line)
//=============================================================================
// Note: TEST_MODE_ENABLED is defined via -define flag when building test mode

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
// Test Pattern Philosophy (suggested by Sven Petersen - https://github.com/svenpetersen1965):
// 1. $AA pattern (10101010): Detects stuck-low bits on odd positions
// 2. $55 pattern (01010101): Detects stuck-high bits on even positions
// 3. 247-byte PRN sequence: Detects address bus problems and page confusion
// 4. Walking ones/zeros (16 patterns): Identifies specific failing chips
//
// Why 247-byte PRN sequence?
// - Prime-like odd length ensures pattern "drifts" relative to page boundaries
// - After 247 bytes, pattern repeats but at different offset
// - Catches mirrored or confused address lines that 256-aligned tests miss
// - If pages are swapped or address lines crossed, PRN will be out of phase
//
// Method: For entire memory range ($0200-$03FF):
//          1. Write $AA to all locations, then verify
//          2. Write $55 to all locations, then verify
//          3. Write 247-byte PRN sequence repeatedly, then verify
//          4. Write each of 16 walking bit patterns, then verify
//          5. Any mismatch indicates RAM or address bus failure
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
                ldx #$00
        verifyAALoop:
                lda $0200,x                     // Read actual value
#if TEST_MODE_ENABLED
                // TEST MODE: Simulate bit 0 (U21 chip) failure
                eor #$01                        // Flip bit 0 to simulate failure
#endif
                cmp #$aa                        // Compare with expected
                bne !fail+                      // If mismatch, identify chip
                lda $0300,x                     // Read actual value from page 3
#if TEST_MODE_ENABLED
                // TEST MODE: Simulate bit 0 (U21 chip) failure
                eor #$01                        // Flip bit 0 to simulate failure
#endif
                cmp #$aa                        // Compare with expected
                bne !fail+                      // If mismatch, identify chip
                inx
                bne verifyAALoop
                jmp !next+
        !fail:
                jmp testFailed_AA
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
                ldx #$00
        verify55Loop:
                lda $0200,x                     // Read actual value
                cmp #$55                        // Compare with expected
                bne !fail+                      // If mismatch, identify chip
                lda $0300,x                     // Read actual value from page 3
                cmp #$55                        // Compare with expected
                bne !fail+                      // If mismatch, identify chip
                inx
                bne verify55Loop
                jmp !next+
        !fail:
                jmp testFailed_55
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
                ldy #$00
                lda (ZP.tmpDestAddressLow),y    // Read actual value from memory
                cmp PrnTestPattern,x            // Compare with expected pattern
                bne !fail+                      // Branch to nearby intermediate label

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
                bne !+
                lda ZP.tmpDestAddressLow
                cmp #<$0400
                bne !+
                jmp walkingBitsPhase
        !:      jmp verifyPRNLoop

        !fail:  jmp testFailed_PRN              // Intermediate label for branch distance

                //=====================================================
                // TEST PHASE 4: Walking Bits (16 patterns)
                // Tests individual bit positions for chip identification
                //=====================================================
        walkingBitsPhase:
                ldx #$04                        // Start with walking ones
        walkingBitsLoop:
                lda MemTestPattern,x
                ldy #$00
        writeWalkingLoop:
                sta $0200,y
                sta $0300,y
                iny
                bne writeWalkingLoop

                ShortDelayLoop($3f)

                lda MemTestPattern,x
                ldy #$00
        verifyWalkingLoop:
                cmp $0200,y
                bne !fail+
                cmp $0300,y
                bne !fail+
                iny
                bne verifyWalkingLoop
                jmp !next+
        !fail:  jmp testFailed_Walking
        !next:

                inx
                cpx #$14                        // Test through index 19
                bne walkingBitsLoop

        allTestsPassed:
                // All patterns passed!
                // Display "OK" at screen positions $00AD-$00AE (row 4, +13 offset)
                lda #$0f                        // Screen code for "O"
                sta VIDEO_RAM+$ad
                lda #$0b                        // Screen code for "K"
                sta VIDEO_RAM+$ae
                rts

        //=====================================================
        // FAILURE HANDLERS - Identify failing chip(s)
        //=====================================================

        testFailed_AA:
                // $AA pattern test failed - stuck bit
                eor #$aa                        // XOR with expected to find bad bits
                tax                             // Move to X for UFailed
                // Display "BIT" - stuck bit failure
                lda #$02                        // Screen code for "B"
                sta VIDEO_RAM+$ad
                lda #$09                        // Screen code for "I"
                sta VIDEO_RAM+$ae
                lda #$14                        // Screen code for "T"
                sta VIDEO_RAM+$af
                jsr UFailed                     // Show which bits failed

        testFailed_55:
                // $55 pattern test failed - stuck bit
                eor #$55                        // XOR with expected to find bad bits
                tax                             // Move to X for UFailed
                // Display "BIT" - stuck bit failure
                lda #$02                        // Screen code for "B"
                sta VIDEO_RAM+$ad
                lda #$09                        // Screen code for "I"
                sta VIDEO_RAM+$ae
                lda #$14                        // Screen code for "T"
                sta VIDEO_RAM+$af
                jsr UFailed                     // Show which bits failed

        testFailed_PRN:
                // PRN sequence test failed - address bus issue
                // Display "BUS" - address bus failure
                lda #$02                        // Screen code for "B"
                sta VIDEO_RAM+$ad
                lda #$15                        // Screen code for "U"
                sta VIDEO_RAM+$ae
                lda #$13                        // Screen code for "S"
                sta VIDEO_RAM+$af
                // Don't call UFailed - this is not a chip failure
                jmp UFailed.deadLoop                    // Halt (address bus issue)

        testFailed_Walking:
                // Walking bits test failed - specific chip failure
                eor MemTestPattern,x            // XOR with expected to find bad bits
                tax                             // Move to X for UFailed
                // Display "BAD" - specific chip failure
                lda #$02                        // Screen code for "B"
                sta VIDEO_RAM+$ad
                lda #$01                        // Screen code for "A"
                sta VIDEO_RAM+$ae
                lda #$04                        // Screen code for "D"
                sta VIDEO_RAM+$af
                jsr UFailed                     // Show which chip failed
}
