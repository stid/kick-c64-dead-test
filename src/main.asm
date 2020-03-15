#importonce
//-------------------------------------------
// c64 deadtest diagnostic 781220
// original disassembly by worldofjani.com
// Kickassembler porting by =stid=
// Revisited flow by =stid=
//-------------------------------------------
//
#import "./zeropage.asm"
#import "./constants.asm"

        * = $e000 "Main"

#import "./main_loop.asm"
#import "./mem_bank_test.asm"
#import "./zero_page_test.asm"
#import "./stack_page_test.asm"
#import "./cia_timers.asm"
#import "./screen_ram_test.asm"
#import "./color_ram_test.asm"
#import "./ram_test.asm"
#import "./font_test.asm"
#import "./sound_test.asm"


#import "./data.asm"
#import "./zeropage.asm"

prefill:

//      This should be an Util (ROMHI) cartrige
//      GAME = 0, EXROM = 1 - Ultimax Mode, ROMLOW should be ignored
//      C64 Karnel $E000-$FFFF will be overwritten
//      Vectors below will grant start control
.fill ($ffff-prefill-5), $aa

         *=$fffa
         .word mainLoop
         *=$fffc
         .word mainLoop
         *=$fffe
         .word mainLoop

//---------------------------------------
