CLASS zcl_virtual DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_virtual IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    IF iv_entity <> 'ZCDS_CTRAVEL_M'.
      RETURN.
    ENDIF.
    LOOP AT it_requested_calc_elements ASSIGNING FIELD-SYMBOL(<fs_calc_element>).
      CASE <fs_calc_element>.
        WHEN 'VIRT_FIELD'.
          APPEND 'TOTALPRICE' TO et_requested_orig_elements.
        WHEN OTHERS.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA lt_original_data TYPE STANDARD TABLE OF zcds_c_travel_m WITH DEFAULT KEY.
    lt_original_data = CORRESPONDING #( it_original_data ).
    LOOP AT lt_original_data ASSIGNING FIELD-SYMBOL(<fs_original_data>).
      <fs_original_data>-virt_field = <fs_original_data>-TotalPrice - ( <fs_original_data>-TotalPrice * ( 1 / 10 ) ).
    ENDLOOP.
    ct_calculated_data = CORRESPONDING #( lt_original_data ).
  ENDMETHOD.

ENDCLASS.
