# Retro-Go SD — FCEUmm (NES) dynamic core

Standalone FCEUmm core for
[Game & Watch Retro-Go SD](https://github.com/sylverb/game-and-watch-retro-go-sd).

## Build

```bash
make            # → nes.bin + nes_fceumm_mappers/{mappers.pak,ines_correct.bin}
make docker     # same, no host toolchain
```

Requires `arm-none-eabi-gcc` (hard-float `fpv5-d16`), Make, Python 3 + Pillow.

## Deploy on SD

| Path | Role |
|------|------|
| `/cores/nes.bin` | Packed core |
| `/cores/nes_fceumm_mappers/mappers.pak` | Runtime mapper overlays |
| `/cores/nes_fceumm_mappers/ines_correct.bin` | iNES header corrections |
| `/roms/nes/*.nes` (also `.fds`, `.nsf`) | ROMs |
| `/bios/nes/palettes.bin` | Optional palettes |

Cheat files use the `ggcodes` extension (Game Genie).

## Memory layout

- **ITCM**: hot `.text` only (`x6502`, `ppu`, `fceu-sound`)
- **DTCM**: WRAM / CHR-RAM / ExtraNTA via `dtc_calloc`
- **RAM_EMU**: core image (after 48 KiB mapper window) + `ram_calloc` FCEU heap
- **AHB**: unused by this core (tight ~56 KiB budget)

## Logos

`src/assets/pad.bmp` / `header.bmp` come from firmware `icons/c_nes.bmp` /
`h_nes.bmp`. Pack uses `--logo-invert` (light-on-dark source artwork).
