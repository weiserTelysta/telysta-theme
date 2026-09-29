#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "========================================"
echo "        Telysta Theme Installer"
echo "========================================"
echo


# ============================================================
# Environment
# ============================================================

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Error: Telysta Theme currently supports Linux only."
    exit 1
fi

if [[ ! -d "$HOME/.config" ]]; then
    echo "Error: user configuration directory was not found."
    exit 1
fi


# ============================================================
# Color Scheme
# ============================================================

echo "[1/3] KDE Color Scheme"
echo

"$ROOT_DIR/ColorScheme/apply.sh"

echo


# ============================================================
# Global Appearance
# ============================================================

echo "[2/3] Global Appearance"
echo

"$ROOT_DIR/GlobalAppearance/apply.sh"

echo


# ============================================================
# Wallpaper
# ============================================================

echo "[3/3] Wallpaper"
echo

"$ROOT_DIR/Wallpaper/apply.sh"

echo


# ============================================================
# Finished
# ============================================================

echo "========================================"
echo " Telysta Theme installation completed."
echo "========================================"
echo
echo "Some applications may need to be restarted."
echo
