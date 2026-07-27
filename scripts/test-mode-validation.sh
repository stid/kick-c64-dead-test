#!/bin/bash
# TEST_MODE Validation Script
#
# Validates that TEST_MODE builds correctly simulate a U21 (bit 0) RAM failure
# in the Low RAM test and that the diagnostic identifies the failing chip.
#
# Two builds are validated, because test phases run in order and the first
# failing phase halts the test:
#
#   test-mode          -> fault in the $AA phase       -> testFailed_AA
#   test-mode-walking  -> fault in the walking bits    -> testFailed_Walking
#
# Without the second build the walking bits handler is never executed, which
# is how a bug that made it report no failing chip at all went unnoticed.
#
# Expected on screen, with U21 marked in the chip diagram for both (the
# injected fault is bit 0, which is U21). The status word differs by phase:
#
#   test-mode          -> "LOW RAM  BIT"  (testFailed_AA reports a stuck bit)
#   test-mode-walking  -> "LOW RAM  BAD"  (testFailed_Walking reports a chip)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🧪 TEST_MODE Validation"
echo "======================="
echo
echo "This test validates that the diagnostic correctly detects"
echo "simulated hardware failures using the TEST_MODE build flags."
echo

# Check if VICE is installed
if ! command -v x64sc &> /dev/null; then
    echo -e "${RED}❌ VICE emulator (x64sc) not found${NC}"
    echo "Please install VICE to run this test."
    exit 1
fi

# Check if xvfb-run is available (for headless mode)
XVFB_CMD=""
if command -v xvfb-run &> /dev/null; then
    XVFB_CMD="xvfb-run -a"
    echo "✓ Using Xvfb for headless display"
else
    echo "⚠️  Xvfb not available - will attempt to use current display"
    echo "   (may not work in CI environments)"
fi

# VICE is a GTK application and aborts if it cannot find GSettings schemas.
# Homebrew installs them outside the default search path, so point at them
# when they are present and the caller has not already set the variable.
if [ -z "$GSETTINGS_SCHEMA_DIR" ] && [ -f /opt/homebrew/share/glib-2.0/schemas/gschemas.compiled ]; then
    export GSETTINGS_SCHEMA_DIR=/opt/homebrew/share/glib-2.0/schemas
    echo "✓ Using Homebrew GSettings schemas"
fi

echo

SCREENSHOTS_CAPTURED=0
MODES_RUN=0

# Screenshots must live outside bin/, because each mode runs "make clean" and
# that removes bin/ entirely - which would delete the previous mode's output.
SHOT_DIR="screenshots"
mkdir -p "$SHOT_DIR"

# run_mode <make-target> <human label> <screenshot path>
run_mode() {
    local target="$1"
    local label="$2"
    local shot="$3"

    MODES_RUN=$((MODES_RUN + 1))

    echo -e "${BLUE}📦 Building: $label ($target)${NC}"
    if ! make clean "$target" > "/tmp/${target}-build.log" 2>&1; then
        echo -e "${RED}❌ Build failed for $target${NC}"
        cat "/tmp/${target}-build.log"
        exit 1
    fi
    echo "✓ Build successful"

    if [ ! -f bin/dead-test.crt ]; then
        echo -e "${RED}❌ Cartridge file not found: bin/dead-test.crt${NC}"
        exit 1
    fi
    echo "✓ Cartridge file exists"

    echo -e "${BLUE}🖥️  Running $label in VICE...${NC}"
    echo "   ~25s of emulated time (black screen memory bank test alone is ~10s)"

    rm -f "$shot"

    # -limitcycles gives a clean exit; ~985,248 cycles/sec, so 25M ≈ 25 seconds.
    # NOTE: +confirmonexit, not "-confirmonexit 0". It is a boolean flag with no
    # value - passing "0" made VICE treat it as a positional argument and silently
    # discard every option after it, including -exitscreenshot. That is why this
    # script used to never produce a screenshot.
    $XVFB_CMD x64sc \
        -default \
        -cartcrt bin/dead-test.crt \
        -warp \
        -limitcycles 25000000 \
        +confirmonexit \
        -exitscreenshot "$shot" \
        > "/tmp/vice-${target}.log" 2>&1 || true

    if [ ! -f "$shot" ]; then
        echo -e "${YELLOW}⚠️  No screenshot produced for $label${NC}"
        echo "   Runtime behavior was NOT validated for this mode."
        if [ -f "/tmp/vice-${target}.log" ]; then
            echo "   VICE output (last 20 lines - errors print at the end):"
            sed 's/^/     /' "/tmp/vice-${target}.log" | tail -20
        fi
        # In CI (REQUIRE_SCREENSHOT=1) a missing screenshot is a hard failure:
        # a green job must mean the runtime behavior was actually observed.
        # Locally it stays a soft warning so the script is still usable on
        # setups where VICE cannot render.
        if [ "${REQUIRE_SCREENSHOT:-0}" = "1" ]; then
            echo -e "${RED}❌ REQUIRE_SCREENSHOT=1: missing screenshot is a failure${NC}"
            exit 1
        fi
        echo
        return 0
    fi

    if ! file "$shot" | grep -q "PNG image data"; then
        echo -e "${RED}❌ Screenshot for $label is not a valid PNG${NC}"
        file "$shot"
        exit 1
    fi

    local size
    size=$(wc -c < "$shot")
    if [ "$size" -lt 1000 ]; then
        echo -e "${RED}❌ Screenshot for $label is implausibly small ($size bytes)${NC}"
        echo "   VICE likely did not render the emulated screen."
        exit 1
    fi

    SCREENSHOTS_CAPTURED=$((SCREENSHOTS_CAPTURED + 1))
    echo -e "${GREEN}✓ Screenshot captured: $shot ($size bytes)${NC}"
    echo
}

run_mode test-mode         "\$AA phase failure"   "$SHOT_DIR/test-mode-aa.png"
run_mode test-mode-walking "walking bits failure" "$SHOT_DIR/test-mode-walking.png"

echo "======================="
echo

if [ "$SCREENSHOTS_CAPTURED" -eq "$MODES_RUN" ]; then
    echo -e "${GREEN}✅ TEST_MODE validation PASSED${NC}"
    echo
    echo "Summary:"
    echo "  ✓ Both TEST_MODE builds compiled"
    echo "  ✓ Both ran in VICE and rendered a screen"
    echo "  ✓ Screenshots captured for visual inspection"
else
    echo -e "${YELLOW}⚠️  TEST_MODE validation INCOMPLETE${NC}"
    echo
    echo "Summary:"
    echo "  ✓ Both TEST_MODE builds compiled"
    echo "  ⚠️ Screenshots captured for $SCREENSHOTS_CAPTURED of $MODES_RUN modes"
    echo
    echo "  The builds are valid but their runtime output was not observed."
    echo "  Treat this as a build check only, not a behavioral check."
fi

echo
echo "Manual verification (the part no automated check here covers):"
echo "  Open the screenshots and confirm each shows:"
echo "    - $SHOT_DIR/test-mode-aa.png:      \"LOW RAM\" followed by \"BIT\""
echo "    - $SHOT_DIR/test-mode-walking.png: \"LOW RAM\" followed by \"BAD\""
echo "    - both: \"BAD\" marked next to U21 in the chip diagram"
echo "  The status word differs by design: the \$AA phase reports a stuck bit"
echo "  (BIT), the walking bits phase reports a failed chip (BAD)."
echo "  An empty chip diagram means the failing chip was not identified."
echo

exit 0
