#importonce
#import "./zeropage_map.asm"
#import "./mem_map.asm"
#import "./const.asm"

//=============================================================================
// RAM CHIP FAILURE VISUALIZATION MACRO
// Displays "BAD" text at specific screen positions for failed RAM chips
//
// Purpose: Provide visual indication of which RAM chip has failed
// Method:  Check specific bit in X register and display "BAD" if set
//
// Parameters:
// - id:       Bit mask for the specific chip (e.g., $01 for bit 0)
// - videoPos: Screen memory offset for displaying the failure message
//
// Register Usage:
// - X register: Contains XOR result from memory test (each bit = one chip)
// - A register: Used for character/color data (preserved via TXA)
//
// How it works:
// 1. The X register holds the XOR result from the memory test
// 2. Each bit position corresponds to a specific RAM chip
// 3. If a bit is set (1), that chip has failed the test
// 4. The macro displays "BAD" in red at the chip's screen position
//=============================================================================
.macro failCheck (id, videoPos) {
                // Save X register (contains failure bits) to A for testing
                txa
                
                // Check if this specific chip's bit is set
                // AND operation isolates the bit we're testing
                and #id
                
                // If bit is clear (chip OK), skip display
                beq !+
                
                // Display "BAD" at the chip's position on screen
                // Using PETSCII screen codes: B=02, A=01, D=04
                lda #$02         // "B" character
                sta VIDEO_RAM+videoPos
                lda #$01         // "A" character
                sta VIDEO_RAM+videoPos+1
                lda #$04         // "D" character
                sta VIDEO_RAM+videoPos+2
                
                // Set all three characters to red to highlight the failure
                lda #FAIL_COLOR   // Red color (typically $02)
                sta COLOR_VIDEO_RAM+videoPos
                sta COLOR_VIDEO_RAM+videoPos+1
                sta COLOR_VIDEO_RAM+videoPos+2
        !:      // Exit label - continue to next check
}

//=============================================================================
// RAM CHIP TO BIT MAPPING
// Maps each physical RAM chip to its corresponding bit in test results
//
// C64 Memory Architecture:
// - Main RAM uses 8 x 4164 (64K x 1 bit) DRAM chips
// - Each chip provides one bit of the 8-bit data bus
// - Chip failures manifest as specific bit errors
//
// Bit Assignment:
// - Bit 0 (LSB): U21 - Provides data bit 0
// - Bit 1:       U9  - Provides data bit 1
// - Bit 2:       U22 - Provides data bit 2
// - Bit 3:       U10 - Provides data bit 3
// - Bit 4:       U23 - Provides data bit 4
// - Bit 5:       U11 - Provides data bit 5
// - Bit 6:       U24 - Provides data bit 6
// - Bit 7 (MSB): U12 - Provides data bit 7
//
// Note: These U-numbers match the C64 motherboard silkscreen labels
//=============================================================================
.namespace UNIT {
        .label U21      = $01   // Bit 0 - RAM chip U21
        .label U9       = $02   // Bit 1 - RAM chip U9
        .label U22      = $04   // Bit 2 - RAM chip U22
        .label U10      = $08   // Bit 3 - RAM chip U10
        .label U23      = $10   // Bit 4 - RAM chip U23
        .label U11      = $20   // Bit 5 - RAM chip U11
        .label U24      = $40   // Bit 6 - RAM chip U24
        .label U12      = $80   // Bit 7 - RAM chip U12
}

        * = * "u failure"

//=============================================================================
// RAM CHIP FAILURE DISPLAY ROUTINE
// Checks each bit in X register and displays "BAD" for failed chips
//
// Entry Conditions:
// - X register contains XOR result from memory test
// - Each set bit indicates the corresponding chip failed
//
// Screen Layout:
// The screen positions ($2a4, $299, etc.) correspond to a visual diagram
// of the C64 motherboard showing RAM chip locations. This helps technicians
// quickly identify which physical chip needs replacement.
//
// Why use a macro:
// - Eliminates repetitive code for 8 identical operations
// - Makes the bit-to-chip mapping explicit and maintainable
// - Reduces code size while improving readability
// - Ensures consistent failure display across all chips
//=============================================================================
UFailed: {
        // Check U21 (bit 0) - Located at screen position $2a4
        failCheck(UNIT.U21, $2a4)

        // Check U9 (bit 1) - Located at screen position $299
        failCheck(UNIT.U9, $299)

        // Check U22 (bit 2) - Located at screen position $2cc
        failCheck(UNIT.U22, $02cc)

        // Check U10 (bit 3) - Located at screen position $2c1
        failCheck(UNIT.U10, $02c1)

        // Check U23 (bit 4) - Located at screen position $2f4
        failCheck(UNIT.U23, $02f4)

        // Check U11 (bit 5) - Located at screen position $2e9
        failCheck(UNIT.U11, $02e9)

        // Check U24 (bit 6) - Located at screen position $31c
        failCheck(UNIT.U24, $031c)

        // Check U12 (bit 7) - Located at screen position $311
        failCheck(UNIT.U12, $0311)

        //=============================================================================
        // INFINITE LOOP - CRITICAL SYSTEM FAILURE
        // 
        // Purpose: Halt system execution after displaying failed chip(s)
        // 
        // Why an infinite loop:
        // 1. RAM failure makes normal program execution unreliable
        // 2. Keeps failure display on screen for technician to see
        // 3. Prevents unpredictable behavior from corrupted memory
        // 4. Simple and reliable - doesn't depend on working RAM/stack
        // 5. User must power cycle to restart the test
        //
        // The display remains visible showing exactly which chip(s) failed,
        // allowing repair technicians to identify and replace faulty components
        //=============================================================================
        deadLoop:
                jmp deadLoop
}