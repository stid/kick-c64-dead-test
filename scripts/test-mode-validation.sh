#!/bin/bash
# TEST_MODE Validation Script
#
# Validates that TEST_MODE builds correctly simulate a RAM failure and that the
# diagnostic identifies the failing chip.
#
# Five builds are validated - one per distinct diagnostic signal the cartridge
# can produce. Each needs its own build, because tests run in order and the
# first failure halts the diagnostic:
#
#   test-mode           -> Low RAM $AA        -> "LOW RAM BIT", U21 marked
#   test-mode-walking   -> Low RAM walking    -> "LOW RAM BAD", U21 marked
#   test-mode-prn       -> Low RAM PRN        -> "LOW RAM BUS", NO chip marked
#   test-mode-bank      -> Mem Bank $AA       -> border flashes 8 times
#   test-mode-bank-bus  -> Mem Bank PRN       -> border flashes continuously
#
# Without the walking build that handler was never executed, which is how a bug
# that made it report no failing chip at all went unnoticed.
#
# The three Low RAM builds are checked by reading screen RAM back. BIT/BAD/BUS
# are three different diagnoses and must not be confused: BUS deliberately marks
# NO chip, because a bus fault is not a chip fault and blaming one would send a
# technician to replace a good part.
#
# The two Memory Bank builds are different in kind. They fail before the display
# is initialised, so there is nothing on screen: the border flash is the entire
# diagnosis, and the only feedback available on a machine too broken to draw
# anything. A COUNT identifies a chip; CONTINUOUS flashing means a bus fault
# with no chip identified. Both are read back through a probe byte.
#
# test-mode-bank injects a TWO-bit fault deliberately: the bank decode always
# handled single-bit faults correctly and mis-reported multi-bit ones, so a
# single-bit injection would pass either way and prove nothing. Expected count
# is 8 (bank 8 = U21); the superseded decode produced 1 (U12) - a good chip.

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
SCREENS_VERIFIED=0
MODES_RUN=0

# Screenshots must live outside bin/, because each mode runs "make clean" and
# that removes bin/ entirely - which would delete the previous mode's output.
SHOT_DIR="screenshots"
mkdir -p "$SHOT_DIR"

#=============================================================================
# assert_screen <make-target> <human label> <dump path> <expected status word>
#
# Reads back WHAT the diagnostic displayed, not merely that it displayed
# something. A VICE monitor checkpoint on UFailed's halt loop dumps screen RAM
# the moment the diagnostic gives up, and check-screen-dump.py asserts the
# status word and the U21 mark in the chip diagram.
#
# This needs its own VICE run. Hitting the checkpoint stops emulation, so VICE
# never reaches -limitcycles and never writes the -exitscreenshot PNG; the run
# above keeps producing the human-viewable screenshot, this one produces the
# machine-checkable dump. The emulator is killed once the dump lands, because
# the monitor blocks waiting for input that never comes.
#=============================================================================
assert_screen() {
    local target="$1"
    local label="$2"
    local dump="$3"
    local expected="$4"
    local chips="$5"

    # Label addresses shift between builds, so take deadLoop from this build.
    local dead_loop
    dead_loop=$(grep -o 'deadLoop=\$[0-9a-fA-F]*' bin/main.sym | head -1 | cut -d'$' -f2)
    if [ -z "$dead_loop" ]; then
        echo -e "${RED}❌ Could not find deadLoop in bin/main.sym${NC}"
        return 1
    fi
    echo "   Halt loop at \$$dead_loop (from bin/main.sym)"

    local moncmds="/tmp/${target}-moncommands.txt"
    printf 'break $%s\ncommand 1 "save \\"%s/%s\\" 0 0400 07e7"\n' \
        "$dead_loop" "$PWD" "$dump" > "$moncmds"

    rm -f "$dump"
    $XVFB_CMD x64sc \
        -default \
        -cartcrt bin/dead-test.crt \
        -warp \
        -limitcycles 40000000 \
        +confirmonexit \
        -moncommands "$moncmds" \
        > "/tmp/vice-${target}-dump.log" 2>&1 &
    local vice_pid=$!

    # Wait for the COMPLETE dump, not merely for the file to appear: the
    # monitor's save is not atomic, and killing VICE between create and write
    # would leave a truncated file that fails the check for the wrong reason.
    # 1002 = 2-byte load address + 1000 bytes of screen RAM.
    #
    # Locally the checkpoint lands in ~5s of warp; allow generous headroom for
    # slower CI runners. If the halt loop is never reached, VICE exits at its
    # cycle limit and the kill -0 check ends the wait early.
    local dump_size=1002
    local waited=0
    while [ "$(wc -c < "$dump" 2>/dev/null || echo 0)" -lt "$dump_size" ] \
          && [ "$waited" -lt 120 ]; do
        sleep 1
        waited=$((waited + 1))
        kill -0 "$vice_pid" 2>/dev/null || break
    done
    kill "$vice_pid" 2>/dev/null || true
    wait "$vice_pid" 2>/dev/null || true

    if [ "$(wc -c < "$dump" 2>/dev/null || echo 0)" -lt "$dump_size" ]; then
        echo -e "${RED}❌ No complete screen dump for $label${NC}"
        echo "   The halt loop was never reached: the diagnostic did not report"
        echo "   a failure, or never got that far."
        tail -20 "/tmp/vice-${target}-dump.log" 2>/dev/null | sed 's/^/     /'
        return 1
    fi

    if ! python3 scripts/check-screen-dump.py "$dump" "$expected" "$chips"; then
        echo -e "${RED}❌ Screen contents wrong for $label${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ Screen contents verified for $label${NC}"
    return 0
}

#=============================================================================
# run_bank_mode <expected flash count>
#
# The Memory Bank failure path cannot be checked like the others: it halts
# before the display exists, so there is no text to read back, and VICE's
# monitor cannot export a CPU register to a file. The TEST_MODE_BANK_ENABLED
# build therefore publishes the computed flash count to $07E7 (last byte of the
# untouched screen page) and a checkpoint on the flash loop dumps that byte.
# The value written is whatever the real decode produced - the probe observes
# it, it does not compute it.
#=============================================================================
run_bank_mode() {
    local target="$1"
    local label="$2"
    local expected="$3"
    local meaning="$4"
    local symbol="$5"          # flashLoop (counted) or busFlashLoop (bus fault)
    local dump="$SHOT_DIR/${target}-probe.bin"

    MODES_RUN=$((MODES_RUN + 1))

    echo -e "${BLUE}📦 Building: $label ($target)${NC}"
    if ! make clean "$target" > "/tmp/${target}-build.log" 2>&1; then
        echo -e "${RED}❌ Build failed for $target${NC}"
        cat "/tmp/${target}-build.log"
        exit 1
    fi
    echo "✓ Build successful"

    local flash_loop
    # \$ so the shell passes a literal '$' to grep. Anchored on ".label " to
    # keep "flashLoop" from also matching "busFlashLoop", which is a different
    # failure signal entirely.
    flash_loop=$(grep -oE "\.label ${symbol}=\\\$[0-9a-fA-F]+" bin/main.sym | head -1 | cut -d'$' -f2)
    if [ -z "$flash_loop" ]; then
        echo -e "${RED}❌ Could not find $symbol in bin/main.sym${NC}"
        exit 1
    fi
    echo "   $symbol at \$$flash_loop (from bin/main.sym)"

    local moncmds="/tmp/${target}-moncommands.txt"
    printf 'break $%s\ncommand 1 "save \\"%s/%s\\" 0 07e7 07e7"\n' \
        "$flash_loop" "$PWD" "$dump" > "$moncmds"

    echo -e "${BLUE}🖥️  Running $label in VICE...${NC}"
    rm -f "$dump"
    $XVFB_CMD x64sc \
        -default \
        -cartcrt bin/dead-test.crt \
        -warp \
        -limitcycles 40000000 \
        +confirmonexit \
        -moncommands "$moncmds" \
        > "/tmp/vice-${target}.log" 2>&1 &
    local vice_pid=$!

    # 3 = 2-byte load address + the single probe byte.
    local waited=0
    while [ "$(wc -c < "$dump" 2>/dev/null || echo 0)" -lt 3 ] && [ "$waited" -lt 120 ]; do
        sleep 1
        waited=$((waited + 1))
        kill -0 "$vice_pid" 2>/dev/null || break
    done
    kill "$vice_pid" 2>/dev/null || true
    wait "$vice_pid" 2>/dev/null || true

    if [ "$(wc -c < "$dump" 2>/dev/null || echo 0)" -lt 3 ]; then
        echo -e "${RED}❌ No probe written for $label${NC}"
        echo "   The flash path was never reached: the Memory Bank test did not fail."
        tail -20 "/tmp/vice-${target}.log" 2>/dev/null | sed 's/^/     /'
        exit 1
    fi

    local actual
    actual=$(python3 -c "import sys; print(open(sys.argv[1],'rb').read()[2])" "$dump")
    if [ "$actual" != "$expected" ]; then
        echo -e "${RED}❌ Probe reads $actual, expected $expected ($meaning)${NC}"
        if [ "$expected" = "255" ]; then
            echo "   255 is the sentinel for the bus-fault path, which flashes"
            echo "   continuously with NO count. A real count here means a page"
            echo "   confusion fault was reported as a single bad chip."
        else
            echo "   The border flashes $actual times, sending a technician to the"
            echo "   wrong chip. Bank 8 = U21; a count of 1 means bank 1 = U12, which"
            echo "   is what the superseded decode reported for any multi-bit fault."
        fi
        exit 1
    fi

    echo -e "${GREEN}✓ Probe reads $actual ($meaning), as expected${NC}"

    # The probe proves the right branch was taken. It says nothing about the
    # RATE, which for a border flash IS the diagnosis - and a flash too fast to
    # see is indistinguishable from broken video. Needs its own run: the
    # checkpoint above blocks emulation, so that run never writes a screenshot.
    local shot="$SHOT_DIR/${target}.png"
    rm -f "$shot"
    $XVFB_CMD x64sc \
        -default \
        -cartcrt bin/dead-test.crt \
        -warp \
        -limitcycles 30000000 \
        +confirmonexit \
        -exitscreenshot "$shot" \
        > "/tmp/vice-${target}-shot.log" 2>&1 || true

    if [ ! -f "$shot" ]; then
        echo -e "${YELLOW}⚠️  No screenshot for $label - flash rate not checked${NC}"
        if [ "${REQUIRE_SCREENSHOT:-0}" = "1" ]; then
            echo -e "${RED}❌ REQUIRE_SCREENSHOT=1: missing screenshot is a failure${NC}"
            exit 1
        fi
    elif ! python3 scripts/check-flash-pattern.py "$shot"; then
        echo -e "${RED}❌ Flash rate wrong for $label${NC}"
        exit 1
    fi

    SCREENS_VERIFIED=$((SCREENS_VERIFIED + 1))
    SCREENSHOTS_CAPTURED=$((SCREENSHOTS_CAPTURED + 1))
    echo
}

# run_mode <make-target> <label> <screenshot path> <status word> [chip expectation]
# chip expectation: U21 (default) or NONE - NONE is correct for a bus fault,
# which must not blame a chip.
run_mode() {
    local target="$1"
    local label="$2"
    local shot="$3"
    local expected="$4"
    local chips="${5:-U21}"

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

    # A screenshot only proves VICE rendered a screen. Now check what is ON it.
    # VICE clearly works at this point, so a wrong screen is a real regression -
    # always a hard failure, not gated on REQUIRE_SCREENSHOT.
    echo -e "${BLUE}🔎 Verifying screen contents for $label...${NC}"
    if ! assert_screen "$target" "$label" "${shot%.png}-screen.bin" "$expected" "$chips"; then
        exit 1
    fi
    SCREENS_VERIFIED=$((SCREENS_VERIFIED + 1))
    echo
}

run_mode test-mode         "\$AA phase failure"   "$SHOT_DIR/test-mode-aa.png"      BIT
run_mode test-mode-walking "walking bits failure" "$SHOT_DIR/test-mode-walking.png" BAD
run_mode test-mode-prn     "Low RAM bus fault"    "$SHOT_DIR/test-mode-prn.png"     BUS NONE
run_bank_mode test-mode-bank     "memory bank two-bit failure" 8   "bank 8 = U21"               flashLoop
run_bank_mode test-mode-bank-bus "memory bank bus fault"       255 "continuous flash, no count" busFlashLoop

echo "======================="
echo

if [ "$SCREENSHOTS_CAPTURED" -eq "$MODES_RUN" ]; then
    echo -e "${GREEN}✅ TEST_MODE validation PASSED${NC}"
    echo
    echo "Summary:"
    echo "  ✓ All $MODES_RUN TEST_MODE builds compiled and ran in VICE"
    echo "  ✓ Screenshots captured for the three Low RAM modes"
    echo "  ✓ Diagnosis verified for $SCREENS_VERIFIED of $MODES_RUN modes:"
    echo "    Low RAM  - status word (BIT/BAD/BUS) and chip marks from screen RAM"
    echo "    Mem Bank - border flash signal (count vs continuous) from the probe"
else
    echo -e "${YELLOW}⚠️  TEST_MODE validation INCOMPLETE${NC}"
    echo
    echo "Summary:"
    echo "  ✓ Both TEST_MODE builds compiled"
    echo "  ⚠️ Screenshots captured for $SCREENSHOTS_CAPTURED of $MODES_RUN modes"
    echo "  ⚠️ Screen contents verified for $SCREENS_VERIFIED of $MODES_RUN modes"
    echo
    echo "  The builds are valid but their runtime output was not observed."
    echo "  A mode that produced no screenshot is skipped before the screen"
    echo "  content check runs, so neither ran for it."
    echo "  Treat this as a build check only, not a behavioral check."
fi

echo
echo "What was checked automatically, from screen RAM:"
echo "    - $SHOT_DIR/test-mode-aa.png:      \"LOW RAM\" followed by \"BIT\""
echo "    - $SHOT_DIR/test-mode-walking.png: \"LOW RAM\" followed by \"BAD\""
 echo "    - $SHOT_DIR/test-mode-prn.png:     \"LOW RAM\" followed by \"BUS\", no chip marked"
echo "    - the two Memory Bank probes: flash count 8, then the 255 sentinel"
echo "  The three words are three different diagnoses: BIT is a stuck bit, BAD"
echo "  a failed chip, BUS an address bus fault - which marks NO chip, because"
echo "  blaming one would send a technician to replace a good part."
echo
echo "Still worth an eyeball: the screenshots show colors, the border, and the"
echo "rest of the layout, none of which the screen-code check looks at."
echo

exit 0
