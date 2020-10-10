CLASS lhc_booksupl DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateTotalSupplimPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR booksupl~calculateTotalSupplimPrice.

*    METHODS get_features FOR FEATURES
*      IMPORTING keys REQUEST requested_features FOR booksupl RESULT result.

ENDCLASS.


CLASS lhc_booksupl IMPLEMENTATION.

  METHOD calculateTotalSupplimPrice.
    IF keys IS NOT INITIAL.
      zcl_travel_auxiliary_man=>calculate_price( it_travel_id = VALUE #( FOR GROUPS <booking_suppl> OF booksuppl_key IN keys
                                                                 GROUP BY booksuppl_key-travel_id WITHOUT MEMBERS ( <booking_suppl> ) ) ).
    ENDIF.
  ENDMETHOD.

*  METHOD get_features.
*  ENDMETHOD.

ENDCLASS.


CLASS lcl_save DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.


CLASS lcl_save IMPLEMENTATION.
  METHOD save_modified.
    DATA lt_booksuppl_db TYPE STANDARD TABLE OF ztlog_bsuppl_m.
    " (1) Get instance data of all instances that have been created
    IF create-booksupl IS NOT INITIAL.
      lt_booksuppl_db = CORRESPONDING #( create-booksupl ).
      CALL FUNCTION 'ZFM_INSERT'
        EXPORTING
          values = lt_booksuppl_db.
    ENDIF.
    " (2) Get instance data of all instances that have been updated during the transaction
    IF update-booksupl IS NOT INITIAL.
      lt_booksuppl_db = CORRESPONDING #( update-booksupl ).
      " Read all field values from database
      SELECT * FROM ztlog_bsuppl_m FOR ALL ENTRIES IN @lt_booksuppl_db
      WHERE booking_supplement_id = @lt_booksuppl_db-booking_supplement_id
      INTO TABLE @lt_booksuppl_db .
      " Take over field values that have been changed during the transaction
      LOOP AT update-booksupl ASSIGNING FIELD-SYMBOL(<ls_unmanaged_booksupl>).
        ASSIGN lt_booksuppl_db[ travel_id = <ls_unmanaged_booksupl>-travel_id
        booking_id = <ls_unmanaged_booksupl>-booking_id
        booking_supplement_id = <ls_unmanaged_booksupl>-booking_supplement_id
        ] TO FIELD-SYMBOL(<ls_booksuppl_db>).
        IF <ls_unmanaged_booksupl>-%control-supplement_id = if_abap_behv=>mk-on.
          <ls_booksuppl_db>-supplement_id = <ls_unmanaged_booksupl>-supplement_id.
        ENDIF.
        IF <ls_unmanaged_booksupl>-%control-price = if_abap_behv=>mk-on.
          <ls_booksuppl_db>-price = <ls_unmanaged_booksupl>-price.
        ENDIF.
        IF <ls_unmanaged_booksupl>-%control-currency_code = if_abap_behv=>mk-on.
          <ls_booksuppl_db>-currency_code = <ls_unmanaged_booksupl>-currency_code.
        ENDIF.
      ENDLOOP.
      " Update the complete instance data
      CALL FUNCTION 'ZFM_UPDATE'
        EXPORTING
          values = lt_booksuppl_db.
    ENDIF.
    " (3) Get keys of all travel instances that have been deleted during the transaction
    IF delete-booksupl IS NOT INITIAL.
      lt_booksuppl_db = CORRESPONDING #( delete-booksupl ).
      CALL FUNCTION 'ZFM_DELETE'
        EXPORTING
          values = lt_booksuppl_db.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
