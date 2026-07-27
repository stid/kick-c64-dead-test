#!/usr/bin/env python3
"""Assert a border-flash screenshot shows a flash, not banding.

The bus-fault signal is the only diagnosis whose correctness is a TIMING
property, and nothing else in CI can see it. It once alternated the border at
~2.9 kHz - about 57 times per PAL frame - which fills the screen with fine
horizontal banding. It reads as broken video or a dead machine, the opposite
of the intended "bus fault" message, and every other check passed happily:
the code branched correctly, the probe byte was right, only the rate was
wrong.

A screenshot captures one instant. A real flash is uniform across the frame,
or has a single boundary where the colour changed mid-capture. Banding shows
one transition every few raster lines. Counting row transitions separates
them by two orders of magnitude, so no fine-tuned threshold is needed.

Usage: check-flash-pattern.py <screenshot.png> [max-transitions]

Pure stdlib: VICE writes 8-bit RGBA (colour type 6), which zlib plus the
standard PNG unfiltering handles in a few lines. No Pillow in CI.
"""

import struct
import sys
import zlib

DEFAULT_MAX_TRANSITIONS = 4


def read_png_rows(path):
    """Return a list of scanlines, each a list of (r,g,b) tuples."""
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")

    pos, idat = 8, bytearray()
    width = height = bit_depth = colour_type = None

    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        ctype = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        if ctype == b"IHDR":
            width, height, bit_depth, colour_type = struct.unpack(">IIBB", body[:10])
        elif ctype == b"IDAT":
            idat += body
        elif ctype == b"IEND":
            break
        pos += 12 + length

    if bit_depth != 8 or colour_type not in (2, 6):
        raise ValueError(f"unsupported PNG: depth={bit_depth} colour_type={colour_type}")

    channels = 4 if colour_type == 6 else 3
    stride = width * channels
    raw = zlib.decompress(bytes(idat))

    rows, prev = [], bytearray(stride)
    for y in range(height):
        start = y * (stride + 1)
        filt = raw[start]
        line = bytearray(raw[start + 1:start + 1 + stride])

        # Standard PNG unfiltering. Left neighbour is `channels` bytes back.
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b = prev[i]
            c = prev[i - channels] if i >= channels else 0
            if filt == 1:
                line[i] = (line[i] + a) & 0xFF
            elif filt == 2:
                line[i] = (line[i] + b) & 0xFF
            elif filt == 3:
                line[i] = (line[i] + (a + b) // 2) & 0xFF
            elif filt == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pred) & 0xFF

        rows.append([tuple(line[x * channels:x * channels + 3]) for x in range(width)])
        prev = line

    return rows


def main():
    if len(sys.argv) not in (2, 3):
        print(__doc__)
        return 2

    path = sys.argv[1]
    limit = int(sys.argv[2]) if len(sys.argv) == 3 else DEFAULT_MAX_TRANSITIONS

    rows = read_png_rows(path)

    # Sample the left edge, which is border on every line regardless of what
    # the screen area is doing.
    column = [row[4] for row in rows]
    transitions = sum(1 for a, b in zip(column, column[1:]) if a != b)

    print(f"   Border column: {transitions} colour transitions over {len(rows)} lines")

    if transitions <= limit:
        print(f"   ✓ Flash rate is visible (<= {limit} transitions in one frame)")
        return 0

    print(f"❌ {transitions} transitions in a single frame - this is BANDING, not flashing")
    print("   The border is alternating many times per frame, so it appears as")
    print("   fine horizontal stripes. A technician reads that as broken video,")
    print("   not as the bus-fault diagnosis it is meant to signal.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
