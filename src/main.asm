#importonce
//-------------------------------------------
// c64 deadtest diagnostic 781220
// original disassembly by worldofjani.com
// Kickassembler porting by =stid=
// Revisited flow by =stid=
//-------------------------------------------
//
#import "./zeropage.asm"

        * = $e000 "Main"


main: {
                sei                     // Set Interrupt
                ldx #$ff
                txs
                cld
                lda #$e7                // Set IO registers
                sta ZProcessPortBit
                lda #$37                // Set Data direction
                sta ZProcessDataDir

                lda #$00                // Set video to Black
                sta $d020               // Border color (only bits #0-#3).
                sta $d021               // Background color (only bits #0-#3).

                jmp memBankTest

                // At this point RAM is working
                // program draw main interface layout
        drawLayout:
                lda #<font
                ldx #>font
                sta tmpSourceAddressLow         // Source Address
                stx tmpSourceAddressHigh
                lda #<$0800
                ldx #>$0800
                sta tmpDestAddressLow         // Dest Address
                stx tmpDestAddressHigh
                ldx #$01
                ldy #$00
        fontCopyLoop:
                lda (tmpTargetPointer),y     // Load from source
                sta (tmpDestPointer),y     // Write to dest
                iny
                bne fontCopyLoop
                inc tmpSourceAddressHigh
                inc tmpDestAddressHigh
                dex
                bpl fontCopyLoop        // Loop until -1

                // Clear CIA timers
                ldx #$04
        !:      lda cia1Table,x
                sta $dc07,x
                lda cia2Table,x
                sta $dd07,x
                dex
                bne !-

                // Reset Counter
                ldx #$00
                stx counterLow
                stx counterHigh


                ldx #$00                // Cleanup Screen
        clanScreenLoop:
                lda #$20
                sta $0400,x             // Video Mem
                sta $0500,x
                sta $0600,x
                sta $0700,x
                lda #$06
                sta $d800,x             // Color Videa Mem
                sta $d900,x
                sta $da00,x
                sta $db00,x
                inx
                bne clanScreenLoop

                // Upper Box
                ldx #$27
        !:      lda upBox,x             // Load Box Bytes
                sta $0630,x             // Store in Mem
                lda #BOX_BORDER_COLOR                // Color Red
                sta $da30,x
                dex
                bpl !-

                // Box border & Area
                ldx #$00
        !:      lda boxArea,x
                cmp #$ff
                beq boxFill
                sta $0658,x
                inx
                jmp !-

                // Box Color fill
        boxFill:
                ldx #$00
        !:      lda boxColor,x      //color
                cmp #$ff
                beq drawLowerBox
                sta $da58,x
                inx
                jmp !-

                // Lower Box
        drawLowerBox:
                ldx #$27
        !:      lda lowBox,x
                sta $0748,x
                lda #BOX_BORDER_COLOR         //Color red
                sta $db48,x
                dex
                bpl !-

                // Set CIA timers
                lda #$08
                sta $dc0f
                sta $dd0f
                lda #$48
                sta $dc0e
                lda #$08
                sta $dd0e

                // Init VIC
        initVic:
                ldx #$2f            // Init VIC values
        !:      lda vicMap-1,x
                sta $cfff,x
                dex
                bne !-

                // About string
                ldx #$16
        !:      lda strAbout,x
                sta $0408,x
                dex
                bpl !-
                ldx #$04

                // Test Count
        !:      lda strCount,x  // Print Count Label
                sta $07c0,x
                dex
                bpl !-

                // Print Count
                lda counterLow
                and #$0f
                ora #$30
                sta $07c9
                lda counterLow
                lsr
                lsr
                lsr
                lsr
                and #$0f
                ora #$30
                sta $07c8
                lda counterHigh
                and #$0f
                ora #$30
                sta $07c7
                lda counterHigh
                lsr
                lsr
                lsr
                lsr
                and #$0f
                ora #$30
                sta $07c6

                lda #$37
                sta ZProcessPortBit
                jmp zeroPageTest
        goStackPageTest:
                jmp stackPageTest

        testSetB:
                jsr updateCia1Time
                jsr screenRamTest        //screen ram test
                jsr updateCia1Time
                jsr colorRamTest        //color ram test
                jsr updateCia1Time
                jsr ramTest             //ram test
                jsr fontTest
                jmp main.initVic
}

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

prefill:

//      This should be an Util (ROMHI) cartrige
//      GAME = 0, EXROM = 1 - Ultimax Mode, ROMLOW should be ignored
//      C64 Karnel $E000-$FFFF will be overwritten
//      Vectors below will grant start control
.fill ($ffff-prefill-5), $aa

         *=$fffa
         .word $e000
         *=$fffc
         .word $e000
         *=$fffe
         .word $e000

//---------------------------------------
//eof