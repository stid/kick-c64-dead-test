#importonce
#import "./zeropage.asm"
#import "./constants.asm"
#import "./mem_bank_test.asm"

mainLoop: {
                sei                             // Set Interrupt
                ldx #$ff
                txs
                cld
                lda #$e7                        // Set IO registers
                sta ZProcessPortBit
                lda #$37                        // Set Data direction
                sta ZProcessDataDir

                lda #$00                        // Set video to Black
                sta VIC2_BORDERCOLOUR           // Border color (only bits #0-#3).
                sta VIC2_BGCOLOUR               // Background color (only bits #0-#3).

                jmp memBankTest                 // Ram test first, screen is black here

                // At this point RAM is working
                // program draw main interface layout
        drawLayout:
                lda #<font
                ldx #>font
                sta tmpSourceAddressLow         // Source Address
                stx tmpSourceAddressHigh
                lda #<$0800
                ldx #>$0800
                sta tmpDestAddressLow           // Dest Address
                stx tmpDestAddressHigh
                ldx #$01
                ldy #$00
        fontCopyLoop:
                lda (tmpTargetPointer),y        // Load from source
                sta (tmpDestPointer),y          // Write to dest
                iny
                bne fontCopyLoop
                inc tmpSourceAddressHigh
                inc tmpDestAddressHigh
                dex
                bpl fontCopyLoop                // Loop until -1

                // Clear CIA timers
                // Start from $Dx07 down to $Dx03
                ldx #$04
        !:      lda cia1Table,x
                sta CIA1_TIMER_B_HIGH, x
                lda cia2Table,x
                sta CIA2_TIMER_B_HIGH, x
                dex
                bne !-

                // Reset Counter
                ldx #$00
                stx counterLow
                stx counterHigh


                ldx #$00                        // Cleanup Screen
        clanScreenLoop:
                lda #$20
                sta VIDEO_RAM,x                 // Video Mem
                sta VIDEO_RAM+$100,x
                sta VIDEO_RAM+$200,x
                sta VIDEO_RAM+$300,x

                lda #$06
                sta COLOR_VIDEO_RAM,x           // Color Videa Mem
                sta COLOR_VIDEO_RAM+$100,x
                sta COLOR_VIDEO_RAM+$200,x
                sta COLOR_VIDEO_RAM+$300,x
                inx
                bne clanScreenLoop

                // Upper Box
                ldx #$27
        !:      lda upBox,x                     // Load Box Bytes
                sta VIDEO_RAM+$230,x            // Store in Mem
                lda #BOX_BORDER_COLOR           // Color Red
                sta COLOR_VIDEO_RAM+$230,x
                dex
                bpl !-

                // Box border & Area
                ldx #$00
        !:      lda boxArea,x
                cmp #$ff
                beq boxFill
                sta VIDEO_RAM+$258,x
                inx
                jmp !-

                // Box Color fill
        boxFill:
                ldx #$00
        !:      lda boxColor,x                  // color
                cmp #$ff
                beq drawLowerBox
                sta COLOR_VIDEO_RAM+$258,x
                inx
                jmp !-

                // Lower Box
        drawLowerBox:
                ldx #$27
        !:      lda lowBox,x
                sta VIDEO_RAM+$0348,x
                lda #BOX_BORDER_COLOR           // Color red
                sta COLOR_VIDEO_RAM+$0348,x
                dex
                bpl !-

                // Set CIA timers
                lda #$08
                sta CIA1_CONTROL_TIMER_B
                sta CIA2_CONTROL_TIMER_B
                lda #$48
                sta CIA1_CONTROL_TIMER_A
                lda #$08
                sta CIA2_CONTROL_TIMER_A

                // Init VIC
        initVic:
                ldx #$2f                        // Init VIC values
        !:      lda vicMap-1, x
                sta $cfff, x
                dex
                bne !-

                // Cycle border color based on actual counter
                lda counterLow
                sta VIC2_BORDERCOLOUR

                // About string
                ldx #$1c
        !:      lda strAbout,x
                sta VIDEO_RAM+$6,x
                dex
                bpl !-
                ldx #$04

                // Test Count
        !:      lda strCount,x                  // Print Count Label
                sta VIDEO_RAM+$03c0,x
                dex
                bpl !-

                // Print Count
                lda counterLow
                and #$0f
                ora #$30
                sta VIDEO_RAM+$03c9
                lda counterLow
                lsr
                lsr
                lsr
                lsr
                and #$0f
                ora #$30
                sta VIDEO_RAM+$03c8
                lda counterHigh
                and #$0f
                ora #$30
                sta VIDEO_RAM+$03c7
                lda counterHigh
                lsr
                lsr
                lsr
                lsr
                and #$0f
                ora #$30
                sta VIDEO_RAM+$03c6

                lda #$37
                sta ZProcessPortBit

                jmp zeroPageTest
        goStackPageTest:
                jmp stackPageTest

        testSetB:
                jsr updateCia1Time
                jsr screenRamTest
                jsr updateCia1Time
                jsr colorRamTest
                jsr updateCia1Time
                jsr ramTest
                jsr fontTest
                jsr soundTest

                //                      Prepare to Restart
                sed
                lda #$01
                clc
                adc counterLow
                sta counterLow
                lda #$00
                adc counterHigh
                sta counterHigh
                cld
                lda #$e7
                sta ZProcessPortBit
                lda #$37
                sta ZProcessDataDir

                //  VOLUME OFF
                lda #$00
                sta SID_FILTER_VOL

                //  Clear view
                ldx #$00
                lda #$20
        !:      sta VIDEO_RAM,x
                sta VIDEO_RAM+$100,x
                inx
                bne !-
                ldx #$2e
                lda #$20
        !:      sta VIDEO_RAM+$200,x
                dex
                bpl !-

                jmp mainLoop.initVic
}