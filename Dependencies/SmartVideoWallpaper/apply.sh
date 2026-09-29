#!/usr/bin/env bash

set -euo pipefail


ROOT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd
)"

PLUGIN_ID="luisbocanegra.smart.video.wallpaper.reborn"

PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/$PLUGIN_ID"

METADATA="$PLUGIN_DIR/metadata.json"
MAIN_QML="$PLUGIN_DIR/contents/ui/main.qml"

PATCH_215="$ROOT_DIR/patch-2.15.0.py"

SUPPORTED_VERSION="2.15.0"


echo "Checking Smart Video Wallpaper Reborn..."


# --------------------------------------------------
# Detect plugin
# --------------------------------------------------

if [[ ! -f "$METADATA" || ! -f "$MAIN_QML" ]]; then
    echo
    echo "Warning:"
    echo "Smart Video Wallpaper Reborn was not found."
    echo
    echo "Expected location:"
    echo "  $PLUGIN_DIR"
    echo
    echo "Video wallpaper compatibility patch was skipped."
    exit 0
fi


# --------------------------------------------------
# Read version
# --------------------------------------------------

VERSION="$(
    python3 - "$METADATA" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)

print(data.get("KPlugin", {}).get("Version", ""))
PY
)"


if [[ -z "$VERSION" ]]; then
    echo "Error: unable to determine plugin version."
    exit 1
fi


echo "  Detected version: $VERSION"


# --------------------------------------------------
# Version gate
# --------------------------------------------------

if [[ "$VERSION" != "$SUPPORTED_VERSION" ]]; then
    echo
    echo "Warning:"
    echo "Smart Video Wallpaper version $VERSION"
    echo "has not been validated by Telysta."
    echo
    echo "Supported version:"
    echo "  $SUPPORTED_VERSION"
    echo
    echo "No files were modified."
    exit 0
fi


# --------------------------------------------------
# Apply compatibility patch
# --------------------------------------------------

python3 \
    "$PATCH_215" \
    apply \
    "$MAIN_QML"


echo
echo "Smart Video Wallpaper compatibility ready."
