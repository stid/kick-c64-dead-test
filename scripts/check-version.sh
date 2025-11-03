#!/bin/bash
# Version Consistency Checker
# Validates that VERSION is consistent across all project files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Checking version consistency..."
echo

# Extract version from makefile
MAKEFILE_VERSION=$(grep "^VERSION ?=" makefile | sed 's/VERSION ?= //')
echo "📄 makefile: $MAKEFILE_VERSION"

# Extract version from README.md badge
README_VERSION=$(grep "version-.*-blue" readme.md | sed -E 's/.*version-([0-9.]+)-blue.*/\1/')
echo "📄 README.md badge: $README_VERSION"

# Extract version from src/data.asm
DATA_ASM_VERSION=$(grep "c-64 dead test rev stid" src/data.asm | sed -E 's/.*stid ([0-9.]+).*/\1/')
echo "📄 src/data.asm: $DATA_ASM_VERSION"

# Extract latest version from CHANGELOG.md (skip [Unreleased])
CHANGELOG_VERSION=$(grep "^## \[" CHANGELOG.md | grep -v Unreleased | head -1 | sed -E 's/.*\[([0-9.]+)\].*/\1/')
echo "📄 CHANGELOG.md: $CHANGELOG_VERSION"

echo

# Check if all versions match
VERSIONS_MATCH=true

if [ "$MAKEFILE_VERSION" != "$README_VERSION" ]; then
    echo -e "${RED}❌ Version mismatch: makefile ($MAKEFILE_VERSION) != README.md ($README_VERSION)${NC}"
    VERSIONS_MATCH=false
fi

if [ "$MAKEFILE_VERSION" != "$DATA_ASM_VERSION" ]; then
    echo -e "${RED}❌ Version mismatch: makefile ($MAKEFILE_VERSION) != src/data.asm ($DATA_ASM_VERSION)${NC}"
    VERSIONS_MATCH=false
fi

if [ "$MAKEFILE_VERSION" != "$CHANGELOG_VERSION" ]; then
    echo -e "${RED}❌ Version mismatch: makefile ($MAKEFILE_VERSION) != CHANGELOG.md ($CHANGELOG_VERSION)${NC}"
    VERSIONS_MATCH=false
fi

if [ "$VERSIONS_MATCH" = true ]; then
    echo -e "${GREEN}✅ All version strings match: $MAKEFILE_VERSION${NC}"
    exit 0
else
    echo
    echo -e "${RED}Version consistency check FAILED${NC}"
    echo "Please ensure all version strings are updated consistently."
    exit 1
fi
