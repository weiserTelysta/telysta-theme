#!/usr/bin/env python3

from pathlib import Path
import sys


if len(sys.argv) != 3:
    raise SystemExit(
        "Usage: patch-smart-video-2.15.0.py "
        "<apply|restore> <main.qml>"
    )

mode = sys.argv[1]
path = Path(sys.argv[2])

if mode not in {"apply", "restore"}:
    raise SystemExit("Mode must be apply or restore.")

if not path.is_file():
    raise SystemExit(f"File not found: {path}")

text = path.read_text(encoding="utf-8")


pairs = [
    (
        'if (Plasmoid.activity === undefined) {',
        'if (typeof Plasmoid === "undefined" '
        '|| Plasmoid.activity === undefined) {',
    ),
    (
        'instanceId: Plasmoid.id ?? ""',
        'instanceId: typeof Plasmoid !== "undefined" '
        '? (Plasmoid.id ?? "") : ""',
    ),
    (
        'text += `id: ${Plasmoid.id}\\n`;',
        'text += `id: ${typeof Plasmoid !== "undefined" '
        '? Plasmoid.id : ""}\\n`;',
    ),
]


changed = False

for original, patched in pairs:

    if mode == "apply":
        old = original
        new = patched
    else:
        old = patched
        new = original

    old_count = text.count(old)
    new_count = text.count(new)

    if old_count == 1 and new_count == 0:
        text = text.replace(old, new, 1)
        changed = True

    elif old_count == 0 and new_count == 1:
        # 已经处于目标状态
        continue

    else:
        raise SystemExit(
            "Unexpected Smart Video Wallpaper source structure:\n"
            f"old occurrences = {old_count}\n"
            f"new occurrences = {new_count}\n"
            f"target = {old}"
        )


if changed:
    path.write_text(text, encoding="utf-8")


print(
    "Smart Video Wallpaper compatibility patch "
    f"{mode}: {'updated' if changed else 'already correct'}."
)
