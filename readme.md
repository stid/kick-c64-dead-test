# Commodore 64 Dead Test - Kick Assembler Port

[![Build Status](https://github.com/stid/kick-c64-dead-test/workflows/Build%20Dead%20Test/badge.svg)](https://github.com/stid/kick-c64-dead-test/actions)
[![Version](https://img.shields.io/badge/version-1.2.0-blue)](https://github.com/stid/kick-c64-dead-test/releases)
[![Platform](https://img.shields.io/badge/platform-C64%20%7C%20C128-orange)]()

> **Quick Start**: Download the [latest release](https://github.com/stid/kick-c64-dead-test/releases) and burn `dead-test.bin` to an EPROM, or run `dead-test.crt` in VICE.

A comprehensive hardware diagnostic tool for the Commodore 64, designed to test all critical components even when the system is severely damaged. This is an enhanced KickAssembler port of the **COMMODORE 64 Dead Test rev. 781220**, based on the disassembly by [worldofjani.com](https://blog.worldofjani.com/?p=164).

![Running Dead Test](/images/IMG_20200329_152641.png)

## Why This Version?

- ✅ **Enhanced visual feedback** - Color reference bar and border cycling
- ✅ **SID filter test** - Detects analog filter failures missed by other tests  
- ✅ **Modern codebase** - Modular structure with extensive documentation
- ✅ **Preserved compatibility** - Original test logic remains untouched
- ✅ **Open development** - Clear attribution and contribution guidelines

## Quick Start

```bash
# Clone the repository
git clone https://github.com/stid/kick-c64-dead-test.git
cd kick-c64-dead-test

# Build the diagnostic
make

# Run in VICE emulator
make run
```

## Prerequisites

- [KickAssembler](http://theweb.dk/KickAssembler/Main.html#frontpage) should be installed on your system. The makefile expects it at `/Applications/KickAssembler/KickAss.jar` by default. You can override this by setting `KICKASS_BIN` when running make (e.g., `make KICKASS_BIN=/path/to/KickAss.jar`).

- [VICE](https://vice-emu.sourceforge.io/) is required for testing and building. You need:
  - **cartconv** - For converting `.prg` files to `.crt` and `.bin` formats
  - **x64sc** - The C64 emulator for testing
  
  On **macOS**, install VICE via Homebrew: `brew install vice`
  
  The makefile expects these tools to be in your PATH. Run `make check-tools` to verify everything is properly installed.

## Binary Files

Stable releases are published at https://github.com/stid/kick-c64-dead-test/releases. Both CRT and BIN files are available.

## Build, Compile & Run

You should be able to compile the code starting from `src/main.asm` - chunks of the program will be subsequently included.

A convenient makefile is included to simplify the compilation. It will generate a proper .crt image during the build process.

### Basic Usage

```bash
make              # Build the project
make run          # Build and run in VICE emulator
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

## Differences from the Original rev. 781220 Dead Test

The original test logic and sequence remain untouched - it should behave exactly like the original. Below are the main differences between this version and the original rev. 781220:

- **Code has been split** into small chunks and KickAssembler imports are used to include related dependencies. This changes the way the different parts of code are ordered in memory.
- **Border & background colors are different** from the original version at startup. Additionally, the border color cycles through all 16 colors (0-15) with each test execution.
- **A color reference bar** is rendered at the bottom of the screen, just above the counter and timer info. I've found this to be a useful reference for quickly checking color issues when testing a machine.
- **Small optimizations** have been added to the code.
- Compared to the worldofjani.com original disassembly, **constants, labels & comments** have been added to the code. This is definitely something that can be further improved.
- I personalized the about string (**hacked by**) :) - couldn't resist.
- A **sound filters test** was added just after the original sound test. This was suggested in the Facebook group "Commodore 64/128 Programming" and is based on this video: https://www.youtube.com/watch?v=QYgfcvlqIlc&t=1438s. Broken filters are not easily detected with the sound test alone.

## Customizing the Dead Test

You should be able to customize this version quite easily, assuming you have proper assembler knowledge and understand C64 hardware.

**NOTE**: memBankTest, zeroPageTestDone, and stackPageTestDone are executed at startup without using any **JSR** instructions. While you might be tempted to improve the code by using JSR/RTS instead of absolute **JMP** instructions, you must remember that the stack memory has not been tested yet at this stage. This means that using JSR before the stack test can lead to an unrecoverable state, leaving you without any clue about the actual stack failure.

## Test Flow

As mentioned above, the test logic and **flow remain untouched** and should be identical to the Dead Test rev. 781220. This is the high-level flow executed during each test cycle:

1. memBankTest - Black screen; if test fails, jumps to screen blinking and enters infinite loop
2. drawLayout executed - VIC initialized
3. zeroPageTest
4. stackPageTest
5. screenRamTest
6. colorRamTest
7. ramTest
8. fontTest
9. soundTest
10. filtersTest
11. Counter updated, loop to VIC initialization and restart tests

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
