# Changelog

## [v0.1.1] - 2026-09-08

### Added

- The optional custom palette pack is declared as a `bios[]` entry. The core
  reads `/bios/nes/palettes.bin` for the alternative colour palettes offered in
  the options menu; without the file `apply_palette()` falls back to the
  built-in fceumm palette and the option simply has nothing to choose from. It
  is `required: false` because nothing stops working when it is absent. The
  project does not ship it: this repository has no generator for it, so it is
  the user's file to supply.

### Notes

- `/bios/nes/gamegenie.nes` is deliberately *not* declared. The only code that
  reads it, `FCEU_OpenGenie()` in `src/fceumm/src/fceu-cart.c`, sits inside
  `#ifdef FCEU_ENABLE_GAMEGENIE_ROM`, and that macro is defined nowhere in this
  tree or its build. The shipped binary never opens the file, and a manifest
  that asked a user for a copyrighted Game Genie ROM the core cannot use would
  be asking for nothing.

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

## [v0.0.2]

### Added

- Nothing

### Changed

- Use LUT8 mode instead of RGB565

### Fixed

- Fix for green screen showing randomly

## [v0.0.1]

### Added

- Nothing

### Changed

- No more grey screen at startup

### Fixed

- Big NFS don't crash
- Slowdowns in YS III (mapper 118)

### Install

Only the section corresponding to your chosen `PROJECT_KIND` is relevant for
your derived project.

**Core (`PROJECT_KIND=core`, default)**

- Copy `example.bin` to `/cores/` on the SD card.
- Place test ROMs under `/roms/example/` (dirname matches `CORE_NAME` in the
  Makefile).
- Requires firmware whose ABI matches `SDK_VERSION` in this repository.
