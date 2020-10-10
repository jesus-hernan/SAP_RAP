*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    "actions
    METHODS:
      copy_travel            FOR MODIFY IMPORTING keys FOR ACTION travel~createTravelByTemplate RESULT result,
      set_status_completed   FOR MODIFY IMPORTING keys FOR ACTION travel~acceptTravel RESULT result,
      set_status_cancelled   FOR MODIFY IMPORTING keys FOR ACTION travel~rejectTravel RESULT result,

      get_features           FOR FEATURES IMPORTING keys REQUEST requested_features FOR travel RESULT result,
      "validations
      validate_customer      FOR VALIDATION travel~validateCustomer IMPORTING keys FOR travel,
      validate_dates         FOR VALIDATION travel~validateDates    IMPORTING keys FOR travel,
      validate_travel_status FOR VALIDATION travel~validateStatus   IMPORTING keys FOR travel,
      "autorizations
      check_authority_for_entity FOR AUTHORIZATION IMPORTING lt_entity_key REQUEST is_request FOR travel RESULT result.
ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD copy_travel.
    SELECT MAX( travel_id ) FROM ztlog_travel_m INTO @DATA(lv_travel_id).

    "EML
    READ ENTITY zcds_i_travel_m
    FIELDS ( travel_id agency_id customer_id booking_fee total_price currency_code )
    WITH VALUE #( FOR travel IN keys ( %key = travel-%key ) )
    RESULT DATA(lt_read_result)
    FAILED failed
    REPORTED reported.

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    DATA lt_create TYPE TABLE FOR CREATE zcds_i_travel_m\\travel.

    lt_create = VALUE #( FOR row IN lt_read_result INDEX INTO idx
    ( travel_id      = lv_travel_id + idx
      agency_id      = row-agency_id
      customer_id    = row-customer_id
      begin_date     = lv_today
      end_date       = lv_today + 30
      booking_fee    = row-booking_fee
      total_price    = row-total_price
      currency_code  = row-currency_code
      description    = 'Enter your comments here'
      overall_status = 'O') ).

    "EML
    MODIFY ENTITIES OF zcds_i_travel_m
    IN LOCAL MODE ENTITY travel
    CREATE FIELDS ( travel_id
                    agency_id
                    customer_id
                    begin_date
                    end_date
                    booking_fee
                    total_price
                    currency_code
                    description
                    overall_status )
                    WITH lt_create
                    MAPPED mapped
                    FAILED failed
                    REPORTED reported.

    result = VALUE #( FOR create IN lt_create INDEX INTO idx
                    ( %cid_ref = keys[ idx ]-%cid_ref
                      %key     = keys[ idx ]-travel_id
                      %param   = CORRESPONDING #( create ) ) ).

  ENDMETHOD.

  METHOD set_status_completed.
    " Modify in local mode: BO-related updates that are not relevant for authorization checks
    MODIFY ENTITIES OF zcds_i_travel_m IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( overall_status )
    WITH VALUE #( FOR key IN keys ( travel_id = key-travel_id
    overall_status = 'A' ) ) " Accepted
    FAILED failed
    REPORTED reported.

    " Read changed data for action result
    READ ENTITIES OF zcds_i_travel_m IN LOCAL MODE
    ENTITY travel
    FIELDS ( agency_id
             customer_id
             begin_date
             end_date
             booking_fee
             total_price
             currency_code
             overall_status
             description
             created_by
             created_at
             last_changed_at
             last_changed_by )
    WITH VALUE #( FOR key IN keys ( travel_id = key-travel_id ) )
    RESULT DATA(lt_travel).
    result = VALUE #( FOR travel IN lt_travel ( travel_id = travel-travel_id
    %param = travel
    ) ).
  ENDMETHOD.

  METHOD set_status_cancelled.
    MODIFY ENTITIES OF zcds_i_travel_m IN LOCAL MODE
           ENTITY travel
              UPDATE FROM VALUE #( FOR key IN keys ( travel_id = key-travel_id
                                                     overall_status = 'X'   " Canceled
                                                     %control-overall_status = if_abap_behv=>mk-on ) )
           FAILED   failed
           REPORTED reported.

    " read changed data for result
    READ ENTITIES OF zcds_i_travel_m IN LOCAL MODE
     ENTITY travel
       FIELDS ( agency_id
                customer_id
                begin_date
                end_date
                booking_fee
                total_price
                currency_code
                overall_status
                description
                created_by
                created_at
                last_changed_at
                last_changed_by )
         WITH VALUE #( FOR key IN keys ( travel_id = key-travel_id ) )
     RESULT DATA(lt_travel).

    result = VALUE #( FOR travel IN lt_travel ( travel_id = travel-travel_id
                                                %param    = travel
                                              ) ).
  ENDMETHOD.

  METHOD get_features.
    READ ENTITY zcds_i_travel_m
    "FIELDS ( travel_id overall_status description )
    FROM VALUE #( FOR keyval IN keys ( %key = keyval-%key ) )
    RESULT DATA(lt_travel_result).

    result = VALUE #( FOR ls_travel IN lt_travel_result (
    %key = ls_travel-%key
    %field-travel_id = if_abap_behv=>fc-f-read_only
    %features-%action-rejectTravel = COND #( WHEN ls_travel-overall_status = 'X'
                                                THEN if_abap_behv=>fc-o-disabled
                                                ELSE if_abap_behv=>fc-o-enabled )

    %features-%action-acceptTravel = COND #( WHEN ls_travel-overall_status = 'A'
                                                THEN if_abap_behv=>fc-o-disabled
                                                ELSE if_abap_behv=>fc-o-enabled )
        ) ).

  ENDMETHOD.

  METHOD validate_customer.
    " Read relevant travel instance data
    READ ENTITIES OF zcds_i_travel_m IN LOCAL MODE
    ENTITY travel
     FIELDS ( customer_id )
     WITH CORRESPONDING #(  keys )
    RESULT DATA(lt_travel).

    DATA lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    lt_customer = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = customer_id EXCEPT * ).
    DELETE lt_customer WHERE customer_id IS INITIAL.
    IF lt_customer IS NOT INITIAL.

      " Check if customer ID exists
      SELECT FROM /dmo/customer FIELDS customer_id
        FOR ALL ENTRIES IN @lt_customer
        WHERE customer_id = @lt_customer-customer_id
        INTO TABLE @DATA(lt_customer_db).
    ENDIF.
    " Raise msg for non existing and initial customer id
    LOOP AT lt_travel INTO DATA(ls_travel).
      IF ls_travel-customer_id IS INITIAL
         OR NOT line_exists( lt_customer_db[ customer_id = ls_travel-customer_id ] ).

        APPEND VALUE #(  travel_id = ls_travel-travel_id ) TO failed.
        APPEND VALUE #(  travel_id = ls_travel-travel_id
                         %msg = new_message( id        = '/DMO/CM_FLIGHT_LEGAC'
                                             number    = '002'
                                             v1        = ls_travel-customer_id
                                             severity  = if_abap_behv_message=>severity-error )
                         %element-customer_id = if_abap_behv=>mk-on )
          TO reported.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validate_dates.
    READ ENTITY zcds_i_travel_m\\travel FIELDS ( begin_date end_date )  WITH
            VALUE #( FOR <root_key> IN keys ( %key = <root_key> ) )
            RESULT DATA(lt_travel_result).

    LOOP AT lt_travel_result INTO DATA(ls_travel_result).

      IF ls_travel_result-end_date < ls_travel_result-begin_date.  "end_date before begin_date

        APPEND VALUE #( %key        = ls_travel_result-%key
                        travel_id   = ls_travel_result-travel_id ) TO failed.

        APPEND VALUE #( %key     = ls_travel_result-%key
                        %msg     = new_message( id       = /dmo/cx_flight_legacy=>end_date_before_begin_date-msgid
                                                number   = /dmo/cx_flight_legacy=>end_date_before_begin_date-msgno
                                                v1       = ls_travel_result-begin_date
                                                v2       = ls_travel_result-end_date
                                                v3       = ls_travel_result-travel_id
                                                severity = if_abap_behv_message=>severity-error )
                        %element-begin_date = if_abap_behv=>mk-on
                        %element-end_date   = if_abap_behv=>mk-on ) TO reported.

      ELSEIF ls_travel_result-begin_date < cl_abap_context_info=>get_system_date( ).  "begin_date must be in the future

        APPEND VALUE #( %key        = ls_travel_result-%key
                        travel_id   = ls_travel_result-travel_id ) TO failed.

        APPEND VALUE #( %key = ls_travel_result-%key
                        %msg = new_message( id       = /dmo/cx_flight_legacy=>begin_date_before_system_date-msgid
                                            number   = /dmo/cx_flight_legacy=>begin_date_before_system_date-msgno
                                            severity = if_abap_behv_message=>severity-error )
                        %element-begin_date = if_abap_behv=>mk-on
                        %element-end_date   = if_abap_behv=>mk-on ) TO reported.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validate_travel_status.
    READ ENTITY zcds_i_travel_m\\travel FIELDS ( overall_status ) WITH
            VALUE #( FOR <root_key> IN keys ( %key = <root_key> ) )
            RESULT DATA(lt_travel_result).

    LOOP AT lt_travel_result INTO DATA(ls_travel_result).
      CASE ls_travel_result-overall_status.
        WHEN 'O'.  " Open
        WHEN 'X'.  " Cancelled
        WHEN 'A'.  " Accepted

        WHEN OTHERS.
          APPEND VALUE #( %key = ls_travel_result-%key ) TO failed.

          APPEND VALUE #( %key = ls_travel_result-%key
                          %msg = new_message( id       = /dmo/cx_flight_legacy=>status_is_not_valid-msgid
                                              number   = /dmo/cx_flight_legacy=>status_is_not_valid-msgno
                                              v1       = ls_travel_result-overall_status
                                              severity = if_abap_behv_message=>severity-error )
                          %element-overall_status = if_abap_behv=>mk-on ) TO reported.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_authority_for_entity.
    DATA(lv_syuname) = cl_abap_context_info=>get_user_technical_name( ).
    IF lv_syuname = 'CB0000000025'.
      LOOP AT lt_entity_key INTO DATA(ls_entity_key).
        APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
        <ls_result> = VALUE #( %key = ls_entity_key-%key
*      %update = if_abap_behv=>auth-allowed
        %op-%update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed
        %action-createTravelByTemplate = if_abap_behv=>auth-allowed
        %action-acceptTravel = if_abap_behv=>auth-allowed
        %action-rejectTravel = if_abap_behv=>auth-allowed
        %assoc-_Booking = if_abap_behv=>auth-allowed ).
      ENDLOOP.
    ELSE.
      LOOP AT lt_entity_key INTO DATA(ls_entity_e_key).
        APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result_e>).
        <ls_result_e> = VALUE #( %key = ls_entity_e_key-%key
*      %update = if_abap_behv=>auth-unauthorized
        %op-%update = if_abap_behv=>auth-unauthorized
        %delete = if_abap_behv=>auth-unauthorized
        %action-createTravelByTemplate = if_abap_behv=>auth-unauthorized
        %action-acceptTravel = if_abap_behv=>auth-unauthorized
        %action-rejectTravel = if_abap_behv=>auth-unauthorized
        %assoc-_Booking = if_abap_behv=>auth-unauthorized ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_save DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lcl_save IMPLEMENTATION.
  METHOD save_modified.
    DATA: lt_travel_log   TYPE STANDARD TABLE OF ztlog_log_travel,
          lt_travel_log_c TYPE STANDARD TABLE OF ztlog_log_travel,
          lt_travel_log_u TYPE STANDARD TABLE OF ztlog_log_travel.
*    DATA(lv_syuname) = cl_abap_context_info=>get_user_technical_name( ).
    " (1) Get instance data of all instances that have been created
    IF create-travel IS NOT INITIAL.
      " Creates internal table with instance data
      lt_travel_log = CORRESPONDING #( create-travel ).
      LOOP AT lt_travel_log ASSIGNING FIELD-SYMBOL(<fs_travel_log_c>).
        <fs_travel_log_c>-changing_operation = 'CREATE'.
        " Generate time stamp
        GET TIME STAMP FIELD <fs_travel_log_c>-created_at.
        " Read travel instance data into ls_travel that includes %control structure
        READ TABLE create-travel WITH TABLE KEY entity COMPONENTS travel_id = <fs_travel_log_c>-travel_id INTO DATA(ls_travel).
        IF sy-subrc = 0.
          " If new value of the booking_fee field created
          IF ls_travel-%control-booking_fee = cl_abap_behv=>flag_changed.
            " Generate uuid as value of the change_id field
            TRY.
                <fs_travel_log_c>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
              CATCH cx_uuid_error.
                "handle exception
            ENDTRY.
            <fs_travel_log_c>-changed_field_name = 'booking_fee'.
            <fs_travel_log_c>-changed_value = ls_travel-booking_fee.
            <fs_travel_log_c>-user_mod = cl_abap_context_info=>get_user_technical_name( ).
            APPEND <fs_travel_log_c> TO lt_travel_log_c.
          ENDIF.
          " If new value of the overal_status field created
          IF ls_travel-%control-overall_status = cl_abap_behv=>flag_changed.
            " Generate uuid as value of the change_id field
            TRY.
                <fs_travel_log_c>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
              CATCH cx_uuid_error.
                "handle exception
            ENDTRY.
            <fs_travel_log_c>-changed_field_name = 'overal_status'.
            <fs_travel_log_c>-changed_value = ls_travel-overall_status.
            <fs_travel_log_c>-user_mod = cl_abap_context_info=>get_user_technical_name( ).
            APPEND <fs_travel_log_c> TO lt_travel_log_c.
          ENDIF.
          " IF ls_travel-%control-...
        ENDIF.
      ENDLOOP.
      " Inserts rows specified in lt_travel_log into the DB table ztlog_log_travel
      INSERT ztlog_log_travel FROM TABLE @lt_travel_log_c.
    ENDIF.
    " (2) Get instance data of all instances that have been updated during the transaction
    IF update-travel IS NOT INITIAL.
      lt_travel_log = CORRESPONDING #( update-travel ).
      LOOP AT update-travel ASSIGNING FIELD-SYMBOL(<fs_travel_log_u>).
        ASSIGN lt_travel_log[ travel_id = <fs_travel_log_u>-travel_id ] TO FIELD-SYMBOL(<fs_travel_db>).
        <fs_travel_db>-changing_operation = 'UPDATE'.
        " Generate time stamp
        GET TIME STAMP FIELD <fs_travel_db>-created_at.
        IF <fs_travel_log_u>-%control-customer_id = if_abap_behv=>mk-on.
          <fs_travel_db>-changed_value = <fs_travel_log_u>-customer_id.
          " Generate uuid as value of the change_id field
          TRY.
              <fs_travel_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
            CATCH cx_uuid_error.
              "handle exception
          ENDTRY.
          <fs_travel_db>-changed_field_name = 'customer_id'.
          <fs_travel_db>-user_mod = cl_abap_context_info=>get_user_technical_name( ).
          APPEND <fs_travel_db> TO lt_travel_log_u.
        ENDIF.
        IF <fs_travel_log_u>-%control-description = if_abap_behv=>mk-on.
          <fs_travel_db>-changed_value = <fs_travel_log_u>-description.
          " Generate uuid as value of the change_id field
          TRY.
              <fs_travel_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
            CATCH cx_uuid_error.
              "handle exception
          ENDTRY.
          <fs_travel_db>-changed_field_name = 'description'.
          <fs_travel_db>-user_mod = cl_abap_context_info=>get_user_technical_name( ).
          APPEND <fs_travel_db> TO lt_travel_log_u.
        ENDIF.
        "IF <fs_travel_log_u>-%control-...
      ENDLOOP.
      " Inserts rows specified in lt_travel_log into the DB table ztlog_log_travel
      INSERT ztlog_log_travel FROM TABLE @lt_travel_log_u.
    ENDIF.
    " (3) Get keys of all travel instances that have been deleted during the transaction
    IF delete-travel IS NOT INITIAL.
      lt_travel_log = CORRESPONDING #( delete-travel ).
      LOOP AT lt_travel_log ASSIGNING FIELD-SYMBOL(<fs_travel_log_d>).
        <fs_travel_log_d>-changing_operation = 'DELETE'.
        <fs_travel_log_d>-user_mod = cl_abap_context_info=>get_user_technical_name( ).
        " Generate time stamp
        GET TIME STAMP FIELD <fs_travel_log_d>-created_at.
        " Generate uuid as value of the change_id field
        TRY.
            <fs_travel_log_d>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
          CATCH cx_uuid_error.
            "handle exception
        ENDTRY.
      ENDLOOP.
      " Inserts rows specified in lt_travel_log into the DB table ztlog_log_travel
      INSERT ztlog_log_travel FROM TABLE @lt_travel_log.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
