# Changelog

All notable changes to the C64 Dead Test Diagnostic will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2025 - "Professional Diagnostics Generation"

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

- **Bus failures:** Continuous rapid flashing with no pattern
  - Fast white/black cycling with no pause
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

- 10 files changed
- 1,020 insertions(+), 299 deletions(-)
- 16 commits since 1.3.0
- All core RAM test modules rewritten
- 100% of RAM tests now use AA/55/PRN methodology

### 🔄 Migration Notes

**Backward Compatibility:** Test sequence unchanged - all tests run in the same order as v1.x

**Output Changes:** Error messages now differentiate failure types (BIT/BUS/BAD) instead of showing only "BAD"

**Visual Changes:** Memory Bank Test flash patterns now distinguish chip vs bus failures

**No Hardware Changes Required:** Binary is compatible with all v1.x cartridge configurations

### 🎓 Why This Matters

This release transforms the C64 Dead Test from a basic diagnostic into a professional-grade hardware testing suite. The AA/55/PRN pattern methodology isn't just theoretical improvement - it provides **practical diagnostic value** that helps users identify and fix real hardware failures more accurately and efficiently than ever before.

The differentiation between stuck bits, address bus faults, and chip failures is the key innovation. Rather than showing "U21 BAD" for an address bus fault, v2.0 correctly identifies "BUS error" and prevents wasted time replacing a chip that's actually fine.

---

## [1.3.0] - 2025

### Added
- **Low RAM Test** - New test module for previously untested $0200-$03FF region (test patterns and methodology suggested by [Sven Petersen](https://github.com/svenpetersen1965))
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