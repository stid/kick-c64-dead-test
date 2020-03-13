#importonce
#import "./zeropage.asm"

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