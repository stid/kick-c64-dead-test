#importonce
#import "./data.asm"
#import "./mem_map.asm"
#import "./zeropage_map.asm"

        * = * "cia timers"

//=============================================================================
// CIA TIMER DISPLAY
// Reads and displays Time-of-Day (TOD) clocks from both CIA chips
//
// Purpose: Verify CIA timer functionality for diagnostics
// - CIA timers are critical for disk I/O, serial communication, and interrupts
// - Each CIA contains a 24-hour TOD clock with 1/10 second resolution
// - Faulty CIA timers can cause disk read errors or system timing issues
//
// Hardware Details:
// - CIA1 ($DC00-$DCFF): Keyboard, joystick ports, Timer A drives IRQ
// - CIA2 ($DD00-$DDFF): Serial bus, user port, Timer A drives NMI
// - TOD clocks are BCD (Binary Coded Decimal) format
// - Bit 7 of hours register indicates PM when set
//
// Display Format: HH-MM-SS AM/PM for each CIA
//=============================================================================

// Step identifiers for the BCD conversion state machine
// These control which digit (hours/minutes/seconds) is being processed
.enum {
        CIA1_HOUR_STEP  = $01,
        CIA1_MIN_STEP   = $02,
        CIA1_SEC_STEP   = $03,
        CIA_CALC_STEP   = $04,      // Intermediate calculation step
        CIA2_HOUR_STEP  = $05,
        CIA2_MIN_STEP   = $06,
        CIA2_SEC_STEP   = $07
        }

//-----------------------------------------------------------------------------
// Update CIA1 Time Display
// Reads TOD registers from CIA1 and formats for screen display
//-----------------------------------------------------------------------------
updateCia1Time: {
                // Read hours register to check AM/PM flag
                // Bit 7 = 1 indicates PM, 0 indicates AM
                lda CIA1.REAL_TIME_HOUR
                clc
                asl                         // Shift bit 7 into carry flag
                bcc setAm                   // Branch if AM (bit 7 was 0)
                
                // Display "PM" indicator at screen position
                lda #$10                    // PETSCII "P"
                sta VIDEO_RAM+$03db
                lda #$0d                    // PETSCII "M"
                sta VIDEO_RAM+$03dc
                clc
                bcc !+
                
        setAm:  // Display "AM" indicator at screen position
                lda #$01                    // PETSCII "A"
                sta VIDEO_RAM+$03db
                lda #$0d                    // PETSCII "M"
                sta VIDEO_RAM+$03dc
                
        !:      // Extract hour value without PM flag
                // Hours are stored in BCD format (00-23)
                // Bit 7 is PM flag, bits 0-6 contain BCD hour
                lda CIA1.REAL_TIME_HOUR
                and #$7f                    // Mask off PM flag bit
                ldy #CIA1_HOUR_STEP         // Set state for hour processing
                bne calcTime                // Always branches - convert BCD to display
                
        setHour:
                // Display hours at screen position (HH-00-00 format)
                sta VIDEO_RAM+$03d3         // First digit of hours
                stx VIDEO_RAM+$03d4         // Second digit of hours
                lda #$2d                    // PETSCII "-" separator
                sta VIDEO_RAM+$03d5
                
                // Process minutes next
                lda CIA1.REAL_TIME_MIN      // BCD minutes (00-59)
                ldy #CIA1_MIN_STEP          // Set state for minute processing
                bne calcTime                // Always branches
                
        setMinute:
                // Display minutes at screen position (00-MM-00 format)
                sta VIDEO_RAM+$03d6         // First digit of minutes
                stx VIDEO_RAM+$03d7         // Second digit of minutes
                lda #$2d                    // PETSCII "-" separator
                sta VIDEO_RAM+$03d8
                
                // Process seconds next
                lda CIA1.REAL_TIME_SEC      // BCD seconds (00-59)
                ldy #CIA1_SEC_STEP          // Set state for second processing
                bne calcTime                // Always branches
                
        setSecond:
                // Display seconds at screen position (00-00-SS format)
                sta VIDEO_RAM+$03d9         // First digit of seconds
                stx VIDEO_RAM+$03da         // Second digit of seconds
                
                // Read but don't display tenths of seconds
                // This read is necessary to latch all TOD registers
                lda CIA1.REAL_TIME_10THS

                // Continue to CIA2 processing
                clc
                bcc UpdateCia2Time          // Always branches
                ldy #$00                    // Dead code - never executed
}


//-----------------------------------------------------------------------------
// BCD to PETSCII Conversion
// Converts Binary Coded Decimal values to displayable PETSCII characters
//
// Input:  A = BCD value (two digits: upper nibble = tens, lower nibble = ones)
//         Y = Step identifier (which time component we're processing)
// Output: A = First digit PETSCII, X = Second digit PETSCII
//
// BCD Format: Each nibble (4 bits) represents one decimal digit (0-9)
// Example: BCD value $23 = decimal 23 (2 in upper nibble, 3 in lower nibble)
//-----------------------------------------------------------------------------
calcTime:  {
                pha                         // Save BCD value for second digit
                sty ZP.tmpY                 // Save step identifier
                ldy #CIA_CALC_STEP          // Mark that we're in calculation mode
                bne done                    // Always branches
                
        loop:   // Process second digit (lower nibble)
                ldy ZP.tmpY                 // Restore step identifier
                tax                         // Save first digit in X
                pla                         // Restore original BCD value
                
                // Extract upper nibble (tens digit)
                lsr                         // Shift right 4 times
                lsr                         // to move upper nibble
                lsr                         // into lower nibble position
                lsr
                
        done:   // Convert nibble to PETSCII character
                and #$0f                    // Isolate lower nibble (0-9)
                
                // BCD values should only be 0-9, but hardware faults
                // might produce invalid values $A-$F
                cmp #$0a                    // Check if valid BCD digit
                bmi ie74c                   // Branch if 0-9
                
                // Handle invalid BCD (hardware fault detected)
                // Convert $A-$F to displayable characters
                sec
                sbc #$09                    // $A becomes $01, $B becomes $02, etc.
                bne !+                      // Always branches
                
        ie74c:  // Convert valid BCD digit to PETSCII
                ora #$30                    // Add PETSCII offset (0-9 -> $30-$39)
                
        !:      // Route to appropriate display routine based on step
                cpy #CIA1_HOUR_STEP
                beq updateCia1Time.setHour
                cpy #CIA1_MIN_STEP
                beq updateCia1Time.setMinute
                cpy #CIA1_SEC_STEP
                beq updateCia1Time.setSecond
                cpy #CIA_CALC_STEP
                beq loop                    // Process second digit
                cpy #CIA2_HOUR_STEP
                beq UpdateCia2Time.setHour
                cpy #CIA2_MIN_STEP
                beq UpdateCia2Time.setMinue
                cpy #CIA2_SEC_STEP
                beq UpdateCia2Time.setSecond
                rts
}


//-----------------------------------------------------------------------------
// Update CIA2 Time Display
// Reads TOD registers from CIA2 and formats for screen display
//
// CIA2 Controls:
// - Serial bus (disk drive communication)
// - User port
// - VIC bank switching
// - NMI generation via Timer A
//
// Faulty CIA2 timers often manifest as:
// - Disk drive timeout errors
// - Serial communication failures
// - Inability to load programs
//-----------------------------------------------------------------------------
UpdateCia2Time: {
                // Read hours register to check AM/PM flag
                // CIA2 uses same TOD format as CIA1
                lda CIA2.REAL_TIME_HOUR
                clc
                asl                         // Shift bit 7 into carry flag
                bcc setAm                   // Branch if AM (bit 7 was 0)
                
                // Display "PM" indicator at different screen location than CIA1
                lda #$10                    // PETSCII "P"
                sta VIDEO_RAM+$03e6         // 11 chars to the right of CIA1
                lda #$0d                    // PETSCII "M"
                sta VIDEO_RAM+$03e7
                clc
                bcc !+
                
        setAm:  // Display "AM" indicator
                lda #$01                    // PETSCII "A"
                sta VIDEO_RAM+$03e6
                lda #$0d                    // PETSCII "M"
                sta VIDEO_RAM+$03e7
                
        !:      // Extract hour value without PM flag
                lda CIA2.REAL_TIME_HOUR
                and #$7f                    // Mask off PM flag bit
                ldy #$05                    // CIA2_HOUR_STEP
        ie790:  bne calcTime                // Always branches - convert BCD
        
        setHour:
                // Display hours at screen position (HH-00-00 format)
                sta VIDEO_RAM+$03de         // First digit of hours
                stx VIDEO_RAM+$03df         // Second digit of hours
                lda #$2d                    // PETSCII "-" separator
                sta VIDEO_RAM+$03e0
                
                // Process minutes next
                lda CIA2.REAL_TIME_MIN      // BCD minutes (00-59)
                ldy #$06                    // CIA2_MIN_STEP
                bne ie790                   // Always branches
                
        setMinue:  // Note: Original typo preserved (should be setMinute)
                // Display minutes at screen position (00-MM-00 format)
                sta VIDEO_RAM+$03e1         // First digit of minutes
                stx VIDEO_RAM+$03e2         // Second digit of minutes
                lda #$2d                    // PETSCII "-" separator
                sta VIDEO_RAM+$03e3
                
                // Process seconds next
                lda CIA2.REAL_TIME_SEC      // BCD seconds (00-59)
                ldy #$07                    // CIA2_SEC_STEP
                bne ie790                   // Always branches
                
        setSecond:
                // Display seconds at screen position (00-00-SS format)
                sta VIDEO_RAM+$03e4         // First digit of seconds
                stx VIDEO_RAM+$03e5         // Second digit of seconds
                
                // Read but don't display tenths of seconds
                // This read latches all TOD registers for consistent reading
                lda CIA2.REAL_TIME_10THS
                rts
}
