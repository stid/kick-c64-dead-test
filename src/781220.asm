//-------------------------------------------
// c64 deadtest diagnostic 781220
// original disassembly by worldofjani.com
// Kickassembler porting by =stid=
//-------------------------------------------
//
.const ZProcessDataDir          = $00    // 6510 CPU's data direction I/O port register; 0 = input, 1 = output
.const ZProcessPortBit          = $01    // 6510 CPU's on-chip port register
//
.const counterLow               = $02
.const counterHigh              = $03
.const tmpSourceAddressLow      = $09
.const tmpSourceAddressHigh     = $0a
.const tmpDestAddressLow        = $0b
.const tmpDestAddressHigh       = $0c
.const tmpY                     = $10
//
.const tmpTargetPointer         = $09
.const tmpDestPointer           = $0b
//
.const  FAIL_COLOR              = $02
.const  BOX_BORDER_COLOR        = $02


.macro LongDelayLoop (xRep, yRep) {
                txa
                ldx #xRep
                ldy #yRep
        !:      dey
                bne !-
                dex
                bne !-
                tax
}

.macro ShortDelayLoop (xRep) {
                txa
                ldx #xRep
        !:      dex
                bne !-
                tax
}

//---------------------------------------
        * = $e000 "Main"


///////      MAIN
main: {
                sei                     // Set Interrupt
                ldx #$ff
                txs
                cld
                lda #$e7                // Set IO registers
                sta ZProcessPortBit
                lda #$37                // Set Data direction
                sta ZProcessDataDir
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

}


///////      FONT TESTS
        lda #<font
        ldx #>font
        sta tmpSourceAddressLow
        stx tmpSourceAddressHigh
        lda #<$0800
        ldx #>$0800
        sta tmpDestAddressLow
        stx tmpDestAddressHigh
        ldx #$01
        ldy #$00
copyFontLoop:
        lda (tmpTargetPointer),y
        sta (tmpDestPointer),y
        iny
        bne copyFontLoop
        inc tmpSourceAddressHigh
        inc tmpDestAddressHigh
        dex
        bpl copyFontLoop
        jsr updateCia1Time

        jsr soundTest        // sound test



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
        lda #$00
        sta $d418
        ldx #$00
        lda #$20
!:      sta $0400,x
        sta $0500,x
        inx
        bne !-
        ldx #$2e
        lda #$20
!:      sta $0600,x
        dex
        bpl !-
        jmp main.initVic        // Loop & Restart test


///////      MEMORY BANK TEST
memBankTest: {
                lda #$00                // Set video to Black
                sta $d020               // Border color (only bits #0-#3).
                sta $d021               // Background color (only bits #0-#3).

                // prepare memory
                ldx #$15                // MemPattern Lenght is 20 - start at 21 here to dec later
                ldy #$00                // reset loop counter

        memPatternSetLoop:
                lda MemTestPattern,x    // Load pattern byte
                sta $0100,y             // Store in mem chunks, will fill
                sta $0200,y
                sta $0300,y
                sta $0400,y
                sta $0500,y
                sta $0600,y
                sta $0700,y
                sta $0800,y
                sta $0900,y
                sta $0a00,y
                sta $0b00,y
                sta $0c00,y
                sta $0d00,y
                sta $0e00,y
                sta $0f00,y
                iny
                bne memPatternSetLoop   // Loop to FF

                LongDelayLoop(0,0)

                // Compare previous stored mem pattern
                // Against related mem chunks
        memPatternCompLoop:
                lda $0100,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0200,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0300,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0400,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0500,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0600,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0700,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0800,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0900,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0a00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0b00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0c00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0d00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0e00,y
                cmp MemTestPattern,x
                bne memTestFailed
                lda $0f00,y
                cmp MemTestPattern,x
                bne memTestFailed
                iny
                beq memTestPassed       // Test done, no issues
                jmp memPatternCompLoop  // Loop over FF range

        memTestFailed:
                jmp memFailureFlash     // Memory Pattern Test failed

        memTestPassed:
                dex                     // Dec X to loade next pattern byte
                bmi memTestDone         // Done? - exit loop
                ldy #$00                // Reset Y counter
                jmp memPatternSetLoop   // back to pattern loop with new x pointer

        memTestDone:
                jmp main.drawLayout     //memtest ok, go to next stage


        memFailureFlash: {
                                        // Given actual pattern, indentify what's failed
                // Bank 8 Failed
                        eor MemTestPattern,x
                        tax
                        and #$fe
                        bne bank7Fail
                        ldx #$08
                        jmp flash        //mem error flash

                bank7Fail:
                        txa
                        and #$fd
                        bne bank6Fail
                        ldx #$07
                        jmp flash        //mem error flash

                bank6Fail:
                        txa
                        and #$fb
                        bne bank5Fail
                        ldx #$06
                        jmp flash        //mem error flash

                bank5Fail:
                        txa
                        and #$f7
                        bne bank4Fail
                        ldx #$05
                        jmp flash        //mem error flash

                bank4Fail:
                        txa
                        and #$ef
                        bne bank3Fail
                        ldx #$04
                        jmp flash        //mem error flash

                bank3Fail:
                        txa
                        and #$df
                        bne bank2Fail
                        ldx #$03
                        jmp flash        //mem error flash

                bank2Fail:
                        txa
                        and #$bf
                        bne bank1Fail
                        ldx #$02
                        jmp flash        //mem error flash

                bank1Fail:
                        ldx #$01         //mem error flash
        }


        flash: {
                        txs
                flashLoop:              // Infinite Flash Loop
                        lda #$01        // set Screen to White
                        sta $d020
                        sta $d021

                        LongDelayLoop($7f,0)

                        lda #$00        // set Screen to Black
                        sta $d020
                        sta $d021

                        LongDelayLoop($7f,0)

                !:      dey
                        bne !-
                        dex
                        bne !-
                        tax
                        dex
                        beq endLoopDelay       // Flash Loop End
                        jmp flashLoop

                        // End flash cycle Long Delay
                endLoopDelay:
                        ldx #$00
                        ldy #$00
                !:      dey
                        bne !-
                        dex
                        bne !-
                !:      dey
                        bne !-
                        dex
                        bne !-
                !:      dey
                        bne !-
                        dex
                        bne !-
                !:      dey
                        bne !-
                        dex
                        bne !-
                        tsx
                        jmp flashLoop           // Back to main loop
        }
}


///////      ZERO PAGE TEST
zeroPageTest: {
                ldx #$08
        !:      lda strZero,x   // Print Zero Page String
                sta $0450,x
                dex
                bpl !-

                // Start filling Zero Page with mem pattern's byte
                ldx #$13
        zeroPagePatternLoop:
                lda MemTestPattern,x
                ldy #$12
        !:      sta $0000,y
                iny
                bne !-

                LongDelayLoop(0,0)

                // Check Zero Page mem consistency
                lda MemTestPattern,x
                ldy #$12
        !:      cmp $0000,y
                bne zeroPagePatternFailed
                iny
                bne !-
                dex
                bpl zeroPagePatternLoop

                // Zero Page Pattern Test OK
                lda #$0f         //"o"
                sta $045d
                lda #$0b         //"k"
                sta $045e
                jmp main.goStackPageTest

                // Zero Page Pattern Test BAD
        zeroPagePatternFailed:
                eor MemTestPattern,x
                tax
                lda #$02         //"b"
                sta $045d
                lda #$01         //"a"
                sta $045e
                lda #$04         //"d"
                sta $045f
                jmp testU
}


///////      STACK TRACE TEST
stackPageTest: {
                ldx #$09
        !:      lda strStack,x      // stack page label
                sta $0478,x
                dex
                bpl !-

                ldx #$13
        stackPagePatternLoop:
                lda MemTestPattern,x
                ldy #$00
        !:      sta $0100,y
                iny
                bne !-

                LongDelayLoop(0,0)

                // Test Stack Pattern consistency
                tax
                lda MemTestPattern,x
        !:      cmp $0100,y
                bne stackPageFailed
                iny
                bne !-
                dex
                bpl stackPagePatternLoop
                lda #$0f         //"o"
                sta $0485
                lda #$0b         //"k"
                sta $0486
                jmp main.testSetB       // Done with stack - progress to next chunk of tests

        stackPageFailed:
                eor MemTestPattern,x      //memtest pattern
                tax
                lda #$02         //"b"
                sta $0485
                lda #$01         //"a"
                sta $0486
                lda #$04         //"d"
                sta $0487
                jmp testU
}


///////      SCREEN RAM TEST
screenRamTest: {
                ldx #$09
        !:      lda strScreen,x      //screen ram label
                sta $04a0,x
                dex
                bpl !-

                ldx #<$0400
                ldy #>$0400
                stx tmpSourceAddressLow
                sty tmpSourceAddressHigh
        screenRamTestLoop:
                ldy #$00
                lda (tmpTargetPointer),y
                pha
                ldx #$13
        screenRamPatternTestLoop:
                lda MemTestPattern,x
                sta (tmpTargetPointer),y

                ShortDelayLoop(0)

                lda (tmpTargetPointer),y
                cmp MemTestPattern,x
                bne screenRamTestFailed
                dex
                bpl screenRamPatternTestLoop
                pla
                sta (tmpTargetPointer),y
                inc tmpSourceAddressLow
                bne !+
                inc tmpSourceAddressHigh         // > 255

        !:  lda tmpSourceAddressHigh
                cmp #$08
                bne screenRamTestLoop
                lda #$0f         //"o"
                sta $04ad
                lda #$0b         //"k"
                sta $04ae
                rts

        screenRamTestFailed:
                eor MemTestPattern,x
                tax
                lda #$02         //"b"
                sta $04ad
                lda #$01         //"a"
                sta $04ae
                lda #$04         //"d"
                sta $04af
                jsr testU
}


///////      COLOR RAM TEST
colorRamTest: {
                ldx #$08
        !:      lda srtColor,x      // Print color ram test
                sta $04c8,x
                dex
                bpl !-

                ldx #<$d800
                ldy #>$d800
                stx tmpSourceAddressLow
                sty tmpSourceAddressHigh
                ldy #$00
        colorRamTestLoop:
                ldy #$00
                lda (tmpTargetPointer),y
                pha
                ldx #$0b
        colorRamPattermTestLoop:
                lda colorRamPattern,x
                sta (tmpTargetPointer),y

                ShortDelayLoop(0)

                lda (tmpTargetPointer),y
                and #$0f
                cmp colorRamPattern,x
                bne colorRamTestFailed
                dex
                bpl colorRamPattermTestLoop
                pla
                sta (tmpTargetPointer),y
                inc tmpSourceAddressLow
                bne !+          // > 255
                inc tmpSourceAddressHigh
        !:      lda tmpSourceAddressHigh
                cmp #$dc
                bne colorRamTestLoop
                lda #$0f         //"o"
                sta $04d5
                lda #$0b         //"k"
                sta $04d6
                rts

        colorRamTestFailed:
                eor colorRamPattern,x
                tax
                lda #$02         //"b"
                sta $04d5
                lda #$01         //"a"
                sta $04d6
                lda #$04         //"d"
                sta $04d7
                jmp testU
}

///////      RAM TEST
ramTest: {

                ldx #$07
        !:      lda strRam,x      // ram test label
                sta $04f0,x
                dex
                bpl !-

                ldx #<$0800
                ldy #>$0800
                stx tmpSourceAddressLow
                sty tmpSourceAddressHigh
        RamTestLoop:
                ldy #$00
                ldx #$13
        RamTestPatternLoop:
                lda MemTestPattern,x
                sta (tmpTargetPointer),y

                ShortDelayLoop($7f)

                lda (tmpTargetPointer),y
                cmp MemTestPattern,x
                bne RamTestFailed
                dex
                bpl RamTestPatternLoop
                inc tmpSourceAddressLow
                bne !+
                inc tmpSourceAddressHigh         // > 255
        !:      lda tmpSourceAddressHigh
                cmp #$10
                bne RamTestLoop
                lda #$0f         //"o"
                sta $04fd
                lda #$0b         //"k"
                sta $04fe
                rts

        RamTestFailed:
                eor MemTestPattern,x
                tax
                lda #$02         //"b"
                sta $04fd
                lda #$01         //"a"
                sta $04fe
                lda #$04         //"d"
                sta $04ff
}

//////       TEST FAILED U
testU: {
        testU21:
                txa
                and #$01
                beq testU9
                lda #$02         //"b"
                sta $06a4
                lda #$01         //"a"
                sta $06a5
                lda #$04         //"d"
                sta $06a6
                lda #FAIL_COLOR   //red
                sta $daa4
                sta $daa5
                sta $daa6

        testU9:
                txa
                and #$02
                beq testU22
                lda #$02         //"b"
                sta $0699
                lda #$01         //"a"
                sta $069a
                lda #$04         //"d"
                sta $069b
                lda #FAIL_COLOR   //red
                sta $da99
                sta $da9a
                sta $da9b

        testU22:
                txa
                and #$04
                beq testU10
                lda #$02         //"b"
                sta $06cc
                lda #$01         //"a"
                sta $06cd
                lda #$04         //"d"
                sta $06ce
                lda #FAIL_COLOR   //red
                sta $dacc
                sta $dacd
                sta $dace

        testU10:
                txa
                and #$08
                beq testU23
                lda #$02         //"b"
                sta $06c1
                lda #$01         //"a"
                sta $06c2
                lda #$04         //"d"
                sta $06c3
                lda #FAIL_COLOR   //red
                sta $dac1
                sta $dac2
                sta $dac3

        testU23:
                txa
                and #$10
                beq testU11
                lda #$02         //"b"
                sta $06f4
                lda #$01         //"a"
                sta $06f5
                lda #$04         //"d"
                sta $06f6
                lda #FAIL_COLOR   //red
                sta $daf4
                sta $daf5
                sta $daf6

        testU11:
                txa
                and #$20
                beq testU24
                lda #$02         //"b"
                sta $06e9
                lda #$01         //"a"
                sta $06ea
                lda #$04         //"d"
                sta $06eb
                lda #FAIL_COLOR   //red
                sta $dae9
                sta $daea
                sta $daeb

        testU24:
                txa
                and #$40
                beq testU12
                lda #$02         //"b"
                sta $071c
                lda #$01         //"a"
                sta $071d
                lda #$04         //"d"
                sta $071e
                lda #FAIL_COLOR   //red
                sta $db1c
                sta $db1d
                sta $db1e

        testU12:
                txa
                and #$80
                beq deadLoop
                lda #$02         //"b"
                sta $0711
                lda #$01         //"a"
                sta $0712
                lda #$04         //"d"
                sta $0713
                lda #FAIL_COLOR   //red
                sta $db11
                sta $db12
                sta $db13

                // Something bad failed - program stop
        deadLoop:
                jmp deadLoop
}

soundTest: {
                ldx #$09
        !:      lda strSound,x      //label sound test
                sta $0518,x
                dex
                bpl !-

                lda #$14
                sta $d418
                lda #$00
                sta $d417
                lda #$3e
                sta $d405
                lda #$ca
                sta $d406
                lda #$00
                sta $d412
                lda #$02
        mainLoop:
                pha
                ldx #$06
        loopA:  lda sound1,x
                sta $d401
                lda sound2,x
                sta $d400
                pla
                tay
                lda sound8,y
                sta $d402
                lda sound9,y
                sta $d403
                lda sound7,y
                sta $d404
                tya
                pha
                lda #$6a
                jsr pauseOrExit
                lda #$00
                sta $d404
                lda #$00
                jsr pauseOrExit
                dex
                bne loopA
                lda #$00
                sta $d417
                lda #$18
                sta $d418
                lda #$3e
                sta $d40c
                lda #$ca
                sta $d40d
                ldx #$06
        loopB:  lda sound3,x
                sta $d408
                lda sound4,x
                sta $d407
                pla
                tay
                lda sound8,y
                sta $d409
                lda sound9,y
                sta $d40a
                lda sound7,y
                sta $d40b
                tya
                pha
                lda #$6a
                jsr pauseOrExit
                lda #$00
                sta $d40b
                lda #$00
                jsr pauseOrExit
                dex
                bne loopB
                lda #$00
                sta $d417
                lda #$1f
                sta $d418
                lda #$3e
                sta $d413
                lda #$ca
                sta $d414
                ldx #$06
        loopC:  lda sound5,x
                sta $d40f
                lda sound6,x
                sta $d40e
                pla
                tay
                lda sound8,y
                sta $d410
                lda sound9,y
                sta $d411
                lda sound7,y
                sta $d412
                tya
                pha
                lda #$6a
                jsr pauseOrExit
                lda #$00
                sta $d412
                lda #$00
                jsr pauseOrExit
                dex
                bne loopC
                pla
                tay
                dey
                tya
                bmi !+
                jmp mainLoop
        !:      rts

        pauseOrExit:
                cmp #$00
                beq done
                tay
                txa
                pha
                tya
                tax
        delayLoop:
                ldy #$ff
        !:      dey
                bne !-
                dex
                bne delayLoop
                pla
                tax
        done:   rts
}

        //not referenced?
        lda #$37
        sta ZProcessPortBit
        lda #$48
        sta $dc0e
        lda #$08
        sta $dd0e

/////////////// TIMERS

// CIA 1
updateCia1Time: {
                lda $dc0b
                clc
                asl
                bcc setAm
                lda #$10         //"p"
                sta $07db
                lda #$0d         //"m"
                sta $07dc
                clc
                bcc !+
        setAm:  lda #$01         //"a"
                sta $07db
                lda #$0d         //"m"
                sta $07dc
        !:      lda $dc0b
                and #$7f
                ldy #$01
                bne calcTime
        setHour:
                sta $07d3        //xx-00-00
                stx $07d4
                lda #$2d         //"-"
                sta $07d5
                lda $dc0a
                ldy #$02
                bne calcTime
        setMinute:
                sta $07d6        //00-xx-00
                stx $07d7
                lda #$2d         //"-"
                sta $07d8
                lda $dc09
                ldy #$03
                bne calcTime
        setSecond:
                sta $07d9        //00-00-xx
                stx $07da
                lda $dc08

                clc
                bcc UpdateCia2Time
                ldy #$00
}


calcTime:  {
                pha
                sty tmpY
                ldy #$04
                bne done
        loop:   ldy tmpY
                tax
                pla
                lsr
                lsr
                lsr
                lsr
        done:   and #$0f
                cmp #$0a
                bmi ie74c
                sec
                sbc #$09
                bne !+
        ie74c:  ora #$30
        !:      cpy #$01
                beq updateCia1Time.setHour
                cpy #$02
                beq updateCia1Time.setMinute
                cpy #$03
                beq updateCia1Time.setSecond
                cpy #$04
                beq loop
                cpy #$05
                beq UpdateCia2Time.setHour
                cpy #$06
                beq UpdateCia2Time.setMinue
                cpy #$07
                beq UpdateCia2Time.setSecond
                rts
}


// CIA 2
UpdateCia2Time: {
                lda $dd0b
                clc
                asl
                bcc setAm
                lda #$10         //"p"
                sta $07e6
                lda #$0d         //"m"
                sta $07e7
                clc
                bcc !+
        setAm:  lda #$01         //"a"
                sta $07e6
                lda #$0d         //"m"
                sta $07e7
        !:  lda $dd0b
                and #$7f
                ldy #$05
        ie790:  bne calcTime
        setHour:
                sta $07de        //xx-00-00
                stx $07df
                lda #$2d         //"-"
                sta $07e0
                lda $dd0a
                ldy #$06
                bne ie790
        setMinue:
                sta $07e1        //00-xx-00
                stx $07e2
                lda #$2d         //"-"
                sta $07e3
                lda $dd09
                ldy #$07
                bne ie790
        setSecond:
                sta $07e4        //00-00-xx
                stx $07e5
                lda $dd08
                rts
}


vicMap:
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$1b,$00,$00,$00,$00,$08,$00
        .byte $12,$00,$00,$00,$00,$00,$00,$00
        .byte $03,$01,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00

cia1Table:  .byte $00,$00,$00,$00
cia2Table:  .byte $00,$00,$00,$00,$80

MemTestPattern:
        .byte $00,$55,$aa,$ff,$01,$02,$04,$08     // memtest pattern
        .byte $10,$20,$40,$80,$fe,$fd,$fb,$f7     //
        .byte $ef,$df,$bf,$7f                     //

colorRamPattern:  .byte $00,$05,$0a,$0f,$01,$02,$04,$08
        .byte $0e,$0d,$0b,$07


.encoding "screencode_mixed"
strAbout:   .text "c-64 dead test rev stid"
strCount:   .text "count"
strZero:    .text "zero page"
strStack:   .text "stack page"
strRam:     .text "ram test"
srtColor:   .text "color ram"
strSound:   .text "sound test"
strScreen:  .text "screen ram"

sound1:  .byte $11,$15,$19,$22,$19,$15,$11         // soundtest
sound2:  .byte $25,$9a,$b1,$4b,$b1,$9a,$25         //
sound3:  .byte $22,$2b,$33,$44,$33,$2b,$22         //
sound4:  .byte $4b,$34,$61,$95,$61,$34,$4b         //
sound5:  .byte $44,$56,$66,$89,$66,$56,$44         //
sound6:  .byte $95,$69,$c2,$2b,$c2,$69,$95         //
sound7:  .byte $45,$11,$25                         //
sound8:  .byte $00,$00,$00                         //
sound9:  .byte $08,$00,$00,$09,$00,$28,$ff,$1f     //
         .byte $af                                 //


upBox:   .byte $20,$20,$20,$20,$20,$20,$20,$20     // box upper part
        .byte $20,$20,$20,$20,$20,$20,$22,$26
        .byte $26,$26,$26,$26,$26,$26,$26,$26
        .byte $26,$26,$26,$26,$26,$26,$26,$26
        .byte $26,$26,$26,$26,$26,$26,$26,$23

boxArea:   .byte $20,$20,$20,$20,$20,$20,$20,$20     // box text. 4164 etc.
        .byte $20,$20,$20,$20,$20,$20,$27,$20
        .byte $20,$20,$20,$20,$20,$20,$20,$20
        .byte $20,$20,$34,$31,$36,$34,$20,$20
        .byte $20,$20,$20,$20,$20,$20,$20,$27
        .byte $20,$20,$20,$20,$20,$20,$20,$20
        .byte $20,$20,$20,$20,$20,$20,$27,$20
        .byte $20,$20,$20,$20,$15,$39,$20,$20
        .byte $20,$20,$20,$20,$20,$20,$20,$15
        .byte $32,$31,$20,$20,$20,$20,$20,$27
        .byte $20,$20,$20,$20,$20,$20,$20,$20
        .byte $20,$20,$20,$20,$20,$20,$27,$20
        .byte $20,$20,$20,$20,$15,$31,$30,$20
        .byte $20,$20,$20,$20,$20,$20,$20,$15
        .byte $32,$32,$20,$20,$20,$20,$20,$27
        .byte $20,$20,$20,$20,$20,$20,$20,$20
        .byte $20,$20,$20,$20,$20,$20,$27,$20
        .byte $20,$20,$20,$20,$15,$31,$31,$20
        .byte $20,$20,$20,$20,$20,$20,$20,$15
        .byte $32,$33,$20,$20,$20,$20,$20,$27
        .byte $20,$20,$20,$20,$20,$20,$20,$20
        .byte $20,$20,$20,$20,$20,$20,$27,$20
        .byte $20,$20,$20,$20,$15,$31,$32,$20
        .byte $20,$20,$20,$20,$20,$20,$20,$15
        .byte $32,$34,$20,$20,$20,$20,$20,$27
        .byte $20,$20,$20,$20,$20,$20,$20,$20
        .byte $20,$20,$20,$20,$20,$20,$27,$20
        .byte $20,$20,$20,$20,$20,$20,$20,$20
        .byte $20,$20,$20,$20,$20,$20,$20,$20
        .byte $20,$20,$20,$20,$20,$20,$20,$27
        .byte $ff

boxColor:  .byte $06,$06,$06,$06,$06,$06,$06,$06     //color
        .byte $06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,$06
        .byte $06,$06,$06,$06,$06,$06,$06,BOX_BORDER_COLOR
        .byte $ff

lowBox:  .byte $20,$20,$20,$20,$20,$20,$20,$20     //box lower part
        .byte $20,$20,$20,$20,$20,$20,$24,$26
        .byte $26,$26,$26,$26,$26,$26,$26,$26
        .byte $26,$26,$26,$26,$26,$26,$26,$26
        .byte $26,$26,$26,$26,$26,$26,$26,$25

font:  .byte $00,$00,$00,$00,$00,$00,$00,$00     //font
        .byte $7e,$42,$42,$7e,$46,$46,$46,$00
        .byte $7e,$62,$62,$7e,$62,$62,$7e,$00
        .byte $7e,$42,$40,$40,$40,$42,$7e,$00
        .byte $7e,$42,$42,$62,$62,$62,$7e,$00
        .byte $7e,$60,$60,$78,$70,$70,$7e,$00
        .byte $7e,$60,$60,$78,$70,$70,$70,$00
        .byte $7e,$42,$40,$6e,$62,$62,$7e,$00
        .byte $42,$42,$42,$7e,$62,$62,$62,$00
        .byte $10,$10,$10,$18,$18,$18,$18,$00
        .byte $04,$04,$04,$06,$06,$66,$7e,$00
        .byte $42,$44,$48,$7e,$66,$66,$66,$00
        .byte $40,$40,$40,$60,$60,$60,$7e,$00
        .byte $43,$67,$5b,$43,$43,$43,$43,$00
        .byte $e2,$d2,$ca,$c6,$c2,$c2,$c2,$00
        .byte $7e,$42,$42,$46,$46,$46,$7e,$00
        .byte $7e,$42,$42,$7e,$60,$60,$60,$00
        .byte $7e,$42,$42,$62,$6a,$66,$7e,$00
        .byte $7e,$42,$42,$7e,$68,$64,$62,$00
        .byte $7e,$42,$40,$7e,$02,$62,$7e,$00
        .byte $7e,$18,$18,$18,$18,$18,$18,$00
        .byte $62,$62,$62,$62,$62,$62,$3c,$00
        .byte $62,$62,$62,$62,$62,$24,$18,$00
        .byte $c2,$c2,$c2,$c2,$da,$e6,$c2,$00
        .byte $62,$62,$24,$18,$24,$62,$62,$00
        .byte $62,$62,$62,$34,$18,$18,$18,$00
        .byte $7f,$03,$06,$08,$10,$60,$7f,$00
        .byte $3c,$30,$30,$30,$30,$30,$3c,$00
        .byte $0e,$10,$30,$fe,$30,$60,$ff,$00
        .byte $3c,$0c,$0c,$0c,$0c,$0c,$3c,$00
        .byte $00,$18,$3c,$7e,$18,$18,$18,$18
        .byte $00,$10,$30,$7f,$7f,$30,$10,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $0e,$0e,$60,$60,$60,$60,$0e,$0e
        .byte $00,$00,$00,$07,$0f,$1c,$18,$18
        .byte $00,$00,$00,$e0,$f0,$38,$18,$18
        .byte $18,$18,$1c,$0f,$07,$00,$00,$00
        .byte $18,$18,$38,$f0,$e0,$00,$00,$00
        .byte $00,$00,$00,$ff,$ff,$00,$00,$00
        .byte $18,$18,$18,$18,$18,$18,$18,$18
        .byte $0c,$18,$30,$30,$30,$18,$0c,$00
        .byte $30,$18,$0c,$0c,$0c,$18,$30,$00
        .byte $00,$66,$3c,$ff,$3c,$66,$00,$00
        .byte $00,$18,$18,$7e,$18,$18,$00,$00
        .byte $00,$00,$00,$00,$00,$18,$18,$30
        .byte $00,$00,$00,$7e,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$18,$18,$00
        .byte $00,$03,$06,$0c,$18,$30,$60,$00
        .byte $7e,$42,$42,$42,$42,$42,$7e,$00
        .byte $30,$30,$10,$10,$3c,$3c,$3c,$00
        .byte $7e,$02,$02,$7e,$40,$40,$7e,$00
        .byte $7e,$02,$02,$7e,$06,$06,$7e,$00
        .byte $60,$60,$60,$66,$7e,$06,$06,$00
        .byte $7e,$40,$40,$7e,$02,$02,$7e,$00
        .byte $78,$48,$40,$7e,$42,$42,$7e,$00
        .byte $7e,$42,$04,$08,$08,$08,$08,$00
        .byte $3c,$24,$24,$3c,$66,$66,$7e,$00
        .byte $7e,$42,$42,$7e,$06,$06,$06,$00
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