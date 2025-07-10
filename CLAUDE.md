# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Building the project

```bash
make              # Build everything
make clean        # Clean build artifacts
make help         # Show all available commands
```

This compiles the assembly code using KickAssembler, generating:

- `bin/main.prg` - Program file
- `bin/dead-test.crt` - Cartridge format for emulators
- `bin/dead-test.bin` - Binary for EPROM burning

### Running in emulator

```bash
make run          # Build and run in VICE
make debug        # Build and run with VICE monitor
x64sc ./bin/dead-test.crt  # Manual run after build
```

### Makefile variables

You can override these when running make:

```bash
make KICKASS_BIN=/path/to/KickAss.jar  # Custom KickAssembler path
make JAVA=/usr/bin/java                # Custom Java executable
make X64SC=x64                         # Use different C64 emulator
```

### Prerequisites

- KickAssembler must be installed at `/Applications/KickAssembler/KickAss.jar` (update `KICKASS_BIN` in makefile if different)
- VICE emulator for testing and cartridge conversion tools (cartconv, x64sc)
- Java runtime for running KickAssembler

## Architecture Overview

This is a Commodore 64 diagnostic tool that tests hardware components in a specific order without relying on untested systems.

### Test Execution Order

1. **Memory Bank Test** (black screen ~10 seconds) - Tests basic RAM functionality
2. **Layout Drawing** - Initializes display after RAM passes
3. **Zero Page Test** - Tests $00-$FF memory
4. **Stack Page Test** - Tests $0100-$01FF
5. **Screen/Color RAM Tests** - Tests display memory
6. **General RAM Test** - Extended memory testing
7. **Font Test** - Character ROM verification
8. **Sound/Filter Tests** - SID chip testing

### Key Architectural Principles

- **No Stack Before Testing**: Early tests use only JMP instructions, never JSR/RTS
- **Pattern-Based Testing**: Uses 20-byte test pattern for memory verification
- **Visual Feedback**: Shows "OK"/"BAD" results with chip identification (U9-U12, U21-U24)
- **Continuous Loop**: Tests run indefinitely with iteration counter

### Memory Layout

- Code location: $E000-$FFFF (Ultimax cartridge mode)
- Zero page variables: $00-$09 (test counters, temp addresses)
- Critical addresses: Stack ($0100), Screen RAM ($0400), Color RAM ($D800)

### Important Implementation Notes

- Each test module is in a separate `.asm` file
- Failure handling identifies specific RAM chips
- Border color cycles on each test iteration
- Tests must maintain critical-to-less-critical order
