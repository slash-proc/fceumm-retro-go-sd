# Changelog

## [v0.1.0] - 2026-09-08

### Added

- Published under the [GWRG distribution
  spec](https://github.com/slash-proc/gwrg-dist-spec): a `manifest.json`
  describing this core and the system it provides, an offline bundle, and a
  GitHub Pages mirror of `dist/` that a web installer can read without a human
  in the loop.
- `symbols[]` publishes the linked ELF so a crash address from a device can be
  resolved back to a function. It is named by the manifest and mirrored, but is
  not part of the install set and never reaches the card.
- `gwrg.json`, the hand-written half of the manifest: the short console name
  and whether compressed ROMs work. Everything else -- the system, its folder,
  extensions and browse mode, the firmware ABI, sizes and hashes -- is derived
  from the packed binary at release time, so the manifest and the firmware
  cannot disagree about which folder the system reads.
- The Famicom Disk System BIOS is declared as a `bios[]` entry required for
  `.fds` only. The core reads `/bios/nes/disksys.rom`, refuses to start a
  disk image without it and rejects anything that is not 8 KiB, while
  cartridges and `.nsf` music need nothing.

### Changed

- `scripts/make_manifest.py`, `build_dist.py`, `make_bundle.py` and
  `stage_release.py` are now the shared copies, byte-identical across every
  project. A script that has to be edited on the way in is a script that
  drifts.
- The Makefile answers `print-SIDECARS` and `print-RO_BIN`. This core installs
  neither, but the shared release script reads its variables positionally: a
  missing target shifts every later value onto the wrong name.

## [v0.0.5]

### Added

- Nothing.

### Changed

- Nothing.

### Fixed

- Invalidate I cache after loading mapper in ram to prevent crash with some games.

### Install

- Unzip the release archive onto the SD card root (`cores/fceumm.bin`).
- Place ROMs/FDS/NSF under `/roms/nes/`.
- Place FDS bios under `/bios/nes/disksys.rom` to play FDS games.
- Requires firmware whose ABI matches `SDK_VERSION` in this repository.
