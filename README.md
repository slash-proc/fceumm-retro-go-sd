# Retro-Go SD — FCEUmm (NES) dynamic core

Standalone FCEUmm core for
[Game & Watch Retro-Go SD](https://github.com/sylverb/game-and-watch-retro-go-sd).

## Build

```bash
make            # → fceumm.bin (CORE + mappers.pak + ines_correct.bin)
make docker     # same, no host toolchain
```

Requires `arm-none-eabi-gcc` (hard-float `fpv5-d16`), Make, Python 3 + Pillow.

## Deploy on SD

| Path | Role |
|------|------|
| `/cores/fceumm.bin` | Packed core + mapper overlays + iNES correction DB |
| `/roms/nes/*.nes` (also `.fds`, `.nsf`) | ROMs |
| `/bios/nes/palettes.bin` | Optional palettes |

Cheat files use the `ggcodes` extension (Game Genie).

## Memory layout

- **ITCM**: hot `.text` only (`x6502`, `ppu`, `fceu-sound`)
- **DTCM**: WRAM / CHR-RAM / ExtraNTA via `dtc_calloc`
- **RAM_EMU**: core image (after 48 KiB mapper window) + `ram_calloc` FCEU heap
- **AHB**: unused by this core (tight ~56 KiB budget)
- **LCD**: compile-time via `NES_LCD_MODE=rgb565` (default) or `NES_LCD_MODE=lut8` (frees ~150 KiB RAM_UC)

## Logos

`src/assets/pad.bmp` / `header.bmp` come from firmware `icons/c_nes.bmp` /
`h_nes.bmp`. Pack uses `--logo-invert` (light-on-dark source artwork).
