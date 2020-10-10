FUNCTION zfm_insert.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VALUES) TYPE  /DMO/TT_BOOKSUPPL_M
*"----------------------------------------------------------------------
  INSERT ztlog_bsuppl_m FROM TABLE @values.
ENDFUNCTION.
