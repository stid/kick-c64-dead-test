#importonce
//-------------------------------------------
// c64 deadtest diagnostic 781220
// original disassembly by worldofjani.com
// Kickassembler porting by =stid=
// Revisited flow by =stid=
//-------------------------------------------
//
#import "./zeropage_map.asm"

        * = $e000 "Main"

#import "./main_loop.asm"
#import "./data.asm"
#import "./zeropage_map.asm"


//      This should be an Util (ROMHI) cartrige
//      GAME = 0, EXROM = 1 - Ultimax Mode, ROMLOW should be ignored
//      C64 Karnel $E000-$FFFF will be overwritten
//      Vectors below will grant start control
prefill: .fill ($ffff-prefill-5), $aa

         *=$fffa        "Non-Maskable Interrupt Hardware Vector"
         .word mainLoop
         *=$fffc        "System Reset (RES) Hardware Vector"
         .word mainLoop
         *=$fffe        "Maskable Interrupt Request and Break Hardware Vectors"
         .word mainLoop

//---------------------------------------
