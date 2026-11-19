# Quick reference

A short guide to reading the Dead Test's output. For the full explanation of each verdict see the [readme](../readme.md#understanding-error-messages).

## Which chip is which bit

Each of the eight 4164 RAM chips holds one data bit. This mapping applies to the long C64 boards (ASSY 250407, 250425, 250466). Boards that use different RAM chips, such as the 250469 short board, do not have these U-numbers.

| Data bit | Chip | Border flashes (black screen) |
| -------- | ---- | ----------------------------- |
| Bit 7    | U12  | 1                             |
| Bit 6    | U24  | 2                             |
| Bit 5    | U11  | 3                             |
| Bit 4    | U23  | 4                             |
| Bit 3    | U10  | 5                             |
| Bit 2    | U22  | 6                             |
| Bit 1    | U9   | 7                             |
| Bit 0    | U21  | 8                             |

The on-screen diagram draws the chips in two columns, U9 to U12 on the left and U21 to U24 on the right, and writes a red "BAD" over each failed one.

## Border flashes during the black screen

If the initial memory bank test fails there is no display, so the border flash is the whole diagnosis:

- **N flashes, pause, repeat**: the chip in the table above failed. With several bad bits only the lowest one is reported, so after replacing that chip the count may change to the next one.
- **Continuous flashing, no pause**: address bus fault (the PRN pattern came back wrong in several bits at once). No single chip is identified.

## Test sequence

1. **Black screen** (~10 seconds): memory bank test
2. **Display appears**: RAM passed the initial test
3. **Tests run in order**, each showing OK or one of BIT, BUS, BAD
4. **Border color changes** with each iteration
5. **Counter increments** at the bottom of the screen

## Common issues

### No display (black screen forever)

- RAM failure in lower memory: read the border flashes as described above
- No flashing at all points away from RAM (power, CPU, PLA, VIC-II, the cartridge itself)

### Display corrupted

- Screen RAM failure ($0400-$07FF)
- Color RAM failure ($D800-$DBFF)
- VIC-II issues

### No sound during sound test

- SID chip failure
- Check the SID supply voltage (12V for 6581, 9V for 8580)

### Filter test silent

- Analog filter components degraded, common on older 6581 SIDs

## Tips for hardware testing

1. Test with a known good power supply first
2. Remove all peripherals during testing
3. Run multiple iterations to catch intermittent failures
4. Note which chips are flagged across runs

## Contributing examples

Photos of real failures with a confirmed cause are welcome: note the board revision, what the screen or border showed, and what the fault turned out to be. Submit them through a GitHub issue or pull request. See [CONTRIBUTING.md](../CONTRIBUTING.md).
