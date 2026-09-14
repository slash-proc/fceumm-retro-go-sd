#!/usr/bin/env python3
"""Append mappers.pak + ines_correct.bin + palettes.bin after a packed CORE .bin.

Layout (all little-endian):

    [existing CORE container from pack_core.py]
    [mappers.pak bytes]
    [ines_correct.bin bytes]
    [palettes.bin bytes]
    [footer 32 bytes]
        magic         u32  'FCAS' (0x53414346)
        version       u32  2
        mappers_off   u32  absolute file offset of mappers.pak
        mappers_size  u32
        ines_off      u32  absolute file offset of ines_correct.bin
        ines_size     u32
        palettes_off  u32  absolute file offset of palettes.bin
        palettes_size u32

The firmware loader only copies declared CORE segments, so the trailer is
ignored at load time. The core opens its own .bin and seeks using the footer.

Older v1 footers (24 bytes, no palettes) are stripped on re-pack and no longer
emitted.
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

MAGIC = 0x53414346  # 'F','C','A','S'
VERSION = 2
FOOTER_SIZE_V1 = 24
FOOTER_SIZE_V2 = 32


def strip_previous_footer(core: bytes) -> bytes:
    """Remove a previous FCAS trailer + sidecars if present (v1 or v2)."""
    for footer_size, nfields in ((FOOTER_SIZE_V2, 8), (FOOTER_SIZE_V1, 6)):
        if len(core) < footer_size:
            continue
        fields = struct.unpack_from(f"<{nfields}I", core, len(core) - footer_size)
        magic, ver = fields[0], fields[1]
        if magic != MAGIC:
            continue
        if footer_size == FOOTER_SIZE_V2 and ver != 2:
            continue
        if footer_size == FOOTER_SIZE_V1 and ver != 1:
            continue
        # Offsets live at fields[2], [4], and (v2) [6].
        offs = [fields[i] for i in range(2, nfields, 2) if fields[i] > 0]
        if not offs:
            continue
        cut = min(offs)
        if 0 < cut < len(core):
            return core[:cut]
    return core


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--core", type=Path, required=True, help="packed CORE .bin (updated in place)")
    ap.add_argument("--mappers", type=Path, required=True, help="mappers.pak")
    ap.add_argument("--ines", type=Path, required=True, help="ines_correct.bin")
    ap.add_argument("--palettes", type=Path, required=True, help="palettes.bin")
    args = ap.parse_args()

    for label, path in (
        ("core", args.core),
        ("mappers.pak", args.mappers),
        ("ines_correct.bin", args.ines),
        ("palettes.bin", args.palettes),
    ):
        if not path.is_file():
            sys.exit(f"error: {label} not found: {path}")

    core = strip_previous_footer(args.core.read_bytes())
    mappers = args.mappers.read_bytes()
    ines = args.ines.read_bytes()
    palettes = args.palettes.read_bytes()
    if not mappers:
        sys.exit("error: mappers.pak is empty")
    if not ines:
        sys.exit("error: ines_correct.bin is empty")
    if not palettes:
        sys.exit("error: palettes.bin is empty")

    mappers_off = len(core)
    ines_off = mappers_off + len(mappers)
    palettes_off = ines_off + len(ines)
    footer = struct.pack(
        "<IIIIIIII",
        MAGIC,
        VERSION,
        mappers_off,
        len(mappers),
        ines_off,
        len(ines),
        palettes_off,
        len(palettes),
    )
    out = core + mappers + ines + palettes + footer
    args.core.write_bytes(out)

    print(
        f"append_fceumm_sidecars: {args.core} "
        f"({len(out)} bytes; core={mappers_off}, "
        f"mappers@{mappers_off}+{len(mappers)}, "
        f"ines@{ines_off}+{len(ines)}, "
        f"palettes@{palettes_off}+{len(palettes)})"
    )


if __name__ == "__main__":
    main()
