# Changelog

## [v0.0.6] - 2026-10-03

### Added

- UNIF-format NES cartridge support for `.unf` and `.unif` files, including
  boards without an iNES mapper id.

### Changed

- Publish the new ROM extensions through the packed core metadata and GWRG
  release manifest.

### Fixed

- Refuse ROM images larger than available flash cache with a clear size error.
- Map supported multi-chip UNIF images in place to avoid oversized RAM copies.

## [v0.0.5]

### Added

- Support for UNIF ROMs (`.unf` / `.unif`).

### Changed

- Nothing.

### Fixed

- Oversized ROMs are refused when `size > flash_cache_usable_size()` (same
  ABI helper as gngeo), with a dialog showing ROM size vs flash cache max.
- UNIF multi-chip PRG mapped in-place (contiguous span or dominant chip;
  fixes CoolBoy 32 MiB + 256 B dumps that previously tried to allocate 64 MiB).
- UNIF boards without an iNES id load their mapper overlay via a dedicated
  `overlay_id` (mappers.pak aliases 600–608), so LE05 / PEC-586 / etc. work.

### Install

- Unzip the release archive onto the SD card root (`cores/fceumm.bin`).
- Place ROMs/FDS/NSF/UNIF under `/roms/nes/` (extensions: `nes ines fds nsf unf unif`).
- Place FDS bios under `/bios/nes/disksys.rom` to play FDS games.
- Requires firmware whose ABI matches `SDK_VERSION` in this repository.
