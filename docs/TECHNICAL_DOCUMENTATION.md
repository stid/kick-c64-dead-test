# Commodore 64 Dead Test - Technical Documentation

## Overview

This is a comprehensive hardware diagnostic tool for the Commodore 64, designed to systematically test all critical components even when the system is severely damaged. Based on the original COMMODORE 64 Dead Test rev. 781220, this version has been enhanced with improved visual feedback, additional tests, and better code organization.

## Architecture and Design Philosophy

### Cartridge Mode

The diagnostic runs as an Ultimax cartridge (GAME=0, EXROM=1), which:

- Overwrites the C64 Kernal ROM space ($E000-$FFFF)
- Ensures the diagnostic starts even with a faulty Kernal ROM
- All hardware vectors ($FFFA-$FFFF) point to the main loop

### Progressive Testing Strategy

Tests are ordered from most critical to least critical:

1. **Pre-display tests** (black screen): Basic RAM functionality
2. **Foundation tests**: Zero page and stack (still no JSR/RTS)
3. **Low RAM completeness**: Test previously untested $0200-$03FF
4. **Display tests**: Screen and color RAM
5. **Extended tests**: General RAM, fonts, sound

### Key Design Constraint

Early tests (memory bank, zero page, stack) cannot use:

- JSR/RTS instructions (stack not verified)
- Any stack operations (PHA/PLA)
- Only JMP for flow control

## Detailed Test Analysis

### 1. Memory Bank Test (Black Screen Phase)

**Purpose**: Verify basic RAM functionality before any visual output

**Test Methodology**: AA/55/PRN + walking bits patterns (suggested by Sven Petersen)

**Test Patterns** (4 phases, 19 patterns total):

1. **Phase 1 - $AA pattern (10101010)**: Detects stuck-low bits on odd positions
2. **Phase 2 - $55 pattern (01010101)**: Detects stuck-high bits on even positions
3. **Phase 3 - 247-byte PRN sequence**: Detects address bus problems and page confusion
   - Prime-like length ensures non-alignment with 256-byte pages
   - Catches mirrored or crossed address lines that aligned patterns miss
4. **Phase 4 - Walking bits** (16 patterns):
   - Walking ones: $01,$02,$04,$08,$10,$20,$40,$80
   - Walking zeros: $FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F
   - Enables specific chip identification

**Algorithm**:

1. Write AA pattern to all memory pages ($0100-$0FFF) simultaneously, delay, verify
2. Write 55 pattern to all memory pages simultaneously, delay, verify
3. Write repeating 247-byte PRN sequence across all memory pages, delay, verify
4. For each walking bit pattern: write to all pages, delay, verify
5. Each phase tests all 3840 bytes before moving to next phase

**Why This Approach**:

- **AA/55 patterns**: Fast detection of stuck bits without complex calculations
- **247-byte PRN**: Detects address bus faults (crossed lines, mirroring, page confusion)
- **Walking bits**: Precise chip identification for failures
- **Combined approach**: Maximum test coverage with both fault detection and chip ID

**Failure Detection**:

The test differentiates between chip failures and bus failures:

**Chip Failures** (AA/55/Walking Bits patterns):
- XOR failed value with expected to identify bad bits
- Each bit corresponds to a specific RAM chip:
  - Bit 0 → U21 (Bank 8) - Flash 8 times
  - Bit 1 → U9 (Bank 7) - Flash 7 times
  - Bit 2 → U22 (Bank 6) - Flash 6 times
  - Bit 3 → U10 (Bank 5) - Flash 5 times
  - Bit 4 → U23 (Bank 4) - Flash 4 times
  - Bit 5 → U11 (Bank 3) - Flash 3 times
  - Bit 6 → U24 (Bank 2) - Flash 2 times
  - Bit 7 → U12 (Bank 1) - Flash 1 time
- Screen flashes white/black N times for chip N, then repeats

**Bus Failures** (PRN pattern):
- Indicates address bus fault (crossed lines, mirroring, page confusion)
- Continuous FAST flashing (no count pattern)
- Not a chip failure - no specific chip can be identified

### 2. Zero Page Test ($00-$FF)

**Purpose**: Test the most critical 256 bytes used for:

- Variable storage
- Indirect addressing pointers
- Fast 2-cycle instructions

**Test Methodology**: AA/55/PRN + walking bits patterns (same as Memory Bank Test)

**Test Range**: $12-$FF (238 bytes, preserves $00-$11 for test variables)

**Method**:

- Phase 1: Write/verify $AA pattern across $12-$FF
- Phase 2: Write/verify $55 pattern across $12-$FF
- Phase 3: Write/verify 247-byte PRN sequence across $12-$FF
- Phase 4: Write/verify 16 walking bit patterns across $12-$FF
- Still cannot use stack operations (JMP only)

### 3. Stack Page Test ($0100-$01FF)

**Purpose**: Verify stack memory for:

- Subroutine calls (JSR/RTS)
- Interrupt handling
- Temporary storage (PHA/PLA)

**Test Methodology**: AA/55/PRN + walking bits patterns (same as Memory Bank Test)

**Test Range**: $0100-$01FF (full 256 bytes)

**Method**:

- Phase 1: Write/verify $AA pattern across stack page
- Phase 2: Write/verify $55 pattern across stack page
- Phase 3: Write/verify 247-byte PRN sequence across stack page
- Phase 4: Write/verify 16 walking bit patterns across stack page
- LAST test to avoid JSR/RTS (still uses JMP only)

**Significance**: After this test passes, the code can use JSR/RTS and full 6502 functionality

### 4. Low RAM Test ($0200-$03FF)

**Purpose**: Test the previously untested 512 bytes between stack and screen RAM

**Test Pattern Philosophy** (suggested by [Sven Petersen](https://github.com/svenpetersen1965)):

1. $AA pattern (10101010) - Detects even-bit stuck failures
2. $55 pattern (01010101) - Detects odd-bit stuck failures
3. 247-byte PRN sequence - Detects address bus problems and page confusion
4. 16 walking bit patterns - Enables specific chip identification (walking ones + walking zeros)

**Why 247-byte PRN sequence?**

- Prime-like odd length ensures pattern "drifts" relative to page boundaries
- After 247 bytes, pattern repeats but at different offset within 256-byte pages
- Catches mirrored or confused address lines that 256-aligned tests miss
- If pages are swapped or address lines crossed, PRN will be out of phase

**Algorithm**:

1. Write $AA to entire region, delay, verify
2. Write $55 to entire region, delay, verify
3. Write repeating 247-byte PRN sequence, delay, verify
4. Write/verify 16 walking bit patterns to entire region
5. Any mismatch indicates RAM or address bus failure

**Error Message Differentiation**:

When Low RAM test fails, different error messages indicate the failure type:

- **"BIT"** - Stuck bit detected by $AA or $55 patterns
  - Shows chip diagram with failed chip(s)
  - System halts (infinite loop)

- **"BUS"** - Address bus failure detected by PRN pattern
  - Indicates crossed/shorted address lines or page confusion
  - No chip diagram shown (not a chip failure)
  - System halts (infinite loop)

- **"BAD"** - Specific chip failure detected by walking bits
  - Shows chip diagram with failed chip(s)
  - System halts (infinite loop)

This differentiation helps diagnose whether the problem is a failed RAM chip or an address bus fault.

**Completeness**: With this test, 100% of Ultimax-accessible RAM is now tested ($0000-$0FFF)

### 5. Screen RAM Test ($0400-$07FF)

**Purpose**: Test 1KB of screen memory

**Features**:

- Non-destructive testing (saves/restores content)
- Tests beyond visible screen area
- Full pattern verification

### 6. Color RAM Test ($D800-$DBFF)

**Purpose**: Test the separate 4-bit color RAM chip

**Special Handling**:

- Only lower 4 bits are valid (masked with `and #$0f`)
- Uses 12-byte pattern suitable for 4-bit values
- Tests all 16 possible colors

### 7. General RAM Test ($0800-$0FFF)

**Purpose**: Thorough byte-by-byte test of remaining lower RAM

**Test Methodology**: Byte-by-byte AA/55/PRN + walking bits testing

**Key Difference**: Different methodology from Memory Bank Test for maximum coverage

**Method (for each address from $0800-$0FFF)**:

1. Write $AA pattern, delay, verify
2. Write $55 pattern, delay, verify
3. Write corresponding PRN byte (based on offset from $0800, mod 247), delay, verify
4. Write each of 16 walking bit patterns, delay, verify
5. Move to next address only after all 19 patterns pass

**Why Byte-by-Byte Approach**:

- **Complementary to page-based testing**: Memory Bank Test uses page-by-page, this uses byte-by-byte
- **Catches different failures**: Immediate write-delay-verify detects timing-sensitive issues
- **Granular detection**: Can pinpoint exact failing address, not just chip
- **Aggressive timing**: Uses shorter delays to catch marginal RAM cells

**Combined Coverage**: The $0800-$0FFF region is tested twice with different methodologies:
1. Memory Bank Test: Page-by-page with all patterns
2. General RAM Test: Byte-by-byte with all patterns

### 8. Font Test

**Purpose**: Verify custom character set loading

- Copies 512 bytes to character RAM
- Ensures character generator works

### 8. Sound Test

**Purpose**: Test SID chip oscillators and envelopes

**Method**:

- Tests each voice sequentially
- 7 different frequencies per voice
- Increasing volume per voice (diagnostic aid)
- ADSR envelope: Attack=3, Decay=E, Sustain=C, Release=A

### 9. Filter Test (Your Addition)

**Purpose**: Test analog filter components

**Why Important**:

- Filters use analog components (capacitors) that degrade
- Failures are subtle and not detected by oscillator tests
- Based on Andrew Challis's SID tester methodology

**Method**:

1. Sweeps filter cutoff frequency (0-255)
2. Tests all filter types (low/band/high-pass)
3. Uses two test frequencies (15 and 45)
4. Gate on/off cycling creates audible sweep
5. Working filters produce characteristic "whoosh" sound

## Visual Enhancements

### 1. Border Color Cycling

- Border color = test counter + 2
- Provides visual progress indication
- Helps identify color generation issues

### 2. Color Reference Bar

- 40-character bar showing all color values
- Located at bottom of screen
- Uses inverted space ($3A) for solid blocks
- Immediate reference for color accuracy

### 3. Chip Location Display

- Visual diagram shows RAM chip positions
- "BAD" appears at failed chip location
- Red color for failed indicators

## CIA Timer Integration

The diagnostic maintains CIA timers for:

- Timing accuracy
- Visual timer display
- Ensures CIA functionality

## Test Flow Summary

```text
1. Initialize (SEI, set processor port)
2. Black screen memory bank test
   → Failure: Flash screen N times for chip N
3. Draw layout (only after RAM verified)
4. Zero page test → Show OK/BAD
5. Stack test → Show OK/BAD
6. Enable JSR/RTS usage
7. Screen RAM test → Show OK/BAD
8. Color RAM test → Show OK/BAD
9. General RAM test → Show OK/BAD
10. Font test (no display)
11. Sound test (audible)
12. Filter test (audible sweep)
13. Increment counter
14. Clear screen and restart
```

## Failure Handling

**Memory Bank Test Failure**:

*Chip Failures (AA/55/Walking Bits patterns)*:
- Screen flashing pattern - counted flashes
- Number of flashes (1-8) = failed chip number
- Pattern repeats continuously: flash N times → pause → repeat
- Infinite loop (system halted)

*Bus Failures (PRN pattern)*:
- Continuous fast flashing (no count pattern)
- No pause between cycles
- Indicates address bus fault (crossed lines, mirroring)
- NOT a chip failure
- Infinite loop (system halted)

**Other Test Failures** (Zero Page, Stack Page, Low RAM, Screen RAM, Color RAM, RAM Test):

- Display "BIT", "BUS", or "BAD" at test location (depending on failure type):
  - **"BIT"** - Stuck bit failure (AA/55 patterns) - shows chip diagram
  - **"BUS"** - Address bus failure (PRN pattern) - no chip diagram
  - **"BAD"** - Specific chip failure (walking bits) - shows chip diagram
- Show failed chip ID in diagram (for BIT and BAD, not BUS)
- Color failed chips red
- Enter infinite loop (deadLoop)

## Memory Map

```text
$0000-$00FF - Zero page (test variables $00-$11)
$0100-$01FF - Stack
$0400-$07FF - Screen RAM
$0800-$0FFF - General RAM / Character set
$D000-$D3FF - VIC-II registers
$D400-$D7FF - SID registers
$D800-$DBFF - Color RAM
$DC00-$DCFF - CIA 1
$DD00-$DDFF - CIA 2
$E000-$FFFF - Diagnostic code (cartridge ROM)
```

## Improvements Over Original

1. **Visual Enhancements**:

   - Color reference bar
   - Border color cycling
   - Better initial colors

2. **Additional Tests**:

   - Comprehensive SID filter test
   - More thorough pattern testing

3. **Code Organization**:

   - Modular file structure
   - Clear separation of concerns
   - Extensive comments and labels
   - Macro usage for common patterns

4. **Diagnostic Aids**:
   - Visual progress indication
   - Better failure identification
   - Enhanced audio feedback

## Potential Future Enhancements

1. **Additional Tests**:

   - CIA timer tests
   - Keyboard matrix test
   - Joystick port test
   - Serial port test
   - Cassette port test

2. **Enhanced Diagnostics**:

   - Test result logging to serial
   - More detailed failure analysis
   - Memory address failure reporting

3. **User Interface**:
   - Test selection menu
   - Continuous vs single-pass mode
   - Detailed help screens
