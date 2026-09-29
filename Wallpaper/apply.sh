#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Paths
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

WALLPAPER_NAME="6th_wallpaper.mp4"

SOURCE_VIDEO="$ROOT_DIR/Assets/$WALLPAPER_NAME"

TARGET_DIR="$HOME/.local/share/wallpapers/Telysta"
TARGET_VIDEO="$TARGET_DIR/$WALLPAPER_NAME"

# ============================================================
# Start
# ============================================================

echo "Applying Telysta video wallpaper..."

# ============================================================
# Check source asset
# ============================================================

if [[ ! -f "$SOURCE_VIDEO" ]]; then
    echo "Error: wallpaper asset was not found:"
    echo "  $SOURCE_VIDEO"
    exit 1
fi

# ============================================================
# Check Plasma video support
# ============================================================

missing_packages=()

for package in \
    libqt6multimedia6 \
    qml6-module-qtmultimedia
do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null \
        | grep -q "install ok installed"; then
        missing_packages+=("$package")
    fi
done

if (( ${#missing_packages[@]} > 0 )); then
    echo "  Warning: missing multimedia packages:"
    printf '    %s\n' "${missing_packages[@]}"
    echo
    echo "  Install them with:"
    echo "    sudo apt install ${missing_packages[*]}"
    echo
fi

# ============================================================
# Install wallpaper asset
# ============================================================

mkdir -p "$TARGET_DIR"

if [[ -f "$TARGET_VIDEO" ]] && cmp -s "$SOURCE_VIDEO" "$TARGET_VIDEO"; then
    echo "  Wallpaper asset already up to date."
else
    cp -f "$SOURCE_VIDEO" "$TARGET_VIDEO"
    echo "  Wallpaper asset installed."
fi

# ============================================================
# Result
# ============================================================

echo
echo "Telysta video wallpaper installed successfully."
echo
echo "Source:"
echo "  $SOURCE_VIDEO"
echo
echo "Installed:"
echo "  $TARGET_VIDEO"
