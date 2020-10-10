FUNCTION zfm_delete.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VALUES) TYPE  /DMO/TT_BOOKSUPPL_M
*"----------------------------------------------------------------------
  DELETE ztlog_bsuppl_m FROM TABLE @values.
ENDFUNCTION.
