#pragma once

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* Absolute SD path used when ACTIVE_FILE->system->core_path is unavailable. */
#define FCEUMM_CORE_BIN_FALLBACK "/cores/fceumm.bin"

/* Legacy separate sidecars (still accepted if the packed .bin has no FCAS trailer). */
#define FCEUMM_MAPPER_PACK_LEGACY "/cores/nes_fceumm_mappers/mappers.pak"
#define FCEUMM_INES_CORRECT_LEGACY "/cores/nes_fceumm_mappers/ines_correct.bin"

/* FCAS trailer after the CORE container — see scripts/append_fceumm_sidecars.py. */
#define FCEUMM_ASSETS_MAGIC   0x53414346u /* 'F','C','A','S' */
#define FCEUMM_ASSETS_VERSION 1u
#define FCEUMM_ASSETS_FOOTER_SIZE 24u

/* Resolve the running core .bin and locate embedded (or legacy) assets.
 * Returns false if neither form is available. */
bool fceumm_assets_ready(void);
const char *fceumm_assets_core_path(void);
/* Path of the file that contains the iNES correction DB (core .bin or legacy). */
const char *fceumm_assets_ines_path(void);
bool fceumm_assets_mappers(uint32_t *offset, uint32_t *size);
bool fceumm_assets_ines(uint32_t *offset, uint32_t *size);

/* Load the mapper blob for `mapper_number` into `dest`.
 * Returns bytes loaded, or 0 when absent / too large. */
size_t fceumm_load_mapper(uint16_t mapper_number, uint8_t *dest, size_t dest_capacity);
