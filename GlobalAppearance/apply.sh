#!/usr/bin/env bash

set -euo pipefail

echo "Applying Telysta global appearance..."

# ============================================================
# GTK / cross-desktop dark preference
# ============================================================

if command -v gsettings >/dev/null 2>&1; then
    if gsettings list-keys org.gnome.desktop.interface 2>/dev/null \
        | grep -qx "color-scheme"; then

        gsettings set \
            org.gnome.desktop.interface \
            color-scheme \
            'prefer-dark'

        echo "  Dark appearance preference: enabled"
    else
        echo "  GTK color-scheme preference is not available."
    fi
else
    echo "  gsettings not found, skipping GTK appearance preference."
fi

echo "Global appearance applied."
