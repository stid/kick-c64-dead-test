#importonce

//=============================================================================
// MEMORY MAP DEFINITIONS FOR C64 DEAD TEST
// 
// Purpose: Define critical memory locations for hardware diagnostics
// 
// This file maps essential C64 hardware registers and memory regions
// required for the dead test diagnostic. These addresses are used to:
// - Display visual feedback when screen RAM is functional
// - Generate audio feedback through the SID chip
// - Access timing hardware for delays and measurements
//
// Note: Many standard C64 memory locations are omitted as they require
//       working RAM to function (BASIC ROM, Kernal ROM vectors, etc.)
//=============================================================================

//=============================================================================
// CORE MEMORY REGIONS
//=============================================================================

// Stack memory starts at $0100 and extends to $01FF
// Critical for: JSR/RTS instructions, interrupt handling, temporary storage
// Test requirement: Must be verified before using any stack-based operations
.label STACK_MEM                    = $100

// Screen memory (1000 bytes) for 40x25 character display
// Each byte represents one character on screen (PETSCII code)
// Test usage: Visual feedback after basic RAM tests pass
.label VIDEO_RAM                    = $400

// Color RAM - 1000 nybbles (only lower 4 bits used per location)
// Maps 1:1 with screen memory to set character colors
// Hardware constraint: Upper 4 bits always read as $F due to 4-bit RAM chips
// Test usage: Colored borders/screens to indicate specific failures
.label COLOR_VIDEO_RAM              = $d800

//=============================================================================
// VIC-II (VIDEO INTERFACE CHIP II) REGISTERS
// Base address: $D000-$D02E
// 
// The VIC-II generates all video output for the C64. For dead test
// diagnostics, we primarily use border/background colors as they don't
// require functioning character ROM or screen RAM to be visible.
//=============================================================================
.namespace VIC2 {
    // Border color register (0-15)
    // Most reliable visual feedback - works even if screen RAM fails
    // Test usage: Flash patterns indicate specific chip failures
    .label BORDERCOLOUR            = $d020
    
    // Background color for screen area (0-15)
    // Only visible when screen is cleared or spaces displayed
    // Test usage: Different color from border helps identify display issues
    .label BGCOLOUR                = $d021
}

//=============================================================================
// CIA1 (COMPLEX INTERFACE ADAPTER #1) REGISTERS
// Base address: $DC00-$DCFF
// 
// CIA1 handles keyboard, joystick ports, and Timer A/B
// For dead test, we use timers for precise delays and time-of-day
// clock for basic timekeeping verification
//=============================================================================
.namespace CIA1 {
    // Timer B 16-bit counter (low byte)
    // Counts down from loaded value to zero at system clock rate
    .label TIMER_B_LOW             = $dc06
    
    // Timer B 16-bit counter (high byte)
    // Together with low byte forms 16-bit timer (0-65535)
    .label TIMER_B_HIGH            = $dc07
    
    // Timer A control register
    // Bit 0: Start/stop timer
    // Bit 1: Indicates timer underflow
    // Bit 3: One-shot (0) or continuous (1) mode
    // Bit 4: Load latch into timer
    // Bit 5: Count system cycles (0) or Timer B underflows (1)
    // Bit 6-7: Serial port control
    .label CONTROL_TIMER_A         = $dc0e
    
    // Timer B control register
    // Same bit definitions as Timer A, except:
    // Bit 5-6: Count mode selection
    //   00 = Count system cycles
    //   01 = Count positive CNT transitions
    //   10 = Count Timer A underflows
    //   11 = Count Timer A underflows while CNT high
    .label CONTROL_TIMER_B         = $dC0f
    
    // Time-of-day clock registers (BCD format)
    // These continuously count real time when powered
    // Test usage: Verify CIA functionality and timing accuracy
    
    // Hours (0-23 in BCD, bit 7 = AM/PM flag in 12-hour mode)
    .label REAL_TIME_HOUR          = $dc0b
    
    // Minutes (0-59 in BCD)
    .label REAL_TIME_MIN           = $dc0a
    
    // Seconds (0-59 in BCD)
    .label REAL_TIME_SEC           = $dc09
    
    // Tenths of seconds (0-9 in BCD)
    .label REAL_TIME_10THS         = $dc08
}

//=============================================================================
// CIA2 (COMPLEX INTERFACE ADAPTER #2) REGISTERS
// Base address: $DD00-$DDFF
// 
// CIA2 handles serial bus, user port, and VIC bank switching
// Dead test uses timers for additional delay/measurement capabilities
// Note: CIA2 is less critical than CIA1 for basic operation
//=============================================================================
.namespace CIA2 {
    // Timer B registers - identical functionality to CIA1
    // Having two CIAs allows independent timing operations
    .label TIMER_B_LOW             = $dd06
    .label TIMER_B_HIGH            = $dd07
    
    // Control registers - same bit definitions as CIA1
    .label CONTROL_TIMER_A         = $dD0e
    .label CONTROL_TIMER_B         = $dd0f
    
    // Time-of-day clock - independent from CIA1's clock
    // Can be used to verify both CIAs functioning correctly
    .label REAL_TIME_HOUR          = $dd0b
    .label REAL_TIME_MIN           = $dd0a
    .label REAL_TIME_SEC           = $dd09
    .label REAL_TIME_10THS         = $dd08
}

//=============================================================================
// SID (SOUND INTERFACE DEVICE) REGISTERS
// Base address: $D400-$D41C
// 
// The SID chip provides 3 voice synthesis and filtering capabilities.
// Dead test uses simple tones to provide audio feedback for failures,
// especially useful when video output is completely non-functional.
//=============================================================================
.namespace SID {
    // Voice 1 Frequency Control (16-bit)
    // Frequency = (register value * clock) / 16777216
    // For PAL: clock = 985248 Hz, NTSC: clock = 1022727 Hz
    .label VOICE_1_FREQ_L           = $d400  // Bits 0-7 of frequency
    .label VOICE_1_FREQ_H           = $d401  // Bits 8-15 of frequency
    
    // Voice 1 Pulse Width for rectangle waveform (12-bit)
    // Controls duty cycle: 0 = 0%, 2048 = 50%, 4095 = 100%
    .label VOICE_1_PULSE_L          = $d402  // Bits 0-7 of pulse width
    .label VOICE_1_PULSE_H          = $d403  // Bits 8-11 of pulse width (upper 4 bits unused)
    
    // Voice 1 Control Register
    // Bit 0: Gate (1 = start attack/decay/sustain, 0 = start release)
    // Bit 1: Sync (1 = sync oscillator with voice 3)
    // Bit 2: Ring modulation (1 = ring modulate with voice 3)
    // Bit 3: Test (1 = disable oscillator)
    // Bit 4-7: Waveform select (can combine):
    //   Bit 4: Triangle
    //   Bit 5: Sawtooth
    //   Bit 6: Rectangle/Pulse
    //   Bit 7: Noise
    .label VOICE_1_CTRL             = $d404
    
    // Voice 1 ADSR Envelope
    // Attack/Decay: High nybble = Attack (0-15), Low nybble = Decay (0-15)
    .label VOICE_1_ATK_DEC          = $d405
    
    // Sustain/Release: High nybble = Sustain level (0-15), Low = Release (0-15)
    .label VOICE_1_SUS_VOL_REL      = $d406
    
    // Voice 2 registers - identical functionality to Voice 1
    .label VOICE_2_FREQ_L           = $d407
    .label VOICE_2_FREQ_H           = $d408
    .label VOICE_2_PULSE_L          = $d409
    .label VOICE_2_PULSE_H          = $d40a
    .label VOICE_2_CTRL             = $d40b
    .label VOICE_2_ATK_DEC          = $d40c
    .label VOICE_2_SUS_VOL_REL      = $d40d
    
    // Voice 3 registers - identical functionality to Voice 1
    // Voice 3 special: Can be used as modulation source for filter/ring mod
    .label VOICE_3_FREQ_L           = $d40e
    .label VOICE_3_FREQ_H           = $d40f
    .label VOICE_3_PULSE_L          = $d410
    .label VOICE_3_PULSE_H          = $d411
    .label VOICE_3_CTRL             = $d412
    .label VOICE_3_ATK_DEC          = $d413
    .label VOICE_3_SUS_VOL_REL      = $d414
    
    // Filter Cutoff Frequency (11-bit)
    // Determines which frequencies pass through filter
    // Linear scale: 0 = 30Hz, 2047 = ~12KHz
    .label FILTER_CUTOFF_L          = $d415  // Bits 0-2 of cutoff (bits 3-7 unused)
    .label FILTER_CUTOFF_H          = $d416  // Bits 3-10 of cutoff
    
    // Filter Resonance and Routing
    // Bits 0-3: Filter routing
    //   Bit 0: Filter voice 1
    //   Bit 1: Filter voice 2
    //   Bit 2: Filter voice 3
    //   Bit 3: Filter external input
    // Bits 4-7: Resonance (0 = none, 15 = maximum)
    .label FILTER_RES_ROUT          = $d417
    
    // Filter Mode and Main Volume
    // Bits 0-3: Main volume (0 = silent, 15 = maximum)
    // Bit 4: Low pass filter enable
    // Bit 5: Band pass filter enable
    // Bit 6: High pass filter enable
    // Bit 7: Disable voice 3 (1 = voice 3 silent)
    .label FILTER_VOL               = $d418
}


