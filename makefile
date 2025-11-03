# Commodore 64 Dead Test Makefile
# ================================

# Configuration
BUILD_PATH = bin
SRC_PATH = src
MAIN_SOURCE = $(SRC_PATH)/main.asm
PROJECT_NAME = dead-test

# Tools configuration
KICKASS_BIN ?= /Applications/KickAssembler/KickAss.jar
JAVA ?= java
CARTCONV ?= cartconv
X64SC ?= x64sc

# Output files
PRG_FILE = $(BUILD_PATH)/main.prg
CRT_FILE = $(BUILD_PATH)/$(PROJECT_NAME).crt
BIN_FILE = $(BUILD_PATH)/$(PROJECT_NAME).bin
LOG_FILE = $(BUILD_PATH)/buildlog.txt

# KickAssembler options
KICKASS_OPTS = -odir ../$(BUILD_PATH) -log ./$(LOG_FILE) -showmem

# Version
VERSION ?= 2.0.0

# Phony targets
.PHONY: all build clean run debug help check-tools test release check version test-mode

# Default target
all: build

# Check required tools
check-tools:
	@echo "Checking required tools..."
	@command -v $(JAVA) >/dev/null 2>&1 || { echo "Error: Java not found. Please install Java."; exit 1; }
	@test -f $(KICKASS_BIN) || { echo "Error: KickAssembler not found at $(KICKASS_BIN). Please update KICKASS_BIN path."; exit 1; }
	@command -v $(CARTCONV) >/dev/null 2>&1 || { echo "Error: cartconv not found. Please install VICE."; exit 1; }
	@echo "All required tools found."

# Create build directory if it doesn't exist
$(BUILD_PATH):
	@mkdir -p $(BUILD_PATH)

# Build the project
build: check-tools $(BUILD_PATH)
	@echo "Building $(PROJECT_NAME)..."
	@echo "Compiling assembly code..."
	@$(JAVA) -jar $(KICKASS_BIN) $(KICKASS_OPTS) $(MAIN_SOURCE) || { echo "Assembly failed!"; exit 1; }
	@echo "Converting to cartridge format..."
	@$(CARTCONV) -t ulti -n "$(PROJECT_NAME)" -i $(PRG_FILE) -o $(CRT_FILE) || { echo "CRT conversion failed!"; exit 1; }
	@echo "Creating binary for EPROM..."
	@$(CARTCONV) -i $(CRT_FILE) -o $(BIN_FILE) || { echo "BIN conversion failed!"; exit 1; }
	@echo "Build complete!"
	@echo "Generated files:"
	@echo "  - $(PRG_FILE)"
	@echo "  - $(CRT_FILE)"
	@echo "  - $(BIN_FILE)"

# Run in emulator (runs whatever is currently built)
run:
	@echo "Starting $(PROJECT_NAME) in VICE..."
	@command -v $(X64SC) >/dev/null 2>&1 || { echo "Error: x64sc not found. Please install VICE."; exit 1; }
	@test -f $(CRT_FILE) || { echo "Error: No cartridge file found. Run 'make' or 'make test-mode' first."; exit 1; }
	@$(X64SC) $(CRT_FILE)

# Build and run in one step
build-and-run: build run

# Run with debug options (runs whatever is currently built)
debug:
	@echo "Starting $(PROJECT_NAME) in VICE with monitor..."
	@command -v $(X64SC) >/dev/null 2>&1 || { echo "Error: x64sc not found. Please install VICE."; exit 1; }
	@test -f $(CRT_FILE) || { echo "Error: No cartridge file found. Run 'make' or 'make test-mode' first."; exit 1; }
	@$(X64SC) -moncommands $(BUILD_PATH)/monitor.txt $(CRT_FILE) 2>/dev/null || $(X64SC) $(CRT_FILE)

# Build with test mode enabled (simulates RAM failure for validation)
test-mode: check-tools $(BUILD_PATH)
	@echo "Building $(PROJECT_NAME) in TEST MODE..."
	@echo "WARNING: This build will intentionally FAIL the Low RAM test!"
	@echo "Expected: U21 (bit 0) will show as BAD in the chip diagram"
	@echo ""
	@echo "Compiling with TEST_MODE_ENABLED defined..."
	@$(JAVA) -jar $(KICKASS_BIN) $(KICKASS_OPTS) -define TEST_MODE_ENABLED $(MAIN_SOURCE) || { \
		echo "Assembly failed!"; \
		exit 1; \
	}
	@echo "Converting to cartridge format..."
	@$(CARTCONV) -t ulti -n "$(PROJECT_NAME)" -i $(PRG_FILE) -o $(CRT_FILE) || { echo "CRT conversion failed!"; exit 1; }
	@echo "Creating binary for EPROM..."
	@$(CARTCONV) -i $(CRT_FILE) -o $(BIN_FILE) || { echo "BIN conversion failed!"; exit 1; }
	@echo ""
	@echo "TEST MODE build complete!"
	@echo "This build will show LOW RAM as BAD with U21 chip failure."
	@echo "Run with: make run  OR  x64sc $(CRT_FILE)"
	@echo ""
	@echo "Note: No source files modified - test mode uses compile-time flag"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_PATH)
	@echo "Clean complete."

# Test in emulator (automated)
test: build
	@echo "Running automated test in VICE..."
	@command -v $(X64SC) >/dev/null 2>&1 || { echo "Error: x64sc not found. Please install VICE."; exit 1; }
	@echo "Starting test run (will timeout after 30 seconds)..."
	@timeout 30s $(X64SC) -default -warp -exitscreenshot $(BUILD_PATH)/test-result.png $(CRT_FILE) 2>/dev/null || true
	@if [ -f $(BUILD_PATH)/test-result.png ]; then \
		echo "Test completed - screenshot saved to $(BUILD_PATH)/test-result.png"; \
	else \
		echo "Test completed - no screenshot generated"; \
	fi

# Create release package
release: clean build
	@echo "Creating release package v$(VERSION)..."
	@mkdir -p releases
	@cp $(BIN_FILE) releases/dead-test-v$(VERSION).bin
	@cp $(CRT_FILE) releases/dead-test-v$(VERSION).crt
	@cp $(PRG_FILE) releases/dead-test-v$(VERSION).prg
	@cd releases && zip dead-test-v$(VERSION).zip dead-test-v$(VERSION).*
	@echo "Release package created: releases/dead-test-v$(VERSION).zip"
	@ls -la releases/dead-test-v$(VERSION).*

# Check code style (basic validation)
check: $(SRC_PATH)/*.asm
	@echo "Checking assembly files..."
	@for file in $(SRC_PATH)/*.asm; do \
		echo "Checking $$file..."; \
		grep -q "#importonce" $$file || echo "Warning: $$file missing #importonce"; \
	done
	@echo "Style check complete."

# Show version
version:
	@echo "C64 Dead Test Diagnostic v$(VERSION)"
	@echo "Based on original rev. 781220"

# Show help
help:
	@echo "Commodore 64 Dead Test - Build System"
	@echo "====================================="
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Main Targets:"
	@echo "  all          - Build the project (default)"
	@echo "  build        - Compile and create .prg, .crt, and .bin files"
	@echo "  run          - Run currently built cartridge in VICE emulator"
	@echo "  build-and-run- Build and run in one step"
	@echo "  debug        - Run with VICE monitor (no rebuild)"
	@echo "  test         - Run automated test in VICE"
	@echo "  clean        - Remove all build artifacts"
	@echo ""
	@echo "Development Targets:"
	@echo "  test-mode    - Build with simulated RAM failure (Low RAM U21 chip)"
	@echo "  check        - Basic code style validation"
	@echo "  check-tools  - Verify required tools are installed"
	@echo "  release      - Create release package (v$(VERSION))"
	@echo "  version      - Show current version"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  KICKASS_BIN  - Path to KickAssembler JAR (current: $(KICKASS_BIN))"
	@echo "  JAVA         - Java command (current: $(JAVA))"
	@echo "  CARTCONV     - cartconv command (current: $(CARTCONV))"
	@echo "  X64SC        - VICE emulator command (current: $(X64SC))"
	@echo "  VERSION      - Version number (current: $(VERSION))"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Build the project"
	@echo "  make build-and-run      # Build and run in emulator"
	@echo "  make test-mode && make run  # Test RAM failure simulation"
	@echo "  make test               # Run automated test"
	@echo "  make release            # Create release package"
	@echo "  make VERSION=1.3.0 release  # Create release with custom version"
	@echo "  make KICKASS_BIN=/path/to/KickAss.jar  # Use custom KickAssembler path"