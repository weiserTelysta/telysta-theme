#!/usr/bin/env python3

from pathlib import Path
import re
import sys


if len(sys.argv) != 3:
    raise SystemExit(
        "Usage: patch-lockscreen.py <source> <destination>"
    )

source = Path(sys.argv[1])
destination = Path(sys.argv[2])

if not source.is_file():
    raise SystemExit(f"Source file not found: {source}")

text = source.read_text(encoding="utf-8")


# 已经被 Telysta patch
if "TelystaWallpaperFader {" in text:
    if "effectStrength: 0.28" not in text:
        raise SystemExit(
            "TelystaWallpaperFader exists, "
            "but effectStrength is not the expected value."
        )

    destination.write_text(text, encoding="utf-8")
    print("Lock screen already patched.")
    raise SystemExit(0)


pattern = re.compile(
    r"(?m)^([ \t]*)WallpaperFader\s*\{\s*\n"
    r"([ \t]+)anchors\.fill:\s*parent\s*$"
)

matches = list(pattern.finditer(text))

if len(matches) != 1:
    raise SystemExit(
        "Unsupported LockScreenUi.qml structure: "
        f"expected exactly one WallpaperFader block, "
        f"found {len(matches)}."
    )


match = matches[0]

parent_indent = match.group(1)
child_indent = match.group(2)

replacement = (
    f"{parent_indent}TelystaWallpaperFader {{\n"
    f"{child_indent}anchors.fill: parent\n"
    f"\n"
    f"{child_indent}effectStrength: 0.28"
)

patched = pattern.sub(
    replacement,
    text,
    count=1,
)

if "TelystaWallpaperFader {" not in patched:
    raise SystemExit("Patch verification failed.")

if "effectStrength: 0.28" not in patched:
    raise SystemExit("effectStrength verification failed.")

destination.write_text(
    patched,
    encoding="utf-8",
)

print("Telysta lock screen patch generated successfully.")
