
//=============================================================================
// ZERO PAGE MEMORY MAP FOR C64 DEAD TEST
// 
// Purpose: Define zero page locations for critical test variables
// 
// The zero page ($0000-$00FF) is the fastest accessible memory on the 6502,
// supporting special addressing modes that save cycles and code size.
// For dead test diagnostics, we must carefully choose locations that:
// - Don't conflict with the 6510 processor port at $00-$01
// - Are safe to use before BASIC/Kernal initialization
// - Support our need for fast memory access during testing
//
// Memory layout consideration:
// $00-$01: 6510 processor port (CPU hardware registers)
// $02-$8F: Available for use (normally used by BASIC)
// $90-$FF: Available for use (normally used by Kernal)
//
// Since we run before any ROM initialization, we can use most of zero page,
// but we start at $02 to avoid the processor port registers.
//=============================================================================

#importonce

*=$0 "ZERO PAGE" virtual

.namespace ZP {
    //=========================================================================
    // 6510 PROCESSOR PORT REGISTERS ($00-$01)
    // 
    // These are hardware registers built into the 6510 CPU itself.
    // They control memory banking and cassette motor operation.
    // WARNING: Modifying these affects which ROM/RAM banks are visible!
    //=========================================================================
    
    // 6510 Data Direction Register (DDR) at $00
    // Each bit controls whether the corresponding bit in $01 is:
    // 0 = Input (read external state)
    // 1 = Output (CPU controls the bit)
    // 
    // Bit assignments:
    // Bit 0: LORAM - Low RAM control (usually set to output)
    // Bit 1: HIRAM - High RAM control (usually set to output)
    // Bit 2: CHAREN - Character ROM control (usually set to output)
    // Bit 3: Cassette data output (output for saving)
    // Bit 4: Cassette switch sense (input to detect button)
    // Bit 5: Cassette motor control (output to control motor)
    // Bits 6-7: Not connected, undefined behavior
    //
    // Dead test consideration: We must preserve or properly set these
    // to ensure ROMs remain visible during testing
    ProcessDataDir:        .byte 0
    
    // 6510 I/O Port Register at $01
    // Controls actual state of pins when DDR bit = 1 (output)
    // Reads external state when DDR bit = 0 (input)
    // 
    // Bit functions when set as output:
    // Bit 0: LORAM - 0 = RAM at $A000, 1 = BASIC ROM
    // Bit 1: HIRAM - 0 = RAM at $E000, 1 = Kernal ROM
    // Bit 2: CHAREN - 0 = I/O at $D000, 1 = Character ROM
    // Bit 3: Cassette data output signal
    // Bit 4: (Input only) Cassette switch state
    // Bit 5: Cassette motor - 0 = motor on, 1 = motor off
    //
    // Common configurations:
    // $37 (%00110111) = Normal (BASIC + Kernal + I/O visible)
    // $36 (%00110110) = RAM at $A000-$BFFF, Kernal + I/O visible
    // $35 (%00110101) = RAM + I/O visible, no ROMs
    // $34 (%00110100) = All RAM (no ROMs, no I/O)
    //
    // Dead test note: We need I/O visible for hardware access
    ProcessPortBit:        .byte 0
    
    //=========================================================================
    // TEST ROUTINE VARIABLES
    // 
    // These zero page locations are chosen for optimal performance
    // during memory testing and diagnostic routines. Using zero page
    // saves 1 cycle per access and 1 byte per instruction.
    //=========================================================================
    
    // 16-bit counter for loops and delays
    // Used extensively in delay routines and pattern generation
    // Zero page location allows fast increment/decrement operations
    counterLow:             .byte 0
    counterHigh:            .byte 0
    
    // Source address pointer for memory copy operations
    // Zero page allows use of indirect indexed addressing: lda (ptr),y
    // Critical for fast memory pattern writing during tests
    tmpSourceAddressLow:    .byte 0
    tmpSourceAddressHigh:   .byte 0
    
    // Destination address pointer for memory operations
    // Paired with source for memory-to-memory transfers
    // Essential for screen update routines after RAM verification
    tmpDestAddressLow:      .byte 0
    tmpDestAddressHigh:     .byte 0
    
    // Temporary Y register storage
    // Preserves Y during nested loops since we can't use stack early
    // Named to clearly indicate it shadows the Y register
    tmpY:                   .byte 0
    
    // SID filter test state storage
    // Tracks current filter setting during audio diagnostic
    // Zero page ensures fast access during sound generation loops
    tmpFilterSound:         .byte 0
}