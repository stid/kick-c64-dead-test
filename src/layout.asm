#importonce
#import "./zeropage_map.asm"
#import "./mem_map.asm"
#import "./data.asm"
#import "./main_loop.asm"


        * = * "layout"

//=============================================================================
// DRAW LAYOUT
// Creates the initial test screen interface after memory bank verification
//
// Purpose: Display the test status interface with custom font and UI elements
// Method:  Copy custom font to character memory, initialize screen layout,
//          set up CIA timers for test operations
//
// Execution Order Rationale:
// - Runs AFTER memory bank test: We now know main RAM ($0100-$0FFF) works
// - Runs BEFORE zero page test: ZP is partially verified but not exhaustive
// - This ordering ensures we have working memory for screen display while
//   avoiding dependency on untested critical memory areas
//
// Constraints:
// - Cannot use stack operations (JSR/RTS/PHA/PLA) - stack page not tested
// - Limited to verified zero page locations for temporary storage
// - Must use JMP for flow control instead of subroutines
//=============================================================================
drawLayout: {
            //=========================================================================
            // CUSTOM FONT LOADING
            // Copies 512 bytes of custom character set to VIC-II character memory
            //
            // Why custom font:
            // - Ensures consistent display across all C64 ROM versions
            // - Provides clear, diagnostic-friendly character shapes
            // - Includes special box-drawing characters for UI elements
            //
            // Memory layout:
            // - Source: Custom font data embedded in program
            // - Destination: $0800 (2KB character RAM when VIC bank 0 selected)
            // - Size: 512 bytes (64 characters × 8 bytes per character)
            //=========================================================================
            lda #<font
            ldx #>font
            sta ZP.tmpSourceAddressLow         // Source Address
            stx ZP.tmpSourceAddressHigh
            lda #<$0800
            ldx #>$0800
            sta ZP.tmpDestAddressLow           // Dest Address
            stx ZP.tmpDestAddressHigh
            
            // Copy 2 pages (512 bytes) of font data
            // X register counts pages: 1, 0, then -1 (exit)
            ldx #$01
            ldy #$00
    fontCopyLoop:
            lda (ZP.tmpSourceAddressLow),y        // Load from source
            sta (ZP.tmpDestAddressLow),y          // Write to dest
            iny
            bne fontCopyLoop
            
            // Move to next page (256 bytes)
            inc ZP.tmpSourceAddressHigh
            inc ZP.tmpDestAddressHigh
            dex
            bpl fontCopyLoop                // Loop until X goes negative

            //=========================================================================
            // CIA TIMER INITIALIZATION
            // Resets both CIA chips' Timer B registers to known state
            //
            // Purpose:
            // - Ensures predictable timer behavior for upcoming tests
            // - Clears any residual timer values from warm reset
            // - Timer B will be used for precise delay loops in tests
            //
            // Hardware notes:
            // - CIA1 ($DC00): Keyboard, joysticks, timers
            // - CIA2 ($DD00): Serial port, user port, VIC bank switching
            // - Writing $00 to timer registers prevents unexpected interrupts
            //=========================================================================
            ldx #$04
    !:      lda cia1Table,x
            sta CIA1.TIMER_B_HIGH, x
            lda cia2Table,x
            sta CIA2.TIMER_B_HIGH, x
            dex
            bne !-

            // Reset test iteration counter for display
            // This tracks how many complete test passes have occurred
            ldx #$00
            stx ZP.counterLow
            stx ZP.counterHigh

            //=========================================================================
            // SCREEN INITIALIZATION
            // Clears screen and sets consistent color scheme
            //
            // Design choice: Dark blue background with light blue text
            // - High contrast for readability on all monitors
            // - Blue indicates "system operational" vs red for errors
            // - Space character ($20) clears previous display artifacts
            //=========================================================================
            ldx #$00
    clanScreenLoop:
            // Clear all 1000 screen positions with space character
            lda #$20
            sta VIDEO_RAM,x                 // $0400-$04FF
            sta VIDEO_RAM+$100,x           // $0500-$05FF
            sta VIDEO_RAM+$200,x           // $0600-$06FF
            sta VIDEO_RAM+$300,x           // $0700-$07E7

            // Set light blue color for entire screen
            lda #$06
            sta COLOR_VIDEO_RAM,x           // $D800-$D8FF
            sta COLOR_VIDEO_RAM+$100,x      // $D900-$D9FF
            sta COLOR_VIDEO_RAM+$200,x      // $DA00-$DAFF
            sta COLOR_VIDEO_RAM+$300,x      // $DB00-$DBE7
            inx
            bne clanScreenLoop

            //=========================================================================
            // UI ELEMENT DRAWING - UPPER BOX
            // Creates top border of main diagnostic display area
            //
            // Visual design:
            // +--------------------------------------+
            // |  RAM chip status and test progress   |
            //
            // Box placement: Row 14, spans full width (40 chars)
            // - Centered vertically for balanced layout
            // - Red border indicates critical diagnostic area
            // - Will contain RAM chip indicators (U9-U24)
            //=========================================================================
            ldx #$27                        // 40 characters - 1
    !:      lda upBox,x                     // Load box border characters
            sta VIDEO_RAM+$230,x            // Row 14 ($0400 + 14*40 = $0630)
            lda #BOX_BORDER_COLOR           // Red color for emphasis
            sta COLOR_VIDEO_RAM+$230,x
            dex
            bpl !-

            //=========================================================================
            // BOX CONTENT AREA
            // Fills the diagnostic box with chip position indicators
            //
            // The box will show:
            // - RAM chip positions (U21, U9, U22, U10, U23, U11, U24, U12)
            // - Each position corresponds to a data bit (0-7)
            // - Failed chips will be highlighted during memory tests
            //=========================================================================
            ldx #$00
    !:      lda boxArea,x
            cmp #$ff                        // $FF marks end of content data
            beq boxFill
            sta VIDEO_RAM+$258,x            // Inside upper box area
            inx
            jmp !-

            // Apply colors to box content
            // Different colors indicate chip status during tests
    boxFill:
            ldx #$00
    !:      lda boxColor,x
            cmp #$ff                        // $FF marks end of color data
            beq drawLowerBox
            sta COLOR_VIDEO_RAM+$258,x
            inx
            jmp !-

            //=========================================================================
            // UI ELEMENT DRAWING - LOWER BOX
            // Creates bottom border of diagnostic display area
            //
            // Completes the visual frame:
            // |  RAM chip status and test progress   |
            // +--------------------------------------+
            //=========================================================================
    drawLowerBox:
            ldx #$27
    !:      lda lowBox,x
            sta VIDEO_RAM+$0348,x           // Row 21
            lda #BOX_BORDER_COLOR           // Matching red border
            sta COLOR_VIDEO_RAM+$0348,x
            dex
            bpl !-

            //=========================================================================
            // CIA TIMER CONFIGURATION
            // Sets up Timer A and Timer B for test timing operations
            //
            // Timer A configuration ($48):
            // - Bit 0: Start timer
            // - Bit 3: One-shot mode (stop after timeout)
            // - Bit 6: Pulse output on PB6
            //
            // Timer B configuration ($08):
            // - Bit 3: One-shot mode
            // - Used for delay loops in memory tests
            //
            // These timers provide microsecond-accurate delays essential for
            // detecting timing-sensitive memory failures
            //=========================================================================
            lda #$08
            sta CIA1.CONTROL_TIMER_B
            sta CIA2.CONTROL_TIMER_B
            lda #$48
            sta CIA1.CONTROL_TIMER_A
            lda #$08
            sta CIA2.CONTROL_TIMER_A

            //=========================================================================
            // COLOR REFERENCE BAR
            // Diagnostic color gradient bar at bottom of screen
            //
            // Purpose:
            // - Verifies color RAM is functioning (shows all 16 colors)
            // - Helps diagnose color output issues (bad VIC-II or RAM)
            // - Provides visual reference for monitor adjustment
            //
            // Technical implementation:
            // - Each screen position gets its X coordinate as color (0-39)
            // - Only colors 0-15 are valid, creating a repeating pattern
            // - Character $3A (':') provides consistent test pattern
            //
            // Diagnostic value:
            // - Missing colors indicate color RAM failures
            // - Incorrect colors suggest VIC-II problems
            // - Useful for adjusting monitor tint/saturation
            //=========================================================================
            ldx #39                         // Full screen width
      !:    txa                            // Use position as color value
            sta COLOR_VIDEO_RAM+$398, x     // Row 23 (bottom area)
            lda #$3a                        // ':' character for visibility
            sta VIDEO_RAM+$398, x
            dex
            bpl !-

            //=========================================================================
            // FLOW CONTROL
            // Cannot use JSR - stack page hasn't been tested yet!
            //
            // The stack ($0100-$01FF) is tested after this layout setup.
            // Using JSR here would push return address to potentially bad RAM,
            // causing unpredictable behavior if stack memory has failed bits.
            //
            // JMP ensures we continue execution without stack dependency.
            //=========================================================================
            jmp mainLoop.initVic            // Continue to VIC initialization
}