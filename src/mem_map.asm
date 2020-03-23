#importonce

// MEM
.label STACK_MEM                    = $100
.label VIDEO_RAM                    = $400
.label COLOR_VIDEO_RAM              = $d800

.namespace VIC2 {
    .label BORDERCOLOUR            = $d020
    .label BGCOLOUR                = $d021
}

.namespace CIA1 {
    .label TIMER_B_LOW             = $dc06
    .label TIMER_B_HIGH            = $dc07
    .label CONTROL_TIMER_A         = $dc0e
    .label CONTROL_TIMER_B         = $dC0f
    .label REAL_TIME_HOUR          = $dc0b
    .label REAL_TIME_MIN           = $dc0a
    .label REAL_TIME_SEC           = $dc09
    .label REAL_TIME_10THS         = $dc08
}

.namespace CIA2 {
    .label TIMER_B_LOW             = $dd06
    .label TIMER_B_HIGH            = $dd07
    .label CONTROL_TIMER_A         = $dD0e
    .label CONTROL_TIMER_B         = $dd0f
    .label REAL_TIME_HOUR          = $dd0b
    .label REAL_TIME_MIN           = $dd0a
    .label REAL_TIME_SEC           = $dd09
    .label REAL_TIME_10THS         = $dd08
}

.namespace SID {
    .label VOICE_1_FREQ_L           = $d400
    .label VOICE_1_FREQ_H           = $d401
    .label VOICE_1_PULSE_L          = $d402
    .label VOICE_1_PULSE_H          = $d403
    .label VOICE_1_CTRL             = $d404
    .label VOICE_1_ATK_DEC          = $d405
    .label VOICE_1_SUS_VOL_REL      = $d406
    .label VOICE_3_CTRL             = $d412
    .label FILTER_RES_ROUT          = $d417
    .label FILTER_VOL               = $d418
    .label VOICE_2_ATK_DEC          = $d40c
    .label VOICE_2_SUS_VOL_REL      = $d40d
    .label VOICE_2_FREQ_L           = $d407
    .label VOICE_2_FREQ_H           = $d408
    .label VOICE_2_PULSE_L          = $d409
    .label VOICE_2_PULSE_H          = $d40a
    .label VOICE_2_CTRL             = $d40b
    .label VOICE_3_ATK_DEC          = $d413
    .label VOICE_3_SUS_VOL_REL      = $d414
    .label VOICE_3_FREQ_L           = $d40e
    .label VOICE_3_FREQ_H           = $d40f
    .label VOICE_3_PULSE_L          = $d410
    .label VOICE_3_PULSE_H          = $d411
}