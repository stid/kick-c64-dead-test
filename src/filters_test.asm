#importonce
#import "./data.asm"
#import "./macros.asm"
#import "./mem_map.asm"
#import "./zeropage_map.asm"


        * = * "filters test"

// Waveform constant: bit 6 = pulse wave for filter testing
.const SID_WF       = 64

//=============================================================================
// SID FILTER TEST
// Tests the analog filter section of the SID chip (6581/8580)
// Based on BASIC SID TESTER by Andrew Challis
// http://hackjunk.com/2017/11/07/commodore-64-sid-tester/
//
// Purpose: Detect failed filter capacitors or analog circuitry
// Method:  Sweeps filter cutoff frequency while playing test tones
//          Working filters produce audible "whoosh" sound
//          Failed filters sound flat or distorted
//
// Why needed: Original sound test only verifies oscillators/envelopes
//             Filter failures are common due to capacitor aging
//=============================================================================

filterTest: {
                // Display "filters test" label on screen at row 9
                ldx #11
        !:      lda strFilters,x
                sta VIDEO_RAM+$168,x
                dex
                bpl !-

                // Reset SID to known state before testing
                jsr     clearSid

                // Test with low frequency (15) 
                // This tests filter response in lower frequency range
                lda     #15
                sta     ZP.tmpFilterSound
                jsr     filtersLoop
                
                // Test with higher frequency (45)
                // This tests filter response in upper frequency range
                // Different frequencies can reveal different filter problems
                lda     #45
                sta     ZP.tmpFilterSound
                jsr     filtersLoop

                rts

    filtersLoop: {
                // Configure filter routing and resonance:
                // Bits 0-2: Enable filter for voices 1,2,3 (1+2+4=7)
                // Bit 4: Disable external input filter (0)
                // Bits 5-7: Resonance level (5 = moderate resonance)
                // Formula: resonance*16 + filter_enables = 5*16 + 7 = 87
                ldx     #5*16+1+2+4
                stx     SID.FILTER_RES_ROUT
                
                // Start with filter mode = low-pass (bit 4 set)
                lda     #16
        !:
                pha                     // Save current filter mode
                
                // Delay between filter mode changes
                // Allows time to hear each filter configuration
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                
                pla                     // Restore filter mode
                tax                     // Save for later comparison
                clc
                adc     #15                // Add volume level (0-15)
                sta     SID.FILTER_VOL      // Set filter mode + volume
                txa                     // Get filter mode back

                jsr     mainSoundLoop      // Play test sound with current filter

                // Cycle through filter modes:
                // 16 = low-pass only (bit 4)
                // 32 = band-pass only (bit 5) 
                // 64 = high-pass only (bit 6)
                cmp     #64                // Have we tested all three modes?
                beq     done
                asl                        // Shift to next filter mode bit
                jmp     !-                 // Test next mode

        done:
                rts
    }


    mainSoundLoop: {
                pha                        // Save filter mode
                ldy     #0                 // Start with voice 1

        loop:
                pha
                // Delay for audible tone duration
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                pla
                
                // Configure voice for filter testing:
                // - Fixed frequency from ZP.tmpFilterSound
                // - Fast attack, full sustain for continuous tone
                // - Pulse wave with 50% duty cycle
                lda     ZP.tmpFilterSound
                sta     SID.VOICE_1_FREQ_H, y       // Set frequency high byte
                lda     #0
                sta     SID.VOICE_1_ATK_DEC, y      // Attack=0, Decay=0 (fastest)
                lda     #240                         // Sustain=15, Release=0
                sta     SID.VOICE_1_SUS_VOL_REL, y
                lda     #8                           // 50% pulse width (2048/4096)
                sta     SID.VOICE_1_PULSE_H, y
                
                // Start tone with gate bit
                lda     #SID_WF+1                    // Pulse wave + gate on
                sta     SID.VOICE_1_CTRL, y

                // Sweep filter cutoff while tone plays
                // This creates the characteristic filter sweep sound
                jsr     filterCutOff
                
                // Gate off but keep waveform selected
                lda     #SID_WF                      // Pulse wave, gate off
                sta     SID.VOICE_1_CTRL, y

                pha
                // Move to next voice registers
                // SID voices are 7 bytes apart:
                // Voice 1: $D400-$D406
                // Voice 2: $D407-$D40D  
                // Voice 3: $D40E-$D414
                tya
                clc
                adc     #7                 // Next voice offset
                tay
                pla
                
                // Test all three voices (Y=0, 7, 14)
                // Testing all voices ensures filter affects all channels
                cpy     #21                // Past voice 3?
                bne     loop               // No, test next voice
                
                pla                        // Restore filter mode
                rts
    }


    filterCutOff: {
                // Sweep filter cutoff frequency from 0 to 255
                // This creates an audible sweep effect that reveals filter problems
                // Working filters: smooth "whoosh" sound
                // Failed filters: no effect, distortion, or clicking
                
                txa
                pha                        // Save X register
                ldx     #0                 // Start at lowest cutoff
        !:
                pha
                // Delay controls sweep speed
                // Slower sweep = easier to hear filter response
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                pla

                // Set filter cutoff high byte (bits 3-10 of 11-bit value)
                // Low 3 bits are in FILTER_CUTOFF_L (not used here)
                stx     SID.FILTER_CUTOFF_H
                inx
                bne     !-                 // Sweep all 256 values
                
                pla
                tax                        // Restore X register
                rts
    }

    clearSid: {
                // Reset all SID registers to silence
                // Important: Clear any previous test's settings
                // to ensure consistent filter test results
                
                lda     #0
                sta     SID.FILTER_VOL      // Silence and filter mode off
                ldy     #0
        !:
                pha
                // Small delay ensures SID registers update properly
                // Some SID operations need time to take effect
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                ShortDelayLoop($ff)
                pla

                sta     $D400, y            // Clear each SID register
                iny
                cpy     #$19                // $19 = 25 registers ($D400-$D418)
                bne     !-
                rts
    }
}
