// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2020-2026 stid and contributors
//
// Ported from Commodore 64 Dead Test rev. 781220, (C) 1988 Commodore Electronics Ltd.
// Structure, labels, constants and comments here are this project's work and are
// MIT licensed. The underlying algorithm, test sequence and data are Commodore's
// and are not licensed by this project. See NOTICE.md.

#importonce
#import "./macros.asm"
#import "./zeropage_map.asm"
#import "./data.asm"
#import "./main_loop.asm"

//=============================================================================
// TEST MODE CONFIGURATION
//
//   TEST_MODE_BANK_ENABLED - injects a two-bit fault (bits 0 and 2) into the
//                            $AA phase, exercising memFailureFlash's bank
//                            decode and the border flash counter.
//
// Why this needs its own flag rather than reusing the Low RAM ones: this test
// runs first, so a fault here halts the diagnostic before any other test is
// reached, and it produces no screen output at all - the flash count IS the
// diagnosis. It is the only feedback available on a machine too broken to
// draw a display, which makes it the path where a wrong answer costs the most.
//
// Usage: 'make test-mode-bank'. No source files are modified.
//=============================================================================

        * = * "mem bank test"

// Where the TEST_MODE_BANK_ENABLED probe publishes the computed flash count.
// Last byte of the screen page - safe because this test fails long before the
// layout is drawn. Only referenced by the probe, which is compiled out of
// normal builds.
.label TEST_PROBE = $07e7

//=============================================================================
// MEMORY BANK TEST - Critical First Test
// Tests main RAM banks $0100-$0FFF before any visual output
//
// Purpose: Verify basic RAM functionality to establish foundation for all
//          subsequent tests. Without working RAM, nothing else can function.
//
// Method:  AA/55/PRN pattern testing (suggested by Sven Petersen)
//          Superior to walking bits for detecting address bus problems
//
// Test Patterns:
//   1. $AA (10101010) - Detects stuck-low bits on odd positions
//   2. $55 (01010101) - Detects stuck-high bits on even positions
//   3. 247-byte PRN sequence - Detects address bus problems and page confusion
//
// CRITICAL CONSTRAINTS:
// - NO STACK OPERATIONS (JSR/RTS/PHA/PLA) - Stack at $0100-$01FF not verified
// - NO ZERO PAGE beyond test variables - Zero page not yet tested
// - Screen remains BLACK during test - No visual RAM verified yet
// - Only registers A,X,Y and JMP instructions available
//
// Failure Mode: Screen flashes white/black N times for failed chip N (1-8)
//               Then enters infinite loop - system halted
//=============================================================================
memBankTest: {
                //=============================================================
                // PHASE 1: Write and verify $AA pattern
                //=============================================================
                ldy #$00                // Start at offset 0 in each page

        writeAALoop:
                lda #$aa                // $AA pattern

                // Write to all 15 pages ($0100-$0F00)
                sta $0100,y             // Stack page (will be tested separately too)
                sta $0200,y             // Page 2
                sta $0300,y             // Page 3
                sta $0400,y             // Screen RAM page
                sta $0500,y             // Page 5
                sta $0600,y             // Page 6
                sta $0700,y             // Page 7
                sta $0800,y             // Page 8 - Character/sprite data
                sta $0900,y             // Page 9
                sta $0a00,y             // Page 10
                sta $0b00,y             // Page 11
                sta $0c00,y             // Page 12
                sta $0d00,y             // Page 13
                sta $0e00,y             // Page 14
                sta $0f00,y             // Page 15 - Last testable page

                iny                     // Next offset in page
                bne writeAALoop         // Continue until page filled (256 bytes)

                // Critical delay to ensure memory cells stabilize
                LongDelayLoop(0,0)

                // Verify $AA pattern
                ldy #$00
        verifyAALoop:
                lda $0100,y
#if TEST_MODE_BANK_ENABLED
                // TEST MODE: simulate a TWO-bit failure (bits 0 and 2).
                // Multi-bit is the case that matters: the old bank decode
                // handled single-bit faults correctly and mis-reported every
                // multi-bit one, so a single-bit injection would pass either
                // way and prove nothing. $AA EOR $05 = $AF, so the handler
                // recovers a difference of $05 -> lowest set bit is 0 ->
                // bank 8 -> U21 -> 8 flashes. The old cascade said 1 (U12).
                eor #$05
#endif
                cmp #$aa
                bne !fail+
                lda $0200,y
                cmp #$aa
                bne !fail+
                lda $0300,y
                cmp #$aa
                bne !fail+
                lda $0400,y
                cmp #$aa
                bne !fail+
                lda $0500,y
                cmp #$aa
                bne !fail+
                lda $0600,y
                cmp #$aa
                bne !fail+
                lda $0700,y
                cmp #$aa
                bne !fail+
                lda $0800,y
                cmp #$aa
                bne !fail+
                lda $0900,y
                cmp #$aa
                bne !fail+
                lda $0a00,y
                cmp #$aa
                bne !fail+
                lda $0b00,y
                cmp #$aa
                bne !fail+
                lda $0c00,y
                cmp #$aa
                bne !fail+
                lda $0d00,y
                cmp #$aa
                bne !fail+
                lda $0e00,y
                cmp #$aa
                bne !fail+
                lda $0f00,y
                cmp #$aa
                bne !fail+
                iny
                bne verifyAALoop
                jmp !next+
        !fail:  jmp memTestFailed_AA
        !next:

                //=============================================================
                // PHASE 2: Write and verify $55 pattern
                //=============================================================
                ldy #$00

        write55Loop:
                lda #$55                // $55 pattern

                sta $0100,y
                sta $0200,y
                sta $0300,y
                sta $0400,y
                sta $0500,y
                sta $0600,y
                sta $0700,y
                sta $0800,y
                sta $0900,y
                sta $0a00,y
                sta $0b00,y
                sta $0c00,y
                sta $0d00,y
                sta $0e00,y
                sta $0f00,y

                iny
                bne write55Loop

                LongDelayLoop(0,0)

                // Verify $55 pattern
                ldy #$00
        verify55Loop:
                lda $0100,y
                cmp #$55
                bne !fail+
                lda $0200,y
                cmp #$55
                bne !fail+
                lda $0300,y
                cmp #$55
                bne !fail+
                lda $0400,y
                cmp #$55
                bne !fail+
                lda $0500,y
                cmp #$55
                bne !fail+
                lda $0600,y
                cmp #$55
                bne !fail+
                lda $0700,y
                cmp #$55
                bne !fail+
                lda $0800,y
                cmp #$55
                bne !fail+
                lda $0900,y
                cmp #$55
                bne !fail+
                lda $0a00,y
                cmp #$55
                bne !fail+
                lda $0b00,y
                cmp #$55
                bne !fail+
                lda $0c00,y
                cmp #$55
                bne !fail+
                lda $0d00,y
                cmp #$55
                bne !fail+
                lda $0e00,y
                cmp #$55
                bne !fail+
                lda $0f00,y
                cmp #$55
                bne !fail+
                iny
                bne verify55Loop
                jmp !next+
        !fail:  jmp memTestFailed_55
        !next:

                //=============================================================
                // PHASE 3: Write and verify PRN sequence
                // PRN is 247 bytes, so it repeats: [0-246],[0-8] for 256 bytes
                //
                // Each page reads the table through a different base address
                // (PrnTestPattern+0 for $0100 up to +14 for $0F00), so every
                // page holds a DIFFERENT byte sequence. Without the stagger all
                // 15 pages would be identical and a swapped or mirrored high
                // address line (A8-A11) could never produce a mismatch.
                // The 14-byte PrnTestPatternExt keeps base+index in bounds.
                //=============================================================
                ldx #$00                // PRN pattern index
                ldy #$00                // Page offset

        writePRNLoop:
                lda PrnTestPattern,x    // Page $01xx: PRN offset 0
                sta $0100,y
                lda PrnTestPattern+1,x  // Page $02xx: PRN offset 1
                sta $0200,y
                lda PrnTestPattern+2,x
                sta $0300,y
                lda PrnTestPattern+3,x
                sta $0400,y
                lda PrnTestPattern+4,x
                sta $0500,y
                lda PrnTestPattern+5,x
                sta $0600,y
                lda PrnTestPattern+6,x
                sta $0700,y
                lda PrnTestPattern+7,x
                sta $0800,y
                lda PrnTestPattern+8,x
                sta $0900,y
                lda PrnTestPattern+9,x
                sta $0a00,y
                lda PrnTestPattern+10,x
                sta $0b00,y
                lda PrnTestPattern+11,x
                sta $0c00,y
                lda PrnTestPattern+12,x
                sta $0d00,y
                lda PrnTestPattern+13,x
                sta $0e00,y
                lda PrnTestPattern+14,x // Page $0Fxx: PRN offset 14
                sta $0f00,y

                // Increment PRN index with wrap at 247
                inx
                cpx #247                // PRN sequence length
                bne !+
                ldx #$00                // Wrap to start
        !:
                iny                     // Next page offset
                bne writePRNLoop

                LongDelayLoop(0,0)

                // Verify PRN pattern (same per-page stagger as the write)
                ldx #$00
                ldy #$00
        verifyPRNLoop:
                lda $0100,y
#if TEST_MODE_BANK_BUS_ENABLED
                // TEST MODE: corrupt the readback so the PRN phase fails,
                // routing to memBusFailureFlash instead of the counted flash.
                // Which bits differ is irrelevant here: a PRN mismatch across
                // pages means page confusion, not a single bad chip, so this
                // path deliberately flashes continuously with no count.
                eor #$01
#endif
                cmp PrnTestPattern,x
                bne !fail+
                lda $0200,y
                cmp PrnTestPattern+1,x
                bne !fail+
                lda $0300,y
                cmp PrnTestPattern+2,x
                bne !fail+
                lda $0400,y
                cmp PrnTestPattern+3,x
                bne !fail+
                jmp !continue+
        !fail:  jmp memTestFailed_PRN
        !continue:
                lda $0500,y
                cmp PrnTestPattern+4,x
                bne !fail-
                lda $0600,y
                cmp PrnTestPattern+5,x
                bne !fail-
                lda $0700,y
                cmp PrnTestPattern+6,x
                bne !fail-
                lda $0800,y
                cmp PrnTestPattern+7,x
                bne !fail-
                lda $0900,y
                cmp PrnTestPattern+8,x
                bne !fail-
                lda $0a00,y
                cmp PrnTestPattern+9,x
                bne !fail-
                lda $0b00,y
                cmp PrnTestPattern+10,x
                bne !fail-
                lda $0c00,y
                cmp PrnTestPattern+11,x
                bne !fail-
                lda $0d00,y
                cmp PrnTestPattern+12,x
                bne !fail-
                lda $0e00,y
                cmp PrnTestPattern+13,x
                bne !fail-
                lda $0f00,y
                cmp PrnTestPattern+14,x
                bne !fail-

                // Increment PRN index with wrap at 247
                inx
                cpx #247
                bne !+
                ldx #$00
        !:
                iny
                bne !+
                jmp walkingBitsPhase
        !:      jmp verifyPRNLoop

                //=============================================================
                // PHASE 4: Walking bits tests (from original Dead Test)
                // Tests individual bit positions for chip identification
                //=============================================================
        walkingBitsPhase:
                // Test patterns: walking ones + walking zeros from MemTestPattern
                // Index 4-11 = walking ones ($01, $02, $04, $08, $10, $20, $40, $80)
                // Index 12-19 = walking zeros ($FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F)
                ldx #$04                // Start at index 4 (first walking one)

        walkingBitsLoop:
                lda MemTestPattern,x    // Get current test pattern
                ldy #$00                // Reset page offset

        writeWalkingLoop:
                sta $0100,y
                sta $0200,y
                sta $0300,y
                sta $0400,y
                sta $0500,y
                sta $0600,y
                sta $0700,y
                sta $0800,y
                sta $0900,y
                sta $0a00,y
                sta $0b00,y
                sta $0c00,y
                sta $0d00,y
                sta $0e00,y
                sta $0f00,y
                iny
                bne writeWalkingLoop

                // Delay for memory stabilization
                LongDelayLoop(0,0)

                // Verify pattern
                // Read the ACTUAL value into A, then compare against the expected
                // pattern. This ordering matters: on failure the accumulator must
                // hold the value read from RAM so memTestFailed_Walking can XOR it
                // against the expected pattern to isolate the failing bits.
                // (Same ordering as the PRN verify loop above.)
                ldy #$00
        verifyWalkingLoop:
                lda $0100,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0200,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0300,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0400,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0500,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0600,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0700,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0800,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0900,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0a00,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0b00,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0c00,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0d00,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0e00,y
                cmp MemTestPattern,x
                bne !fail+
                lda $0f00,y
                cmp MemTestPattern,x
                bne !fail+
                iny
                bne verifyWalkingLoop
                jmp !next+
        !fail:  jmp memTestFailed_Walking
        !next:

                // Move to next pattern
                inx
                cpx #$14                // Test through index 19 (last walking zero)
                bne !+
                jmp memTestDone
        !:      jmp walkingBitsLoop

        memTestDone:
                // All memory tested successfully with all patterns!
                // Safe to proceed with visual initialization
                jmp mainLoop.memBankTestDone     // Continue to next test
                // CRITICAL: Using JMP not JSR - stack still not verified!

        memTestFailed_AA:
                // Failed during $AA pattern test
                // Accumulator contains actual value, XOR with expected $AA
                eor #$aa
                jmp memFailureFlash

        memTestFailed_55:
                // Failed during $55 pattern test
                // Accumulator contains actual value, XOR with expected $55
                eor #$55
                jmp memFailureFlash

        memTestFailed_PRN:
                // Failed during PRN pattern test - ADDRESS BUS FAILURE
                // This indicates crossed address lines or page mirroring
                // NOT a chip failure - do continuous fast flash instead
                jmp memBusFailureFlash

        memTestFailed_Walking:
                // Failed during walking bits test
                // Accumulator contains actual value
                // X contains index into MemTestPattern (the expected value)
                // XOR actual with expected to get failing bits
                eor MemTestPattern,x
                jmp memFailureFlash

        memFailureFlash: {
                // Identify which RAM chip failed based on bit differences
                // Each data bit is handled by a specific RAM chip:
                // Bit 0 = U21 (Bank 8)  Bit 4 = U23 (Bank 4)
                // Bit 1 = U9  (Bank 7)  Bit 5 = U11 (Bank 3)
                // Bit 2 = U22 (Bank 6)  Bit 6 = U24 (Bank 2)
                // Bit 3 = U10 (Bank 5)  Bit 7 = U12 (Bank 1)
                //
                // A contains the XOR result (difference bits, non-zero).
                // Flash the bank of the LOWEST set bit: with multiple bad
                // bits at least one genuinely failing chip is reported.
                // (The previous cascade tested "exactly this bit set" per
                // bank and fell through to bank 1/U12 for ANY multi-bit
                // difference, blaming a chip that may be fine.)
                ldy #$08                // Bit 0 = bank 8 ... bit 7 = bank 1
        !:      lsr                     // Shift lowest bit into carry
                bcs found               // Bit set -> Y is its bank number
                dey
                bne !-                  // A is non-zero, so a bit is always found
        found:
                tya                     // Bank number = flash count
                tax                     // X = flash count for the flash loop
        }


        flash: {
                // Visual failure indication through screen flashing
                // Number of flashes = failed chip number (1-8)
                // This provides diagnostic info even without working display RAM

#if TEST_MODE_BANK_ENABLED
                // TEST MODE PROBE: publish the computed flash count to memory
                // so it can be asserted automatically.
                //
                // This path produces NO screen output - it fails before the
                // display is initialised, and the border flash count is the
                // entire diagnosis. That is also why it cannot be checked the
                // way the Low RAM tests are: there is no text to read back,
                // and VICE's monitor cannot export a CPU register to a file.
                // Storing X makes the real decode result observable without
                // altering it - the value written is whatever memFailureFlash
                // just computed.
                //
                // $07E7 is the last byte of the screen page, which is untouched
                // here: this test fails before the layout is ever drawn.
                stx TEST_PROBE
#endif
                txs                             // Park flash count in SP - the only
                                                // storage that survives the delay loops
                                                // (RAM is bad, registers get clobbered)

                flashLoop:                      // Main flash cycle
                        // Flash WHITE
                        lda #$01                // White color
                        sta VIC2.BORDERCOLOUR   // Set border
                        sta VIC2.BGCOLOUR       // Set background

                        LongDelayLoop($7f,0)    // Visible duration (preserves X)

                        // Flash BLACK
                        lda #$00                // Black color
                        sta VIC2.BORDERCOLOUR
                        sta VIC2.BGCOLOUR

                        LongDelayLoop($7f,0)    // Visible duration (preserves X)

                        // Short gap between flashes - Y-only delay so X (the
                        // remaining flash count) survives. The old version
                        // clobbered X here and recovered the count from A only
                        // by accident of LongDelayLoop's TXA/TAX save/restore.
                        ldy #$00
                !:      dey
                        bne !-

                        dex                     // One flash done
                        beq endLoopDelay        // Counted all N? Long pause
                        jmp flashLoop           // Continue flashing

                endLoopDelay:
                        // Long pause between flash sequences
                        // Makes it clear when sequence repeats
                        ldx #$00
                        ldy #$00

                        // Four nested 256x256 loops for long delay
                !:      dey
                        bne !-
                        dex
                        bne !-
                !:      dey
                        bne !-
                        dex
                        bne !-
                !:      dey
                        bne !-
                        dex
                        bne !-
                !:      dey
                        bne !-
                        dex
                        bne !-

                        tsx                     // Restore flash count
                        jmp flashLoop           // Repeat sequence forever
        }

        // ADDRESS BUS FAILURE FLASH - Continuous fast flashing
        // No chip count pattern - indicates bus fault, not chip fault
        memBusFailureFlash: {
#if TEST_MODE_BANK_BUS_ENABLED
                // TEST MODE PROBE: record that the BUS path was taken.
                // $FF is a sentinel, not a flash count - this path deliberately
                // has no count, and the distinction between "flashes N times"
                // and "flashes continuously" is the entire diagnosis here.
                lda #$ff
                sta TEST_PROBE
#endif
                // Rate matters as much as the colours here. ShortDelayLoop($1f)
                // gave a half-cycle of ~171 cycles - about 2.9 kHz, alternating
                // ~57 times per PAL frame. That is not a flash: the screen fills
                // with fine horizontal banding that reads as broken video or a
                // dead machine, which is the opposite of the intended message.
                //
                // LongDelayLoop($30,0) is ~62 ms per half-cycle, so ~8 Hz:
                // unmistakably flashing, and clearly faster than the 3 Hz counted
                // flash it must be told apart from. The counted flash also pauses
                // between groups, so the two are distinguishable at a glance:
                //   N flashes, pause, repeat  -> chip N failed
                //   never stops, never pauses -> bus fault, no chip identified
                busFlashLoop:
                        // Flash WHITE
                        lda #$01                // White color
                        sta VIC2.BORDERCOLOUR
                        sta VIC2.BGCOLOUR

                        LongDelayLoop($30,0)    // ~62ms - visible, no pause

                        // Flash BLACK
                        lda #$00                // Black color
                        sta VIC2.BORDERCOLOUR
                        sta VIC2.BGCOLOUR

                        LongDelayLoop($30,0)    // ~62ms - visible, no pause

                        jmp busFlashLoop        // Continuous loop - no pattern
        }
}
