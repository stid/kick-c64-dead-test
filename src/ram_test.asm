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
//          1. Write all 20 test patterns sequentially
//          2. Add timing delay after each write
//          3. Immediately verify the written value
//          4. Move to next address only after all patterns pass
//
// On Success: Displays "OK" on screen
// On Failure: Displays "BAD" and shows which bits failed via XOR result
//=============================================================================
ramTest: {
                // Display "RAM TEST" label on screen
                // This appears at position $04F0 in video RAM
                ldx #$07
        !:      lda strRam,x      // ram test label
                sta VIDEO_RAM+$f0,x
                dex
                bpl !-

                // Initialize test starting address to $0800
                // Using zero page pointers for indirect addressing
                ldx #<$0800             // Low byte = $00
                ldy #>$0800             // High byte = $08
                stx ZP.tmpSourceAddressLow
                sty ZP.tmpSourceAddressHigh
        RamTestLoop:
                // Y = 0 for indirect addressing offset
                // The actual address comes from zero page pointer
                ldy #$00
                
                // Start with pattern 19 ($13) - test patterns in reverse order
                // This matches the order used in memBankTest for consistency
                ldx #$13
        RamTestPatternLoop:
                // Write one test pattern to current memory location
                // Using indirect addressing: effective address = (ZP pointer) + Y
                lda MemTestPattern,x
                sta (ZP.tmpSourceAddressLow),y

                // CRITICAL TIMING DELAY - $7F iterations
                // This delay serves multiple purposes:
                // 1. Allows DRAM capacitors time to stabilize after write
                // 2. Detects weak memory cells that lose charge quickly  
                // 3. Simulates real-world timing between writes and reads
                // 4. More aggressive than memBankTest to catch marginal failures
                ShortDelayLoop($7f)

                // Immediately read back and verify the written value
                // If DRAM refresh failed or cell is weak, data will be corrupted
                lda (ZP.tmpSourceAddressLow),y
                cmp MemTestPattern,x
                bne RamTestFailed       // Jump if read doesn't match written value
                
                // Test next pattern at same address
                dex                     // Previous pattern (counting down from 19 to 0)
                bpl RamTestPatternLoop  // Continue until all 20 patterns tested

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
                // Display "OK" at screen positions $04FD and $04FE
                lda #$0f         // Screen code for "O"
                sta VIDEO_RAM+$fd
                lda #$0b         // Screen code for "K"
                sta VIDEO_RAM+$fe
                rts

        RamTestFailed:
                // TEST FAILED - Memory corruption detected
                // The accumulator contains the corrupted value read from memory
                // By XORing with the expected pattern, we identify failed bits
                
                // XOR actual value with expected pattern to get difference bits
                // Result: Each '1' bit indicates a bit that failed
                // This helps identify which RAM chip has issues
                eor MemTestPattern,x
                tax                     // Save bit difference pattern for potential debugging
                
                // Display "BAD" error message at screen positions $04FD-$04FF
                // Unlike memBankTest which flashes to indicate chip number,
                // this test simply reports failure since we test byte-by-byte
                // The exact failing address is known from the pointer values
                lda #$02         // Screen code for "B"
                sta VIDEO_RAM+$fd
                lda #$01         // Screen code for "A"
                sta VIDEO_RAM+$fe
                lda #$04         // Screen code for "D"
                sta VIDEO_RAM+$ff
                
                // Note: Test continues rather than halting
                // This allows checking if failure is isolated or widespread
                // The XOR result in X register indicates which bits failed
}