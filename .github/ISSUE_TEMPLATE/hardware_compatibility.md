---
name: Hardware Compatibility Report
about: Report compatibility with specific C64 hardware configurations
title: '[HARDWARE] '
labels: compatibility
assignees: ''
---

## Hardware Configuration

### System Information
- **C64 Model**: [e.g., C64 breadbin, C64C, C128 in C64 mode]
- **Board Revision**: [e.g., ASSY 250407, 250425, 250466, 250469]
- **Serial Number**: [if comfortable sharing]
- **Region**: [NTSC/PAL]

### Chip Information
- **CPU**: [6510/8500]
- **VIC-II**: [6567/6569/8562/8565]
- **SID**: [6581/8580]
- **PLA**: [906114-01 or replacement type]
- **RAM Chips**: [e.g., 4164, 41464, 41256]

### Modifications (if any)
- [ ] JiffyDOS
- [ ] RAM expansion
- [ ] SID replacement (SwinSID, ARMSID, etc.)
- [ ] PLA replacement
- [ ] Other: _____________

## Test Results

### Memory Tests
```
Memory Bank:  [PASS/FAIL - specify chips if failed]
Zero Page:    [OK/BAD]
Stack:        [OK/BAD]
Screen RAM:   [OK/BAD]
Color RAM:    [OK/BAD]
RAM Test:     [OK/BAD]
```

### Other Tests
```
Font Test:    [Visual result]
Sound Test:   [All voices working/Voice X failed]
Filter Test:  [Sweep heard/No sweep/Distorted]
```

## Compatibility Issues

### Describe any issues encountered:
- Test failures that seem incorrect
- Display problems
- Sound issues
- Crashes or hangs
- Incorrect chip identification

### Expected vs Actual:
What you expected based on known hardware condition vs what the diagnostic reported.

## Photos/Evidence
Please attach if possible:
- Photo of the diagnostic screen showing results
- Photo of the motherboard (if opened)
- Photo of specific chips if relevant

## Comparison with Other Diagnostics
Have you tested with other diagnostic tools? Results:
- Original Dead Test 781220: [Results]
- Diagnostic 586220: [Results]
- Other tools: [Results]

## Additional Notes
- Any peculiar behavior noticed
- Intermittent vs consistent issues
- Temperature-dependent problems
- Previous repair history

## Would you be willing to:
- [ ] Test beta versions on this hardware
- [ ] Provide more detailed testing if guided
- [ ] Share this configuration with other developers