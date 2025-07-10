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

# Phony targets
.PHONY: all build clean run debug help check-tools

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

# Run in emulator
run: build
	@echo "Starting $(PROJECT_NAME) in VICE..."
	@command -v $(X64SC) >/dev/null 2>&1 || { echo "Error: x64sc not found. Please install VICE."; exit 1; }
	@$(X64SC) $(CRT_FILE)

# Run with debug options
debug: build
	@echo "Starting $(PROJECT_NAME) in VICE with monitor..."
	@command -v $(X64SC) >/dev/null 2>&1 || { echo "Error: x64sc not found. Please install VICE."; exit 1; }
	@$(X64SC) -moncommands $(BUILD_PATH)/monitor.txt $(CRT_FILE) 2>/dev/null || $(X64SC) $(CRT_FILE)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_PATH)
	@echo "Clean complete."

# Show help
help:
	@echo "Commodore 64 Dead Test - Build System"
	@echo "====================================="
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build the project (default)"
	@echo "  build        - Compile and create .prg, .crt, and .bin files"
	@echo "  run          - Build and run in VICE emulator"
	@echo "  debug        - Build and run with VICE monitor"
	@echo "  clean        - Remove all build artifacts"
	@echo "  check-tools  - Verify required tools are installed"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  KICKASS_BIN  - Path to KickAssembler JAR (current: $(KICKASS_BIN))"
	@echo "  JAVA         - Java command (current: $(JAVA))"
	@echo "  CARTCONV     - cartconv command (current: $(CARTCONV))"
	@echo "  X64SC        - VICE emulator command (current: $(X64SC))"
	@echo ""
	@echo "Example:"
	@echo "  make                    # Build the project"
	@echo "  make run                # Build and run in emulator"
	@echo "  make clean              # Clean build files"
	@echo "  make KICKASS_BIN=/path/to/KickAss.jar  # Use custom KickAssembler path"