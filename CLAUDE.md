# CLAUDE.md

## Project Summary
Commodore 64 hardware diagnostic tool running as Ultimax cartridge ($E000-$FFFF). Tests RAM, ROM, and SID systematically without relying on untested components. Uses visual feedback to identify specific failed chips (U9-U12, U21-U24).

## Quick Start
```bash
make         # Build .prg, .crt, and .bin files
make run     # Build and launch in VICE emulator
make debug   # Build and run with VICE monitor
make clean   # Remove all build artifacts
make help    # Show all available targets
```
**Output files:** `bin/main.prg` (program), `bin/dead-test.crt` (cartridge), `bin/dead-test.bin` (EPROM)

## Project Structure
```
src/
├── main.asm           # Entry point, cartridge setup
├── main_loop.asm      # Test orchestration and iteration control
├── layout.asm         # Screen layout initialization
├── macros.asm         # Common test patterns and utilities
├── *_test.asm         # Individual hardware test modules:
│   ├── mem_bank_test.asm    # Initial RAM bank verification
│   ├── zero_page_test.asm   # $00-$FF testing
│   ├── stack_page_test.asm  # $0100-$01FF testing
│   ├── screen_ram_test.asm  # $0400 display memory
│   ├── color_ram_test.asm   # $D800 color memory
│   ├── ram_test.asm          # General RAM testing
│   ├── font_test.asm         # Character ROM verification
│   ├── sound_test.asm        # SID chip testing
│   └── filters_test.asm      # SID filter testing
├── u_failure.asm      # Chip failure identification logic
├── *_map.asm          # Memory definitions:
│   ├── mem_map.asm           # Memory layout constants
│   └── zeropage_map.asm      # Zero page variable allocation
└── data.asm           # Test patterns and constants
```

## Critical Constraints

⚠️ **MUST FOLLOW - Violations will cause crashes:**
- **NEVER use JSR/RTS before stack test completes** - Use only JMP instructions
- **NEVER modify $00-$11** - Reserved for test state variables
- **ALWAYS maintain test order** - Critical components first (RAM → Stack → Display → ROM → Sound)
- **Pattern-based testing** - All tests use 20-byte pattern from `data.asm`

## Test Flow

```
1. Memory Bank Test    → Black screen ~10 seconds (initial RAM test)
2. Layout Drawing      → Display initialized only after RAM passes
3. Zero Page Test      → Tests $00-$FF (critical for variables)
4. Stack Page Test     → Tests $0100-$01FF (enables JSR/RTS usage)
5. Screen RAM Test     → Tests $0400 display memory
6. Color RAM Test      → Tests $D800 color attributes
7. General RAM Test    → Extended memory testing
8. Font Test           → Character ROM verification
9. Sound/Filter Tests  → SID chip testing
```
Border color cycles on each iteration. Tests run continuously with iteration counter.

## Memory Map

| Address | Usage | Notes |
|---------|-------|-------|
| $00-$11 | Test variables | DO NOT MODIFY during tests |
| $0100-$01FF | Stack | Not available until stack test passes |
| $0400 | Screen RAM | 1000 bytes display memory |
| $D800 | Color RAM | 1000 bytes color attributes |
| $E000-$FFFF | Code | Ultimax cartridge ROM space |

## Build Configuration

Override defaults with: `make VARIABLE=value`
- `KICKASS_BIN`: KickAssembler path (default: `/Applications/KickAssembler/KickAss.jar`)
- `JAVA`: Java executable (default: `java`)
- `X64SC`: VICE emulator binary (default: `x64sc`)

## References

- **Installation & Prerequisites:** See `README.md`
- **Detailed Test Algorithms:** See `TECHNICAL_DOCUMENTATION.md`
- **Makefile Options:** Run `make help`
- **VICE Documentation:** [https://vice-emu.sourceforge.io/](https://vice-emu.sourceforge.io/)
