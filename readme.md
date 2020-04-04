# Commodore 64 Dead Test - Kick assembler port

This is a kick assembler adapted and slight personalized version of the **COMMODORE 64 Dead Test rev. 781220**.
It's based on the Original disassembly by worldofjani.com. The pre existing test logic is in fact untouched.

If you just need to test your machine, I strongly suggest to go with the original version. This version is mainly useful if you want to understand the logic behind the tests and add your personal touch to them.

![Running Dead Test](/images/IMG_20200329_152641.png)


## Prerequisites

- [kickassembler](http://theweb.dk/KickAssembler/Main.html#frontpage) should be installed in your system. Also if you use the provided makefile, you need to ensure it will be in same path as `KICKASS_BIN` is pointing at. You can update this variable to match your needs of course.

- [vice](https://vice-emu.sourceforge.io/) is the recommended way to test the compiled `.crt` file and is also required to convert the `.prg` output to crt and then bin. If you are on **MacOS** like me, best option is to use the brew version of vice. The make file assume **cartconv** is available in the execution path. Note as an alternative path you can generate the bin from the prg by just  remove the first two bytes in it.

## Build, Compile & run

You should be able to compile the code starring from `src/main.asm` - chunks of the program will be subsequently included.

A convenient makefile was included to simplify the compilation, it will generate a proper .crt image via build.

``` bash
make
```

To execute the generated .crt via **VICE** (I'm using brew installed version of VICE on MacOS):

``` bash
x64sc ./bin/dead-test.crt
```

The dead test should start with the common black screen, during this phase, the memory is tested. The common test view will show up just after (it will take around 10 seconds).

## Differences with the original rev. 781220 dead test

The original test logic & sequence is in fact untouched, it should act as the original. Below are the main differences between this version and the original rev. 781220:

- **Code has been split** in small chunks and kickassembler imports are used to include related dependencies. This change the way the different parts of code are ordered in memory.
- **Border & Background colors are different** from the original version at start. Also the border color will cycle (0-255) at every test execution.
- **A color reference bar** is rendered at the bottom of the screen, just above the counter and timers info. I have found this to be a good reference to fast check color issues when testing a machine.
- Very **small optimizations** were added to the code.
- compared to the worldofjani.com original disassembly, **constants, labels & comments** has been added on the code. Definitely something that cab  be further improved.
- I personalized (**hacked** by) the about string :) - didn't resist.
- Sound Filters test was added just after the original sound test. This was pointed out in the facebook group "Commodore 64/128 programming" and based on this video: https://www.youtube.com/watch?v=QYgfcvlqIlc&t=1438s. Broken filters are not easy to be spotted with the sound only test.

## Customizing the Dead Test

You should be able to customize this version very easily, assuming proper assembler knowledge & C64 hardware.

**NOTE**: memBankTest, zeroPageTestDone & stackPageTestDone are execute at start without using any **JSR**. As much as you might be tempted to improve the code a bit by JSR / RTS instead of using absolute **JMP**, you should keep care of the fact that the stack memory is not tested yet at this stage and this means a JSR used before the stack test can lead to a unrecoverable state - leaving you without any clue about the effective stack failure.

## Test Flow

As mentioned above, test logic and **flow is untouched** and should be identical to the Dead Test rev. 781220. These is the high level flow executed on any test cycle:

1. memBankTest - clack screen, if test fail, jump to screen blinking and go in infinite loop
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

## Burning EPROM & compatible Cartridge

The `make` will generate a `.bin` file ready to be burned on an **EPROM**. I was able to successfully burn the Dead Test on a **M2764A**. You can also use the faster and easy to be erased/rewritten **2W27C512**, but you need to ensure the code is positioned at 256Kb offset. You can concat the 8k bin 33 times to just fill the cartridge with cloned code up to the 256k offset. **27C256** should also work but I didn't try it myself.

![Image of Cartridge](/images/IMG_20200329_152721.png)

I used a [HomeBrew development cartridge](https://www.ebay.com/sch/i.html?_from=R40&_trksid=m570.l1313&_nkw=commodore+64+HomeBrew+DEVelopment+cartridge&_sacat=0) to install the related EPROM.
You need to have an 8K setup with GAME = 0, EXROM = 1, Ultimax Mode, ROMLOW should be ignored - This should be an Util (ROMHI) cartrige.

You can also buy a pre assembled Dead Test **"DEAD TEST DIAGNOSTIC cartridge 781220"** and substitute the related EPROM (or burn over it if you don't mind loosing the original version).

You can definitely try to build your [own](http://blog.worldofjani.com/?p=879).

**WARNING:** As much as this program will probably never be able to harm your C64/128, a bad assembled cartridge can potentially do. Keep this in mind if you go on your own. If you are not comfortable with soldering, boards & jumpers, I strongly recommend to buy a pre assembled Dead Test Cartridge on e-bay or on one of the many retro stores (ensure rev. 781220) and just swap the pre existing EPROM with your custom version.

## Potential bugs

I ported the original source to kick assembler and ensured the compiled version matched 1:1 with the original bin - byte to byte. After that I started splitting the code in multiple files, adding macros, constants & labels. As much as I tested the flow many times I can't exclude some bug has been introduced in the process.
