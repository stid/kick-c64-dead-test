
#importonce

.label ZProcessDataDir          = $00    // 6510 CPU's data direction I/O port register; 0 = input, 1 = output
.label ZProcessPortBit          = $01    // 6510 CPU's on-chip port register
//
.label counterLow               = $02
.label counterHigh              = $03
.label tmpSourceAddressLow      = $09
.label tmpSourceAddressHigh     = $0a
.label tmpDestAddressLow        = $0b
.label tmpDestAddressHigh       = $0c
.label tmpY                     = $10
//
.label tmpTargetPointer         = $09
.label tmpDestPointer           = $0b

.label colorCycle               = $0c
