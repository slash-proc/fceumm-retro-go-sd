/*
 * Host stand-in for gw_core_bridge.h macros / linker symbols.
 * Include instead of gw_core_bridge.h when building with -DHOST_BUILD.
 */
#pragma once

#include <stdint.h>
#include "rom_manager.h"
#include "gw_malloc.h"
#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Same names the device linker script exports. */
extern uint32_t __CORE_BSS_END__;
extern uint32_t __CORE_CODE_END__;

void gw_core_bridge_init(void);

/* DMA2D ABI stand-ins (device: gw_core_bridge.h). */
uint32_t dma2d_m2m_rgb565_start(uint32_t src, uint32_t dst, uint16_t width, uint16_t height);
uint32_t dma2d_m2m_rgb565_start_ex(uint32_t src, uint32_t dst, uint16_t width, uint16_t height,
                                   uint16_t src_offset, uint16_t dst_offset);
uint32_t dma2d_r2m_rgb565_start(uint32_t color, uint32_t dst, uint16_t width, uint16_t height,
                                uint16_t dst_offset);
uint32_t dma2d_poll(uint32_t timeout_ms);

/* Optional: path passed on the CLI / HOST_ROM for core ROM load. */
void host_set_rom_path(const char *path);
int host_poll_events(void); /* returns 0 if the window should quit */

/* Map a firmware SD absolute path ("/roms/nes/foo.nes") onto the host
 * filesystem. Prefix with $HOST_SD when set (SD card root mirror). */
int host_map_sd_path(const char *sd_path, char *out, size_t out_sz);

#ifdef __cplusplus
}
#endif
