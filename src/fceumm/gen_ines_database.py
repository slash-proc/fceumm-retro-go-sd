#!/usr/bin/env python3
import sys
import os
import re
import struct

n = len(sys.argv)

if n < 2: print("Usage :\ngen_ines_database.py output_file.bin\n"); sys.exit(0)

input_file = "src/fceumm/src/ines-correct.h"
output_file = sys.argv[1]

# Allow running from repo root or with an absolute output path; locate the
# header relative to this script when the cwd-relative path is missing.
_script_dir = os.path.dirname(os.path.abspath(__file__))
_fallback = os.path.join(_script_dir, "src", "ines-correct.h")
if not os.path.isfile(input_file) and os.path.isfile(_fallback):
    input_file = _fallback

defines = {
    "DEFAULT": -1,
    "NOEXTRA": -1,
    "MI_4": 2,
    "DFAULT8": 8,
    "PAL": 1,
    "MULTI": 2,
    "DENDY": 3
}

pattern = re.compile(r"\{\s*0x([0-9a-fA-F]+),\s*(-?\w+),\s*(-?\w+),\s*(-?\w+),\s*(-?\w+),\s*(-?\w+),\s*(-?\w+),\s*(-?\w+),\s*(-?\w+)\s*\}")

entries = []

# Extract datat from .h file
with open(input_file, "r") as f:
    for line in f:
        match = pattern.search(line)
        if match:
            crc32 = int(match.group(1), 16)
            if crc32 == 0:
                continue
            data = [
                crc32,
                match.group(2),
                match.group(3),
                match.group(4),
                match.group(5),
                match.group(6),
                match.group(7),
                match.group(8),
                match.group(9)
            ]

            processed_data = []
            for value in data:
                if isinstance(value, str):
                    if value.startswith("0x"):
                        processed_data.append(int(value, 16))
                    elif value.isdigit() or (value.startswith("-") and value[1:].isdigit()):
                        processed_data.append(int(value))
                    else:
                        processed_data.append(defines.get(value, -1))
                else:
                    processed_data.append(value)
            
            entries.append(tuple(processed_data))

# Sort entries by crc32 to allow binary search
entries.sort(key=lambda x: x[0])

with open(output_file, "wb") as f:
    for entry in entries:
        f.write(struct.pack("<Iiiiiiiii", *entry))  # Format little-endian : uint32 + 8x int32

print(f"file \"{output_file}\" generated")
