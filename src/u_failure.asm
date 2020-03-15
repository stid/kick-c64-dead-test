#importonce
#import "./zeropage.asm"
#import "./constants.asm"

//////       TEST FAILED U
testU: {
        testU21:
                txa
                and #$01
                beq testU9
                lda #$02         //"b"
                sta VIDEO_RAM+$2a4
                lda #$01         //"a"
                sta VIDEO_RAM+$2a5
                lda #$04         //"d"
                sta VIDEO_RAM+$2a6
                lda #FAIL_COLOR   //red
                sta COLOR_VIDEO_RAM+$2a4
                sta COLOR_VIDEO_RAM+$2a5
                sta COLOR_VIDEO_RAM+$2a6

        testU9:
                txa
                and #$02
                beq testU22
                lda #$02         //"b"
                sta VIDEO_RAM+$299
                lda #$01         //"a"
                sta VIDEO_RAM+$29a
                lda #$04         //"d"
                sta VIDEO_RAM+$29b
                lda #FAIL_COLOR   //red
                sta COLOR_VIDEO_RAM+$299
                sta COLOR_VIDEO_RAM+$29a
                sta COLOR_VIDEO_RAM+$29b

        testU22:
                txa
                and #$04
                beq testU10
                lda #$02         //"b"
                sta VIDEO_RAM+$02cc
                lda #$01         //"a"
                sta VIDEO_RAM+$02cd
                lda #$04         //"d"
                sta VIDEO_RAM+$02ce
                lda #FAIL_COLOR   //red
                sta COLOR_VIDEO_RAM+$02cc
                sta COLOR_VIDEO_RAM+$02cd
                sta COLOR_VIDEO_RAM+$02ce

        testU10:
                txa
                and #$08
                beq testU23
                lda #$02         //"b"
                sta VIDEO_RAM+$02c1
                lda #$01         //"a"
                sta VIDEO_RAM+$02c2
                lda #$04         //"d"
                sta VIDEO_RAM+$02c3
                lda #FAIL_COLOR   //red
                sta COLOR_VIDEO_RAM+$2c1
                sta COLOR_VIDEO_RAM+$2c2
                sta COLOR_VIDEO_RAM+$2c3

        testU23:
                txa
                and #$10
                beq testU11
                lda #$02         //"b"
                sta VIDEO_RAM+$02f4
                lda #$01         //"a"
                sta VIDEO_RAM+$02f5
                lda #$04         //"d"
                sta VIDEO_RAM+$02f6
                lda #FAIL_COLOR   //red
                sta COLOR_VIDEO_RAM+$2f4
                sta COLOR_VIDEO_RAM+$2f5
                sta COLOR_VIDEO_RAM+$2f6

        testU11:
                txa
                and #$20
                beq testU24
                lda #$02         //"b"
                sta VIDEO_RAM+$02e9
                lda #$01         //"a"
                sta VIDEO_RAM+$02ea
                lda #$04         //"d"
                sta VIDEO_RAM+$02eb
                lda #FAIL_COLOR   //red
                sta COLOR_VIDEO_RAM+$2e9
                sta COLOR_VIDEO_RAM+$2ea
                sta COLOR_VIDEO_RAM+$2eb

        testU24:
                txa
                and #$40
                beq testU12
                lda #$02         //"b"
                sta VIDEO_RAM+$031c
                lda #$01         //"a"
                sta VIDEO_RAM+$031d
                lda #$04         //"d"
                sta VIDEO_RAM+$031e
                lda #FAIL_COLOR   //red
                sta COLOR_VIDEO_RAM+$31c
                sta COLOR_VIDEO_RAM+$31d
                sta COLOR_VIDEO_RAM+$31e

        testU12:
                txa
                and #$80
                beq deadLoop
                lda #$02         //"b"
                sta VIDEO_RAM+$0311
                lda #$01         //"a"
                sta VIDEO_RAM+$0312
                lda #$04         //"d"
                sta VIDEO_RAM+$0313
                lda #FAIL_COLOR   //red
                sta COLOR_VIDEO_RAM+$311
                sta COLOR_VIDEO_RAM+$312
                sta COLOR_VIDEO_RAM+$313

                // Something bad failed - program stop
        deadLoop:
                jmp deadLoop
}