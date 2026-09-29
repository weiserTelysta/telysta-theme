#!/usr/bin/env bash

set -euo pipefail


ROOT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd
)"


echo
echo "========================================"
echo "        Telysta Dependencies"
echo "========================================"
echo


echo "[1/1] Smart Video Wallpaper Reborn"

"$ROOT_DIR/SmartVideoWallpaper/apply.sh"


echo
echo "========================================"
echo " Dependencies configured successfully"
echo "========================================"

