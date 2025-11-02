#importonce
//=============================================================================
// COMMODORE 64 DEAD TEST DIAGNOSTIC - MAIN ENTRY POINT
//
// Purpose: Comprehensive hardware diagnostic that runs from cartridge ROM
//          Tests all critical C64 components in order of dependency
//          Provides visual/audio feedback even with severely damaged hardware
//=============================================================================

#import "./zeropage_map.asm"

// Code starts at $E000 - Beginning of Ultimax cartridge space
// This overwrites the C64 Kernal ROM area ($E000-$FFFF)
        * = $e000 "Main"

#import "./main_loop.asm"
#import "./data.asm"
#import "./zeropage_map.asm"


//=============================================================================
// CARTRIDGE CONFIGURATION - Ultimax Mode
// GAME = 0, EXROM = 1 - This creates an Ultimax cartridge (16KB at $E000)
// 
// In Ultimax mode:
// - $E000-$FFFF: Cartridge ROM (this code)
// - $8000-$9FFF: Optional cartridge ROM (not used here)
// - $0000-$0FFF: RAM as normal
// - $1000-$7FFF: Open bus (no RAM/ROM)
// - $D000-$DFFF: I/O as normal
//
// This mode ensures the diagnostic runs even if:
// - Kernal ROM is faulty or missing
// - BASIC ROM is faulty
// - High RAM is damaged
//=============================================================================

// Fill unused ROM space with $AA pattern
// This makes unexecuted areas visible in memory dumps
// Calculate fill size: $FFFF - current_address - 6 bytes for vectors
prefill: .fill ($ffff-prefill-5), $aa

//=============================================================================
// HARDWARE VECTORS - Critical for System Control
// These vectors at the top of memory space direct CPU execution
// All point to mainLoop to ensure diagnostic starts regardless of entry
//=============================================================================

         *=$fffa        "Non-Maskable Interrupt Hardware Vector"
         .word mainLoop        // NMI vector - Usually RESTORE key
         
         *=$fffc        "System Reset (RES) Hardware Vector"
         .word mainLoop        // Reset vector - Power on or reset button
         
         *=$fffe        "Maskable Interrupt Request and Break Hardware Vectors"
         .word mainLoop        // IRQ/BRK vector - Timer interrupts

// Note: By setting all vectors to mainLoop, the diagnostic starts
// whether the system is powered on, reset, or an interrupt occurs
// This maximizes the chance of the diagnostic running on damaged hardware
