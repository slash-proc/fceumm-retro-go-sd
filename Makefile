# Nintendo Entertainment System (FCEUmm) — standalone Retro-Go SD core.
#
#   make                  — build + pack → fceumm.bin (core + mappers + ines DB)
#   make NES_LCD_MODE=lut8|rgb565
#   make docker           — same build inside Docker (no host toolchain)
#   make docker_shell     — interactive shell in the builder image
#
# Layout: 48 KiB mapper window at __RAM_EMU_START__ (runtime load from the
# FCAS trailer inside fceumm.bin). Hot CPU/PPU/sound .text lives in ITCM;
# FCEU heap data uses RAM_EMU (ram_calloc); WRAM/CHR-RAM use DTCM.
# BUILD_DIR must stay `build`: ld/nes_core.ld names objects as build/*.o.
#
# NES_LCD_MODE (default rgb565): compile-time LCD pixel format — LUT8 frees
# ~150 KiB RAM_UC; rgb565 matches the classic firmware blit path.

#######################################
# Project identity
#######################################
PROJECT_KIND ?= core

CORE_NAME  := nes
CORE_ENTRY := app_main_nes_fceu

CORE_FCEUMM := src/fceumm
CORE_PORTING := src/porting

# Engine + shared boards only (sidecars are MAPPER_C_SOURCES below).
CORE_C_SOURCES := \
$(CORE_PORTING)/main_nes_fceu.c \
$(CORE_PORTING)/nes_i18n.c \
$(CORE_PORTING)/nes_fceu_mappers.c \
$(CORE_FCEUMM)/src/cheat.c \
$(CORE_FCEUMM)/src/fceu-cart.c \
$(CORE_FCEUMM)/src/fceu-endian.c \
$(CORE_FCEUMM)/src/fceu-memory.c \
$(CORE_FCEUMM)/src/fceu-sound.c \
$(CORE_FCEUMM)/src/fceu-state.c \
$(CORE_FCEUMM)/src/fceu.c \
$(CORE_FCEUMM)/src/fds.c \
$(CORE_FCEUMM)/src/fds_apu.c \
$(CORE_FCEUMM)/src/filter.c \
$(CORE_FCEUMM)/src/general.c \
$(CORE_FCEUMM)/src/ines.c \
$(CORE_FCEUMM)/src/input.c \
$(CORE_FCEUMM)/src/md5.c \
$(CORE_FCEUMM)/src/nsf.c \
$(CORE_FCEUMM)/src/palette.c \
$(CORE_FCEUMM)/src/ppu.c \
$(CORE_FCEUMM)/src/video.c \
$(CORE_FCEUMM)/src/x6502.c \
$(CORE_FCEUMM)/src/boards/mmc3.c \
$(CORE_FCEUMM)/src/boards/latch.c \
$(CORE_FCEUMM)/src/boards/vrcirq.c \
$(CORE_FCEUMM)/src/boards/eeprom_93C66.c \
$(CORE_FCEUMM)/src/boards/fceu-emu2413.c

CORE_C_INCLUDES := \
-I$(CORE_FCEUMM)/src \
-I$(CORE_PORTING)

# Relative path so Docker bind-mounts work (do NOT use $(abspath)).
GNW_CORE_SDK ?= sdk
# Must match EXCLUDE_FILE / .core_itcm paths in ld/nes_core.ld.
BUILD_DIR ?= build

#######################################
# Kind-specific compile defs + packing
#######################################
ifeq ($(PROJECT_KIND),core)
# FCEU_* / __LIBRETRO__: match firmware nes_fceu C_DEFS.
# COVERFLOW+CHEAT_CODES must match firmware ACTIVE_FILE layout.
NES_LCD_MODE ?= lut8
ifeq ($(NES_LCD_MODE),lut8)
NES_LCD_DEF := -DNES_LCD_LUT8=1
else ifeq ($(NES_LCD_MODE),rgb565)
NES_LCD_DEF := -DNES_LCD_RGB565=1
else
$(error NES_LCD_MODE must be 'lut8' or 'rgb565' (got '$(NES_LCD_MODE)'))
endif

CORE_C_DEFS := \
-DPROJECT_KIND_CORE=1 \
-DTARGET_GNW \
-DFCEU_VERSION_NUMERIC=9813 \
-DFCEU_LOW_RAM \
-DFCEU_NO_MALLOC \
-D__LIBRETRO__ \
-DCOVERFLOW=1 \
-DCHEAT_CODES=1 \
-DMAX_CHEAT_CODES=13 \
$(NES_LCD_DEF)

# Drop main_nes_fceu.o when NES_LCD_MODE changes (defs alone are invisible to make).
NES_LCD_STAMP := $(BUILD_DIR)/.nes_lcd_mode
ifneq ($(shell cat $(NES_LCD_STAMP) 2>/dev/null),$(NES_LCD_MODE))
$(shell mkdir -p $(BUILD_DIR) && echo $(NES_LCD_MODE) > $(NES_LCD_STAMP) && rm -f $(BUILD_DIR)/main_nes_fceu.o)
endif

PACKED_BIN  := fceumm.bin
PAD_LOGO    := src/assets/pad.bmp
HEADER_LOGO := src/assets/header.bmp

CORE_LDSCRIPT := ld/nes_core.ld
CORE_EXTRA_SEGMENTS := itcm:core_itcm
# nsf.c DrawNSF uses sin/cos/atan/sqrt once.
CORE_LDLIBS := -lm

#######################################
# Mapper sidecars (linked into the core ELF as overlays)
#######################################
MAPPER_IGNORE := __% fceu-emu2413.c mmc3.c latch.c vrcirq.c eeprom_93C66.c
MAPPER_C_SOURCES := $(filter-out $(addprefix $(CORE_FCEUMM)/src/boards/,$(MAPPER_IGNORE)), \
	$(wildcard $(CORE_FCEUMM)/src/boards/*.c))

MAPPER_OBJECTS := $(addprefix $(BUILD_DIR)/,$(notdir $(MAPPER_C_SOURCES:.c=.o)))
MAPPER_STEMS := $(subst -,_,$(notdir $(basename $(MAPPER_C_SOURCES))))
MAPPERS_OUT := nes_fceumm_mappers
MAPPER_BINS := $(addprefix $(MAPPERS_OUT)/mapper_,$(addsuffix .bin,$(MAPPER_STEMS)))
MAPPERS_PACK := $(MAPPERS_OUT)/mappers.pak
INES_CORRECT := $(MAPPERS_OUT)/ines_correct.bin
MAPPER_OVERLAYS_LD := $(BUILD_DIR)/nes_mapper_overlays.ld

# Feed mapper objects into the shared sdk link recipe (no recipe override).
CORE_EXTRA_OBJECTS := $(MAPPER_OBJECTS)
CORE_ELF_EXTRA_DEPS := $(MAPPER_OVERLAYS_LD)

else
$(error PROJECT_KIND must be 'core' (got '$(PROJECT_KIND)'))
endif

include $(GNW_CORE_SDK)/Makefile

# Upstream fceumm has a few intentional paren/sequence-point patterns.
CFLAGS += -Wno-sequence-point -Wno-parentheses

PACK_CORE := $(GNW_CORE_SDK)/tools/pack_core.py

#######################################
# Packed header version
#######################################
CORE_VERSION ?= $(shell git describe --tags --dirty 2>/dev/null || echo NOTAG)

vpath %.c $(CORE_FCEUMM)/src/boards

$(MAPPERS_OUT):
	$(V)mkdir -p $(MAPPERS_OUT)

$(MAPPER_OVERLAYS_LD): scripts/gen_nes_mapper_overlays_ld.py $(MAPPER_C_SOURCES) | $(BUILD_DIR)
	$(V)python3 scripts/gen_nes_mapper_overlays_ld.py \
		--boards-dir $(CORE_FCEUMM)/src/boards \
		--objects-dir $(BUILD_DIR) \
		--output $@

define NES_MAPPER_BIN_RULE
$(MAPPERS_OUT)/mapper_$(subst -,_,$(notdir $(basename $(1)))).bin: $(TARGET_ELF) | $(MAPPERS_OUT)
	$$(V)$$(CP) -O binary --only-section=.overlay_nes_mapper_$(subst -,_,$(notdir $(basename $(1)))) $$(TARGET_ELF) $$@
endef
$(foreach src,$(MAPPER_C_SOURCES),$(eval $(call NES_MAPPER_BIN_RULE,$(src))))

$(MAPPERS_PACK): $(MAPPER_BINS) scripts/gen_mappers_pack.py $(CORE_FCEUMM)/gen_mappers_table.py | $(MAPPERS_OUT)
	$(V)python3 scripts/gen_mappers_pack.py \
		--bins-dir $(MAPPERS_OUT) \
		--output $@ \
		--repo .

$(INES_CORRECT): $(CORE_FCEUMM)/gen_ines_database.py $(CORE_FCEUMM)/src/ines-correct.h | $(MAPPERS_OUT)
	$(V)python3 $(CORE_FCEUMM)/gen_ines_database.py $@

#######################################
# Pack
#######################################
.PHONY: pack

pack: $(TARGET_BIN) $(BUILD_DIR)/$(CORE_NAME)_core_itcm.bin $(PAD_LOGO) $(HEADER_LOGO) $(MAPPERS_PACK) $(INES_CORRECT)
	$(V)$(ECHO) [ PACK CORE ] $(PACKED_BIN) version=$(CORE_VERSION)
	$(V)python3 $(PACK_CORE) \
		--elf $(TARGET_ELF) --bin $(TARGET_BIN) \
		--system-name "Nintendo Entertainment System" --dirname nes \
		--extensions "nes fds nsf" \
		--cheat-ext ggcodes \
		--pad-logo $(PAD_LOGO) \
		--header-logo $(HEADER_LOGO) \
		--logo-invert \
		--segment itcm:__ITCM_CORE_START__:__CORE_ITCM_CODE_END__:__CORE_ITCM_BSS_END__:$(BUILD_DIR)/$(CORE_NAME)_core_itcm.bin \
		--core-name "FCEUmm" \
		--version "$(CORE_VERSION)" \
		--out $(PACKED_BIN)
	$(V)python3 scripts/append_fceumm_sidecars.py \
		--core $(PACKED_BIN) \
		--mappers $(MAPPERS_PACK) \
		--ines $(INES_CORRECT)

all: pack

.PHONY: print-PROJECT_KIND print-PACKED_BIN print-CORE_NAME print-DOCKER_IMAGE \
	print-TARGET_ELF print-TARGET_MAP print-CORE_VERSION
print-PROJECT_KIND:
	@echo $(PROJECT_KIND)
print-PACKED_BIN:
	@echo $(PACKED_BIN)
print-CORE_NAME:
	@echo $(CORE_NAME)
print-DOCKER_IMAGE:
	@echo $(DOCKER_IMAGE)
print-TARGET_ELF:
	@echo $(TARGET_ELF)
print-TARGET_MAP:
	@echo $(BUILD_DIR)/$(CORE_NAME)_core.map
print-CORE_VERSION:
	@echo $(CORE_VERSION)

clean::
	$(V)rm -f $(PACKED_BIN) nes.bin
	$(V)rm -rf $(MAPPERS_OUT)

#######################################
# Docker
#######################################
.PHONY: docker docker_pull docker_shell

RELEASE_VERSION ?= v1.5
DOCKER_REPOSITORY ?= sylverb/retro-go-sd-builder
DOCKER_IMAGE ?= $(DOCKER_REPOSITORY):$(RELEASE_VERSION)

DOCKER_TTY_FLAG := $(shell if [ -t 0 ]; then echo -it; else echo; fi)
DOCKER_USER := $(shell id -u):$(shell id -g)
DOCKER_RUN := docker run --rm $(DOCKER_TTY_FLAG) \
	--user $(DOCKER_USER) \
	-v "$(CURDIR):/opt/workdir" \
	-w /opt/workdir \
	$(DOCKER_IMAGE)

docker:
	$(V)$(ECHO) "[ DOCKER ]" $(DOCKER_IMAGE) "PROJECT_KIND=$(PROJECT_KIND)"
	$(V)$(DOCKER_RUN) make --no-print-directory -j$$(nproc) PROJECT_KIND=$(PROJECT_KIND)

docker_pull:
	$(V)$(ECHO) "[ PULL ]" $(DOCKER_IMAGE)
	$(V)docker pull $(DOCKER_IMAGE)

docker_shell:
	$(DOCKER_RUN) bash

#######################################
# Host SDL (optional; mapper overlays not fully mirrored)
#######################################
HOST_BIN := fceumm_host
include host/Makefile.host
