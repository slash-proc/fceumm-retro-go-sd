/*
 * FCEUmm (NES) core linker script.
 *
 * Mappers load into the first 48K of RAM_EMU at runtime
 * (fceumm_load_mapper → __RAM_EMU_START__). The core itself lives after
 * that window; the entry trampoline stays at offset 0 so
 * run_dynamic_core() can jump (__RAM_EMU_START__ | 1).
 *
 * Hot CPU / PPU / APU .text run from ITCM (code only — no data heap in
 * ITCM). Former itc_calloc FCEU heap uses ram_calloc (RAM_EMU); WRAM /
 * CHR-RAM stay on DTCM via dtc_calloc.
 *
 * Mapper board .o files are VMA-overlapping overlays (build/
 * nes_mapper_overlays.ld). Requires -Wl,--no-check-sections.
 */

INCLUDE gnw_ram_emu.ld
INCLUDE gnw_itcm_core.ld

__RAM_FCEUMM_MAPPER_LENGTH__ = 48K;
__RAM_FCEUMM_START__ = __RAM_EMU_START__ + __RAM_FCEUMM_MAPPER_LENGTH__;

MEMORY
{
  RAM_EMU (xrw) : ORIGIN = __RAM_EMU_START__, LENGTH = __RAM_EMU_LENGTH__
  ITCM    (xrw) : ORIGIN = __ITCM_CORE_START__, LENGTH = __ITCM_CORE_LENGTH__
  MAPPER_STORE (r) : ORIGIN = 0x60000000, LENGTH = 16M
}

SECTIONS
{
  /* Claim mapper input sections first (explicit file paths). */
  INCLUDE build/nes_mapper_overlays.ld

  /* ITCM: CPU-hot .text only (.rodata/.data/.bss stay in RAM_EMU). */
  .core_itcm __ITCM_CORE_START__ :
  {
    __CORE_ITCM_CODE_START__ = .;
    build/x6502.o(.text*)
    build/ppu.o(.text*)
    build/fceu-sound.o(.text*)
    . = ALIGN(4);
    __CORE_ITCM_CODE_END__ = .;
  } >ITCM AT>RAM_EMU

  __CORE_ITCM_BSS_END__ = __CORE_ITCM_CODE_END__;

  ASSERT(__CORE_ITCM_BSS_END__ <= __ITCM_CORE_START__ + __ITCM_CORE_LENGTH__,
         "Error: NES core ITCM segment (code) overflows the 64K ITCM region")

  /* Overlays leave `.' near the end of the mapper window — pin core. */
  .core_entry __RAM_EMU_START__ :
  {
    KEEP(*(.core_entry))
    KEEP(*(.gw_core_bridge_probe))
    . = ALIGN(4);

    /* Skip the mapper window via relative advance. */
    . = . + __RAM_FCEUMM_MAPPER_LENGTH__;

    EXCLUDE_FILE(build/x6502.o build/ppu.o build/fceu-sound.o) *(.text*)
    *(.rodata*)
    *(.glue_7)
    *(.glue_7t)

    . = ALIGN(4);
    __CORE_INIT_ARRAY_START__ = .;
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array*))
    __CORE_INIT_ARRAY_END__ = .;
  } >RAM_EMU

  . = ALIGN(8);
  .data :
  {
    *(.data*)
  } >RAM_EMU

  __CORE_CODE_END__ = .;

  . = ALIGN(8);
  .bss (NOLOAD) :
  {
    *(.bss*)
    *(COMMON)
  } >RAM_EMU

  __CORE_BSS_END__ = .;

  ASSERT(__CORE_BSS_END__ <= __RAM_EMU_END__,
         "Error: NES FCEUmm core overflows RAM_EMU")
  ASSERT(ABSOLUTE(__CORE_CODE_END__) > __RAM_FCEUMM_START__,
         "Error: NES core code did not land past the mapper window")

  __exidx_start = .;
  __exidx_end = .;

  /DISCARD/ :
  {
    *(.fini_array*)
    *(.preinit_array*)
    *(.ARM.exidx*)
    *(.ARM.extab*)
    *(.comment)
    *(.ARM.attributes)
  }
}
