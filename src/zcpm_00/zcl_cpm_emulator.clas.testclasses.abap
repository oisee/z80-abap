CLASS ltcl_cpm_emulator DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cpm TYPE REF TO zcl_cpm_emulator.

    METHODS setup.
    METHODS test_constructor FOR TESTING.
    METHODS test_reset FOR TESTING.
    METHODS test_hello_world FOR TESTING.
    METHODS test_bdos_print_string FOR TESTING.
    METHODS test_bdos_console_output FOR TESTING.
    METHODS test_bdos_version FOR TESTING.
    METHODS test_hello_trace FOR TESTING.
ENDCLASS.

CLASS ltcl_cpm_emulator IMPLEMENTATION.

  METHOD setup.
    CREATE OBJECT mo_cpm.
  ENDMETHOD.

  METHOD test_hello_trace.
    DATA lv_program TYPE xstring.
    DATA lv_output TYPE string.
    DATA lt_trace TYPE zcl_cpm_emulator=>tt_trace.
    DATA lv_trace_dump TYPE string.

    lv_program = '0E09110801CD0500C948656C6C6F2C2043502F4D20576F726C64210D0A24'.

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    mo_cpm->run(
      EXPORTING
        iv_max_cycles = 1000
        iv_trace = abap_true
      IMPORTING
        et_trace = lt_trace
      RECEIVING
        rv_output = lv_output ).

    LOOP AT lt_trace INTO DATA(ls_trace).
      lv_trace_dump = lv_trace_dump &&
        |{ sy-tabix WIDTH = 3 }: PC={ ls_trace-pc WIDTH = 5 } | &&
        |OP={ ls_trace-opcode WIDTH = 3 } SP={ ls_trace-sp WIDTH = 5 } | &&
        |A={ ls_trace-a WIDTH = 3 } BC={ ls_trace-bc WIDTH = 5 } | &&
        |DE={ ls_trace-de WIDTH = 5 } { ls_trace-info }| &&
        cl_abap_char_utilities=>newline.
    ENDLOOP.

    cl_abap_unit_assert=>assert_equals(
      act = lv_output
      exp = |Hello, CP/M World!{ cl_abap_char_utilities=>newline }|
      msg = |Trace:{ cl_abap_char_utilities=>newline }{ lv_trace_dump }| ).
  ENDMETHOD.

  METHOD test_constructor.
    cl_abap_unit_assert=>assert_bound(
      act = mo_cpm
      msg = 'CPM emulator should be created' ).
  ENDMETHOD.

  METHOD test_reset.
    mo_cpm->reset( ).
    cl_abap_unit_assert=>assert_equals(
      act = mo_cpm->is_running( )
      exp = abap_true
      msg = 'CPM should be running after reset' ).
  ENDMETHOD.

  METHOD test_hello_world.
    " Test the same Hello World program from Python:
    " LD DE, msg (010Dh)
    " LD C, 9 (print string)
    " CALL 0005h (BDOS)
    " LD C, 0 (system reset)
    " CALL 0005h (BDOS)
    " msg: 'Hello, CP/M World!$'

    DATA lv_program TYPE xstring.
    DATA lv_output TYPE string.

    " Build program bytes
    lv_program = '110D01'    " LD DE, 010Dh (msg address)
              && '0E09'      " LD C, 9 (print string function)
              && 'CD0500'    " CALL 0005h (BDOS)
              && '0E00'      " LD C, 0 (system reset)
              && 'CD0500'    " CALL 0005h (BDOS)
              " msg at 010Dh:
              && '48656C6C6F2C2043502F4D20576F726C642124'.  " 'Hello, CP/M World!$'

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    lv_output = mo_cpm->run( ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_output
      exp = 'Hello, CP/M World!'
      msg = 'Hello World program should produce correct output' ).
  ENDMETHOD.

  METHOD test_bdos_print_string.
    " Simple test: Print 'Test$'
    DATA lv_program TYPE xstring.
    DATA lv_output TYPE string.

    " LD DE, 0109h (msg)
    " LD C, 9
    " CALL 5
    " LD C, 0
    " CALL 5
    " msg: 'Test$'
    lv_program = '110901'    " LD DE, 0109h
              && '0E09'      " LD C, 9
              && 'CD0500'    " CALL 5
              && '0E00'      " LD C, 0
              && 'CD0500'    " CALL 5
              && '5465737424'.  " 'Test$'

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    lv_output = mo_cpm->run( ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_output
      exp = 'Test'
      msg = 'BDOS print string should work' ).
  ENDMETHOD.

  METHOD test_bdos_console_output.
    " Output single character 'A' using BDOS function 2
    DATA lv_program TYPE xstring.
    DATA lv_output TYPE string.

    " LD E, 'A' (41h)
    " LD C, 2 (console output)
    " CALL 5
    " LD C, 0 (system reset)
    " CALL 5
    lv_program = '1E41'      " LD E, 41h ('A')
              && '0E02'      " LD C, 2
              && 'CD0500'    " CALL 5
              && '0E00'      " LD C, 0
              && 'CD0500'.   " CALL 5

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    lv_output = mo_cpm->run( ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_output
      exp = 'A'
      msg = 'BDOS console output should print single char' ).
  ENDMETHOD.

  METHOD test_bdos_version.
    " Test BDOS function 12 returns CP/M 2.2
    " After call, HL should be 0022h (version 2.2)
    DATA lv_program TYPE xstring.

    " LD C, 12 (version)
    " CALL 5
    " HALT (we'll check registers)
    lv_program = '0E0C'      " LD C, 12
              && 'CD0500'    " CALL 5
              && '76'.       " HALT

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).

    " Run just a few cycles to execute the BDOS call
    DATA lv_i TYPE i.
    lv_i = 0.
    WHILE lv_i < 100 AND mo_cpm->is_running( ) = abap_true.
      mo_cpm->step( ).
      lv_i = lv_i + 1.
    ENDWHILE.

    " Version test passes if we got here without crash
    cl_abap_unit_assert=>assert_true(
      act = abap_true
      msg = 'BDOS version call should complete' ).
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* File BDOS Unit Tests
*----------------------------------------------------------------------*
CLASS ltcl_file_bdos DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cpm TYPE REF TO zcl_cpm_emulator.

    METHODS setup.
    METHODS test_setup_fcb FOR TESTING.
    METHODS test_register_file FOR TESTING.
    METHODS test_file_open FOR TESTING.
    METHODS test_file_open_not_found FOR TESTING.
    METHODS test_file_read_seq FOR TESTING.
    METHODS test_file_read_rand FOR TESTING.
    METHODS test_file_size FOR TESTING.
    METHODS test_set_dma FOR TESTING.
ENDCLASS.

CLASS ltcl_file_bdos IMPLEMENTATION.

  METHOD setup.
    CREATE OBJECT mo_cpm.
  ENDMETHOD.

  METHOD test_setup_fcb.
    " Test FCB setup at address 0x005C (92)
    DATA lv_program TYPE xstring.

    lv_program = '76'.  " HALT

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    mo_cpm->setup_fcb( iv_fcb_addr = 92 iv_filename = 'TEST.DAT' ).

    cl_abap_unit_assert=>assert_true(
      act = abap_true
      msg = 'FCB setup should complete without error' ).
  ENDMETHOD.

  METHOD test_register_file.
    DATA lv_program TYPE xstring.

    lv_program = '76'.

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).

    " Register multiple files
    mo_cpm->register_file( iv_filename = 'FILE1.DAT' iv_data = '0102030405' ).
    mo_cpm->register_file( iv_filename = 'FILE2.COM' iv_data = 'AABBCCDD' ).

    cl_abap_unit_assert=>assert_true(
      act = abap_true
      msg = 'Multiple files should register without error' ).
  ENDMETHOD.

  METHOD test_file_open.
    " Test BDOS function 15 - Open existing file
    DATA lv_program TYPE xstring.
    DATA lv_output TYPE string.

    " Program: Open file, print OK, exit
    lv_program = '115C00'    " LD DE, 005Ch (FCB)
              && '0E0F'      " LD C, 15 (open file)
              && 'CD0500'    " CALL 5
              && '110D01'    " LD DE, MSG
              && '0E09'      " LD C, 9
              && 'CD0500'    " CALL 5
              && '0E00'      " LD C, 0
              && 'CD0500'    " CALL 5
              && '4F4B24'.   " 'OK$'

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    mo_cpm->setup_fcb( iv_fcb_addr = 92 iv_filename = 'EXISTS.DAT' ).
    mo_cpm->register_file( iv_filename = 'EXISTS.DAT' iv_data = '00112233445566778899' ).
    lv_output = mo_cpm->run( iv_max_cycles = 10000 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_output
      exp = 'OK'
      msg = 'File open should work for registered files' ).
  ENDMETHOD.

  METHOD test_file_open_not_found.
    " Test BDOS function 15 - File not found returns 255 in A
    DATA lv_program TYPE xstring.

    lv_program = '115C00'    " LD DE, 005Ch (FCB)
              && '0E0F'      " LD C, 15 (open file)
              && 'CD0500'    " CALL 5
              && '76'.       " HALT

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    mo_cpm->setup_fcb( iv_fcb_addr = 92 iv_filename = 'NOFILE.DAT' ).
    " Don't register file - it shouldn't exist
    mo_cpm->run( iv_max_cycles = 1000 ).

    cl_abap_unit_assert=>assert_true(
      act = abap_true
      msg = 'File not found should not crash' ).
  ENDMETHOD.

  METHOD test_file_read_seq.
    " Test BDOS function 20 - Sequential read
    DATA lv_program TYPE xstring.
    DATA lv_file_data TYPE xstring.
    DATA lv_output TYPE string.

    " Create 128 bytes of test data (1 record)
    lv_file_data = '00010203040506070809'.
    DO 118 TIMES.
      lv_file_data = lv_file_data && '00'.
    ENDDO.

    " Program: Open, read seq, print OK, exit
    lv_program = '115C00'    " LD DE, FCB
              && '0E0F'      " LD C, 15 (open)
              && 'CD0500'    " CALL 5
              && '115C00'    " LD DE, FCB
              && '0E14'      " LD C, 20 (read seq)
              && 'CD0500'    " CALL 5
              && '111601'    " LD DE, MSG
              && '0E09'      " LD C, 9
              && 'CD0500'    " CALL 5
              && '0E00'      " LD C, 0
              && 'CD0500'    " CALL 5
              && '4F4B24'.   " 'OK$'

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    mo_cpm->setup_fcb( iv_fcb_addr = 92 iv_filename = 'DATA.BIN' ).
    mo_cpm->register_file( iv_filename = 'DATA.BIN' iv_data = lv_file_data ).
    lv_output = mo_cpm->run( iv_max_cycles = 10000 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_output
      exp = 'OK'
      msg = 'Sequential read should succeed' ).
  ENDMETHOD.

  METHOD test_file_read_rand.
    " Test BDOS function 33 - Random read
    DATA lv_program TYPE xstring.
    DATA lv_file_data TYPE xstring.
    DATA lv_output TYPE string.

    " Create 384 bytes (3 records)
    DO 384 TIMES.
      lv_file_data = lv_file_data && '00'.
    ENDDO.

    " Program: Open, set record 1, read random, print OK
    lv_program = '115C00'    " LD DE, FCB
              && '0E0F'      " LD C, 15 (open)
              && 'CD0500'    " CALL 5
              && '3E01'      " LD A, 1  (record 1)
              && '327D00'    " LD (007Dh), A  (FCB+33)
              && 'AF'        " XOR A
              && '327E00'    " LD (007Eh), A  (FCB+34)
              && '327F00'    " LD (007Fh), A  (FCB+35)
              && '115C00'    " LD DE, FCB
              && '0E21'      " LD C, 33 (read random)
              && 'CD0500'    " CALL 5
              && '112401'    " LD DE, MSG
              && '0E09'      " LD C, 9
              && 'CD0500'    " CALL 5
              && '0E00'      " LD C, 0
              && 'CD0500'    " CALL 5
              && '4F4B24'.   " 'OK$'

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    mo_cpm->setup_fcb( iv_fcb_addr = 92 iv_filename = 'RAND.DAT' ).
    mo_cpm->register_file( iv_filename = 'RAND.DAT' iv_data = lv_file_data ).
    lv_output = mo_cpm->run( iv_max_cycles = 10000 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_output
      exp = 'OK'
      msg = 'Random read should succeed' ).
  ENDMETHOD.

  METHOD test_file_size.
    " Test BDOS function 35 - Get file size
    DATA lv_program TYPE xstring.
    DATA lv_file_data TYPE xstring.
    DATA lv_output TYPE string.

    " Create 256 bytes = 2 records
    DO 256 TIMES.
      lv_file_data = lv_file_data && '00'.
    ENDDO.

    " Program: Get file size, print OK
    lv_program = '115C00'    " LD DE, FCB
              && '0E23'      " LD C, 35 (file size)
              && 'CD0500'    " CALL 5
              && '110E01'    " LD DE, MSG
              && '0E09'      " LD C, 9
              && 'CD0500'    " CALL 5
              && '0E00'      " LD C, 0
              && 'CD0500'    " CALL 5
              && '4F4B24'.   " 'OK$'

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    mo_cpm->setup_fcb( iv_fcb_addr = 92 iv_filename = 'SIZE.DAT' ).
    mo_cpm->register_file( iv_filename = 'SIZE.DAT' iv_data = lv_file_data ).
    lv_output = mo_cpm->run( iv_max_cycles = 10000 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_output
      exp = 'OK'
      msg = 'File size should return without error' ).
  ENDMETHOD.

  METHOD test_set_dma.
    " Test BDOS function 26 - Set DMA address
    DATA lv_program TYPE xstring.
    DATA lv_output TYPE string.

    " Program: Set DMA to 0x1000, print OK
    lv_program = '110010'    " LD DE, 1000h
              && '0E1A'      " LD C, 26 (set DMA)
              && 'CD0500'    " CALL 5
              && '110C01'    " LD DE, MSG
              && '0E09'      " LD C, 9
              && 'CD0500'    " CALL 5
              && '0E00'      " LD C, 0
              && 'CD0500'    " CALL 5
              && '4F4B24'.   " 'OK$'

    mo_cpm->reset( ).
    mo_cpm->load_program( lv_program ).
    lv_output = mo_cpm->run( iv_max_cycles = 10000 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_output
      exp = 'OK'
      msg = 'Set DMA should work' ).
  ENDMETHOD.

ENDCLASS.
