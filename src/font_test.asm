// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2020-2026 stid and contributors
//
// Ported from Commodore 64 Dead Test rev. 781220, (C) 1988 Commodore Electronics Ltd.
// Structure, labels, constants and comments here are this project's work and are
// MIT licensed. The underlying algorithm, test sequence and data are Commodore's
// and are not licensed by this project. See NOTICE.md.

#importonce
#import "./data.asm"
#import "./zeropage_map.asm"

        * = * "font test"

//=============================================================================
// FONT TEST - Custom Character Set Loading
// Copies custom font data to character RAM at $0800
//
// Purpose: Load diagnostic-friendly character set for consistent display
//          Default C64 character ROM varies between models/regions
//          Custom font ensures test results look identical on all machines
//
// Note:    This is not really a "test" - it just loads the font
//          The copy operation succeeding implies:
//          - RAM at $0800-$09FF is working (already tested)
//          - VIC-II can access custom characters
//          - Character set switching works properly
//
// Font:    512 bytes (64 characters × 8 bytes per character)
//          Includes A-Z, 0-9, and special diagnostic characters
//=============================================================================

fontTest: {
                // Set up source pointer to font data in ROM
                lda #<font                      // Low byte of font data
                ldx #>font                      // High byte of font data
                sta ZP.tmpSourceAddressLow
                stx ZP.tmpSourceAddressHigh
                
                // Set up destination pointer to character RAM
                // VIC-II looks here when custom characters enabled
                lda #<$0800                     // Character RAM start (low)
                ldx #>$0800                     // Character RAM start (high)
                sta ZP.tmpDestAddressLow
                stx ZP.tmpDestAddressHigh
                
                // Copy 512 bytes (2 pages) of font data
                ldx #$01                        // Page counter (1 = 2 pages)
                ldy #$00                        // Byte offset within page
    !:
                // Copy one byte of font data
                lda (ZP.tmpSourceAddressLow),y  // Read from font data
                sta (ZP.tmpDestAddressLow),y    // Write to character RAM
                
                iny                             // Next byte
                bne !-                          // Continue until page done
                
                // Page complete, move to next page
                inc ZP.tmpSourceAddressHigh     // Next source page
                inc ZP.tmpDestAddressHigh       // Next destination page
                
                dex                             // Decrement page counter
                bpl !-                          // Continue if more pages
                
                // Font loaded successfully
                // No verification needed - display will show if it worked
                rts
}