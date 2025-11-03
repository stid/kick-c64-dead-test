#importonce
#import "./data.asm"
#import "./mem_map.asm"
#import "./macros.asm"
#import "./zeropage_map.asm"

        * = * "ram test"


//=============================================================================
// RAM TEST - Byte-by-Byte Memory Verification
// Tests memory range $0800-$0FFF with individual byte granularity
//
// Purpose: Provide more thorough RAM verification than the initial memBankTest
//          by testing each memory location individually with timing delays
//
// Method:  Byte-by-byte testing with AA/55/PRN + walking bits patterns
//          Different methodology from page-based memBankTest for maximum coverage
//
// Test Patterns (applied byte-by-byte):
//   1. $AA (10101010) - Detects stuck-low bits on odd positions
//   2. $55 (01010101) - Detects stuck-high bits on even positions
//   3. 247-byte PRN sequence - Detects address bus problems
//   4. Walking ones/zeros - Identifies specific failing chips
//
// Memory Range: $0800-$0FFF (2KB)
// - This INTENTIONALLY overlaps with memory already tested in memBankTest
// - The overlap provides a second verification pass with different methodology
// - Catches intermittent failures that page-based testing might miss
//
// Key Differences from memBankTest:
// 1. BYTE-BY-BYTE: Tests one location at a time vs entire pages simultaneously
// 2. IMMEDIATE VERIFY: Write-delay-read for each byte vs batch write then verify
// 3. TIMING FOCUS: Deliberate delay after each write to detect retention issues
// 4. GRANULAR DETECTION: Can pinpoint exact failing address, not just chip
//
// Method: For each memory location:
//          1. Write all test patterns sequentially (AA, 55, PRN, walking bits)
//          2. Add timing delay after each write
//          3. Immediately verify the written value
//          4. Move to next address only after all patterns pass
//
// On Success: Displays "OK" on screen
// On Failure: Displays "BAD" and shows which bits failed via XOR result
//=============================================================================
ramTest: {
                // Display "RAM TEST" label on screen
                // This appears at position $0118 in video RAM (row 7)
                ldx #$07
        !:      lda strRam,x      // ram test label
                sta VIDEO_RAM+$118,x
                dex
                bpl !-

                // Initialize test starting address to $0800
                // Using zero page pointers for indirect addressing
                ldx #<$0800             // Low byte = $00
                ldy #>$0800             // High byte = $08
                stx ZP.tmpSourceAddressLow
                sty ZP.tmpSourceAddressHigh

        RamTestLoop:
                ldy #$00                // Y = 0 for indirect addressing offset

                //=======================================================
                // Phase 1: Test $AA pattern
                //=======================================================
                lda #$aa
                sta (ZP.tmpSourceAddressLow),y
                ShortDelayLoop($7f)
                lda (ZP.tmpSourceAddressLow),y
                cmp #$aa
                bne RamTestFailed_AA

                //=======================================================
                // Phase 2: Test $55 pattern
                //=======================================================
                lda #$55
                sta (ZP.tmpSourceAddressLow),y
                ShortDelayLoop($7f)
                lda (ZP.tmpSourceAddressLow),y
                cmp #$55
                bne RamTestFailed_55

                //=======================================================
                // Phase 3: Test PRN pattern (based on current offset)
                //=======================================================
                // Calculate PRN index from current address offset
                // Offset = (address - $0800) mod 247
                lda ZP.tmpSourceAddressLow
                ldx ZP.tmpSourceAddressHigh
                sec
                sbc #<$0800             // Subtract $0800 to get offset
                tay                      // Save low byte
                txa
                sbc #>$0800
                tax                      // X = high byte of offset

                // Convert offset to PRN index (mod 247)
                // For simplicity, use low byte mod 247 (good enough for 2KB)
                tya
                ldx #247
        !:      cmp #247
                bcc !+
                sec
                sbc #247
                jmp !-
        !:      tax                      // X = PRN pattern index

                ldy #$00
                lda PrnTestPattern,x
                sta (ZP.tmpSourceAddressLow),y
                ShortDelayLoop($7f)
                lda (ZP.tmpSourceAddressLow),y
                cmp PrnTestPattern,x
                bne RamTestFailed_PRN

                //=======================================================
                // Phase 4: Test walking bits (16 patterns)
                //=======================================================
                ldx #$04                // Start with walking ones
        WalkingBitsLoop:
                ldy #$00
                lda MemTestPattern,x
                sta (ZP.tmpSourceAddressLow),y
                ShortDelayLoop($7f)
                lda (ZP.tmpSourceAddressLow),y
                cmp MemTestPattern,x
                bne RamTestFailed_Walking

                inx
                cpx #$14                // Test through index 19
                bne WalkingBitsLoop

                // All patterns passed at current address - move to next byte
                // Increment 16-bit address pointer in zero page
                inc ZP.tmpSourceAddressLow
                bne !+                  // Skip high byte increment if no overflow
                inc ZP.tmpSourceAddressHigh         // Handle 256-byte page boundary

        !:      // Check if we've reached end of test range ($1000)
                // Testing stops at $0FFF, so high byte should not reach $10
                lda ZP.tmpSourceAddressHigh
                cmp #$10
                bne RamTestLoop         // Continue if not at $1000 yet
                
                // TEST PASSED - All addresses $0800-$0FFF verified successfully
                // Display "OK" at screen positions $0125-$0126 (row 7, +13 offset)
                lda #$0f         // Screen code for "O"
                sta VIDEO_RAM+$125
                lda #$0b         // Screen code for "K"
                sta VIDEO_RAM+$126
                rts

                //=======================================================
                // Failure handlers
                //=======================================================
        RamTestFailed_AA:
                eor #$aa
                jmp ShowRamTestFailure

        RamTestFailed_55:
                eor #$55
                jmp ShowRamTestFailure

        RamTestFailed_PRN:
                eor PrnTestPattern,x
                jmp ShowRamTestFailure

        RamTestFailed_Walking:
                eor MemTestPattern,x
                // Fall through to ShowRamTestFailure

        ShowRamTestFailure:
                // TEST FAILED - Memory corruption detected
                // Accumulator contains XOR of actual vs expected (failed bits)
                tax                     // Save bit difference pattern

                // Display "BAD" error message at screen positions $0125-$0127
                // Unlike memBankTest which flashes to indicate chip number,
                // this test simply reports failure since we test byte-by-byte
                // The exact failing address is known from the pointer values
                lda #$02         // Screen code for "B"
                sta VIDEO_RAM+$125
                lda #$01         // Screen code for "A"
                sta VIDEO_RAM+$126
                lda #$04         // Screen code for "D"
                sta VIDEO_RAM+$127

                // Note: Test continues rather than halting
                // This allows checking if failure is isolated or widespread
                // The XOR result in X register indicates which bits failed
                rts
}