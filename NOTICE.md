# Legal Notice and Attribution

## Copyright and Ownership

This project is based on multiple sources with complex copyright status:

### Original Work
- **Commodore 64 Dead Test rev. 781220** - © 1988 Commodore Electronics Limited
- Original diagnostic cartridge manual stated: "All rights reserved"
- Current ROM copyright likely owned by Cloanto Corporation (acquired C64 ROM rights)

### Disassembly
- **Disassembly by worldofjani.com** (2015)
- Created "for studying purposes"
- No explicit license provided
- Source: https://blog.worldofjani.com/?p=164

### This Implementation
- **KickAssembler port and enhancements** by stid
- Based on the worldofjani.com disassembly
- Additional features and improvements (see below)

## Important Legal Considerations

1. **The original Dead Test ROM remains under copyright**, now likely owned by Cloanto Corporation
2. **This repository is provided for educational and historical preservation purposes**
3. **No warranty or fitness for any particular purpose is implied**
4. **Use at your own risk for personal, educational, or repair purposes**
5. **For commercial use or distribution, please research current copyright ownership**

## Original Contributions in This Repository

The following enhancements are original work by stid and contributors:

### New Features
- **SID Filter Test** - Comprehensive analog filter testing based on Andrew Challis's methodology
- **Color Reference Bar** - Visual color palette at bottom of screen for quick reference
- **Border Color Cycling** - Visual progress indicator cycling through all 16 colors
- **Enhanced Chip Identification** - Improved visual feedback for failed chip identification

### Code Improvements
- **Modular Architecture** - Code split into logical modules for maintainability
- **KickAssembler Port** - Full conversion from DASM to KickAssembler syntax
- **Extensive Documentation** - Detailed comments explaining test algorithms and hardware
- **Macro System** - Reusable test patterns and delay routines
- **Build System** - Modern Makefile with multiple targets and configurations

### Documentation
- Technical documentation explaining test methodology
- Hardware compatibility information
- EPROM burning instructions
- Troubleshooting guides

## Usage Recommendations

### Permitted Uses
- Personal use for repairing vintage Commodore 64 computers
- Educational purposes for learning 6502 assembly and C64 hardware
- Historical preservation of computing history
- Contributing improvements back to this repository

### Seek Permission For
- Commercial distribution or sales
- Including in commercial products or services
- Large-scale redistribution

## Community and Ethics

This project exists to help preserve and maintain vintage Commodore 64 computers. Please:
- Respect the original creators and copyright holders
- Share knowledge and improvements with the community
- Credit all contributors when using or modifying this code
- Support efforts to preserve computing history

## Contact

For questions about this implementation and enhancements:
- GitHub: https://github.com/stid/kick-c64-dead-test

For questions about the original Dead Test or copyright:
- Consider contacting Cloanto Corporation (C64 ROM rights holder)
- Or relevant trademark holders for "Commodore" brand

## Disclaimer

THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. THE AUTHORS AND CONTRIBUTORS MAKE NO REPRESENTATIONS ABOUT THE SUITABILITY OF THIS SOFTWARE FOR ANY PURPOSE. USE OF THIS SOFTWARE IS AT YOUR OWN RISK.

---

*This notice serves to document the complex copyright situation and provide transparency about the origins and modifications of this diagnostic tool. When in doubt, err on the side of caution and seek appropriate permissions.*