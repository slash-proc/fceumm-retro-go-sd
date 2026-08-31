# Changelog

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
