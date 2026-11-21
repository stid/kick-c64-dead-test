# Beta validation on real hardware

Everything in 2.0 is tested against faults injected in an emulator. This is the list of things only a real board can confirm, written so each one takes a few minutes on a socketed test board. When the rows marked **required** pass, 2.0.0 can be tagged as final.

Build the cartridge with `make` (never from a `make test-mode*` build) and note the version shown on the top line of the screen.

## What to do and what to expect

The chip names below are for the long boards (ASSY 250407, 250425, 250466).

| # | Required | Fault to create | Expected result |
|---|----------|-----------------|-----------------|
| 1 | yes | None: known-good board | Black screen about 10 seconds, then every line shows OK, the counter increments, the border colour changes each pass, sound and filter sweep are audible |
| 2 | yes | One known-dead 4164 in a socket, or one socket left empty | Black screen, border flashes N times, pause, repeat. N matches the table in the readme (U12 = 1 ... U21 = 8) |
| 3 | yes | Same as 2, repeated in at least three other positions, including U12 and U21 | The count follows the chip each time |
| 4 | no | Two dead chips at once | The count for the chip with the lower data bit (the higher count). After replacing it, the count for the other one |
| 5 | yes | One good 4164 with **one address pin bent out of the socket** (pin 5, A0, is the easiest) | That chip is named: a counted flash for it. **Not** continuous flashing. This is the beta.2 change |
| 6 | yes | A fault on the **shared** address bus: one multiplexer output (74LS257, U13 or U25) lifted so the line floats for all eight chips | Continuous flashing with no count and no pause |
| 7 | yes | Color RAM fault: a known-bad 2114 at U6, or one of its data pins lifted | Layout appears, tests run, "COLOR RAM BAD", and the chip diagram stays empty |
| 8 | no | Any row above on an NTSC machine as well as a PAL one | Same result; the counted flash is still countable by eye |
| 9 | no | Known-good 250469 short board | All OK. The diagram's chip names do not apply to this board |

For row 5 the 4164 address pins are 5 (A0), 7 (A1), 6 (A2), 12 (A3), 11 (A4), 10 (A5), 13 (A6) and 9 (A7). A floating pin can also make the chip fail an earlier phase; that is still a pass as long as the chip named is the one you modified.

For row 6, lifting a multiplexer output is safer than shorting two address lines together, which makes two outputs drive against each other.

Faults in the later tests (zero page, stack, low RAM as separate verdicts) are hard to produce on purpose, because the black-screen bank test covers the same chips and fails first. They are covered by the emulator tests only.

## What to look at beyond pass or fail

- Is the counted flash easy to count on your display, and is the pause between groups obvious?
- Is continuous flashing clearly different from a count of 8?
- Does anything show a verdict you cannot explain from the fault you created? That is the most useful kind of result: note exactly what was on screen.

## Results

Add a row per run.

| Date | Board (ASSY, PAL/NTSC) | Version | Row # | Fault created | Observed | Pass |
|------|------------------------|---------|-------|---------------|----------|------|
|      |                        |         |       |               |          |      |
