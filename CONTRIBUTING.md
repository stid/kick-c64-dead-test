# Contributing to C64 Dead Test Diagnostic

Thank you for your interest in contributing to this Commodore 64 diagnostic tool! This guide will help you get started.

## Before Contributing

Please read [NOTICE.md](NOTICE.md) to understand the copyright status and permitted uses of this project.

## How to Contribute

### Reporting Issues

1. **Check existing issues** first to avoid duplicates
2. **Use issue templates** when available
3. **Include details**:
   - Your hardware setup (C64 model, RAM configuration, etc.)
   - VICE emulator version (if applicable)
   - Steps to reproduce the issue
   - Expected vs actual behavior
   - Screenshots or photos if relevant

### Suggesting Enhancements

- Open an issue with the "enhancement" label
- Explain the motivation and use case
- Provide examples of how it would work
- Consider backward compatibility with original hardware

### Pull Requests

1. **Fork the repository** and create your branch from `master`
2. **Follow the coding standards** (see below)
3. **Test your changes** on both emulator and real hardware if possible
4. **Update documentation** if you change functionality
5. **Ensure the build passes** with `make clean && make`

## Coding Standards

### 6502 Assembly Style

```asm
// Brief file header explaining purpose
labelName:      // Use camelCase for labels
                // Indent with tabs (configure your editor to display as 8 spaces)
                lda #$00        // Instructions at 16-char indent
                sta someVar     // Comments at 40-char column

        // Align operands for readability
        lda $0400,x
        sta $d800,x

        // Document complex operations
!loop:  dey             // Countdown loop
        bne !loop-      // 5 cycles per iteration
```

### Naming Conventions

- **Labels**: `camelCase` (e.g., `memBankTest`, `drawLayout`)
- **Constants**: `UPPER_CASE` (e.g., `SCREEN_RAM`, `COLOR_RAM`)
- **Macros**: `PascalCase` (e.g., `LongDelayLoop`, `TestPattern`)
- **Local labels**: `!label` for KickAssembler anonymous labels
- **Zero page variables**: Descriptive names in `zeropage_map.asm`

### Comments

- **Module headers**: Explain purpose, constraints, and algorithm
- **Inline comments**: Explain "why" not "what"
- **Critical sections**: Mark with `CRITICAL:` or `WARNING:`
- **Hardware addresses**: Note the chip/register being accessed

Example:
```asm
// CRITICAL: No JSR/RTS here - stack not tested yet!
// Must use JMP for all flow control
jmp nextTest    // Cannot use JSR until stack verified
```

## Testing Requirements

### Emulator Testing (Minimum)

```bash
make clean
make
make run        # Test in VICE
```

Verify:
- All tests execute in sequence
- Visual indicators work (OK/BAD displays)
- Border color cycles correctly
- Sound tests produce audio
- No crashes or hangs

### Hardware Testing (Preferred)

If you have access to real hardware:
1. Test on multiple C64 models if possible (C64, C64C, C128 in C64 mode)
2. Test with known good and faulty RAM chips
3. Verify chip identification accuracy
4. Document any hardware-specific behavior

### Test Coverage

Ensure your changes don't break:
- Memory bank test (black screen phase)
- Zero page and stack tests
- Display functionality
- Sound generation
- Test sequencing and iteration counter

## Project Structure

```
src/
├── main.asm           # Entry point - modify carefully!
├── main_loop.asm      # Test orchestration
├── *_test.asm         # Individual test modules
├── macros.asm         # Reusable patterns
└── *_map.asm          # Memory definitions
```

### Adding New Tests

1. Create new file: `src/your_test.asm`
2. Follow existing test pattern structure
3. Add to test sequence in `main_loop.asm`
4. Update documentation
5. Test thoroughly on marginal hardware

## Documentation

- Update [Technical Documentation](docs/TECHNICAL_DOCUMENTATION.md) for algorithm changes
- Update [README.md](README.md) for user-visible changes
- Add inline comments for complex logic
- Document any new hardware requirements

## Build System

The Makefile should remain compatible with:
- Standard Unix/Linux systems
- macOS with Homebrew
- Windows with appropriate tools

When adding build targets:
- Follow existing naming patterns
- Add help text to `make help`
- Document any new dependencies

## Version Numbering

We use semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Incompatible changes to test sequence OR fundamental diagnostic methodology shifts
  - Examples: Complete algorithm rewrites, new pattern methodologies, diagnostic capability transformations
  - v2.0.0: Complete rewrite with AA/55/PRN patterns and error type differentiation
- **MINOR**: New tests or significant enhancements (backward-compatible)
  - Examples: Adding new test modules, enhanced error reporting, visual improvements
  - v1.3.0: Low RAM test addition, v1.2.0: SID filter test
- **PATCH**: Bug fixes and minor improvements
  - Examples: Fixing edge cases, documentation updates, small optimizations

## Copyright

This project is based on copyrighted work (Commodore 64 Dead Test © 1988). Your contributions are enhancements for educational and preservation purposes. See [NOTICE.md](NOTICE.md) for details.

## Questions?

- Open an issue for clarification
- Check existing documentation
- Review similar test implementations in the codebase

## Code of Conduct

- Be respectful and constructive
- Help preserve computing history
- Share knowledge with the community
- Credit all contributors appropriately

Thank you for helping improve this diagnostic tool for the Commodore 64 community!