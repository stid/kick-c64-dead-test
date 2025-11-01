# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Commodore 64 hardware diagnostic tool** (Dead Test) that systematically tests all critical C64 components (RAM, CPU, VIC-II, SID, CIA) even when the system is severely damaged. It runs as an Ultimax cartridge and performs tests in order from most-to-least critical without relying on untested systems.

**Key fact**: This is assembly code for 6502 CPU that gets compiled to a cartridge ROM image for physical C64 hardware.

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

## File Organization

### Source Structure

```
src/
├── main.asm              - Entry point, includes all other modules
├── const.asm             - Hardware constants (VIC, SID, CIA registers)
├── macros.asm            - Reusable assembly macros
├── mem_map.asm           - Memory layout definitions
├── zeropage_map.asm      - Zero page variable definitions
├── data.asm              - Static data (fonts, test patterns)
├── mem_bank_test.asm     - Initial black screen RAM test
├── zero_page_test.asm    - Tests $00-$FF
├── stack_page_test.asm   - Tests $0100-$01FF (enables JSR/RTS after)
├── screen_ram_test.asm   - Tests display memory
├── color_ram_test.asm    - Tests color memory
├── ram_test.asm          - General RAM testing
├── font_test.asm         - Character set verification
├── sound_test.asm        - SID oscillator tests
├── filters_test.asm      - SID filter tests (added feature)
├── layout.asm            - Screen layout and display
├── u_failure.asm         - Failure handling (chip ID display)
└── main_loop.asm         - Main test loop coordinator
```

### Build Artifacts

- `bin/main.prg` - Raw program file (intermediate)
- `bin/dead-test.crt` - Cartridge format for emulators (VICE)
- `bin/dead-test.bin` - Binary for burning to EPROM (physical cartridge)

### Documentation

- `CLAUDE.md` - This file (quick reference for Claude Code)
- `TECHNICAL_DOCUMENTATION.md` - Detailed technical analysis of all tests
- `readme.md` - User-facing project documentation

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

## Development Workflow

### Making Changes Safely

1. **Before modifying code:**
   - Run `make` to ensure current code builds successfully
   - Review `TECHNICAL_DOCUMENTATION.md` for detailed test logic if modifying tests
   - Understand which test phase you're modifying (pre-stack vs post-stack)

2. **After making changes:**
   - Build: `make clean && make`
   - Test in emulator: `make run`
   - Verify the test completes at least one full cycle (watch counter increment)
   - Check that border color cycles through colors

3. **Testing changes:**
   - Watch for the ~10 second black screen (memory bank test)
   - Verify layout appears correctly
   - Confirm all tests show "OK" status
   - Listen for sound/filter test audio output

### Critical Constraints When Modifying

**DO NOT:**
- Use JSR/RTS/PHA/PLA in `mem_bank_test.asm`, `zero_page_test.asm`, or `stack_page_test.asm`
- Change the test execution order (it's carefully sequenced)
- Modify zero page variables $00-$11 (used by test framework)
- Remove or skip the stack page test
- Assume the stack works before `stackPageTestDone` completes

**DO:**
- Use only JMP for control flow in pre-stack tests
- Preserve existing test patterns (20-byte pattern is thoroughly tested)
- Maintain the "critical-to-less-critical" test order
- Add new tests AFTER stack page test (so JSR/RTS are safe)
- Update this documentation when adding new tests

### Common Modification Tasks

**Adding a new test:**
1. Create new `.asm` file in `src/`
2. Add test call in `src/main_loop.asm` AFTER `stackPageTestDone`
3. Include the file in `src/main.asm`
4. Add screen layout position in `src/layout.asm` if needed
5. Update test count and border color logic if applicable

**Modifying colors/visuals:**
- Screen colors: `src/layout.asm`
- Border color: `src/main_loop.asm` (cycles through 16 colors)
- Color reference bar: `src/layout.asm` (bottom of screen)

**Modifying sound tests:**
- Oscillator tests: `src/sound_test.asm`
- Filter tests: `src/filters_test.asm`
- Both use SID registers defined in `src/const.asm`

### Assembly Language Notes

This is **6502 assembly** (KickAssembler syntax):
- Labels end with colon: `label:`
- Comments use `//` or `/* */`
- Hexadecimal uses `$` prefix: `$D020` (not `0xD020`)
- Binary uses `%` prefix: `%10101010`
- Includes use `#import "file.asm"`

## Troubleshooting

### Build Issues

**"KickAssembler not found"**
- Update `KICKASS_BIN` path in makefile or set via environment:
  ```bash
  make KICKASS_BIN=/path/to/KickAss.jar
  ```

**"cartconv not found"**
- Install VICE emulator: `brew install vice` (macOS)
- Ensure VICE tools are in PATH

**Assembly errors**
- Check `bin/buildlog.txt` for detailed error messages
- Verify all included files exist in `src/`
- Check for syntax errors (missing commas, incorrect hex format)

### Runtime Issues

**Black screen forever (>15 seconds)**
- Memory bank test is failing
- Try different emulator settings
- Check if ROM is loading correctly ($E000-$FFFF)

**Tests show "BAD"**
- This is expected in emulator (perfect memory)
- On real hardware: indicates failed chip
- Check emulator isn't simulating memory faults

**No sound during tests**
- Ensure emulator audio is enabled
- Check SID chip emulation is active
- Volume should increase with each voice test

## Additional Resources

- **Detailed test analysis**: See `TECHNICAL_DOCUMENTATION.md`
- **User guide**: See `readme.md`
- **Original test**: Based on Dead Test rev. 781220
- **KickAssembler docs**: http://theweb.dk/KickAssembler/
- **C64 hardware reference**: https://www.c64-wiki.com/
