#!/usr/bin/env bash

set -euo pipefail


ROOT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd
)"

if [[ "${EUID}" -eq 0 ]]; then
    echo "Error: run this script as the normal desktop user."
    echo "The script will request sudo only when necessary."
    exit 1
fi


SYS_LOCK="/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen"

TARGET_UI="$SYS_LOCK/LockScreenUi.qml"
DIVERT_UI="$SYS_LOCK/LockScreenUi.qml.telysta-dist"

FADER_SOURCE="$ROOT_DIR/files/TelystaWallpaperFader.qml"

LOCK_PATCH="$ROOT_DIR/patches/patch-lockscreen.py"

echo "========================================"
echo "       Telysta Lock Screen"
echo "========================================"
echo


# --------------------------------------------------
# Requirements
# --------------------------------------------------

command -v python3 >/dev/null || {
    echo "Error: python3 is required."
    exit 1
}

command -v dpkg-divert >/dev/null || {
    echo "Error: dpkg-divert is required."
    echo "This installer currently targets Debian-based systems."
    exit 1
}

[[ -f "$TARGET_UI" || -f "$DIVERT_UI" ]] || {
    echo "Error: KDE LockScreenUi.qml was not found."
    exit 1
}

[[ -f "$FADER_SOURCE" ]] || {
    echo "Error: TelystaWallpaperFader.qml was not found."
    exit 1
}


# --------------------------------------------------
# Verify Plasma shell
# --------------------------------------------------

if command -v kreadconfig6 >/dev/null; then

    shell_package="$(
        kreadconfig6 \
            --file plasmashellrc \
            --group Shell \
            --key ShellPackage \
            2>/dev/null || true
    )"

    if [[ -n "$shell_package" ]] \
        && [[ "$shell_package" != "org.kde.plasma.desktop" ]]; then

        echo "Error: unsupported Plasma Shell:"
        echo "  $shell_package"
        echo
        echo "Telysta LockScreen expects:"
        echo "  org.kde.plasma.desktop"

        exit 1
    fi
fi


# --------------------------------------------------
# Detect diversion
# --------------------------------------------------

diversion="$(
    dpkg-divert --list "$TARGET_UI" 2>/dev/null || true
)"

if [[ -n "$diversion" ]]; then

    if ! grep -Fq "$DIVERT_UI" <<< "$diversion"; then
        echo "Error: LockScreenUi.qml is already diverted"
        echo "by another package or customization:"
        echo
        echo "$diversion"
        exit 1
    fi

    UPSTREAM_UI="$DIVERT_UI"

else

    UPSTREAM_UI="$TARGET_UI"

fi


# --------------------------------------------------
# Generate patched LockScreenUi.qml
# --------------------------------------------------

TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT


python3 \
    "$LOCK_PATCH" \
    "$UPSTREAM_UI" \
    "$TMP_DIR/LockScreenUi.qml"


# --------------------------------------------------
# Create Debian diversion
# --------------------------------------------------

if [[ -z "$diversion" ]]; then

    echo
    echo "Creating dpkg diversion..."

    sudo dpkg-divert \
        --local \
        --quiet \
        --add \
        --rename \
        --divert "$DIVERT_UI" \
        "$TARGET_UI"

fi


# --------------------------------------------------
# Install Telysta lock screen files
# --------------------------------------------------

echo "Installing TelystaWallpaperFader..."

sudo install \
    -m 0644 \
    "$FADER_SOURCE" \
    "$SYS_LOCK/TelystaWallpaperFader.qml"


echo "Installing patched LockScreenUi.qml..."

sudo install \
    -m 0644 \
    "$TMP_DIR/LockScreenUi.qml" \
    "$TARGET_UI"


# --------------------------------------------------
# Smart Video Wallpaper compatibility patch
# --------------------------------------------------

# if [[ -f "$VIDEO_METADATA" && -f "$VIDEO_MAIN" ]]; then

#     VIDEO_VERSION="$(
#         python3 - "$VIDEO_METADATA" <<'PY'
# import json
# import sys

# with open(sys.argv[1], encoding="utf-8") as f:
#     data = json.load(f)

# print(data.get("KPlugin", {}).get("Version", ""))
# PY
#     )"

#     if [[ "$VIDEO_VERSION" == "2.15.0" ]]; then

#         echo
#         echo "Applying Smart Video Wallpaper 2.15.0 compatibility patch..."

#         python3 \
#             "$VIDEO_PATCH" \
#             apply \
#             "$VIDEO_MAIN"

#     else

#         echo
#         echo "Warning:"
#         echo "Smart Video Wallpaper version is:"
#         echo "  ${VIDEO_VERSION:-unknown}"
#         echo
#         echo "Telysta will not patch an unverified version."

#     fi

# else

#     echo
#     echo "Warning:"
#     echo "Smart Video Wallpaper Reborn was not found."
#     echo "Lock screen UI will still work, but video wallpaper"
#     echo "compatibility was not configured."

# fi


echo
echo "========================================"
echo " Telysta Lock Screen applied successfully"
echo "========================================"

