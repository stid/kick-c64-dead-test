#importonce
#import "./zeropage_map.asm"
#import "./mem_map.asm"
#import "./const.asm"

.macro failCheck (id, videoPos) {
                txa
                and #id
                beq !+
                lda #$02         //"b"
                sta VIDEO_RAM+videoPos
                lda #$01         //"a"
                sta VIDEO_RAM+videoPos+1
                lda #$04         //"d"
                sta VIDEO_RAM+videoPos+2
                lda #FAIL_COLOR   //red
                sta COLOR_VIDEO_RAM+videoPos
                sta COLOR_VIDEO_RAM+videoPos+1
                sta COLOR_VIDEO_RAM+videoPos+2
        !:      // Exit
}

.namespace UNIT {
        .label U21      = $01
        .label U9       = $02
        .label U22      = $04
        .label U10      = $08
        .label U23      = $10
        .label U11      = $20
        .label U24      = $40
        .label U12      = $80
}

        * = * "u failure"

//////       TEST FAILED U
UFailed: {
        // testU21:
        failCheck(UNIT.U21, $2a4)

        // testU9:
        failCheck(UNIT.U9, $299)

        // testU22:
        failCheck(UNIT.U22, $02cc)

        // testU10:
        failCheck(UNIT.U10, $02c1)

        //  testU23:
        failCheck(UNIT.U23, $02f4)

        // testU11:
        failCheck(UNIT.U11, $02e9)

        //  testU24:
        failCheck(UNIT.U24, $031c)

        // testU12:
        failCheck(UNIT.U12, $0311)

        // Something bad failed - program stop
        deadLoop:
                jmp deadLoop
}