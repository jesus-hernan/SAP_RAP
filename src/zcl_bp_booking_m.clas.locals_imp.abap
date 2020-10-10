CLASS lhc_book DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateTotalFlightPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR book~calculateTotalFlightPrice.

*    METHODS calculateTotalFlightPrice FOR DETERMINATION book~calculateTotalFlightPrice
*      IMPORTING keys FOR book.


    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR book~validateStatus.

*    METHODS get_authorizations FOR AUTHORIZATION
*      IMPORTING keys REQUEST requested_authorizations FOR book RESULT result.

    METHODS get_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR book RESULT result.

ENDCLASS.

CLASS lhc_book IMPLEMENTATION.

  METHOD calculateTotalFlightPrice.
    IF keys IS NOT INITIAL.
      zcl_travel_auxiliary_man=>calculate_price(
      it_travel_id = VALUE #( FOR GROUPS <booking> OF booking_key IN keys
      GROUP BY booking_key-travel_id WITHOUT MEMBERS ( <booking> ) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD validateStatus.
    READ ENTITY zcds_i_travel_m\\book
    FIELDS ( booking_status )
    WITH VALUE #( FOR <root_key> IN keys ( %key = <root_key> ) )
    RESULT DATA(lt_booking_result).
    LOOP AT lt_booking_result INTO DATA(ls_booking_result).
      CASE ls_booking_result-booking_status.
        WHEN 'N'. " New
        WHEN 'X'. " Canceled
        WHEN 'B'. " Booked
        WHEN OTHERS.
          APPEND VALUE #( %key = ls_booking_result-%key ) TO failed-book.
          APPEND VALUE #( %key = ls_booking_result-%key
                          %msg = new_message( id = /dmo/cx_flight_legacy=>status_is_not_valid-msgid
                                          number = /dmo/cx_flight_legacy=>status_is_not_valid-msgno
                                              v1 = ls_booking_result-booking_status
                                        severity = if_abap_behv_message=>severity-error )
                         %element-booking_status = if_abap_behv=>mk-on ) TO reported-book.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_features.
    "mismo código que la interface
  ENDMETHOD.

ENDCLASS.
