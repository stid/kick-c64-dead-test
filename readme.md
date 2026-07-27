# Commodore 64 Dead Test - Kick Assembler Port

[![Build Status](https://github.com/stid/kick-c64-dead-test/workflows/Build%20Dead%20Test/badge.svg)](https://github.com/stid/kick-c64-dead-test/actions)
[![Version](https://img.shields.io/badge/version-2.0.0--beta.1-blue)](https://github.com/stid/kick-c64-dead-test/releases)
[![Platform](https://img.shields.io/badge/platform-C64%20%7C%20C128-orange)]()

> **Quick Start**: Download the [latest release](https://github.com/stid/kick-c64-dead-test/releases) and burn `dead-test.bin` to an EPROM, or run `dead-test.crt` in VICE.

> **2.0.0-beta.1 is a pre-release.** Every version up to 1.3.0 only *added* tests to the
> original dead test. This one changes how existing tests decide which chip failed and how
> they report it, so a machine you have tested before can give a different answer. The
> changes are believed correct and each one is covered by an automated test, but they have
> been verified only against *injected* faults in an emulator — see
> [Beta status](#beta-status-what-is-and-is-not-verified). If you diagnose real hardware
> with it, 1.3.0 remains available and unchanged.

A comprehensive hardware diagnostic tool for the Commodore 64, designed to test all critical components even when the system is severely damaged. This is an enhanced KickAssembler port of the **COMMODORE 64 Dead Test rev. 781220**, based on the disassembly by [worldofjani.com](https://blog.worldofjani.com/?p=164).

![Running Dead Test](/images/IMG_20200329_152641.png)

## Why This Version?

- ✅ **Complete RAM coverage** - New dedicated Low RAM test for $0200-$03FF, previously covered only by the blind boot-time bank test
- ✅ **Enhanced visual feedback** - Color reference bar and border cycling
- ✅ **SID filter test** - Detects analog filter failures missed by other tests
- ✅ **Modern codebase** - Modular structure with extensive documentation
- ⚠️ **Changed diagnosis logic** - up to v1.x the project only *added* tests. v2.0 is the
  first release to change how existing tests decide and report failures. See
  [What changed in 2.0](#what-changed-in-20-read-this-before-trusting-a-diagnosis).
- ✅ **Open development** - Clear attribution and contribution guidelines

## Quick Start

```bash
# Clone the repository
git clone https://github.com/stid/kick-c64-dead-test.git
cd kick-c64-dead-test

# Build the diagnostic
make

# Run the built cartridge in VICE emulator
make run
```

## Prerequisites

- [KickAssembler](http://theweb.dk/KickAssembler/Main.html#frontpage) should be installed on your system. The makefile expects it at `/Applications/KickAssembler/KickAss.jar` by default. You can override this by setting `KICKASS_BIN` when running make (e.g., `make KICKASS_BIN=/path/to/KickAss.jar`).

- [VICE](https://vice-emu.sourceforge.io/) is required for testing and building. You need:
  - **cartconv** - For converting `.prg` files to `.crt` and `.bin` formats
  - **x64sc** - The C64 emulator for testing
  
  On **macOS**, install VICE via Homebrew: `brew install vice`
  
  The makefile expects these tools to be in your PATH. Run `make check-tools` to verify everything is properly installed.

  On Apple Silicon, running `x64sc` straight from the shell can abort with
  `GLib-GIO-ERROR: No GSettings schemas are installed on the system`. Homebrew puts
  the schemas in `/opt/homebrew/share`, which is not in the macOS default
  `XDG_DATA_DIRS` and which `brew shellenv` does not add. The makefile and
  `scripts/test-mode-validation.sh` point VICE at them, so `make run` works either
  way; to fix it for every GTK app, add this to your shell profile:

  ```bash
  export XDG_DATA_DIRS="/opt/homebrew/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  ```

## Binary Files

Stable releases are published at https://github.com/stid/kick-c64-dead-test/releases. Both CRT and BIN files are available.

## Build, Compile & Run

You should be able to compile the code starting from `src/main.asm` - chunks of the program will be subsequently included.

A convenient makefile is included to simplify the compilation. It will generate a proper .crt image during the build process.

### Basic Usage

```bash
make              # Build the project
make run          # Run the currently built cartridge in VICE (build first)
make build-and-run # Build and run in one step
make clean        # Clean all build artifacts
make help         # Show all available commands
```

### Advanced Usage

```bash
# Use custom KickAssembler path
make KICKASS_BIN=/path/to/KickAss.jar

# Run with VICE monitor for debugging
make debug

# Check if all required tools are installed
make check-tools
```

### Manual Execution

If you prefer to run the emulator manually after building:

```bash
x64sc ./bin/dead-test.crt
```

The dead test should start with the familiar black screen. During this phase, the memory is being tested. The main test view will appear shortly after (it takes around 10 seconds).

## What changed in 2.0 (read this before trusting a diagnosis)

If you have used 1.3.0 or the original rev. 781220, these are the cases where the same
broken machine now gives you a different answer. Everything here is a deliberate change,
not a side effect.

| Situation | 1.3.0 said | 2.0 says | Why |
|---|---|---|---|
| Walking-bits failure in Zero Page, Stack Page or Low RAM | "BAD" over an **empty** chip diagram | "BAD" with the failing chip marked | The handler XORed a value against itself and always got 0, so no chip bit was ever set. It never identified a chip. |
| Walking-bits failure in the Memory Bank test | Border flashed **8 times** (U21) for *every* failure | Flashes the bank that actually failed | Same root cause. On a machine with no display the flash count is the whole diagnosis, so this named the wrong chip with full confidence. |
| Two or more bits bad at once, Memory Bank test | Border flashed **once** (U12) whatever the fault | Flashes the lowest failing bank | The old decode tested "exactly this one bit" per bank and fell through to bank 1 for *any* multi-bit difference — blaming a chip that may be fine. |
| PRN failure in RAM TEST ($0800-$0FFF) | "BUS" | "BIT", chip marked, testing continues | That test writes and reads back through the *same* address, so an aliased write reads back through the same alias. It cannot observe a bus fault, so it should never have claimed one. |
| Address line A8-A11 swapped or mirrored | Memory Bank PRN phase **passed** | Fails, continuous border flash | The PRN phase wrote identical bytes to all 15 pages, so page confusion could not produce a mismatch — the exact fault class the phase exists to catch. Each page now gets a different sequence. |

Two failure signals are **new in 2.0** and have no equivalent in the original — if you have
never seen them, that is why:

- **"BUS"** displayed with the chip diagram left deliberately blank. A bus fault is not a
  chip fault; marking a chip would send you to replace a good part.
- **Continuous border flashing with no count**, during the black-screen phase. A counted
  flash identifies a chip; continuous flashing means page confusion with no single chip to
  blame.

## Beta status: what is and is not verified

**Verified.** Every failure signal the cartridge can produce — "BIT", "BAD", "BUS", the
counted border flash and the continuous one — is exercised by an automated test that runs
in CI, reads the result back out of screen RAM or a probe byte, and asserts the exact
diagnosis. The bank decode fix is confirmed to *discriminate*: with the superseded logic
restored, the test fails.

**Not verified.** All of it is checked against faults *injected* into an emulator. VICE's
memory never actually fails. Real DRAM fails in ways injection does not reproduce —
marginal cells, temperature-dependent faults, several chips degrading at once. The
multi-bit decode in particular only matters in exactly the scenario emulation cannot
create. No amount of CI closes this gap; only real broken hardware does.

That is why this is a beta. If you run it against a machine whose fault you have already
confirmed by other means, a report either way is genuinely useful.

## Differences from the Original rev. 781220 Dead Test

The test sequence still follows the original. The *diagnosis* logic no longer does — see
[What changed in 2.0](#what-changed-in-20-read-this-before-trusting-a-diagnosis) for the
failure reporting that changed in this release. Below are the enhancements and differences
between this version and the original rev. 781220:

### New Tests (Not in Original)

- **Low RAM Test** (v1.3.0) - Dedicated test for the $0200-$03FF memory region (512 bytes between stack and screen RAM), which previously had no on-screen test of its own (only the blind boot-time bank test covered it). Test patterns and methodology suggested by [Sven Petersen](https://github.com/svenpetersen1965). Uses four test patterns:
  - `$AA` pattern (10101010) - Detects stuck-high bits on even positions
  - `$55` pattern (01010101) - Detects stuck-low bits on odd positions
  - 247-byte PRN sequence - Detects address bus problems and page confusion (prime-like length ensures non-alignment with 256-byte pages to catch mirrored or crossed address lines)
  - 16 walking bit patterns - Enables specific chip identification (8 walking ones + 8 walking zeros)

- **Sound Filters Test** (v1.2.0) - Tests SID analog filters which are prone to capacitor aging. Based on Andrew Challis's methodology (video: https://www.youtube.com/watch?v=QYgfcvlqIlc&t=1438s). Broken filters are often not detected by the basic oscillator test alone.

### Visual Enhancements

- **Border color cycling** - Border cycles through all 16 colors (0-15) with each test iteration
- **Color reference bar** - Rendered at bottom of screen for quick color output verification
- **Border & background colors** differ from the original at startup

### Code Improvements

- **Modular structure** - Code split into separate files using KickAssembler imports
- **Enhanced documentation** - Extensive comments, constants, and labels added
- **Small optimizations** throughout the codebase
- Personalized the about string (**hacked by**) :)

## Customizing the Dead Test

You should be able to customize this version quite easily, assuming you have proper assembler knowledge and understand C64 hardware.

**NOTE**: memBankTest, zeroPageTestDone, and stackPageTestDone are executed at startup without using any **JSR** instructions. While you might be tempted to improve the code by using JSR/RTS instead of absolute **JMP** instructions, you must remember that the stack memory has not been tested yet at this stage. This means that using JSR before the stack test can lead to an unrecoverable state, leaving you without any clue about the actual stack failure.

## Test Flow

The original test logic remains preserved, with new tests inserted at appropriate points. This is the complete flow executed during each test cycle:

1. **memBankTest** - Black screen (~10 seconds); if test fails, screen blinks and enters infinite loop
2. **drawLayout** - VIC initialized, screen layout drawn
3. **zeroPageTest** - Tests $00-$FF (original test)
4. **stackPageTest** - Tests $0100-$01FF, enables JSR/RTS after passing (original test)
5. **lowRamTest** - Tests $0200-$03FF with AA/55/PRN patterns (**NEW in v1.3.0**)
6. **screenRamTest** - Tests $0400-$07FF display memory (original test)
7. **colorRamTest** - Tests $D800-$DBFF color memory (original test)
8. **ramTest** - Tests $0800-$0FFF extended RAM (original test)
9. **fontTest** - Verifies character ROM (original test)
10. **soundTest** - Tests SID oscillators (original test)
11. **filtersTest** - Tests SID analog filters (**NEW in v1.2.0**)
12. Counter updated, border color incremented, loop back to step 2

## Understanding Error Messages

When a RAM test fails, the diagnostic displays specific error messages to help identify the problem type:

### Error Message Types

| Message | Meaning | Cause | Chip Diagram | Action |
|---------|---------|-------|--------------|--------|
| **BIT** | Stuck bit failure | One or more bits permanently stuck high or low (detected by $AA/$55 patterns) | ✅ Shows failed chip(s) | Replace identified RAM chip(s) |
| **BUS** | Address bus fault | Crossed, shorted, or open address lines (detected by PRN pattern) | ❌ No diagram | Check address line connections and solder joints |
| **BAD** | Specific chip failure | Individual chip identified by walking bits test | ✅ Shows failed chip(s) | Replace identified RAM chip(s) |

### Memory Bank Test Flash Patterns

During the initial black screen phase (~10 seconds), failures are indicated by border flashing:

**Chip Failures** - Counted flashes (1-8) indicate which chip failed:
- 1 flash = U12 (bit 7)
- 2 flashes = U24 (bit 6)
- 3 flashes = U11 (bit 5)
- 4 flashes = U23 (bit 4)
- 5 flashes = U10 (bit 3)
- 6 flashes = U22 (bit 2)
- 7 flashes = U9 (bit 1)
- 8 flashes = U21 (bit 0)
- Pattern repeats: flash N times → pause → repeat

**Bus Failures** - Continuous rapid flashing with no pattern:
- Fast white/black flashing with no pause between cycles
- Indicates address bus fault (crossed lines, mirroring, page confusion)
- NOT a chip failure - check motherboard traces and solder connections

## Burning EPROM & Compatible Cartridge

The `make` command will generate a `.bin` file ready to be burned onto an **EPROM**. I was able to successfully burn the Dead Test onto an **M2764A**. You can also use the faster and easily erasable/rewritable **2W27C512**, but you need to ensure the code is positioned at the 256KB offset. You can concatenate the 8KB bin file 32 times to fill the cartridge with cloned code up to the 256KB offset. The **27C256** should also work, but I haven't tried it myself.

![Image of Cartridge](/images/IMG_20200329_152721.png)

I used a [HomeBrew development cartridge](https://www.ebay.com/sch/i.html?_from=R40&_trksid=m570.l1313&_nkw=commodore+64+HomeBrew+DEVelopment+cartridge&_sacat=0) to install the EPROM.
You need to have an 8K setup with GAME = 0, EXROM = 1, Ultimax Mode. ROMLOW should be ignored - this should be a Util (ROMHI) cartridge.

You can also buy a pre-assembled Dead Test **"DEAD TEST DIAGNOSTIC cartridge 781220"** and replace the EPROM (or burn over it if you don't mind losing the original version).

You can definitely try to build your [own](http://blog.worldofjani.com/?p=879).

**WARNING:** While this program will probably never harm your C64/128, a poorly assembled cartridge potentially could. Keep this in mind if you build your own. If you're not comfortable with soldering, boards, and jumpers, I strongly recommend buying a pre-assembled Dead Test Cartridge on eBay or from one of the many retro stores (ensure it's rev. 781220) and simply swap the existing EPROM with your custom version.

## Documentation

- [Technical Documentation](docs/TECHNICAL_DOCUMENTATION.md) - Detailed test algorithms and hardware information
- [CONTRIBUTING.md](CONTRIBUTING.md) - Guidelines for contributors
- [CHANGELOG.md](CHANGELOG.md) - Version history and changes
- [NOTICE.md](NOTICE.md) - Copyright and attribution information

## Contributing

We welcome contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Reporting issues
- Submitting pull requests
- Coding standards
- Testing requirements

## Copyright & Attribution

Based on Commodore 64 Dead Test rev. 781220 (© 1988 Commodore). See [NOTICE.md](NOTICE.md) for full copyright information and permitted uses.

## Potential Bugs

I ported the original source to Kick Assembler and ensured the compiled version matched the original binary byte for byte. After that, I started splitting the code into multiple files and adding macros, constants, and labels. Although I've tested the flow many times, I can't rule out that some bugs may have been introduced in the process.
