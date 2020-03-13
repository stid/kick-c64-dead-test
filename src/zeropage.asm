
#importonce

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