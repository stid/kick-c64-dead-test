# Commodore 64 Dead Test - Kick Assembler Port

[![Build Status](https://github.com/stid/kick-c64-dead-test/workflows/Build%20Dead%20Test/badge.svg)](https://github.com/stid/kick-c64-dead-test/actions)
[![Version](https://img.shields.io/badge/version-2.0.0--beta.1-blue)](https://github.com/stid/kick-c64-dead-test/releases)
[![Platform](https://img.shields.io/badge/platform-C64%20%7C%20C128-orange)]()

> **Quick Start**: Download the [latest release](https://github.com/stid/kick-c64-dead-test/releases) and burn `dead-test.bin` to an EPROM, or run `dead-test.crt` in VICE.

> **2.0.0-beta.1 is a pre-release.** The last published release is
> [v1.2.0](https://github.com/stid/kick-c64-dead-test/releases) (2020). Against that, 2.0
> rewrites how every RAM test decides and reports a failure, and changes three existing
> diagnoses outright. Each new signal is
> covered by an automated test, but all of them are verified against *injected* faults in
> an emulator, never against real failing hardware. See
> [Beta status](#beta-status-what-is-and-is-not-verified). v1.2.0 remains available if you
> would rather diagnose with the version that has years of field use behind it.

A comprehensive hardware diagnostic tool for the Commodore 64, designed to test all critical components even when the system is severely damaged. This is an enhanced KickAssembler port of the **COMMODORE 64 Dead Test rev. 781220**, based on the disassembly by [worldofjani.com](https://blog.worldofjani.com/?p=164).

![Running Dead Test](/images/IMG_20200329_152641.png)

## Why This Version?

- ✅ **Complete RAM coverage** - New dedicated Low RAM test for $0200-$03FF, previously covered only by the blind boot-time bank test
- ✅ **Enhanced visual feedback** - Color reference bar and border cycling
- ✅ **SID filter test** - Detects analog filter failures missed by other tests
- ✅ **Modern codebase** - Modular structure with extensive documentation
- ⚠️ **Rewritten diagnosis logic** - v1.x only *added* tests to the original. v2.0 is the
  first release to change how a failure is diagnosed and reported. See
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

The baseline is **v1.2.0**, the last published release. (A 1.3.0 was version-bumped during
development but never tagged or released — 2.0 superseded it a day later, and its content
is folded into the 2.0 changelog entry.) In v1.2.0 every RAM test used the same 20
walking-bit patterns and had one verdict: the chip diagram, or a counted border flash
before the display existed.

### Diagnoses that changed

| Situation | v1.2.0 said | 2.0 says | Why |
|---|---|---|---|
| **Any failure in Zero Page or Stack Page** | "BAD" over a completely **empty** chip diagram, then halt | "BAD" with the failing chip marked | Those two tests held the *expected* byte in the accumulator and compared it against memory. The failure handler then XORed that value against itself, always got zero, and so marked no chip at all. They never identified a chip — for any fault, on any machine. |
| **Any failure in RAM TEST ($0800-$0FFF)** | "BAD" alone, no chip marked | "BIT" or "BAD" **with the chip marked**, and testing continues | Same shape: the failing-bit mask was computed and then discarded. |
| **Two or more data bits bad at once**, Memory Bank test (black screen) | Border flashed **once** — U12 — whatever the actual fault | Flashes the bank of the lowest failing bit | The old decode asked "is exactly this one bit set?" for each bank in turn and fell through to bank 1 when none matched. Any multi-bit difference reported U12, a chip that may be perfectly good. Single-bit faults decoded correctly then and now, so only multi-bit machines see a different count. |

If you diagnosed a machine with v1.2.0 and got "BAD" with nothing marked in the diagram,
that was not a machine too broken to identify — the tool could not mark a chip in those
tests at all. Worth re-testing.

Note the Memory Bank flash reports **one** chip even when several bits are bad, unlike the
on-screen tests which mark all of them. After replacing the chip it names, it will flash
for the next one. Treat it as sequential, not a complete verdict.

### Everything else is new, not changed

These have no v1.2.0 equivalent, so there is no old answer to compare against — but they
are signals you have not seen from this cartridge before:

- **"BIT" / "BUS" / "BAD"** as three distinct verdicts. v1.2.0 had one failure display.
  BIT is a stuck bit, BAD a chip identified by walking bits, BUS an address bus fault.
- **"BUS" leaves the chip diagram deliberately blank.** A bus fault is not a chip fault;
  marking a chip would send you to replace a good part. An empty diagram under BUS is the
  correct result, not a failure to identify.
- **Continuous border flashing with no count**, during the black screen. A counted flash
  identifies a chip; continuous flashing means page confusion with no single chip to blame.
- **AA/55/PRN pattern phases** in every RAM test, where v1.2.0 used walking bits alone.
  The PRN phase can catch swapped or mirrored address lines that walking bits cannot.
- **A dedicated Low RAM test** ($0200-$03FF), which had no test of its own. (The region
  was not *untested* before — the boot-time bank test covers $0200 and $0300. What is new
  is a byte-by-byte address walk over it.)

### Two things that will look wrong but are not

- **Every test below Low RAM moved down one row.** The new "LOW RAM" line sits at row 4,
  pushing SCREEN RAM, COLOR RAM, RAM TEST, SOUND and FILTERS down one each. If you compare
  a 2.0 screen against an old photo, this is the first difference you will notice.
- **Chip marks now persist across iterations.** RAM TEST is the only test that marks the
  diagram and keeps running, and the end-of-iteration screen clear covers $0400-$062E while
  the diagram sits at $0699-$071E — outside it. So marks stay up and accumulate while the
  counter increments and later tests print OK. Under v1.2.0 a marked diagram always meant
  "halted, replace this chip"; now it can also mean "one bad byte in $0800-$0FFF, still
  testing". Power-cycle to clear them.

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

- **Low RAM Test** (new in 2.0) - Dedicated test for the $0200-$03FF memory region (512 bytes between stack and screen RAM), which previously had no on-screen test of its own (only the blind boot-time bank test covered it). Test patterns and methodology suggested by [Sven Petersen](https://github.com/svenpetersen1965). Uses four test patterns:
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
5. **lowRamTest** - Tests $0200-$03FF with AA/55/PRN patterns (**NEW in 2.0**)
6. **screenRamTest** - Tests $0400-$07FF display memory (original test)
7. **colorRamTest** - Tests $D800-$DBFF color memory (original test)
8. **ramTest** - Tests $0800-$0FFF extended RAM (original test)
9. **fontTest** - Copies the custom font from cartridge ROM to $0800 (original test; a load, not a test — the character ROM is not readable in Ultimax mode)
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
- [LICENSE](LICENSE) - MIT license covering this project's own code
- [NOTICE.md](NOTICE.md) - Copyright and attribution information

## Contributing

We welcome contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Reporting issues
- Submitting pull requests
- Coding standards
- Testing requirements

## Copyright & Attribution

This project's own code is MIT licensed — see [LICENSE](LICENSE). It reimplements the Commodore 64 Dead Test rev. 781220 (© 1988 Commodore), in which no rights are claimed and which is not distributed here. See [NOTICE.md](NOTICE.md) for the full attribution and the ownership chain.

## Potential Bugs

I ported the original source to Kick Assembler and ensured the compiled version matched the original binary byte for byte. After that, I started splitting the code into multiple files and adding macros, constants, and labels. Although I've tested the flow many times, I can't rule out that some bugs may have been introduced in the process.
