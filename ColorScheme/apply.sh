#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BUILD_SCRIPT="$MODULE_DIR/build.py"
GENERATED_FILE="$MODULE_DIR/generated/Telysta.colors"

TARGET_DIR="$HOME/.local/share/color-schemes"
TARGET_FILE="$TARGET_DIR/Telysta.colors"


echo "Applying Telysta KDE color scheme..."


# ============================================================
# Check dependencies
# ============================================================

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required."
    exit 1
fi

if ! command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    echo "Error: plasma-apply-colorscheme was not found."
    exit 1
fi


# ============================================================
# Build
# ============================================================

echo "  Building color scheme..."

python3 "$BUILD_SCRIPT"


# ============================================================
# Install
# ============================================================

echo "  Installing color scheme..."

mkdir -p "$TARGET_DIR"

# Remove an existing file or development symlink first.
rm -f "$TARGET_FILE"

cp \
    "$GENERATED_FILE" \
    "$TARGET_FILE"


# ============================================================
# Apply
# ============================================================

echo "  Applying Telysta..."

plasma-apply-colorscheme Telysta >/dev/null


echo "  Telysta KDE color scheme applied."
