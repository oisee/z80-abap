CLASS zcl_hobbit_bus DEFINITION PUBLIC CREATE PUBLIC.
************************************************************************
* Hobbit Graphics Bus - Wraps Z80 bus with graphics port I/O
* Port 0xFB (251) - Graphics control:
*   0x00 = Classic ZX Spectrum mode (8x8 attribute cells)
*   0x01 = Hi-Res mode (per-pixel color, 256x128)
*   0x02 = Hi-Res 2x mode (per-pixel color, 512x256)
*   0x10-0x17 = Set palette 0-7
* Port 0xFC (252) - Read current mode/palette
************************************************************************

  PUBLIC SECTION.
    INTERFACES zif_cpu_z80_bus.

    CONSTANTS: c_port_gfx_ctrl TYPE i VALUE 251,  " 0xFB - Graphics control
               c_port_gfx_read TYPE i VALUE 252.  " 0xFC - Read mode/palette

    " Graphics modes
    CONSTANTS: c_mode_classic   TYPE i VALUE 0,   " ZX Spectrum 8x8 attributes
               c_mode_hires     TYPE i VALUE 1,   " Hi-Res per-pixel 256x128
               c_mode_hires_2x  TYPE i VALUE 2.   " Hi-Res 2x 512x256

    METHODS constructor.

    " Get current graphics mode
    METHODS get_gfx_mode RETURNING VALUE(rv_mode) TYPE i.

    " Get current palette
    METHODS get_gfx_palette RETURNING VALUE(rv_palette) TYPE i.

    " Check if mode/palette changed since last call
    METHODS has_gfx_change RETURNING VALUE(rv_changed) TYPE abap_bool.

    " Get mode change message for WebSocket (clears change flag)
    METHODS get_gfx_message RETURNING VALUE(rv_msg) TYPE string.

  PRIVATE SECTION.
    DATA mo_inner_bus TYPE REF TO zcl_cpu_z80_bus_simple.
    DATA mv_gfx_mode TYPE i.
    DATA mv_gfx_palette TYPE i.
    DATA mv_gfx_changed TYPE abap_bool.

ENDCLASS.


CLASS zcl_hobbit_bus IMPLEMENTATION.

  METHOD constructor.
    CREATE OBJECT mo_inner_bus.
    mv_gfx_mode = c_mode_hires.  " Default to Hi-Res mode
    mv_gfx_palette = 0.          " Default ZX Spectrum palette
    mv_gfx_changed = abap_false.
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~read_mem.
    rv_val = mo_inner_bus->zif_cpu_z80_bus~read_mem( iv_addr ).
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~write_mem.
    mo_inner_bus->zif_cpu_z80_bus~write_mem( iv_addr = iv_addr iv_val = iv_val ).
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~read_io.
    " Special handling for graphics status port
    IF iv_port = c_port_gfx_read.
      " Return current mode in low nibble, palette in high nibble
      rv_val = mv_gfx_mode + mv_gfx_palette * 16.
      RETURN.
    ENDIF.
    rv_val = mo_inner_bus->zif_cpu_z80_bus~read_io( iv_port ).
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~write_io.
    " Intercept graphics control port
    IF iv_port = c_port_gfx_ctrl.
      DATA lv_val TYPE i.
      lv_val = iv_val MOD 256.

      " Check for mode change (0x00-0x0F)
      IF lv_val >= 0 AND lv_val <= 15.
        IF lv_val <= 2.
          " Mode change: 0=Classic, 1=HiRes, 2=HiRes2x
          IF mv_gfx_mode <> lv_val.
            mv_gfx_mode = lv_val.
            mv_gfx_changed = abap_true.
          ENDIF.
        ENDIF.
      " Check for palette change (0x10-0x1F)
      ELSEIF lv_val >= 16 AND lv_val <= 31.
        DATA lv_pal TYPE i.
        lv_pal = lv_val - 16.
        IF mv_gfx_palette <> lv_pal.
          mv_gfx_palette = lv_pal.
          mv_gfx_changed = abap_true.
        ENDIF.
      ENDIF.
      RETURN.
    ENDIF.

    " Pass through to inner bus
    mo_inner_bus->zif_cpu_z80_bus~write_io( iv_port = iv_port iv_val = iv_val ).
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~load.
    mo_inner_bus->zif_cpu_z80_bus~load( iv_addr = iv_addr iv_data = iv_data ).
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~is_input_ready.
    rv_ready = mo_inner_bus->zif_cpu_z80_bus~is_input_ready( ).
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~get_output.
    rv_output = mo_inner_bus->zif_cpu_z80_bus~get_output( ).
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~clear_output.
    mo_inner_bus->zif_cpu_z80_bus~clear_output( ).
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~provide_input.
    mo_inner_bus->zif_cpu_z80_bus~provide_input( iv_text ).
  ENDMETHOD.

  METHOD zif_cpu_z80_bus~remove_last_output.
    mo_inner_bus->zif_cpu_z80_bus~remove_last_output( ).
  ENDMETHOD.

  METHOD get_gfx_mode.
    rv_mode = mv_gfx_mode.
  ENDMETHOD.

  METHOD get_gfx_palette.
    rv_palette = mv_gfx_palette.
  ENDMETHOD.

  METHOD has_gfx_change.
    rv_changed = mv_gfx_changed.
  ENDMETHOD.

  METHOD get_gfx_message.
    " Returns WebSocket message for mode/palette change
    " Format: __GFXMODE__M,P where M=mode (0-2), P=palette (0-7)
    IF mv_gfx_changed = abap_true.
      rv_msg = |__GFXMODE__{ mv_gfx_mode },{ mv_gfx_palette }|.
      mv_gfx_changed = abap_false.
    ELSE.
      rv_msg = ''.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
