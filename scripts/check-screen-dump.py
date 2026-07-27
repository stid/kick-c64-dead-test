#!/usr/bin/env python3
"""Assert what the diagnostic actually displayed, from a screen RAM dump.

The screenshot check in test-mode-validation.sh only proves VICE rendered
something - a regression back to "BAD over an empty chip diagram" still
produces a perfectly valid PNG. This reads the screen codes straight out of
a $0400-$07E7 dump taken by a VICE monitor checkpoint on the halt loop, so
the failing chip really is verified.

Usage: check-screen-dump.py <dump.bin> <expected-status-word> [chip-expectation]

chip-expectation is "U21" (default) to require U21 marked BAD, or "NONE" to
require the whole chip diagram to be blank. NONE is the deliberate behaviour
for a bus fault: it is not a chip failure, so marking a chip would send a
technician to replace a part that is fine.

The dump is a VICE monitor "save" file: a 2-byte little-endian load address
followed by the 1000 bytes of screen RAM.
"""

import sys

# Screen offsets written by the Low RAM test and the chip diagram.
# low_ram_test.asm writes its status word to VIDEO_RAM+$ad..$af.
# Chip cells are the failCheck() positions in u_failure.asm.
STATUS_OFFSET = 0xAD
U21_OFFSET = 0x2A4

CHIP_CELLS = {
    "U21": 0x2A4,
    "U9": 0x299,
    "U22": 0x2CC,
    "U10": 0x2C1,
    "U23": 0x2F4,
    "U11": 0x2E9,
    "U24": 0x31C,
    "U12": 0x311,
}

SCREEN_COLS = 40
SCREEN_ROWS = 25


def to_text(code):
    """Render one screen code as ASCII (letters, digits, space)."""
    code &= 0x7F
    if code == 0x00 or code == 0x20:
        return " "
    if 1 <= code <= 26:
        return chr(ord("A") + code - 1)
    if 0x30 <= code <= 0x39:
        return chr(code)
    return "."


def read_word(screen, offset, length=3):
    return "".join(to_text(b) for b in screen[offset:offset + length])


def main():
    if len(sys.argv) not in (3, 4):
        print(__doc__)
        return 2

    path, expected_status = sys.argv[1], sys.argv[2].upper()
    chip_expectation = (sys.argv[3].upper() if len(sys.argv) == 4 else "U21")

    with open(path, "rb") as f:
        raw = f.read()

    load_addr = raw[0] | (raw[1] << 8)
    screen = raw[2:]

    if load_addr != 0x0400:
        print(f"❌ Dump does not start at $0400 (got ${load_addr:04x})")
        return 1

    if len(screen) < SCREEN_COLS * SCREEN_ROWS:
        print(f"❌ Dump is short: {len(screen)} bytes, need {SCREEN_COLS * SCREEN_ROWS}")
        return 1

    # Always print the screen - it is the debugging output when this fails.
    print("   Screen as displayed at the halt loop:")
    for row in range(SCREEN_ROWS):
        line = screen[row * SCREEN_COLS:(row + 1) * SCREEN_COLS]
        print(f"     |{''.join(to_text(b) for b in line)}|")
    print()

    ok = True

    status = read_word(screen, STATUS_OFFSET)
    if status == expected_status:
        print(f"   ✓ Low RAM status reads {status!r}")
    else:
        print(f"❌ Low RAM status reads {status!r}, expected {expected_status!r}")
        ok = False

    if chip_expectation == "NONE":
        marked = {name: read_word(screen, off)
                  for name, off in CHIP_CELLS.items()
                  if read_word(screen, off).strip()}
        if not marked:
            print("   ✓ Chip diagram is blank, as a bus fault requires")
        else:
            print(f"❌ Chip diagram marks {sorted(marked)}, expected none")
            print("   A bus fault is not a chip failure. Marking a chip here")
            print("   sends a technician to replace a part that is fine.")
            ok = False
    else:
        u21 = read_word(screen, U21_OFFSET)
        if u21 == "BAD":
            print("   ✓ U21 marked BAD in the chip diagram")
        else:
            print(f"❌ U21 cell reads {u21!r}, expected 'BAD'")
            print("   An unmarked chip means the failing chip was not identified -")
            print("   this is exactly the bug the walking bits fix addressed.")
            ok = False

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
