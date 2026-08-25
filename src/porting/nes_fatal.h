#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Structured load failures — preferred over parsing FCEUD_PrintError text. */
typedef enum {
    NES_LOAD_ERR_NONE = 0,
    NES_LOAD_ERR_FDS_BIOS_MISSING,
    NES_LOAD_ERR_FDS_BIOS_SIZE,
    NES_LOAD_ERR_MAPPER_UNSUPPORTED,
    NES_LOAD_ERR_MAPPER_OVERLAY,
    NES_LOAD_ERR_GENERIC,
} nes_load_err_t;

void nes_load_error_clear(void);
void nes_load_error_set(nes_load_err_t code, int arg);

/* Show a confirm dialog then soft-reset the console. Never returns. */
void nes_fatal(const char *line1, const char *line2) __attribute__((noreturn));

/* If gameInfo is NULL, show the pending load error (or a generic message) and reset. */
void nes_fatal_if_load_failed(void *gameInfo);

#ifdef __cplusplus
}
#endif
