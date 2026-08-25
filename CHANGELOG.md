# Changelog

## [v0.0.1]

### Added

- Nothing

### Changed

- No more grey screen at startuo

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

**Homebrew (`PROJECT_KIND=homebrew`)**

- Set `PROJECT_KIND=homebrew` in the Makefile, rebuild, then copy
  `ExampleHB.bin` to `/homebrews/`.
- Optional coverflow override: `/covers/homebrew/ExampleHB.img` (JPEG ≤186×100,
  ≤10 KiB).

The release archive contains the ready-to-copy SD layout for the active project
kind only (`cores/` or `homebrews/`).
