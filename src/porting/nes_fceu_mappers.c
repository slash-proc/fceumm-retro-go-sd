#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "nes_fceu_mappers.h"
#include "rg_storage.h"
#include "rom_manager.h"

#ifdef HOST_BUILD
#include "host_compat.h"
#else
#include "gw_core_bridge.h"
#endif

/* mappers.pak layout (little-endian), see scripts/gen_mappers_pack.py:
 *   Header (16 bytes): 'MPAK', uint32 version, uint32 num_entries, uint32 reserved
 *   Index (num_entries * 8 bytes) indexed by mapper number: uint32 offset, uint32 size
 *   Blobs concatenated after the index. offset == size == 0 => mapper absent.
 */
#define PACK_MAGIC 0x4B41504Du /* 'M','P','A','K' */
#define PACK_HEADER_SIZE 16
#define PACK_INDEX_ENTRY_SIZE 8

typedef struct {
    char path[64];
    uint32_t mappers_off;
    uint32_t mappers_size;
    uint32_t ines_off;
    uint32_t ines_size;
    int8_t ready; /* 0 = unset, 1 = ok, -1 = failed */
} fceumm_assets_cache_t;

static fceumm_assets_cache_t g_assets;

static uint32_t rd_u32le(const uint8_t *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static void fceumm_assets_set_path(const char *path) {
    strncpy(g_assets.path, path, sizeof(g_assets.path) - 1);
    g_assets.path[sizeof(g_assets.path) - 1] = '\0';
}

static bool fceumm_file_size(const char *path, uint32_t *out_size) {
    FILE *file = fopen(path, "rb");
    if (!file)
        return false;
    if (fseek(file, 0, SEEK_END) != 0) {
        fclose(file);
        return false;
    }
    long sz = ftell(file);
    fclose(file);
    if (sz <= 0)
        return false;
    *out_size = (uint32_t)sz;
    return true;
}

static bool fceumm_try_fcas_footer(FILE *file, long filesize) {
    uint8_t footer[FCEUMM_ASSETS_FOOTER_SIZE];

    if (filesize < (long)FCEUMM_ASSETS_FOOTER_SIZE)
        return false;
    if (fseek(file, filesize - (long)FCEUMM_ASSETS_FOOTER_SIZE, SEEK_SET) != 0)
        return false;
    if (fread(footer, 1, FCEUMM_ASSETS_FOOTER_SIZE, file) != FCEUMM_ASSETS_FOOTER_SIZE)
        return false;

    uint32_t magic = rd_u32le(footer);
    uint32_t version = rd_u32le(footer + 4);
    uint32_t m_off = rd_u32le(footer + 8);
    uint32_t m_sz = rd_u32le(footer + 12);
    uint32_t i_off = rd_u32le(footer + 16);
    uint32_t i_sz = rd_u32le(footer + 20);

    if (magic != FCEUMM_ASSETS_MAGIC || version != FCEUMM_ASSETS_VERSION)
        return false;
    if (m_sz == 0 || i_sz == 0)
        return false;
    if ((uint64_t)m_off + m_sz > (uint64_t)filesize - FCEUMM_ASSETS_FOOTER_SIZE)
        return false;
    if ((uint64_t)i_off + i_sz > (uint64_t)filesize - FCEUMM_ASSETS_FOOTER_SIZE)
        return false;

    g_assets.mappers_off = m_off;
    g_assets.mappers_size = m_sz;
    g_assets.ines_off = i_off;
    g_assets.ines_size = i_sz;
    return true;
}

static bool fceumm_assets_init(void) {
    if (g_assets.ready != 0)
        return g_assets.ready > 0;

    const char *core_path = NULL;
    if (ACTIVE_FILE && ACTIVE_FILE->system && ACTIVE_FILE->system->core_path &&
        ACTIVE_FILE->system->core_path[0]) {
        core_path = ACTIVE_FILE->system->core_path;
    } else {
        core_path = FCEUMM_CORE_BIN_FALLBACK;
    }
    fceumm_assets_set_path(core_path);

    FILE *file = fopen(g_assets.path, "rb");
    if (file) {
        if (fseek(file, 0, SEEK_END) == 0) {
            long filesize = ftell(file);
            if (filesize > 0 && fceumm_try_fcas_footer(file, filesize)) {
                fclose(file);
                g_assets.ready = 1;
                return true;
            }
        }
        fclose(file);
    }

    /* Legacy split layout on SD. */
    uint32_t m_sz = 0, i_sz = 0;
    if (fceumm_file_size(FCEUMM_MAPPER_PACK_LEGACY, &m_sz) &&
        fceumm_file_size(FCEUMM_INES_CORRECT_LEGACY, &i_sz)) {
        fceumm_assets_set_path(FCEUMM_MAPPER_PACK_LEGACY);
        g_assets.mappers_off = 0;
        g_assets.mappers_size = m_sz;
        g_assets.ines_off = 0;
        g_assets.ines_size = i_sz;
        g_assets.ready = 1;
        return true;
    }

    g_assets.ready = -1;
    return false;
}

bool fceumm_assets_ready(void) {
    return fceumm_assets_init();
}

const char *fceumm_assets_core_path(void) {
    if (!fceumm_assets_init())
        return NULL;
    return g_assets.path;
}

bool fceumm_assets_mappers(uint32_t *offset, uint32_t *size) {
    if (!fceumm_assets_init())
        return false;
    if (offset)
        *offset = g_assets.mappers_off;
    if (size)
        *size = g_assets.mappers_size;
    return true;
}

bool fceumm_assets_ines(uint32_t *offset, uint32_t *size) {
    if (!fceumm_assets_init())
        return false;
    if (offset)
        *offset = g_assets.ines_off;
    if (size)
        *size = g_assets.ines_size;
    return true;
}

/* True when using the old /cores/nes_fceumm_mappers/ split files. */
static bool fceumm_assets_is_legacy_split(void) {
    return fceumm_assets_init() &&
           g_assets.mappers_off == 0 &&
           strcmp(g_assets.path, FCEUMM_MAPPER_PACK_LEGACY) == 0;
}

const char *fceumm_assets_ines_path(void) {
    if (!fceumm_assets_init())
        return NULL;
    if (fceumm_assets_is_legacy_split())
        return FCEUMM_INES_CORRECT_LEGACY;
    return g_assets.path;
}

size_t fceumm_load_mapper(uint16_t mapper_number, uint8_t *dest, size_t dest_capacity) {
    uint32_t pack_off = 0;
    uint32_t pack_size = 0;
    if (!fceumm_assets_mappers(&pack_off, &pack_size))
        return 0;

    const char *path = fceumm_assets_core_path();
    if (!path)
        return 0;

    FILE *file = fopen(path, "rb");
    if (!file)
        return 0;

    uint8_t header[PACK_HEADER_SIZE];
    if (fseek(file, (long)pack_off, SEEK_SET) != 0 ||
        fread(header, 1, PACK_HEADER_SIZE, file) != PACK_HEADER_SIZE ||
        rd_u32le(header) != PACK_MAGIC) {
        fclose(file);
        return 0;
    }

    uint32_t num_entries = rd_u32le(header + 8);
    if (mapper_number >= num_entries) {
        fclose(file);
        return 0;
    }

    long index_pos = (long)pack_off + (long)PACK_HEADER_SIZE +
                     (long)mapper_number * PACK_INDEX_ENTRY_SIZE;
    uint8_t entry[PACK_INDEX_ENTRY_SIZE];
    if (fseek(file, index_pos, SEEK_SET) != 0 ||
        fread(entry, 1, PACK_INDEX_ENTRY_SIZE, file) != PACK_INDEX_ENTRY_SIZE) {
        fclose(file);
        return 0;
    }
    fclose(file);

    uint32_t offset = rd_u32le(entry);
    uint32_t size = rd_u32le(entry + 4);
    if (size == 0 || size > dest_capacity)
        return 0;
    /* Pak-relative offset must land inside the embedded pak blob. */
    if ((uint64_t)offset + size > pack_size)
        return 0;

    return rg_storage_copy_file_range_to_ram((char *)path, dest,
                                             pack_off + offset, size, NULL);
}
