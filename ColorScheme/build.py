#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import sys
import tomllib
from pathlib import Path
from typing import Any


# ==============================================================================
# Paths
# ==============================================================================

ROOT = Path(__file__).resolve().parent

DEFAULT_PALETTE = ROOT / "palettes" / "catppuccin-mocha.toml"
DEFAULT_MAPPING = ROOT / "mappings" / "kde.toml"
DEFAULT_TEMPLATE = ROOT / "templates" / "kde.colors.template"
DEFAULT_OUTPUT_DIR = ROOT / "generated"


# ==============================================================================
# Template syntax
# ==============================================================================

PLACEHOLDER_PATTERN = re.compile(
    r"\{\{\s*([A-Za-z0-9_.:-]+)\s*\}\}"
)


# ==============================================================================
# Mapping sections whose values must refer to palette colors
# ==============================================================================

PALETTE_REFERENCE_SECTIONS = {
    "window",
    "view",
    "button",
    "header",
    "header_inactive",
    "tooltip",
    "complementary",
    "selection",
    "accent",
    "semantic",
    "wm",
}

PALETTE_REFERENCE_PATHS = {
    "effects.disabled.color",
    "effects.inactive.color",
}


# ==============================================================================
# Errors
# ==============================================================================


class BuildError(Exception):
    """Raised when the color scheme cannot be generated."""


# ==============================================================================
# TOML
# ==============================================================================


def load_toml(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise BuildError(f"File not found:\n  {path}")

    try:
        with path.open("rb") as file:
            return tomllib.load(file)

    except tomllib.TOMLDecodeError as exc:
        raise BuildError(
            f"Invalid TOML:\n"
            f"  {path}\n\n"
            f"{exc}"
        ) from exc


# ==============================================================================
# HEX / RGB
# ==============================================================================


def hex_to_rgb(value: str) -> str:
    """
    Convert:

        #1e1e2e

    to:

        30,30,46
    """

    if not re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
        raise BuildError(
            f"Invalid HEX color: {value!r}\n"
            f"Expected format: #RRGGBB"
        )

    value = value.removeprefix("#")

    red = int(value[0:2], 16)
    green = int(value[2:4], 16)
    blue = int(value[4:6], 16)

    return f"{red},{green},{blue}"


# ==============================================================================
# Nested mapping lookup
# ==============================================================================


def get_nested_value(
    data: dict[str, Any],
    path: str,
) -> Any:
    """
    Resolve:

        window.background

    as:

        data["window"]["background"]
    """

    current: Any = data

    for part in path.split("."):
        if not isinstance(current, dict):
            raise BuildError(
                f"Cannot resolve mapping path:\n"
                f"  {path}\n\n"
                f"'{part}' is not inside a table."
            )

        if part not in current:
            raise BuildError(
                f"Missing mapping value:\n"
                f"  {path}"
            )

        current = current[part]

    return current


# ==============================================================================
# Determine whether a mapping value represents a palette color
# ==============================================================================


def is_palette_reference(path: str) -> bool:
    if path in PALETTE_REFERENCE_PATHS:
        return True

    root = path.split(".", 1)[0]

    return root in PALETTE_REFERENCE_SECTIONS


# ==============================================================================
# Output formatting
# ==============================================================================


def format_raw_value(value: Any) -> str:
    """
    Convert ordinary TOML values to KDE-compatible text.
    """

    if isinstance(value, bool):
        return "true" if value else "false"

    if isinstance(value, (int, float, str)):
        return str(value)

    raise BuildError(
        f"Unsupported mapping value type:\n"
        f"  {type(value).__name__}"
    )


# ==============================================================================
# Palette resolution
# ==============================================================================


def resolve_palette_color(
    palette: dict[str, str],
    color_name: Any,
    mapping_path: str,
) -> str:
    if not isinstance(color_name, str):
        raise BuildError(
            f"Palette reference must be a string:\n"
            f"  {mapping_path}\n\n"
            f"Received: {color_name!r}"
        )

    if color_name not in palette:
        available = ", ".join(sorted(palette.keys()))

        raise BuildError(
            f"Unknown palette color:\n"
            f"  {color_name}\n\n"
            f"Referenced by:\n"
            f"  {mapping_path}\n\n"
            f"Available colors:\n"
            f"  {available}"
        )

    return hex_to_rgb(palette[color_name])


# ==============================================================================
# Validate palette
# ==============================================================================


def validate_palette(palette_data: dict[str, Any]) -> dict[str, str]:
    colors = palette_data.get("colors")

    if not isinstance(colors, dict):
        raise BuildError(
            "Palette TOML must contain a [colors] table."
        )

    if not colors:
        raise BuildError(
            "Palette [colors] table is empty."
        )

    validated: dict[str, str] = {}

    for name, value in colors.items():
        if not isinstance(value, str):
            raise BuildError(
                f"Palette color '{name}' must be a string."
            )

        # Validate HEX now, even though conversion happens later.
        hex_to_rgb(value)

        validated[name] = value

    return validated


# ==============================================================================
# Template renderer
# ==============================================================================


def render_template(
    template: str,
    mapping: dict[str, Any],
    palette: dict[str, str],
) -> str:
    used_placeholders: set[str] = set()

    def replace(match: re.Match[str]) -> str:
        path = match.group(1)

        used_placeholders.add(path)

        value = get_nested_value(mapping, path)

        if is_palette_reference(path):
            return resolve_palette_color(
                palette=palette,
                color_name=value,
                mapping_path=path,
            )

        return format_raw_value(value)

    rendered = PLACEHOLDER_PATTERN.sub(replace, template)

    # Catch malformed / unresolved template expressions.
    remaining = PLACEHOLDER_PATTERN.findall(rendered)

    if remaining:
        raise BuildError(
            "Unresolved template placeholders:\n  "
            + "\n  ".join(sorted(set(remaining)))
        )

    return rendered


# ==============================================================================
# Command line
# ==============================================================================


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build the Telysta KDE color scheme."
    )

    parser.add_argument(
        "--palette",
        type=Path,
        default=DEFAULT_PALETTE,
        help=(
            "Palette TOML file "
            f"(default: {DEFAULT_PALETTE.relative_to(ROOT)})"
        ),
    )

    parser.add_argument(
        "--mapping",
        type=Path,
        default=DEFAULT_MAPPING,
        help=(
            "KDE mapping TOML file "
            f"(default: {DEFAULT_MAPPING.relative_to(ROOT)})"
        ),
    )

    parser.add_argument(
        "--template",
        type=Path,
        default=DEFAULT_TEMPLATE,
        help=(
            "KDE .colors template "
            f"(default: {DEFAULT_TEMPLATE.relative_to(ROOT)})"
        ),
    )

    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output .colors file.",
    )

    return parser.parse_args()


# ==============================================================================
# Build
# ==============================================================================


def build(args: argparse.Namespace) -> Path:
    palette_path = args.palette.resolve()
    mapping_path = args.mapping.resolve()
    template_path = args.template.resolve()

    palette_data = load_toml(palette_path)
    mapping_data = load_toml(mapping_path)

    palette = validate_palette(palette_data)

    if not template_path.exists():
        raise BuildError(
            f"Template not found:\n  {template_path}"
        )

    template = template_path.read_text(
        encoding="utf-8"
    )

    rendered = render_template(
        template=template,
        mapping=mapping_data,
        palette=palette,
    )

    # --------------------------------------------------------------------------
    # Determine output filename
    # --------------------------------------------------------------------------

    if args.output is not None:
        output_path = args.output.resolve()

    else:
        try:
            scheme_id = get_nested_value(
                mapping_data,
                "meta.scheme_id",
            )

        except BuildError:
            scheme_id = "Telysta"

        if not isinstance(scheme_id, str):
            raise BuildError(
                "meta.scheme_id must be a string."
            )

        DEFAULT_OUTPUT_DIR.mkdir(
            parents=True,
            exist_ok=True,
        )

        output_path = (
            DEFAULT_OUTPUT_DIR
            / f"{scheme_id}.colors"
        )

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    # --------------------------------------------------------------------------
    # Write only after the entire build succeeds
    # --------------------------------------------------------------------------

    output_path.write_text(
        rendered.rstrip() + "\n",
        encoding="utf-8",
    )

    return output_path


# ==============================================================================
# Main
# ==============================================================================


def main() -> int:
    args = parse_arguments()

    try:
        output_path = build(args)

    except BuildError as exc:
        print(
            "\nBuild failed.\n",
            file=sys.stderr,
        )

        print(
            exc,
            file=sys.stderr,
        )

        print(
            file=sys.stderr,
        )

        return 1

    print()
    print("Telysta KDE color scheme built successfully.")
    print()
    print(f"Output:")
    print(f"  {output_path}")
    print()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
