#importonce
#import "./zeropage_map.asm"
#import "./mem_bank_test.asm"


        * = * "main loop"

//=============================================================================
// MAIN TEST LOOP - Orchestrates All Diagnostic Tests
// Entry point from hardware vectors at $FFFA-$FFFF
//
// Test Sequence (Critical Order):
// 1. Memory bank test (black screen, no stack)
// 2. Layout drawing (after basic RAM verified)
// 3. Zero page test (no stack)
// 4. Stack page test (no stack)
// 5. All remaining tests (stack available)
//
// The transition from JMP to JSR happens after stack test passes
//=============================================================================

mainLoop: {
                // Initialize system to known state
                sei                             // Disable interrupts - we handle everything
                ldx #$ff
                txs                             // Stack pointer = $01FF (top of stack)
                cld                             // Clear decimal mode (binary arithmetic)
                
                // Configure 6510 processor port for proper memory mapping
                // This ensures we see RAM at $A000-$BFFF and $E000-$FFFF
                lda #$e7                        // %11100111
                sta ZP.ProcessPortBit           // Bits: LORAM=1, HIRAM=1, CHAREN=1
                lda #$37                        // %00110111
                sta ZP.ProcessDataDir           // DDR: Motor=out, others as needed

                // Black screen during memory test
                // Prevents confusing garbage display if RAM is bad
                lda #$00                        // Black
                sta VIC2.BORDERCOLOUR           
                sta VIC2.BGCOLOUR               

                // CRITICAL: First test - no stack operations allowed!
                jmp memBankTest                 // Test RAM with black screen

        memBankTestDone:
                // RAM test passed! Basic memory is functional
                // Now safe to draw screen layout (uses RAM)
                // Still no stack operations - zero page and stack not tested
                jmp     drawLayout              // Draw test interface

        initVic:
                ldx #$2f                        // Init VIC values
        !:      lda vicDefaultValues-1, x
                sta $cfff, x
                dex
                bne !-

                // Cycle border color based on actual counter
                ldx ZP.counterLow
                inx
                inx                     // Start with Color border
                stx VIC2.BORDERCOLOUR

                // About string
                ldx #$1c
        !:      lda strAbout,x
                sta VIDEO_RAM+$6,x
                dex
                bpl !-
                ldx #$04

                // Test Count
        !:      lda strCount,x                  // Print Count Label
                sta VIDEO_RAM+$03c0,x
                dex
                bpl !-

                // Print Count
                lda ZP.counterLow
                and #$0f
                ora #$30
                sta VIDEO_RAM+$03c9
                lda ZP.counterLow
                lsr
                lsr
                lsr
                lsr
                and #$0f
                ora #$30
                sta VIDEO_RAM+$03c8
                lda ZP.counterHigh
                and #$0f
                ora #$30
                sta VIDEO_RAM+$03c7
                lda ZP.counterHigh
                lsr
                lsr
                lsr
                lsr
                and #$0f
                ora #$30
                sta VIDEO_RAM+$03c6

                // Restore normal memory configuration
                lda #$37
                sta ZP.ProcessPortBit

                // Continue with critical tests - still no stack!
                jmp zeroPageTest        

        zeroPageTestDone:
                // Zero page works, but still can't use stack
                jmp stackPageTest       

        stackPageTestDone:
                //=========================================================
                // CRITICAL MILESTONE: Stack test passed!
                // From this point forward we can use:
                // - JSR/RTS for subroutines
                // - PHA/PLA for register preservation
                // - PHP/PLP for status preservation
                // - Interrupt handlers (if we enabled them)
                //=========================================================

                // First subroutine call in the entire program!
                jsr updateCia1Time      // Update timer display
                // Run remaining tests with full subroutine support
                jsr lowRamTest          // Test $0200-$03FF (previously untested)
                jsr updateCia1Time

                jsr screenRamTest       // Test video RAM
                jsr updateCia1Time      
                
                jsr colorRamTest        // Test color RAM (separate chip)
                jsr updateCia1Time
                
                jsr ramTest             // Extended RAM test
                jsr updateCia1Time
                
                jsr fontTest            // Verify character ROM access
                jsr updateCia1Time
                
                jsr soundTest           // Test SID oscillators
                jsr updateCia1Time
                
                jsr filterTest          // Test SID filters (your addition)

                // All tests complete - prepare for next iteration
                // Increment test counter in BCD mode for easy display
                sed                     // Set decimal mode
                lda #$01
                clc
                adc ZP.counterLow       // Add 1 to low byte
                sta ZP.counterLow
                lda #$00
                adc ZP.counterHigh      // Add carry to high byte
                sta ZP.counterHigh
                cld                     // Clear decimal mode
                lda #$e7
                sta ZP.ProcessPortBit
                lda #$37
                sta ZP.ProcessDataDir

                //  VOLUME OFF
                lda #$00
                sta SID.FILTER_VOL

                //  Clear view
                ldx #$00
                lda #$20
        !:      sta VIDEO_RAM,x
                sta VIDEO_RAM+$100,x
                inx
                bne !-
                ldx #$2e
                lda #$20
        !:      sta VIDEO_RAM+$200,x
                dex
                bpl !-

                jmp mainLoop.initVic
}

#import "./layout.asm"
#import "./mem_bank_test.asm"
#import "./zero_page_test.asm"
#import "./stack_page_test.asm"
#import "./cia_timers.asm"
#import "./low_ram_test.asm"
#import "./screen_ram_test.asm"
#import "./color_ram_test.asm"
#import "./ram_test.asm"
#import "./font_test.asm"
#import "./sound_test.asm"
#import "./filters_test.asm"