# Hardware Testing Guide

This guide explains how to simulate failures on real C64 hardware to verify that the diagnostic tests are working correctly.

## Table of Contents
- [RAM Chip Identification](#ram-chip-identification)
- [Safety Precautions](#safety-precautions)
- [Method 1: RAM Chip Reseating](#method-1-ram-chip-reseating-recommended)
- [Method 2: Address Line Testing](#method-2-address-line-testing-advanced)
- [Expected Test Results](#expected-test-results)
- [Troubleshooting](#troubleshooting)

## RAM Chip Identification

The C64 uses **8 RAM chips** (4164 DRAM, 64K x 1-bit each), with each chip providing one bit of the 8-bit data bus:

| Chip | Data Bit | Bit Mask | Notes |
|------|----------|----------|-------|
| U21  | Bit 0 (LSB) | `$01` | Easiest to access on most boards |
| U9   | Bit 1 | `$02` | Easiest to access on most boards |
| U22  | Bit 2 | `$04` | |
| U10  | Bit 3 | `$08` | |
| U23  | Bit 4 | `$10` | |
| U11  | Bit 5 | `$20` | |
| U24  | Bit 6 | `$40` | |
| U12  | Bit 7 (MSB) | `$80` | |

**Memory Regions Tested:**
- **Zero Page Test**: $00-$FF (all 8 chips)
- **Stack Page Test**: $0100-$01FF (all 8 chips)
- **Low RAM Test**: $0200-$03FF (all 8 chips) ← NEW in v1.3.0
- **Screen RAM Test**: $0400-$07FF (all 8 chips)
- **Color RAM Test**: $D800-$DBFF (4-bit color RAM, separate chips)
- **RAM Test**: $0800-$0FFF (all 8 chips)

## Safety Precautions

⚠️ **IMPORTANT: Read these warnings before proceeding!**

### Before Starting:
- **ALWAYS power off** the C64 completely before touching chips
- **Discharge static electricity** by touching grounded metal
- Use an **anti-static wrist strap** if available
- Work on a **non-carpeted surface**

### During Testing:
- **Never** force chips - they should lift/insert with gentle pressure
- **Avoid touching chip pins** - handle chips by their bodies
- **Don't bend pins** when reseating
- **Mark which chip** you're testing to avoid confusion

### What NOT to Do:
- ❌ Don't test with power on (risk of shorts)
- ❌ Don't use metal tools near chips with power on
- ❌ Don't pull chips completely out unless necessary
- ❌ Don't test on your only working C64 if uncertain

**If you're uncomfortable with these procedures, consider:**
- Using the software TEST_MODE instead (`make test-mode`)
- Practicing on a broken/spare C64 first
- Asking an experienced repair technician for guidance

## Method 1: RAM Chip Reseating (Recommended)

This is the **safest and most common** method for testing diagnostic tools.

### What You Need:
- Commodore 64 (any revision)
- Dead Test cartridge (burned EPROM or .crt in VICE)
- Small flathead screwdriver or chip puller (optional)

### Procedure:

#### Step 1: Baseline Test
1. Power off the C64
2. Insert Dead Test cartridge
3. Power on and let all tests complete
4. Verify **all tests show "OK"** (this is your baseline)
5. Note the iteration counter value
6. Power off

#### Step 2: Simulate Failure
1. Open the C64 case (remove screws from bottom)
2. Locate RAM chips U9-U12 and U21-U24
   - Usually in two rows near the center of the board
   - Look for "4164" part numbers
3. **Choose one chip** to test (U21 or U9 recommended for beginners)
4. Using gentle pressure with your finger or tool:
   - **Lift one end** of the chip 1-2mm (about 1/16 inch)
   - Or insert a thin piece of paper under one side
   - **Goal**: Break electrical contact on some pins, not remove chip

#### Step 3: Verify Failure Detection
1. With chip partially seated, power on C64
2. Watch the test sequence:
   - Black screen for ~10 seconds (normal)
   - Layout appears
   - Tests run sequentially
3. **Expected**: One or more tests will show "BAD" instead of "OK"
4. **Expected**: Red "BAD" indicators appear in the chip diagram box showing which chip failed
5. If testing Low RAM specifically:
   - Should see "LOW RAM" line with "BAD"
   - Red "BAD" marker on the chip you lifted (e.g., U21 in lower-left, U9 in lower-right)

#### Step 4: Verify Recovery
1. Power off C64
2. **Firmly reseat the chip** - press down evenly on both ends
3. Power on and run test again
4. **Expected**: All tests now show "OK"
5. **Expected**: No red "BAD" markers in chip diagram

### Which Tests Will Fail?

Depending on which chip and how much you lifted it:

| Lifted Chip | Likely Failed Tests |
|-------------|---------------------|
| Any U9-U24 | Zero Page, Stack Page, Low RAM, Screen RAM, RAM Test |
| U21 (bit 0) | Will see bit 0 errors ($01 in diagram) |
| U9 (bit 1) | Will see bit 1 errors ($02 in diagram) |
| Multiple chips | Multiple bits shown as failed |

**Note:** If you lift a chip too much, **all** RAM tests may fail, and the system might not even show the layout screen (stuck on black screen).

## Method 2: Address Line Testing (Advanced)

This tests the **PRN sequence** detection in the Low RAM test, which specifically checks for address bus problems.

### What You Need:
- Test clip or fine wire
- Multimeter (optional, for verification)
- **Advanced electronics knowledge**

### Procedure:

⚠️ **WARNING**: This method can damage your C64 if done incorrectly. Only attempt if you have electronics experience.

1. Power off C64
2. Identify address lines A8-A15 on RAM chips (see motherboard schematic)
3. Using a test clip, temporarily short two adjacent address lines
   - Example: Short A8 to A9 (will cause page confusion)
4. Power on with Dead Test
5. **Expected**: Low RAM test should fail because PRN pattern will be out of phase
6. **Expected**: May see multiple chips marked as failed due to address confusion
7. Power off and remove short
8. Verify all tests pass again

**Why this works:** The 247-byte PRN pattern is specifically designed to detect address line problems. When address lines are crossed or shorted, the pattern appears at wrong offsets, and verification fails.

## Expected Test Results

### Successful Failure Detection

When you **intentionally lift a RAM chip**, you should see:

```
ZERO PAGE        BAD
STACK PAGE       BAD
LOW RAM          BAD  ← If chip lifted before this test
SCREEN RAM       OK   ← Unless severely lifted
COLOR RAM        OK   ← Separate chips
RAM TEST         BAD  ← If chip lifted
SOUND TEST       OK
FILTERS TEST     OK
```

Plus **red "BAD" indicators** in the chip diagram box showing the specific chip ID (U9, U21, etc.).

### Test Patterns and What They Detect

**Low RAM Test** uses three patterns:

1. **$AA Pattern (10101010)**
   - Tests even bit positions
   - Detects stuck-high bits
   - If this fails → One or more even bits (0,2,4,6) are bad

2. **$55 Pattern (01010101)**
   - Tests odd bit positions
   - Detects stuck-low bits
   - If this fails → One or more odd bits (1,3,5,7) are bad

3. **PRN Sequence (247 bytes)**
   - Tests address bus integrity
   - Detects page confusion and mirrored addresses
   - If this fails → Address lines might be crossed/shorted

### Real-World Failure Patterns

| Symptom | Likely Cause | What You'll See |
|---------|--------------|-----------------|
| Single bit always wrong | One RAM chip dead | One U-chip marked red |
| Multiple bits in pattern | Multiple RAM chips | Multiple U-chips marked red |
| All bits wrong | Chip completely unseated | All U9-U24 marked, or black screen |
| Intermittent failures | Poor socket contact | Test passes sometimes, fails others |
| PRN test fails, AA/55 pass | Address bus problem | May not identify specific chip |

## Troubleshooting

### "I lifted a chip but all tests still pass"

**Possible causes:**
- Chip not lifted enough - try lifting slightly more (still be gentle!)
- Wrong chips - color RAM tests need color RAM chips (different location)
- Good socket contact - try a different chip
- Chip already reseated itself when board flexed

**Solution:** Lift chip a bit more, or try a different chip.

### "Black screen forever, no layout appears"

**Possible causes:**
- Chip lifted too much, system can't boot
- Critical chip for VIC-II access disrupted

**Solution:**
1. Power off immediately
2. Reseat chip firmly
3. Try again with less lift

### "Multiple unrelated tests fail"

**Possible causes:**
- Chip is shared by multiple memory regions (this is normal!)
- Board flexed and disturbed another chip

**Solution:** This is expected behavior. All RAM tests use the same 8 chips.

### "Chip won't reseat properly"

**Possible causes:**
- Bent pin(s)
- Debris in socket

**Solution:**
1. Power off
2. Carefully remove chip completely
3. Inspect pins - straighten any bent ones gently
4. Clean socket with contact cleaner (power off!)
5. Carefully reinsert, ensuring all pins align

### "Test behavior changes between runs"

**Possible causes:**
- Intermittent contact (this proves the test is sensitive!)
- Temperature affecting marginal chip
- Vibration reseating chip

**Solution:** This is actually good - it shows the test can detect marginal failures. Firmly reseat the chip to fix.

## Tips for Best Results

### For Beginners:
1. Start with **U21** (usually front-left of RAM cluster)
2. Use a small flathead screwdriver as a **gentle lever**
3. Lift only **one end** of the chip, about **1mm**
4. Take **photos** of chip positions before starting
5. Test on a **spare/broken C64** first if available

### For Validation Testing:
1. Test **each chip individually** to verify all 8 are detected
2. Document which chip causes which failures (should be consistent)
3. Test with **different lift amounts** to see sensitivity
4. Try **multiple test runs** to check for intermittent detection

### For Educational Purposes:
1. Have a working C64 as reference
2. Use this to demonstrate diagnostic principles
3. Show students the direct relationship between physical chip and bit position
4. Explain how XOR reveals which bits failed

## Additional Resources

- **C64 Service Manual**: Complete schematics showing RAM chip locations
- **Dead Test Source Code**: `src/low_ram_test.asm` shows exactly what's tested
- **Software Test Mode**: Use `make test-mode` for testing without hardware risk
- **Community Forums**: Share your testing results and ask questions

## Questions?

If you encounter issues or have questions:
1. Check [GitHub Issues](https://github.com/stid/kick-c64-dead-test/issues)
2. Consult `TECHNICAL_DOCUMENTATION.md` for test algorithm details
3. Ask in Commodore 64 hardware forums
4. Consider using software TEST_MODE instead

---

**Remember**: The goal is to verify the diagnostic works, not to damage your C64! When in doubt, use software testing methods instead of hardware manipulation.
