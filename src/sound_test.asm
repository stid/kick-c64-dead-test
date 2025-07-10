#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./mem_map.asm"
#import "./zeropage_map.asm"


        * = * "sound test"

//=============================================================================
// SID OSCILLATOR TEST
// Tests all three SID voices sequentially to verify basic sound generation
// 
// Purpose: Verify that the SID chip (6581/8580) can produce audio output
//          on all three independent voices
// Method:  Play frequency sweeps on each voice with increasing volume
//          to aid in diagnostic listening
// 
// Test Coverage:
// - Voice 1: Tests at volume $14 (20/31)
// - Voice 2: Tests at volume $18 (24/31) 
// - Voice 3: Tests at volume $1F (31/31 - maximum)
//
// This test verifies:
// - Oscillator functionality for all three voices
// - ADSR envelope generation
// - Volume control (register $D418 bits 0-3)
// - Basic waveform generation (pulse wave)
//
// NOT tested:
// - Filter functionality (disabled throughout test)
// - Ring modulation or sync features
// - Noise waveform generation
// - External audio input
//
// Hardware Details:
// The SID chip contains three independent voice channels, each with:
// - 16-bit frequency control (0-65535, ~0Hz to ~4kHz at 1MHz clock)
// - 12-bit pulse width control for pulse waveform
// - ADSR envelope generator with 4-bit attack/decay, 4-bit sustain, 4-bit release
// - Waveform selection (triangle, sawtooth, pulse, noise, and combinations)
//
// Test Methodology:
// 1. Each voice plays a 7-note ascending/descending frequency pattern
// 2. Volume increases with each voice to help identify which is playing
// 3. The test cycles through 3 different waveform configurations
// 4. Total test runs 3 waveforms × 3 voices × 7 notes = 63 tones
// 5. A working SID should produce clear, distinct tones without distortion
//
// Common Failures:
// - No sound: SID chip dead or clock failure
// - Missing voice: Specific oscillator circuit failure
// - Distorted sound: Analog circuit degradation (especially in 6581)
// - Stuck notes: ADSR envelope generator failure
//=============================================================================
soundTest: {
                // Display "SOUND TEST" label on screen at line 8, column 24
                ldx #$09
        !:      lda strSound,x      
                sta VIDEO_RAM+$118,x
                dex
                bpl !-

                // Initialize SID for Voice 1 testing
                // Set master volume to $14 (20/31) - moderate volume for first test
                lda #$14
                sta SID.FILTER_VOL
                
                // Disable all filters - we're testing raw oscillator output
                // Bits 0-2: Voice filter enables (all off)
                // Bit 4: External input filter (off)
                lda #$00
                sta SID.FILTER_RES_ROUT
                
                // Configure Voice 1 ADSR envelope
                // Attack = 3 (190μs), Decay = E (6ms)
                // This creates a quick pluck/ping sound
                lda #$3e
                sta SID.VOICE_1_ATK_DEC
                
                // Sustain level = C (12/15), Release = A (100ms)
                // High sustain keeps tone audible, moderate release for clean note end
                lda #$ca
                sta SID.VOICE_1_SUS_VOL_REL
                
                // Ensure Voice 3 is silent (used later in test)
                lda #$00
                sta SID.VOICE_3_CTRL
                
                // Start with waveform pattern index 2
                // This indexes into sound7/8/9 arrays for control/pulse settings
                lda #$02
        mainLoop:
                pha
                
                // === VOICE 1 TEST SEQUENCE ===
                // Play 7 notes with varying frequencies to test oscillator range
                ldx #$06
        loopA:  
                // Load frequency high byte from table
                // Frequencies range from low to high and back (sweep pattern)
                lda sound1,x
                sta SID.VOICE_1_FREQ_H
                
                // Load frequency low byte
                // Together these create frequencies roughly:
                // $1125, $159A, $19B1, $224B, $19B1, $159A, $1125
                lda sound2,x
                sta SID.VOICE_1_FREQ_L
                
                // Restore waveform index for pulse width/control settings
                pla
                tay
                
                // Set pulse width low byte (usually 0 for narrow pulse)
                lda sound8,y
                sta SID.VOICE_1_PULSE_L
                
                // Set pulse width high byte
                // Values: $08, $00, $00, $09, $00, $28
                // Creates varying pulse widths for timbral variation
                lda sound9,y
                sta SID.VOICE_1_PULSE_H
                
                // Set control register - this starts the note
                // Values from sound7: $45, $11, $25
                // Bit 0: Gate (1=on)
                // Bit 4: Triangle wave (sometimes)
                // Bit 5: Sawtooth (sometimes) 
                // Bit 6: Pulse wave (always for $45)
                // Different waveforms test oscillator versatility
                lda sound7,y
                sta SID.VOICE_1_CTRL
                
                // Preserve waveform index for next iteration
                tya
                pha
                
                // Play note for ~106 delay units
                lda #$6a
                jsr pauseOrExit
                
                // Gate off - stop the note
                // This tests envelope release phase
                lda #$00
                sta SID.VOICE_1_CTRL
                
                // Brief pause between notes for clarity
                lda #$00
                jsr pauseOrExit
                
                // Next frequency in sequence
                dex
                bne loopA
                
                // === VOICE 2 TEST SEQUENCE ===
                // Voice 2 uses higher volume to differentiate from Voice 1
                
                // Ensure filters remain disabled
                lda #$00
                sta SID.FILTER_RES_ROUT
                
                // Increase volume to $18 (24/31) - louder than Voice 1
                // This helps technician identify which voice is playing
                lda #$18
                sta SID.FILTER_VOL
                
                // Configure Voice 2 ADSR - identical to Voice 1 for consistency
                // Attack = 3 (190μs), Decay = E (6ms)
                lda #$3e
                sta SID.VOICE_2_ATK_DEC
                
                // Sustain = C (12/15), Release = A (100ms)
                lda #$ca
                sta SID.VOICE_2_SUS_VOL_REL
                
                // Play 7 notes on Voice 2
                ldx #$06
        loopB:  
                // Voice 2 uses different frequency tables (sound3/4)
                // This creates a higher pitch sequence:
                // $224B, $2B34, $3361, $4495, $3361, $2B34, $224B
                // Approximately one octave higher than Voice 1
                lda sound3,x
                sta SID.VOICE_2_FREQ_H
                lda sound4,x
                sta SID.VOICE_2_FREQ_L
                
                // Restore waveform settings index
                pla
                tay
                
                // Apply same pulse width settings as Voice 1
                // This ensures consistent timbre for comparison
                lda sound8,y
                sta SID.VOICE_2_PULSE_L
                lda sound9,y
                sta SID.VOICE_2_PULSE_H
                
                // Gate on with selected waveform
                lda sound7,y
                sta SID.VOICE_2_CTRL
                
                // Preserve index
                tya
                pha
                
                // Same timing as Voice 1 for consistent rhythm
                lda #$6a
                jsr pauseOrExit
                
                // Gate off
                lda #$00
                sta SID.VOICE_2_CTRL
                
                // Inter-note pause
                lda #$00
                jsr pauseOrExit
                
                // Next note
                dex
                bne loopB
                
                // === VOICE 3 TEST SEQUENCE ===
                // Voice 3 uses maximum volume for final verification
                
                // Filters still disabled
                lda #$00
                sta SID.FILTER_RES_ROUT
                
                // Maximum volume $1F (31/31)
                // Loudest setting makes any distortion or failure obvious
                lda #$1f
                sta SID.FILTER_VOL
                
                // Configure Voice 3 ADSR - same envelope as other voices
                lda #$3e
                sta SID.VOICE_3_ATK_DEC
                lda #$ca
                sta SID.VOICE_3_SUS_VOL_REL
                
                // Play 7 notes on Voice 3
                ldx #$06
        loopC:  
                // Voice 3 uses highest frequency tables (sound5/6)
                // Creates even higher pitch sequence:
                // $4495, $5669, $66C2, $892B, $66C2, $5669, $4495
                // Tests upper frequency range of oscillators
                lda sound5,x
                sta SID.VOICE_3_FREQ_H
                lda sound6,x
                sta SID.VOICE_3_FREQ_L
                
                // Restore waveform settings
                pla
                tay
                
                // Same pulse width progression as other voices
                lda sound8,y
                sta SID.VOICE_3_PULSE_L
                lda sound9,y
                sta SID.VOICE_3_PULSE_H
                
                // Gate on
                lda sound7,y
                sta SID.VOICE_3_CTRL
                
                // Preserve index
                tya
                pha
                
                // Standard note duration
                lda #$6a
                jsr pauseOrExit
                
                // Gate off
                lda #$00
                sta SID.VOICE_3_CTRL
                
                // Inter-note pause
                lda #$00
                jsr pauseOrExit
                
                // Continue sequence
                dex
                bne loopC
                
                // === WAVEFORM CYCLE CONTROL ===
                // After testing all 3 voices, advance to next waveform type
                pla
                tay
                dey         // Decrement waveform index (2->1->0)
                tya
                
                // Check if all waveform types tested (negative = done)
                bmi !+
                
                // More waveforms to test - restart voice sequence
                jmp mainLoop
                
        !:      rts         // All tests complete

        //---------------------------------------------------------------------
        // TIMING DELAY SUBROUTINE
        // Creates precise delays for note duration and spacing
        //
        // Input: A = delay duration ($00 = immediate return, else delay)
        // Preserves: X register
        //
        // The delay allows each note to sound long enough to be heard clearly
        // while maintaining a steady rhythm for diagnostic purposes
        //---------------------------------------------------------------------
        pauseOrExit:
                cmp #$00
                beq done            // No delay requested
                
                // Preserve current state
                tay
                txa
                pha
                tya
                tax
                
        delayLoop:
                // Inner loop: 256 iterations
                ldy #$ff
        !:      dey
                bne !-
                
                // Outer loop: A iterations
                dex
                bne delayLoop
                
                // Restore X register
                pla
                tax
        done:   rts
}