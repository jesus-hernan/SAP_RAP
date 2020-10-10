FUNCTION zfm_update.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VALUES) TYPE  /DMO/TT_BOOKSUPPL_M
*"----------------------------------------------------------------------
  UPDATE ztlog_bsuppl_m FROM TABLE @values.

ENDFUNCTION.
