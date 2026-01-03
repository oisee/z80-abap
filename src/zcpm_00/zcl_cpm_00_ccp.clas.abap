CLASS zcl_cpm_00_ccp DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ts_file_info,
             name        TYPE string,
             extension   TYPE string,
             size        TYPE i,
             description TYPE string,
           END OF ts_file_info,
           tt_file_list TYPE STANDARD TABLE OF ts_file_info WITH EMPTY KEY.

    CONSTANTS c_crlf TYPE string VALUE cl_abap_char_utilities=>cr_lf.

    METHODS constructor
      IMPORTING
        iv_disk TYPE char30 DEFAULT 'A'.
    METHODS reset.
    METHODS set_disk
      IMPORTING
        iv_disk TYPE char30.
    METHODS get_disk
      RETURNING VALUE(rv_disk) TYPE char30.
    METHODS process_command
      IMPORTING iv_command TYPE string
      EXPORTING ev_output  TYPE string
                ev_run_program TYPE abap_bool
                ev_program_data TYPE xstring
                ev_program_name TYPE string
                ev_program_args TYPE string.

    METHODS get_prompt RETURNING VALUE(rv_prompt) TYPE string.
    METHODS get_welcome RETURNING VALUE(rv_welcome) TYPE string.

    " File loading from bin table
    METHODS load_bin_file
      IMPORTING iv_name TYPE string
      RETURNING VALUE(rv_data) TYPE xstring.

  PRIVATE SECTION.
    DATA mv_current_drive TYPE c LENGTH 1 VALUE 'A'.
    DATA mv_current_user TYPE i VALUE 0.
    DATA mv_disk TYPE char30 VALUE 'A'.  " Disk for ZCPM_00_BIN

    METHODS cmd_dir
      IMPORTING iv_pattern TYPE string
      RETURNING VALUE(rv_output) TYPE string.

    METHODS cmd_type
      IMPORTING iv_filename TYPE string
      RETURNING VALUE(rv_output) TYPE string.

    METHODS cmd_help
      RETURNING VALUE(rv_output) TYPE string.

    METHODS cmd_era
      IMPORTING iv_filename TYPE string
      RETURNING VALUE(rv_output) TYPE string.

    METHODS load_smw0_file
      IMPORTING iv_name TYPE string
      RETURNING VALUE(rv_data) TYPE xstring.

    METHODS format_size
      IMPORTING iv_size TYPE i
      RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.


CLASS zcl_cpm_00_ccp IMPLEMENTATION.

  METHOD constructor.
    mv_disk = iv_disk.
    reset( ).
  ENDMETHOD.

  METHOD reset.
    mv_current_drive = 'A'.
    mv_current_user = 0.
  ENDMETHOD.

  METHOD set_disk.
    mv_disk = iv_disk.
  ENDMETHOD.

  METHOD get_disk.
    rv_disk = mv_disk.
  ENDMETHOD.

  METHOD get_prompt.
    rv_prompt = |{ mv_current_drive }>|.
  ENDMETHOD.

  METHOD get_welcome.
    rv_welcome =
      |CP/M 2.2 on SAP HANA{ c_crlf }| &&
      |64K TPA  Z80 Emulator{ c_crlf }| &&
      |Disk: { mv_disk }{ c_crlf }| &&
      |{ c_crlf }| &&
      |Type HELP for commands{ c_crlf }| &&
      |{ c_crlf }|.
  ENDMETHOD.

  METHOD process_command.
    DATA: lv_cmd TYPE string,
          lv_arg TYPE string,
          lv_upper TYPE string.

    CLEAR: ev_output, ev_run_program, ev_program_data, ev_program_name, ev_program_args.

    lv_upper = to_upper( iv_command ).
    CONDENSE lv_upper.

    IF lv_upper IS INITIAL.
      RETURN.
    ENDIF.

    SPLIT lv_upper AT space INTO lv_cmd lv_arg.

    IF strlen( lv_cmd ) = 2 AND lv_cmd+1(1) = ':'.
      DATA(lv_drive) = lv_cmd+0(1).
      IF lv_drive >= 'A' AND lv_drive <= 'P'.
        mv_current_drive = lv_drive.
        mv_disk = lv_drive.  " Sync bin disk with drive letter
        RETURN.
      ENDIF.
    ENDIF.

    CASE lv_cmd.
      WHEN 'DIR' OR 'LS'.
        IF lv_arg IS INITIAL.
          lv_arg = '*.*'.
        ENDIF.
        ev_output = cmd_dir( lv_arg ).

      WHEN 'TYPE' OR 'CAT'.
        IF lv_arg IS INITIAL.
          ev_output = |Missing filename{ c_crlf }|.
        ELSE.
          ev_output = cmd_type( lv_arg ).
        ENDIF.

      WHEN 'HELP' OR '?'.
        ev_output = cmd_help( ).

      WHEN 'ERA' OR 'DEL' OR 'RM'.
        ev_output = cmd_era( lv_arg ).

      WHEN 'REN'.
        ev_output = |REN not implemented{ c_crlf }|.

      WHEN 'USER'.
        IF lv_arg IS NOT INITIAL.
          mv_current_user = lv_arg.
        ENDIF.
        ev_output = |User = { mv_current_user }{ c_crlf }|.

      WHEN 'DISK'.
        IF lv_arg IS NOT INITIAL.
          mv_disk = lv_arg.
        ENDIF.
        ev_output = |Bin disk = { mv_disk }{ c_crlf }|.

      WHEN 'CLS' OR 'CLEAR'.
        DATA(lv_esc) = cl_abap_conv_in_ce=>uccpi( 27 ).
        ev_output = lv_esc && '[2J' && lv_esc && '[H'.

      WHEN 'VER' OR 'VERSION'.
        ev_output =
          |CP/M 2.2 Emulator for SAP HANA{ c_crlf }| &&
          |Z80 CPU: ZCL_CPU_Z80{ c_crlf }| &&
          |BDOS: ZCL_CPM_EMULATOR{ c_crlf }| &&
          |CCP: ZCL_CPM_00_CCP{ c_crlf }| &&
          |Bin Disk: { mv_disk }{ c_crlf }|.

      WHEN 'RESET'.
        DELETE FROM SHARED MEMORY indx(zk) ID 'CPM_APC_CONNECTIONS'.
        ev_output = |Connection counter reset{ c_crlf }|.

      WHEN 'DUMP80'.
        " Debug: show command tail at 0x80
        ev_output = |Command tail at 0x80:{ c_crlf }|.
        ev_run_program = abap_true.
        ev_program_data = VALUE xstring( ).
        ev_program_name = '__DUMP80__'.

      WHEN 'EXIT' OR 'BYE' OR 'QUIT'.
        ev_output = |Goodbye!{ c_crlf }|.

      WHEN OTHERS.
        DATA(lv_filename) = lv_cmd.
        IF NOT lv_filename CS '.'.
          lv_filename = lv_filename && '.COM'.
        ENDIF.

        " Try bin table first, then SMW0
        DATA(lv_data) = load_bin_file( lv_filename ).
        IF lv_data IS INITIAL.
          lv_data = load_smw0_file( lv_filename ).
        ENDIF.

        IF lv_data IS NOT INITIAL.
          ev_run_program = abap_true.
          ev_program_data = lv_data.
          ev_program_name = lv_filename.
          ev_program_args = lv_arg.
          ev_output = |Loading { lv_filename }...{ c_crlf }|.
        ELSE.
          ev_output = |{ lv_cmd }?{ c_crlf }|.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD cmd_dir.
    DATA: lt_files TYPE tt_file_list,
          lv_count TYPE i,
          lv_total_size TYPE i,
          ls_file TYPE ts_file_info,
          lv_col TYPE i,
          lv_pos TYPE i.

    " Query ZCPM_00_BIN for files on current disk ONLY
    SELECT name FROM zcpm_00_bin
      INTO TABLE @DATA(lt_bin_files)
      WHERE bin = @mv_disk.

    LOOP AT lt_bin_files INTO DATA(ls_bin).
      DATA(lv_binname) = CONV string( ls_bin-name ).
      lv_pos = find( val = lv_binname sub = '.' occ = -1 ).
      IF lv_pos >= 0.
        ls_file-name = to_upper( lv_binname+0(lv_pos) ).
        DATA(lv_ext_pos) = lv_pos + 1.
        ls_file-extension = to_upper( lv_binname+lv_ext_pos ).
      ELSE.
        ls_file-name = to_upper( lv_binname ).
        ls_file-extension = ''.
      ENDIF.

      IF strlen( ls_file-name ) > 8.
        ls_file-name = ls_file-name+0(8).
      ENDIF.
      IF strlen( ls_file-extension ) > 3.
        ls_file-extension = ls_file-extension+0(3).
      ENDIF.

      ls_file-size = 0.
      ls_file-description = 'BIN'.
      APPEND ls_file TO lt_files.
    ENDLOOP.

    SORT lt_files BY name extension.

    IF lt_files IS INITIAL.
      rv_output = |No files found on disk { mv_disk }{ c_crlf }|.
      RETURN.
    ENDIF.

    rv_output = |{ c_crlf }Directory of { mv_current_drive }: (Disk { mv_disk }){ c_crlf }{ c_crlf }|.

    LOOP AT lt_files INTO ls_file.
      DATA(lv_dname) = |{ ls_file-name WIDTH = 8 }|.
      DATA(lv_dext) = |{ ls_file-extension WIDTH = 3 }|.

      rv_output = rv_output && |{ lv_dname } { lv_dext }  |.

      lv_col = lv_col + 1.
      IF lv_col >= 4.
        rv_output = rv_output && c_crlf.
        lv_col = 0.
      ENDIF.

      lv_count = lv_count + 1.
      lv_total_size = lv_total_size + ls_file-size.
    ENDLOOP.

    IF lv_col > 0.
      rv_output = rv_output && c_crlf.
    ENDIF.

    rv_output = rv_output && |{ c_crlf }{ lv_count } file(s), { format_size( lv_total_size ) }{ c_crlf }|.
  ENDMETHOD.

  METHOD cmd_type.
    " Try bin table first
    DATA(lv_data) = load_bin_file( iv_filename ).
    IF lv_data IS INITIAL.
      lv_data = load_smw0_file( iv_filename ).
    ENDIF.

    IF lv_data IS INITIAL.
      rv_output = |File not found: { iv_filename }{ c_crlf }|.
      RETURN.
    ENDIF.

    " Limit to 4KB
    DATA lv_len TYPE i.
    lv_len = xstrlen( lv_data ).
    IF lv_len > 4096.
      lv_data = lv_data+0(4096).
    ENDIF.

    " Convert xstring to string (preserves spaces)
    DATA lv_text TYPE string.
    TRY.
        lv_text = cl_abap_codepage=>convert_from( lv_data ).
      CATCH cx_root.
        rv_output = |Error reading file{ c_crlf }|.
        RETURN.
    ENDTRY.

    rv_output = lv_text && c_crlf.
  ENDMETHOD.

  METHOD cmd_help.
    rv_output =
      |{ c_crlf }| &&
      |CP/M Commands:{ c_crlf }| &&
      |  DIR [pattern]  - List files (e.g., DIR *.COM){ c_crlf }| &&
      |  TYPE filename  - Display text file{ c_crlf }| &&
      |  filename       - Run .COM program{ c_crlf }| &&
      |  A: B: ...      - Change drive{ c_crlf }| &&
      |  USER n         - Set user number{ c_crlf }| &&
      |  DISK name      - Set bin disk (ZCPM_00_BIN){ c_crlf }| &&
      |  CLS            - Clear screen{ c_crlf }| &&
      |  VER            - Show version{ c_crlf }| &&
      |  RESET          - Reset connection counter{ c_crlf }| &&
      |  HELP           - This help{ c_crlf }| &&
      |  EXIT           - End session{ c_crlf }| &&
      |{ c_crlf }| &&
      |Files loaded from ZCPM_00_BIN (disk { mv_disk }) and SMW0.{ c_crlf }| &&
      |{ c_crlf }|.
  ENDMETHOD.

  METHOD cmd_era.
    rv_output = |Read-only file system{ c_crlf }|.
  ENDMETHOD.

  METHOD load_bin_file.
    " Load file from ZCPM_00_BIN table
    DATA lv_name TYPE text60.
    lv_name = to_upper( iv_name ).

    SELECT SINGLE v FROM zcpm_00_bin
      INTO @rv_data
      WHERE bin = @mv_disk
        AND name = @lv_name.
  ENDMETHOD.

  METHOD load_smw0_file.
    DATA: lt_mime TYPE w3mimetabtype,
          ls_key  TYPE wwwdatatab,
          lv_size TYPE i,
          lv_objid TYPE wwwparams-objid.

    SELECT SINGLE objid FROM wwwparams
      INTO lv_objid
      WHERE relid = 'MI'
        AND objid = iv_name.

    IF sy-subrc <> 0.
      DATA lt_all TYPE STANDARD TABLE OF wwwparams-objid.
      SELECT DISTINCT objid FROM wwwparams
        INTO TABLE lt_all
        WHERE relid = 'MI'.

      LOOP AT lt_all INTO DATA(lv_obj).
        IF to_upper( lv_obj ) = to_upper( iv_name ).
          lv_objid = lv_obj.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF lv_objid IS INITIAL.
        RETURN.
      ENDIF.
    ENDIF.

    ls_key-relid = 'MI'.
    ls_key-objid = lv_objid.

    DATA lv_size_str TYPE wwwparams-value.
    SELECT SINGLE value FROM wwwparams
      INTO lv_size_str
      WHERE relid = 'MI'
        AND objid = lv_objid
        AND name = 'filesize'.

    IF sy-subrc = 0.
      lv_size = lv_size_str.
    ENDIF.

    CALL FUNCTION 'WWWDATA_IMPORT'
      EXPORTING key  = ls_key
      TABLES    mime = lt_mime
      EXCEPTIONS OTHERS = 1.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING input_length = lv_size
      IMPORTING buffer       = rv_data
      TABLES    binary_tab   = lt_mime.
  ENDMETHOD.

  METHOD format_size.
    IF iv_size >= 1048576.
      rv_text = |{ iv_size / 1048576 DECIMALS = 1 }MB|.
    ELSEIF iv_size >= 1024.
      rv_text = |{ iv_size / 1024 DECIMALS = 0 }KB|.
    ELSE.
      rv_text = |{ iv_size }B|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
