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


echo "Restoring Smart Video Wallpaper compatibility patch..."


if [[ ! -f "$METADATA" || ! -f "$MAIN_QML" ]]; then
    echo "Smart Video Wallpaper Reborn was not found."
    exit 0
fi


VERSION="$(
    python3 - "$METADATA" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)

print(data.get("KPlugin", {}).get("Version", ""))
PY
)"


if [[ "$VERSION" != "$SUPPORTED_VERSION" ]]; then
    echo "Unsupported plugin version: ${VERSION:-unknown}"
    echo "No files were modified."
    exit 1
fi


python3 \
    "$PATCH_215" \
    restore \
    "$MAIN_QML"


echo
echo "Smart Video Wallpaper restored to upstream 2.15.0 state."
