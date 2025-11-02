# Examples and Guides

This directory contains practical examples and guides for using the C64 Dead Test diagnostic.

## Directory Structure

### test-outputs/
Screenshots and photos showing various test results, including:
- Normal test completion (all tests pass)
- Common RAM failures with chip identification
- Sound and filter test patterns
- Color reference bar examples

### common-failures/
Guide to interpreting common failure modes:
- RAM chip failure patterns
- How to identify which physical chip failed
- Interpreting border flash codes
- Understanding test sequence failures

### eprom-burning/
Step-by-step guide for creating physical cartridges:
- EPROM selection (27C64, 27C128, 27C256, 27C512)
- Programmer settings and software
- Cartridge PCB options
- Jumper configurations for Ultimax mode

## Quick Reference

### Chip Identification Map
When a RAM test fails, the diagnostic identifies the failed chip:

```
Memory Layout (looking at C64 motherboard):
+--------+--------+--------+--------+
| U12    | U24    | U11    | U23    |
| Bit 7  | Bit 6  | Bit 5  | Bit 4  |
+--------+--------+--------+--------+
| U10    | U22    | U9     | U21    |
| Bit 3  | Bit 2  | Bit 1  | Bit 0  |
+--------+--------+--------+--------+
```

### Border Flash Count
If the initial memory bank test fails:
- 1 flash = U21 (Bit 0)
- 2 flashes = U9 (Bit 1)
- 3 flashes = U22 (Bit 2)
- 4 flashes = U10 (Bit 3)
- 5 flashes = U23 (Bit 4)
- 6 flashes = U11 (Bit 5)
- 7 flashes = U24 (Bit 6)
- 8 flashes = U12 (Bit 7)

### Test Sequence
1. **Black screen** (~10 seconds) - Memory bank test
2. **Display appears** - RAM passed initial test
3. **Tests run in order** showing OK/BAD for each
4. **Border color changes** with each iteration
5. **Counter increments** at bottom of screen

## Common Issues and Solutions

### No Display (Black Screen Forever)
- Severe RAM failure in lower memory
- Count border flashes to identify failed chip
- Check U21-U24 and U9-U12

### Display Corrupted
- Screen RAM failure ($0400-$07FF)
- Color RAM failure ($D800-$DBFF)
- VIC-II issues

### No Sound During Sound Test
- SID chip failure
- Check voltage on SID (9V/12V depending on model)
- Try both 6581 and 8580 if available

### Filter Test Silent
- Analog filter components degraded
- Common on older 6581 SIDs
- Capacitors may need replacement

## Tips for Hardware Testing

1. **Always test with known good power supply first**
2. **Remove all peripherals during testing**
3. **Let the system warm up for accurate results**
4. **Run multiple iterations to catch intermittent failures**
5. **Document which chips are flagged across multiple runs**

## Contributing Examples

If you have documented test results or failure cases, please consider contributing:
1. Take clear photos/screenshots
2. Note the hardware configuration
3. Document what was actually wrong (if determined)
4. Submit via GitHub issue or pull request

See [CONTRIBUTING.md](../CONTRIBUTING.md) for more details.