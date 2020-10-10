@AbapCatalog.sqlViewName: 'ZV_BOOKSUPPL_M'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'Booking Supplement View'
define view ZCDS_I_BOOKSUPPL_M
  as select from ztlog_bsuppl_m as BookingSupplement
  association        to parent ZCDS_I_BOOK_M  as _Booking        on  $projection.travel_id  = _Booking.travel_id
                                                                 and $projection.booking_id = _Booking.booking_id
  association [1..1] to ZCDS_I_TRAVEL_M       as _Travel         on  $projection.travel_id = _Travel.travel_id
  association [1..1] to /DMO/I_Supplement     as _Product        on  $projection.supplement_id = _Product.SupplementID
  association [1..*] to /DMO/I_SupplementText as _SupplementText on  $projection.supplement_id = _SupplementText.SupplementID
{
      //BookingSupplement
  key travel_id,
  key booking_id,
  key booking_supplement_id,
      supplement_id,
      @Semantics.amount.currencyCode: 'currency_code'
      price,
      @Semantics.currencyCode: true
      currency_code,
      @UI.hidden: true
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at,
      _Travel,
      _Booking,
      _Product,
      _SupplementText
}
