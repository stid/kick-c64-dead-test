#importonce

//=============================================================================
// TIMING DELAY MACROS
// Provide calibrated delays for memory testing and hardware timing
//
// Purpose: These macros create precise delays needed for:
// - DRAM refresh testing (detecting weak memory cells)
// - Capacitor discharge timing (ensuring data loss in faulty cells)
// - Visual feedback timing (flash durations for error codes)
// - Hardware stabilization (allowing circuits to settle)
//
// Critical for memory testing because:
// - C64 DRAM cells must hold data between refresh cycles (~15ms)
// - Weak or failing cells lose charge faster than healthy ones
// - Delays stress-test memory retention without CPU intervention
// - Longer delays increase chance of detecting marginal failures
//=============================================================================

//-----------------------------------------------------------------------------
// LongDelayLoop - Creates delays from ~1ms to 333 seconds
//
// Parameters:
//   xRep - X register loop count (0 = 256 iterations)
//   yRep - Y register loop count (0 = 256 iterations)
//
// Timing calculation (NTSC @ 1.023 MHz):
//   Inner loop: 2 (DEY) + 3 (BNE) = 5 cycles per Y iteration
//   Outer loop: 2 (DEX) + 3 (BNE) = 5 cycles per X iteration
//   Setup/restore: 2 (TXA) + 2 (LDX) + 2 (LDY) + 2 (TAX) = 8 cycles
//   Total cycles ≈ (xRep * yRep * 5) + (xRep * 5) + 8
//
// Common usage:
//   LongDelayLoop(0,0)   = ~333ms (maximum delay, used for memory discharge)
//   LongDelayLoop($7f,0) = ~165ms (used for visible flash duration)
//
// Note: Preserves X register by saving/restoring via accumulator
//-----------------------------------------------------------------------------
.macro LongDelayLoop (xRep, yRep) {
                // Save X register (accumulator is considered disposable)
                txa
                
                // Initialize loop counters
                // Note: 0 means 256 iterations due to 8-bit wraparound
                ldx #xRep
                ldy #yRep
                
                // Nested countdown loops
                // Inner loop runs Y times for each X iteration
        !:      dey                     // 2 cycles
                bne !-                  // 3 cycles when taken, 2 when not
                dex                     // 2 cycles
                bne !-                  // 3 cycles when taken, 2 when not
                
                // Restore original X register value
                tax
}

//-----------------------------------------------------------------------------
// ShortDelayLoop - Creates delays from ~15μs to 1.3ms
//
// Parameters:
//   xRep - X register loop count (0 = 256 iterations)
//
// Timing calculation (NTSC @ 1.023 MHz):
//   Loop: 2 (DEX) + 3 (BNE) = 5 cycles per iteration
//   Setup/restore: 2 (TXA) + 2 (LDX) + 2 (TAX) = 6 cycles
//   Total cycles ≈ (xRep * 5) + 6
//
// Common usage:
//   ShortDelayLoop($7f) = ~640μs (used in RAM tests between write/read)
//   ShortDelayLoop($20) = ~165μs (shorter stabilization delay)
//
// Why shorter delays in some tests:
// - Stack/ZP tests use aggressive timing to catch marginal failures
// - Visual feedback doesn't need long delays
// - Some operations just need brief stabilization time
//
// Note: Preserves X register by saving/restoring via accumulator
//-----------------------------------------------------------------------------
.macro ShortDelayLoop (xRep) {
                // Save X register (accumulator is considered disposable)
                txa
                
                // Initialize loop counter
                // Note: 0 means 256 iterations due to 8-bit wraparound
                ldx #xRep
                
                // Simple countdown loop
        !:      dex                     // 2 cycles
                bne !-                  // 3 cycles when taken, 2 when not
                
                // Restore original X register value
                tax
}
