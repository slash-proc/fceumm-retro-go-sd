#!/usr/bin/env python3
"""Append mappers.pak + ines_correct.bin after a packed CORE .bin.

Layout (all little-endian):

    [existing CORE container from pack_core.py]
    [mappers.pak bytes]
    [ines_correct.bin bytes]
    [footer 24 bytes]
        magic        u32  'FCAS' (0x53414346)
        version      u32  1
        mappers_off  u32  absolute file offset of mappers.pak
        mappers_size u32
        ines_off     u32  absolute file offset of ines_correct.bin
        ines_size    u32

The firmware loader only copies declared CORE segments, so the trailer is
ignored at load time. The core opens its own .bin and seeks using the footer.
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

MAGIC = 0x53414346  # 'F','C','A','S'
VERSION = 1
FOOTER_SIZE = 24


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--core", type=Path, required=True, help="packed CORE .bin (updated in place)")
    ap.add_argument("--mappers", type=Path, required=True, help="mappers.pak")
    ap.add_argument("--ines", type=Path, required=True, help="ines_correct.bin")
    args = ap.parse_args()

    if not args.core.is_file():
        sys.exit(f"error: core not found: {args.core}")
    if not args.mappers.is_file():
        sys.exit(f"error: mappers.pak not found: {args.mappers}")
    if not args.ines.is_file():
        sys.exit(f"error: ines_correct.bin not found: {args.ines}")

    core = args.core.read_bytes()
    # Idempotent: strip a previous FCAS footer + sidecars if re-packing.
    if len(core) >= FOOTER_SIZE:
        magic, ver, m_off, m_sz, i_off, i_sz = struct.unpack_from("<IIIIII", core, len(core) - FOOTER_SIZE)
        if magic == MAGIC and ver == VERSION:
            cut = min(m_off, i_off)
            if cut > 0 and cut < len(core) and m_off + m_sz <= len(core) - FOOTER_SIZE:
                core = core[:cut]

    mappers = args.mappers.read_bytes()
    ines = args.ines.read_bytes()
    if not mappers:
        sys.exit("error: mappers.pak is empty")
    if not ines:
        sys.exit("error: ines_correct.bin is empty")

    mappers_off = len(core)
    ines_off = mappers_off + len(mappers)
    footer = struct.pack(
        "<IIIIII",
        MAGIC,
        VERSION,
        mappers_off,
        len(mappers),
        ines_off,
        len(ines),
    )
    out = core + mappers + ines + footer
    args.core.write_bytes(out)

    print(
        f"append_fceumm_sidecars: {args.core} "
        f"({len(out)} bytes; core={mappers_off}, "
        f"mappers@{mappers_off}+{len(mappers)}, "
        f"ines@{ines_off}+{len(ines)})"
    )


if __name__ == "__main__":
    main()
