/* NES-core linker symbols from ld/nes_core.ld — not part of the synced SDK. */
#pragma once

#include <stdint.h>

/* 48 KiB mapper overlay window at the front of RAM_EMU. */
extern uint8_t __RAM_FCEUMM_MAPPER_LENGTH__;
extern void *__RAM_FCEUMM_START__[];
