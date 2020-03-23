#importonce
#import "./zeropage_map.asm"
#import "./mem_map.asm"
#import "./data.asm"
#import "./main_loop.asm"


        * = * "layout"


drawLayout: {
            lda #<font
            ldx #>font
            sta ZP.tmpSourceAddressLow         // Source Address
            stx ZP.tmpSourceAddressHigh
            lda #<$0800
            ldx #>$0800
            sta ZP.tmpDestAddressLow           // Dest Address
            stx ZP.tmpDestAddressHigh
            ldx #$01
            ldy #$00
    fontCopyLoop:
            lda (ZP.tmpSourceAddressLow),y        // Load from source
            sta (ZP.tmpDestAddressLow),y          // Write to dest
            iny
            bne fontCopyLoop
            inc ZP.tmpSourceAddressHigh
            inc ZP.tmpDestAddressHigh
            dex
            bpl fontCopyLoop                // Loop until -1

            // Clear CIA timers
            // Start from $Dx07 down to $Dx03
            ldx #$04
    !:      lda cia1Table,x
            sta CIA1.TIMER_B_HIGH, x
            lda cia2Table,x
            sta CIA2.TIMER_B_HIGH, x
            dex
            bne !-

            // Reset Counter
            ldx #$00
            stx ZP.counterLow
            stx ZP.counterHigh

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
            sta CIA1.CONTROL_TIMER_B
            sta CIA2.CONTROL_TIMER_B
            lda #$48
            sta CIA1.CONTROL_TIMER_A
            lda #$08
            sta CIA2.CONTROL_TIMER_A

             ldx #39
      !:     txa
             sta COLOR_VIDEO_RAM+$398, x
             lda #$3a
             sta VIDEO_RAM+$398, x
             dex
             bpl !-

            jmp mainLoop.initVic            // Stack not tested yet, we need to explicit JMP back
}