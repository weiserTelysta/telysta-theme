#!/usr/bin/env bash

set -euo pipefail


SYS_LOCK="/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen"

TARGET_UI="$SYS_LOCK/LockScreenUi.qml"
DIVERT_UI="$SYS_LOCK/LockScreenUi.qml.telysta-dist"

TELYSTA_FADER="$SYS_LOCK/TelystaWallpaperFader.qml"


echo "========================================"
echo "     Restore KDE Breeze Lock Screen"
echo "========================================"
echo


# --------------------------------------------------
# Detect Telysta diversion
# --------------------------------------------------

diversion="$(
    dpkg-divert --list "$TARGET_UI" 2>/dev/null || true
)"

if [[ -n "$diversion" ]] \
    && grep -Fq "$DIVERT_UI" <<< "$diversion"; then

    echo "Removing Telysta LockScreenUi.qml..."

    sudo rm -f "$TARGET_UI"

    echo "Removing TelystaWallpaperFader.qml..."

    sudo rm -f "$TELYSTA_FADER"

    echo "Restoring original KDE LockScreenUi.qml..."

    sudo dpkg-divert \
        --local \
        --quiet \
        --remove \
        --rename \
        --divert "$DIVERT_UI" \
        "$TARGET_UI"

else

    echo "No Telysta dpkg diversion found."

    # 即便 diversion 不存在，也清理可能残留的 Telysta 文件。
    sudo rm -f "$TELYSTA_FADER"

fi


echo
echo "========================================"
echo " KDE Breeze Lock Screen restored"
echo "========================================"
echo
echo "Note:"
echo "Smart Video Wallpaper compatibility patches"
echo "are intentionally preserved."
