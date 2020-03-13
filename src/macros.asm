#importonce

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