#!/usr/bin/env python3
"""Build palettes.bin from the fceu_palettes.h table.

Each entry is packed as:
  char name[32]          — short id (first quoted string)
  uint32_t data[64]      — RGB888 colours (little-endian)

Matching struct st_palettes in src/porting/main_nes_fceu.c.
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path


def parse_palettes(text: str) -> list[tuple[str, list[int]]]:
    palettes: list[tuple[str, list[int]]] = []
    for block in text.split("},"):
        lines = [line.strip() for line in block.splitlines() if line.strip()]
        if not lines or "{" not in lines[0]:
            continue

        name_line = lines[0]
        if '"' not in name_line:
            continue
        name = name_line.split('"')[1]

        joined = "".join(lines[1:])
        if "{" not in joined:
            continue
        colors_str = joined.split("{", 1)[1].replace("}", "").strip()
        colors = [int(c.strip(), 16) for c in colors_str.split(",") if c.strip()]
        if len(colors) != 64:
            sys.exit(f"error: palette '{name}' has {len(colors)} colours (want 64)")
        palettes.append((name, colors))
    return palettes


def write_binary(palettes: list[tuple[str, list[int]]], output: Path) -> None:
    with output.open("wb") as f:
        for name, colors in palettes:
            name_bytes = name.encode("utf-8").ljust(32, b"\0")[:32]
            f.write(name_bytes)
            f.write(struct.pack(f"<{len(colors)}I", *colors))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--input",
        type=Path,
        default=Path("src/assets/fceu_palettes.h"),
        help="palette table header",
    )
    ap.add_argument("output", type=Path, help="output palettes.bin")
    args = ap.parse_args()

    if not args.input.is_file():
        sys.exit(f"error: input not found: {args.input}")

    palettes = parse_palettes(args.input.read_text())
    if not palettes:
        sys.exit(f"error: no palettes parsed from {args.input}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    write_binary(palettes, args.output)
    entry = 32 + 64 * 4
    print(
        f"gen_fceu_palettes_table: {args.output} "
        f"({len(palettes)} palettes, {args.output.stat().st_size} bytes, "
        f"{entry} B/entry)"
    )


if __name__ == "__main__":
    main()
