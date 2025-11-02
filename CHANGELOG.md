# Changelog

All notable changes to the C64 Dead Test Diagnostic will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive open-source documentation structure
- NOTICE.md with copyright and attribution information
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

## Attribution

### Original Work
- Commodore 64 Dead Test rev. 781220 - © 1988 Commodore Electronics Limited

### Disassembly
- worldofjani.com (2015) - Original disassembly for studying purposes

### This Implementation
- stid - KickAssembler port and enhancements
- Community contributors - See GitHub contributors page

---

For detailed technical information about changes, see [Technical Documentation](docs/TECHNICAL_DOCUMENTATION.md)