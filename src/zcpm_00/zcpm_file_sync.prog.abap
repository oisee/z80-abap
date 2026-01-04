*&---------------------------------------------------------------------*
*& Report ZCPM_FILE_SYNC
*&---------------------------------------------------------------------*
*& Upload single file to ZCPM_00_BIN table
*&---------------------------------------------------------------------*
REPORT zcpm_file_sync.

PARAMETERS:
  p_file TYPE string LOWER CASE OBLIGATORY,
  p_disk TYPE char30 DEFAULT 'A' OBLIGATORY.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  DATA lt_files TYPE filetable.
  DATA lv_rc TYPE i.
  DATA lv_action TYPE i.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title = 'Select file to upload'
      default_extension = '*'
      file_filter = 'All Files (*.*)|*.*|COM Files (*.COM)|*.COM|TAP Files (*.TAP)|*.TAP'
    CHANGING
      file_table = lt_files
      rc = lv_rc
      user_action = lv_action
    EXCEPTIONS
      OTHERS = 1 ).

  IF sy-subrc = 0 AND lv_action = cl_gui_frontend_services=>action_ok.
    READ TABLE lt_files INTO DATA(ls_file) INDEX 1.
    IF sy-subrc = 0.
      p_file = ls_file-filename.
    ENDIF.
  ENDIF.

START-OF-SELECTION.
  DATA lt_bin TYPE TABLE OF x255.
  DATA lv_size TYPE i.
  DATA lv_filename TYPE string.

  " Extract filename from path
  DATA(lv_pos) = 0.
  DATA(lv_last_sep) = 0.
  WHILE lv_pos < strlen( p_file ).
    DATA(lv_ch) = p_file+lv_pos(1).
    IF lv_ch = '\' OR lv_ch = '/'.
      lv_last_sep = lv_pos + 1.
    ENDIF.
    lv_pos = lv_pos + 1.
  ENDWHILE.
  lv_filename = p_file+lv_last_sep.

  WRITE: / 'Uploading:', lv_filename.
  WRITE: / 'To disk:', p_disk.
  WRITE: / '---'.

  " Upload file as binary
  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename   = p_file
      filetype   = 'BIN'
    IMPORTING
      filelength = lv_size
    CHANGING
      data_tab   = lt_bin
    EXCEPTIONS
      OTHERS     = 1 ).

  IF sy-subrc <> 0.
    WRITE: / 'Error uploading file!'.
    RETURN.
  ENDIF.

  " Convert to xstring
  DATA lv_xstring TYPE xstring.
  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = lv_size
    IMPORTING
      buffer       = lv_xstring
    TABLES
      binary_tab   = lt_bin
    EXCEPTIONS
      OTHERS       = 1.

  IF sy-subrc <> 0.
    WRITE: / 'Error converting file!'.
    RETURN.
  ENDIF.

  " Prepare record
  DATA ls_bin TYPE zcpm_00_bin.
  ls_bin-bin   = p_disk.
  ls_bin-name  = to_upper( lv_filename ).
  ls_bin-v     = lv_xstring.
  GET TIME STAMP FIELD ls_bin-ts.
  ls_bin-cdate = sy-datum.

  " Upsert
  MODIFY zcpm_00_bin FROM ls_bin.
  IF sy-subrc = 0.
    WRITE: / 'Success!'.
    WRITE: / 'File:', ls_bin-name.
    WRITE: / 'Size:', lv_size, 'bytes'.
    WRITE: / 'Disk:', p_disk.
  ELSE.
    WRITE: / 'Error saving to database!'.
  ENDIF.
