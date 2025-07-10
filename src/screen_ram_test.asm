#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./u_failure.asm"
#import "./mem_map.asm"


        * = * "screen ram test"

//=============================================================================
// SCREEN RAM TEST - Video Display Memory
// Tests memory locations $0400-$07FF (1KB)
//
// Purpose: Verify screen memory which holds character codes for display
//          40 columns × 25 rows = 1000 bytes used for visible screen
//          Extra 24 bytes available for other purposes
//
// Method:  Non-destructive testing - saves and restores screen content
//          This keeps the display readable during testing
//
// Note:    Screen RAM is regular dynamic RAM, same chips as main memory
//          But it's accessed by both CPU and VIC-II (video chip)
//=============================================================================
screenRamTest: {
                // Display "screen ram" label
                ldx #$09
        !:      lda strScreen,x      
                sta VIDEO_RAM+$a0,x     // Row 4, column 0
                dex
                bpl !-

                // Initialize pointer to screen RAM start
                ldx #<VIDEO_RAM                 // $00
                ldy #>VIDEO_RAM                 // $04
                stx ZP.tmpSourceAddressLow
                sty ZP.tmpSourceAddressHigh
                
        screenRamTestLoop:
                // Test one screen location at a time
                ldy #$00
                lda (ZP.tmpSourceAddressLow),y  // Save current screen character
                pha                             // Preserve on stack (now safe to use!)
                
                ldx #$13                        // Start with pattern 19
        screenRamPatternTestLoop:
                // Write test pattern to current screen location
                lda MemTestPattern,x
                sta (ZP.tmpSourceAddressLow),y

                // Brief delay - screen RAM needs less time than main RAM
                // VIC-II also accesses this memory during display
                ShortDelayLoop(0)

                // Verify pattern was stored correctly
                lda (ZP.tmpSourceAddressLow),y
                cmp MemTestPattern,x
                bne screenRamTestFailed
                
                dex                             // Next pattern
                bpl screenRamPatternTestLoop
                
                // All patterns passed - restore original character
                pla
                sta (ZP.tmpSourceAddressLow),y
                // Move to next screen location
                inc ZP.tmpSourceAddressLow
                bne !+
                inc ZP.tmpSourceAddressHigh     // Crossed page boundary

        !:      // Check if we've tested all screen RAM
                lda ZP.tmpSourceAddressHigh
                cmp #$08                        // Stop at $0800
                bne screenRamTestLoop           // Continue if more to test
                // Screen RAM test passed
                lda #$0f                        // 'O'
                sta VIDEO_RAM+$ad
                lda #$0b                        // 'K'
                sta VIDEO_RAM+$ae
                rts                             // Return to main loop

        screenRamTestFailed:
                // Screen RAM failed - identify which data bit/chip
                eor MemTestPattern,x            // Find differing bits
                tax                             // Save for chip identification
                
                // Display "BAD"
                lda #$02                        // 'B'
                sta VIDEO_RAM+$ad
                lda #$01                        // 'A'
                sta VIDEO_RAM+$ae
                lda #$04                        // 'D'
                sta VIDEO_RAM+$af
                
                // Identify failed chip and halt
                jsr UFailed
}
