*&---------------------------------------------------------------------*
*& Report ZCPM_INSERT_HELLO
*&---------------------------------------------------------------------*
*& Insert minimal COBOL program into ZCPM_00_BIN
*&---------------------------------------------------------------------*
REPORT zcpm_insert_hello.

START-OF-SELECTION.
  DATA ls_bin TYPE zcpm_00_bin.
  DATA lv_source TYPE string.
  DATA lv_crlf TYPE string.

  lv_crlf = cl_abap_char_utilities=>cr_lf.

  " Minimal COBOL program - use concatenation to preserve spaces
  CONCATENATE
    '       IDENTIFICATION DIVISION.' lv_crlf
    '       PROGRAM-ID. HELLO.' lv_crlf
    '       PROCEDURE DIVISION.' lv_crlf
    '           DISPLAY "HELLO FROM COBOL ON SAP HANA!".' lv_crlf
    '           STOP RUN.' lv_crlf
    INTO lv_source RESPECTING BLANKS.

  " Convert to xstring (ASCII/UTF-8)
  DATA(lv_xstring) = cl_abap_codepage=>convert_to( lv_source ).

  " Insert into bin table
  ls_bin-bin   = 'A'.
  ls_bin-name  = 'HELLO.COB'.
  ls_bin-v     = lv_xstring.
  GET TIME STAMP FIELD ls_bin-ts.
  ls_bin-cdate = sy-datum.

  MODIFY zcpm_00_bin FROM ls_bin.
  IF sy-subrc = 0.
    WRITE: / 'HELLO.COB inserted successfully!'.
    WRITE: / 'Size:', xstrlen( lv_xstring ), 'bytes'.
    WRITE: / '---'.
    WRITE: / 'Content preview:'.
    WRITE: / lv_source.
    COMMIT WORK.
  ELSE.
    WRITE: / 'Error inserting HELLO.COB'.
  ENDIF.
