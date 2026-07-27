# Copyright and attribution

## What this is

A Kick Assembler port of the Commodore 64 Dead Test diagnostic cartridge rev. 781220,
restructured and extended for hardware repair and historical preservation.

The original was ported from the 2015 [worldofjani.com](https://blog.worldofjani.com/?p=164)
disassembly, and the compiled result was verified byte-for-byte identical to the original
binary. Only afterwards was it split into modules, annotated, and extended with new tests.
This is a port with additions, not a clean-room reimplementation.

## The original work

- **Dead Test rev. 781220** — © 1988 Commodore Electronics Limited.
- Copyright in Commodore's pre-1994 works passed through Escom (1995), Tulip Computers (1997)
  and Nedfield (2008) to Cloanto IT srl (2010–2020), and is asserted today by Cloanto IT srl /
  Amiga Corporation, of which Cloanto IT srl is a subsidiary.
- Ownership of the 8-bit ROM copyrights specifically has never been tested in court and is not
  universally accepted. This file records what is asserted and takes no position on it.
- The Commodore trademarks are held separately from the copyrights. Commodore Corporation B.V.
  held the 47 surviving marks until 2025, when Commodore International Corporation acquired
  that company and its trademark portfolio, completing on 31 July 2025 — an acquisition
  publicly disputed by Commodore Industries S.r.l., with proceedings between the two parties
  ongoing.
- No claim is made over any of the above.

## This implementation

Two categories. MIT (see [LICENSE](LICENSE)) covers this project's contributions in both, and
nothing beyond them.

### Original work — stid and contributors

- SID filter test (`src/filters_test.asm`)
- Low RAM test (`src/low_ram_test.asm`)
- The 2.0 RAM test methodology — AA/55/PRN and walking-bit patterns
- Chip-level failure reporting and the BIT / BUS / BAD verdicts
- Color reference bar
- `makefile`, `scripts/`, `.github/`, `docs/` and the repository documentation

The 247-byte PRN methodology was suggested by
[Sven Petersen](https://github.com/svenpetersen1965).

### Derived work — ported from rev. 781220

The remaining test modules are a Kick Assembler port of the original's logic, restructured
into separate files and annotated. The file structure, label names, constants and comments
there are this project's work; the underlying algorithms, test sequence and data are
Commodore's. Several of these files also carry substantial later modification — the 2.0
methodology listed above was applied inside them.

Per-file scope is marked with SPDX headers in `src/`.

## Binaries

This repository does not contain the original 781220 ROM image. The `dead-test.bin` and
`dead-test.crt` files published on the Releases page are builds of this project: they carry
the ported logic described above, and therefore whatever rights subsist in the original.

## Usage

Use it, modify it, build cartridges from it, sell them. The MIT license asks only that the
copyright notice travels with the code; no other permission is needed and none is asked for.

That license reaches only this project's own contributions. Redistributing the original
781220 ROM image, or using the Commodore name or logo on a product, is a matter between you
and the respective rights holders.

## Disclaimer

Provided "AS IS" for educational and preservation purposes. Use at your own risk. The authors
make no warranty about its suitability for any purpose. Nothing in this file is legal advice.

---

*This project helps keep vintage Commodore 64 computers running. Please respect the original
creators and support preservation efforts.*
