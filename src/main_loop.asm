#importonce
#import "./zeropage_map.asm"
#import "./constants.asm"
#import "./mem_bank_test.asm"


        * = * "main loop"

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

        memBankTestDone:
                // At this point RAM is working
                // program draw main interface layout
                jmp     drawLayout

        initVic:
                ldx #$2f                        // Init VIC values
        !:      lda vicDefaultValues-1, x
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

                jmp zeroPageTest        // TEST ZERO PAGE

        zeroPageTestDone:
                jmp stackPageTest       // TEST STACK

        stackPageTestDone:              // If here, RAM, Zero Page & Stack are ok
                jsr updateCia1Time      // We can move to JSR and more complex tests
                jsr screenRamTest
                jsr updateCia1Time
                jsr colorRamTest
                jsr updateCia1Time
                jsr ramTest
                jsr updateCia1Time
                jsr fontTest
                jsr updateCia1Time
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

#import "./layout.asm"
#import "./mem_bank_test.asm"
#import "./zero_page_test.asm"
#import "./stack_page_test.asm"
#import "./cia_timers.asm"
#import "./screen_ram_test.asm"
#import "./color_ram_test.asm"
#import "./ram_test.asm"
#import "./font_test.asm"
#import "./sound_test.asm"