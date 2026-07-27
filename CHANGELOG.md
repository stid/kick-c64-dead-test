# Changelog

All notable changes to the C64 Dead Test Diagnostic will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0-beta.1] - 2025 - "Professional Diagnostics Generation"

### 🎯 Why Version 2.0?

This release represents a **paradigm shift** from failure detection to root cause diagnosis. Every RAM test module has been fundamentally rewritten using scientifically rigorous AA/55/PRN patterns, enabling differentiation between stuck bits, address bus faults, and specific chip failures. The methodology aligns with modern memory testing standards (MATS+, galloping patterns) and provides professional-grade diagnostic capability comparable to MemTest86.

**In short:** v1.x detected failures and showed which chip. v2.0 diagnoses root causes and tells you exactly what's wrong and why.

### ✨ Major Enhancements

#### Complete Test Methodology Overhaul
All RAM test modules rewritten with **four-phase AA/55/PRN pattern methodology**:

1. **Phase 1: $AA Pattern (10101010)**
   - Detects stuck-low bits on odd positions
   - Fast detection without complex calculations
   - Industry-standard alternating bit pattern

2. **Phase 2: $55 Pattern (01010101)**
   - Detects stuck-high bits on even positions
   - Complementary to $AA pattern
   - Together catch all stuck-bit failures

3. **Phase 3: 247-byte PRN Sequence**
   - Detects address bus faults (crossed lines, mirroring, decode failures)
   - Prime-like length ensures non-alignment with 256-byte pages
   - Pattern "drifts" through offsets to catch faults aligned tests miss
   - Generated with: `value = ((value * 17) + 137) & 0xFF`, seed = 0x42
   - Credit: Methodology by [Sven Petersen](https://github.com/svenpetersen1965)

4. **Phase 4: 16 Walking Bit Patterns**
   - 8 walking ones: $01, $02, $04, $08, $10, $20, $40, $80
   - 8 walking zeros: $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F
   - Enables precise chip identification (U9-U12, U21-U24)
   - Each pattern isolates a single bit position

#### Error Message Differentiation

**Three distinct error categories** replace generic "BAD" messages:

- **"BIT" Error** - Stuck bit failure detected by AA/55 patterns
  - Indicates one or more bits permanently stuck high or low
  - Shows chip diagram with failed chip(s) highlighted
  - **User action:** Replace identified RAM chip(s)

- **"BUS" Error** - Address bus fault detected by PRN pattern
  - Indicates crossed, shorted, or open address lines
  - Does NOT show chip diagram (not a chip failure)
  - **User action:** Check address line connections, solder joints, motherboard traces

- **"BAD" Error** - Specific chip failure identified by walking bits
  - Individual chip isolated through single-bit patterns
  - Shows chip diagram with failed chip(s) highlighted
  - **User action:** Replace identified RAM chip(s)

#### Memory Bank Test Flash Patterns

Enhanced failure indication during black screen phase:

- **Chip failures:** Counted flashes (1-8) indicate which bit/chip failed
  - Pattern: flash N times → pause → repeat
  - Example: 8 flashes = U21 (bit 0), 1 flash = U12 (bit 7)

- **Bus failures:** Continuous flashing with no count and no pause
  - ~8 Hz white/black cycling, visibly faster than the ~3 Hz counted flash
  - Distinguishes system faults from chip faults
  - Prevents misleading chip identification

### 🔬 Technical Improvements

#### Test Modules Rewritten
- **Memory Bank Test** - Complete rewrite with AA/55/PRN/walking bits (464 line diff)
- **Zero Page Test** - Rewritten with four-phase methodology (195 line diff)
- **Stack Page Test** - Rewritten with four-phase methodology (191 line diff)
- **Low RAM Test** - Added walking bits phase for consistency (250 line diff)
- **RAM Test** - Rewritten with byte-by-byte granular testing (177 line diff)

#### Diagnostic Accuracy
- **XOR-based failure detection** - `actual ^ expected = failed_bits` mathematically identifies exact bits
- **Byte-by-byte testing** - Immediate write-verify catches timing issues
- **Complementary coverage** - Different test methodologies for same memory regions
- **Pattern consistency** - All tests use identical four-phase approach

#### Development Infrastructure
- **TEST_MODE preprocessor support** - Simulates RAM failures for validation
- **Hardware testing guide** - Comprehensive real hardware testing documentation
- **Enhanced comments** - Extensive methodology explanations in source

### 🐛 Fixed During 2.0 Development (never shipped)

The bugs below were introduced while building 2.0 and fixed before release. **None of them
existed in v1.2.0** — they are recorded for development history, not as changes users will
notice. For what actually changed against the last published release, see "What changed in
2.0" in the readme.

#### Walking bits reported the wrong chip
The walking bits verify loops held the *expected* pattern in the accumulator and
used `cmp <memory>`, so at the failure branch the accumulator held
`MemTestPattern[x]` while X was still the pattern index. The handlers then ran
`eor MemTestPattern,x`, XORing a value with itself and always producing 0.

- Memory Bank Test reached `memFailureFlash` with 0, fell through to `ldx #$08`,
  and reported Bank 8 / U21 for **every** failure. This was introduced in 2.0's
  rewrite; v1.2.0's bank test already read memory into the accumulator first and
  decoded single-bit failures correctly.
- Zero Page, Stack Page and Low RAM reached `UFailed` with 0, so `failCheck`
  highlighted no chip at all: "BAD" over an empty chip diagram. For Zero Page and
  Stack Page this bug DID ship in v1.2.0 — it is listed as a genuine user-visible
  fix in the readme, not merely a development-time slip.

Fixed by reading the actual value into the accumulator before comparing against
the expected pattern (`lda <memory>` / `cmp MemTestPattern,x`) — the ordering the
PRN loops and RAM Test already used. The AA/55/PRN handlers were already correct
and are unchanged.

#### TEST_MODE never exercised the walking bits path
Fault injection existed only in the Low RAM `$AA` phase. Since phases run in
order and the first failure halts the test, no build ever reached the walking
bits handler, which is why the above went unnoticed. Added
`TEST_MODE_WALKING_ENABLED` and a `make test-mode-walking` target that leaves
AA/55/PRN passing so phase 4 fails.

#### TEST_MODE validation never validated anything at runtime
`test-mode-validation.sh` passed `-confirmonexit 0`, but `-confirmonexit` is a
boolean flag negated as `+confirmonexit`. VICE parsed the stray `0` as a
positional argument and silently discarded every option after it, including
`-exitscreenshot`. No screenshot was ever produced, and the script reported
PASSED on the missing-screenshot path. It now uses `+confirmonexit`, validates
both TEST_MODE builds, writes screenshots outside `bin/` (which `make clean`
removes between builds), and reports INCOMPLETE rather than PASSED when runtime
output goes unobserved. In CI (`REQUIRE_SCREENSHOT=1`) a missing screenshot is
now a hard failure. That strictness immediately exposed a second layer of the
same problem: the Debian/Ubuntu `vice` package ships without the copyrighted
C64 ROMs, so `x64sc` could never boot in CI at all — the workflow now installs
kernal/basic/chargen from the VICE source mirror (cached, so a transient
network failure does not fail every PR) before running the emulator.

A screenshot still only proved that *a* screen was rendered: a regression back
to "BAD over an empty chip diagram" produces a perfectly valid PNG. The script
now takes a second VICE run per mode with a monitor checkpoint on `UFailed`'s
halt loop, dumps screen RAM at the moment the diagnostic gives up, and
`scripts/check-screen-dump.py` asserts the status word and the U21 mark by
screen code. The `$AA` mode is checked for "BIT" and the walking bits mode for
"BAD" — the two differ by design, and the script's own instructions previously
told the reader to expect "BAD" for both.

#### The bank decode and flash counter had no test coverage at all
`TEST_MODE` injected faults only into the Low RAM test, so `memBankTest`'s
failure path — the bank decode rewritten above and the border flash counter —
had never executed, in CI or anywhere else. That path is the *only* diagnosis
available on a machine too broken to draw a screen, which makes it the one
where a wrong answer costs the most.

Added `TEST_MODE_BANK_ENABLED` (`make test-mode-bank`), injecting a two-bit
fault: single-bit faults were always decoded correctly, so only a multi-bit
injection can tell the old logic from the new. It cannot be checked on screen
(there is none) and VICE's monitor cannot export a CPU register, so the test
build publishes the computed count to `$07E7` and a checkpoint on the flash
loop reads it back. Confirmed it discriminates: with the superseded cascade
restored the probe reads 1 (U12, a good chip), with the current decode it
reads 8 (U21, the actual lowest failing bit).

#### Version file drift
`VERSION` still read 1.3.0 after the 2.0.0 bump. `check-version.sh` did not read
that file, so CI never caught it. Synced to 2.0.0 and added to the check.

#### Memory Bank Test PRN phase could not see cross-page faults
The PRN write loop stored the *same* byte to all 15 pages at each offset, so
every page held identical contents and a swapped or mirrored high address line
(A8-A11) could never produce a mismatch — exactly the fault class the phase
claims to catch. Each page now reads the PRN table through a staggered base
(+0 for $01xx up to +14 for $0Fxx, backed by a 14-byte contiguous extension),
so every page holds a different sequence and page confusion is detectable.

#### RAM Test reported "BUS" it could never prove, and dropped its diagnosis
The byte-by-byte test writes and immediately reads back through the same
address, so an aliased write reads back through the same alias — a bus fault
is unobservable there, and its PRN mismatch is really a pattern-sensitive data
fault. It now reports "BIT" like the other data patterns. Its failure handlers
also computed the failing-bit mask into X and then discarded it; they now mark
the failed chip(s) in the motherboard diagram (via a returning `UMarkChips`)
before continuing with the remaining tests.

#### Multi-bit failures flashed the wrong chip
`memFailureFlash` tested "exactly this bit set" per bank and fell through to
bank 1/U12 for **any** multi-bit difference, blaming a chip that may be fine.
It now flashes the bank of the lowest set bit, so at least one genuinely
failing chip is always reported. The flash loop also recovered its count from
the accumulator only by accident of `LongDelayLoop`'s TXA/TAX save/restore;
the count now stays in X explicitly.

### 📊 Impact & Benefits

#### For Users
- **Root cause diagnosis** - Know exactly what failed and why, not just that something failed
- **Prevents misdiagnosis** - Address bus faults no longer show as chip failures
- **Professional confidence** - Multiple verification passes with different methodologies
- **Better repair guidance** - Specific actions for each error type

#### For Technicians
- **Time savings** - Replace the right component the first time
- **Accurate chip identification** - XOR-based bit mapping is mathematically precise
- **System-level fault detection** - PRN pattern catches issues beyond chip failures
- **Multiple confirmations** - Redundant testing increases diagnostic confidence

#### Technical Excellence
- **Industry alignment** - Follows MemTest86, MATS+, and galloping pattern practices
- **Scientific rigor** - Pattern selection based on failure mode analysis
- **Comprehensive coverage** - Four distinct failure detection mechanisms
- **Professional grade** - Diagnostic capability comparable to commercial tools

### 🙏 Credits & Attribution

- **AA/55/PRN Methodology & 247-byte pattern:** [Sven Petersen](https://github.com/svenpetersen1965)
- **Implementation & testing:** Project maintainers and contributors
- **Inspiration:** Modern memory testing standards (MemTest86, MATS+, IEEE 1149.1)

### 📈 Statistics

- 27 files changed
- 3,580 insertions(+), 401 deletions(-)
- 50 commits since the last published release (v1.2.0)
- All core RAM test modules rewritten
- 100% of RAM tests now use AA/55/PRN methodology

### 🔄 Migration Notes

**Backward Compatibility:** The original tests still run in their original order, but a new
Low RAM test is inserted after the stack test, so every test below it moves down one screen
row. Diagnoses changed too — see "What changed in 2.0" in the readme before comparing a 2.0
screen against an older one.

**Output Changes:** Error messages now differentiate failure types (BIT/BUS/BAD) instead of
showing only "BAD". RAM TEST additionally marks the failing chip and continues rather than
stopping, so a marked chip diagram no longer implies the machine has halted.

**Visual Changes:** Memory Bank Test flash patterns now distinguish chip vs bus failures

**No Hardware Changes Required:** Binary is compatible with all v1.x cartridge configurations

### 🎓 Why This Matters

This release transforms the C64 Dead Test from a basic diagnostic into a professional-grade hardware testing suite. The AA/55/PRN pattern methodology isn't just theoretical improvement - it provides **practical diagnostic value** that helps users identify and fix real hardware failures more accurately and efficiently than ever before.

The differentiation between stuck bits, address bus faults, and chip failures is the key innovation. Rather than showing "U21 BAD" for an address bus fault, v2.0 correctly identifies "BUS error" and prevents wasted time replacing a chip that's actually fine.

---

## [1.3.0] - 2025

### Added
- **Low RAM Test** - New dedicated test module for the $0200-$03FF region, previously covered only by the blind boot-time bank test (test patterns and methodology suggested by [Sven Petersen](https://github.com/svenpetersen1965))
  - Tests 512 bytes between stack page and screen RAM
  - Uses four-phase testing approach:
    1. $AA pattern (10101010) - detects even-bit stuck failures → "BIT" error
    2. $55 pattern (01010101) - detects odd-bit stuck failures → "BIT" error
    3. 247-byte PRN sequence - detects address bus problems and page confusion → "BUS" error
    4. 16 walking bit patterns - enables specific chip identification → "BAD" error
  - Prime-like pattern length ensures detection of mirrored/crossed address lines
  - Error messages differentiate between stuck bits (BIT), address bus faults (BUS), and specific chip failures (BAD)
  - Completes comprehensive RAM coverage of all Ultimax-accessible memory
- Comprehensive open-source documentation structure
- Simplified NOTICE.md with copyright and attribution information
- CONTRIBUTING.md with contributor guidelines
- GitHub Actions workflow for automated builds
- Issue and pull request templates
- Enhanced README with badges and quick start

## [1.2.0] - 2024

### Added
- **SID Filter Test** - New test module for analog filter components
  - Based on Andrew Challis's testing methodology
  - Sweeps filter cutoff frequency (0-255)
  - Tests all filter types (low/band/high-pass)
  - Produces characteristic "whoosh" sound when working
  - Detects failures missed by standard oscillator tests

### Changed
- Improved code organization with better modularization
- Enhanced documentation and comments throughout codebase
- Updated CLAUDE.md for better AI agent interaction

## [1.1.0] - 2023

### Added
- **Color Reference Bar** - Visual color palette at bottom of screen
  - 40-character bar showing all 16 colors
  - Quick reference for identifying color generation issues
  - Uses inverted space character ($3A) for solid blocks

### Changed
- **Border Color Cycling** - Visual progress indicator
  - Border color = test counter + 2
  - Cycles through all 16 colors (0-15) with each iteration
  - Helps identify color generation problems
  - Provides visual feedback that tests are running

## [1.0.0] - 2020-03-29

### Added
- Initial KickAssembler port of Dead Test rev. 781220
- Modular code structure with separate .asm files
- Extensive comments and labels for better understanding
- Macro system for common test patterns
- Modern Makefile build system
- Support for multiple output formats (.prg, .crt, .bin)

### Changed
- Code split into logical modules for maintainability
- Converted from DASM to KickAssembler syntax
- Border and background colors different from original at startup
- Added personal "hacked by" attribution

### Technical Improvements
- LongDelayLoop macro for calibrated timing delays
- Improved chip identification for failed RAM
- Better organization of zero page variables
- Enhanced test pattern implementation

## [Original] - 1988-12-20

### Original Dead Test rev. 781220
- © 1988 Commodore Electronics Limited
- Comprehensive hardware diagnostic for C64
- Tests executed in order of criticality:
  1. Memory Bank Test (black screen phase)
  2. Zero Page Test
  3. Stack Page Test
  4. Screen RAM Test
  5. Color RAM Test
  6. General RAM Test
  7. Font Test
  8. Sound Test
- Visual "OK"/"BAD" indicators
- Chip identification for failed components (U9-U12, U21-U24)
- Continuous loop with iteration counter
- No stack operations before stack test
- Pattern-based memory testing with 20-byte pattern

---

For detailed technical information and attribution, see:
- [Technical Documentation](docs/TECHNICAL_DOCUMENTATION.md)
- [NOTICE.md](NOTICE.md)