
#importonce

*=$0 "ZERO PAGE" virtual

ZProcessDataDir:        .byte 0    // 6510 CPU's data direction I/O port register; 0 = input, 1 = output
ZProcessPortBit:        .byte 0    // 6510 CPU's data direction I/O port register; 0 = input, 1 = output
counterLow:             .byte 0
counterHigh:            .byte 0
tmpSourceAddressLow:    .byte 0
tmpSourceAddressHigh:   .byte 0
tmpDestAddressLow:      .byte 0
tmpDestAddressHigh:     .byte 0
tmpY:                   .byte 0
colorCycle:             .byte 0