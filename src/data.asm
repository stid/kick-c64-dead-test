#importonce
#import "./const.asm"

        * = * "data"

vicDefaultValues:
                .byte $00,$00,$00,$00,$00,$00,$00,$00
                .byte $00,$00,$00,$00,$00,$00,$00,$00
                .byte $00,$1b,$00,$00,$00,$00,$08,$00
                .byte $12,$00,$00,$00,$00,$00,$00,$00
                .byte INITIAL_BORDER_COLOR,INITIAL_BACKGROUND_COLOR,$00,$00,$00,$00,$00,$00
                .byte $00,$00,$00,$00,$00,$00

cia1Table:
                .byte $00,$00,$00,$00
cia2Table:
                .byte $00,$00,$00,$00,$80

// Memory test patterns - each designed to detect specific failure modes
// Total: 20 bytes tested in reverse order (index 19 down to 0)
MemTestPattern:
                // Boundary patterns - detect stuck bits
                .byte $00       // All bits off - detects stuck-at-1
                .byte $55       // 01010101 - alternating bits (even positions)
                .byte $aa       // 10101010 - alternating bits (odd positions)  
                .byte $ff       // All bits on - detects stuck-at-0
                
                // Walking ones - isolate individual bit failures
                .byte $01       // 00000001 - test bit 0 (U21)
                .byte $02       // 00000010 - test bit 1 (U9)
                .byte $04       // 00000100 - test bit 2 (U22)
                .byte $08       // 00001000 - test bit 3 (U10)
                .byte $10       // 00010000 - test bit 4 (U23)
                .byte $20       // 00100000 - test bit 5 (U11)
                .byte $40       // 01000000 - test bit 6 (U24)
                .byte $80       // 10000000 - test bit 7 (U12)
                
                // Walking zeros - detect short circuits between bits
                .byte $fe       // 11111110 - all except bit 0
                .byte $fd       // 11111101 - all except bit 1
                .byte $fb       // 11111011 - all except bit 2
                .byte $f7       // 11110111 - all except bit 3
                .byte $ef       // 11101111 - all except bit 4
                .byte $df       // 11011111 - all except bit 5
                .byte $bf       // 10111111 - all except bit 6
                .byte $7f       // 01111111 - all except bit 7

// Color RAM test patterns - only 4 bits valid (0-15)
colorRamPattern:
                // 4-bit boundary and alternating patterns
                .byte $00       // 0000 - all bits off
                .byte $05       // 0101 - alternating bits
                .byte $0a       // 1010 - inverse alternating
                .byte $0f       // 1111 - all bits on

                // 4-bit walking ones
                .byte $01       // 0001 - bit 0
                .byte $02       // 0010 - bit 1
                .byte $04       // 0100 - bit 2
                .byte $08       // 1000 - bit 3

                // 4-bit walking zeros
                .byte $0e       // 1110 - all except bit 0
                .byte $0d       // 1101 - all except bit 1
                .byte $0b       // 1011 - all except bit 2
                .byte $07       // 0111 - all except bit 3

// PRN (Pseudo-Random Number) Test Pattern - 247 bytes
// Used for detecting address bus problems and page confusion
// The 247-byte length (prime-like odd number) ensures the pattern
// drifts out of alignment with 256-byte page boundaries, making it
// effective at catching mirrored or swapped address lines
//
// Generated using: value = ((value * 17) + 137) & 0xFF, seed = 0x42
// This creates good bit distribution and non-obvious patterns
PrnTestPattern:
                .byte $eb,$24,$ed,$46,$2f,$a8,$b1,$4a,$73,$2c,$75,$4e,$b7,$b0,$39,$52
                .byte $fb,$34,$fd,$56,$3f,$b8,$c1,$5a,$83,$3c,$85,$5e,$c7,$c0,$49,$62
                .byte $0b,$44,$0d,$66,$4f,$c8,$d1,$6a,$93,$4c,$95,$6e,$d7,$d0,$59,$72
                .byte $1b,$54,$1d,$76,$5f,$d8,$e1,$7a,$a3,$5c,$a5,$7e,$e7,$e0,$69,$82
                .byte $2b,$64,$2d,$86,$6f,$e8,$f1,$8a,$b3,$6c,$b5,$8e,$f7,$f0,$79,$92
                .byte $3b,$74,$3d,$96,$7f,$f8,$01,$9a,$c3,$7c,$c5,$9e,$07,$00,$89,$a2
                .byte $4b,$84,$4d,$a6,$8f,$08,$11,$aa,$d3,$8c,$d5,$ae,$17,$10,$99,$b2
                .byte $5b,$94,$5d,$b6,$9f,$18,$21,$ba,$e3,$9c,$e5,$be,$27,$20,$a9,$c2
                .byte $6b,$a4,$6d,$c6,$af,$28,$31,$ca,$f3,$ac,$f5,$ce,$37,$30,$b9,$d2
                .byte $7b,$b4,$7d,$d6,$bf,$38,$41,$da,$03,$bc,$05,$de,$47,$40,$c9,$e2
                .byte $8b,$c4,$8d,$e6,$cf,$48,$51,$ea,$13,$cc,$15,$ee,$57,$50,$d9,$f2
                .byte $9b,$d4,$9d,$f6,$df,$58,$61,$fa,$23,$dc,$25,$fe,$67,$60,$e9,$02
                .byte $ab,$e4,$ad,$06,$ef,$68,$71,$0a,$33,$ec,$35,$0e,$77,$70,$f9,$12
                .byte $bb,$f4,$bd,$16,$ff,$78,$81,$1a,$43,$fc,$45,$1e,$87,$80,$09,$22
                .byte $cb,$04,$cd,$26,$0f,$88,$91,$2a,$53,$0c,$55,$2e,$97,$90,$19,$32
                .byte $db,$14,$dd,$36,$1f,$98,$a1

.encoding       "screencode_mixed"
strAbout:       .text "c-64 dead test rev stid 1.3.0"
strCount:       .text "count"
strZero:        .text "zero page"
strStack:       .text "stack page"
strLowRam:      .text "low ram"
strRam:         .text "ram test"
srtColor:       .text "color ram"
strSound:       .text "sound test"
strScreen:      .text "screen ram"
strFilters:     .text "filters test"

sound1:         .byte $11,$15,$19,$22,$19,$15,$11         // soundtest
sound2:         .byte $25,$9a,$b1,$4b,$b1,$9a,$25         //
sound3:         .byte $22,$2b,$33,$44,$33,$2b,$22         //
sound4:         .byte $4b,$34,$61,$95,$61,$34,$4b         //
sound5:         .byte $44,$56,$66,$89,$66,$56,$44         //
sound6:         .byte $95,$69,$c2,$2b,$c2,$69,$95         //
sound7:         .byte $45,$11,$25                         //
sound8:         .byte $00,$00,$00                         //
sound9:         .byte $08,$00,$00,$09,$00,$28,$ff,$1f     //
                .byte $af                                 //


upBox:
                .byte $20,$20,$20,$20,$20,$20,$20,$20     // box upper part
                .byte $20,$20,$20,$20,$20,$20,$22,$26
                .byte $26,$26,$26,$26,$26,$26,$26,$26
                .byte $26,$26,$26,$26,$26,$26,$26,$26
                .byte $26,$26,$26,$26,$26,$26,$26,$23

boxArea:
                .byte $20,$20,$20,$20,$20,$20,$20,$20     // box text. 4164 etc.
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

boxColor:
                .byte $06,$06,$06,$06,$06,$06,$06,$06     //color
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

lowBox:
                .byte $20,$20,$20,$20,$20,$20,$20,$20     //box lower part
                .byte $20,$20,$20,$20,$20,$20,$24,$26
                .byte $26,$26,$26,$26,$26,$26,$26,$26
                .byte $26,$26,$26,$26,$26,$26,$26,$26
                .byte $26,$26,$26,$26,$26,$26,$26,$25

font:
                .byte $00,$00,$00,$00,$00,$00,$00,$00     //font
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
                .byte $00,$00,$00,$00,$00,$00,$00,$00   // SPACE
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
                .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff   // 3a - space inverted