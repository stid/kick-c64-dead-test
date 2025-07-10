#importonce

//=============================================================================
// COLOR CONSTANTS FOR C64 DEAD TEST DIAGNOSTIC
//
// These colors were carefully chosen for maximum visibility and diagnostic
// significance. The C64 has 16 colors (0-15), each with specific properties
// that make them suitable for different diagnostic purposes.
//
// C64 Color Palette Reference:
// $00 = Black       $08 = Orange
// $01 = White       $09 = Brown
// $02 = Red         $0A = Light Red
// $03 = Cyan        $0B = Dark Grey
// $04 = Purple      $0C = Medium Grey
// $05 = Green       $0D = Light Green
// $06 = Blue        $0E = Light Blue
// $07 = Yellow      $0F = Light Grey
//=============================================================================

// Test failure indicator color
// Red ($02) was chosen for its universal association with errors/failures
// This high-contrast color ensures failures are immediately visible even
// on degraded or poorly calibrated monitors
.label  FAIL_COLOR                  = $02

// Border color for test result boxes in the display layout
// Green ($05) provides good contrast against both white background
// and red failure text, making the test structure clearly visible
.label  BOX_BORDER_COLOR            = $05

// Initial border color before tests begin
// Green ($05) indicates the diagnostic cartridge has started successfully
// This differs from the original dead test which used black borders,
// providing immediate visual confirmation that the test is running
.label  INITIAL_BORDER_COLOR        = $05

// Initial background color during diagnostic startup
// White ($01) provides maximum contrast for text display and ensures
// any screen artifacts or bad pixels are immediately visible
// This is critical for diagnosing video-related failures
.label  INITIAL_BACKGROUND_COLOR    = $01

