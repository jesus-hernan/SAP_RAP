@EndUserText.label: 'Approver Consumption Booking'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity zcd_c_booking_a
  as projection on ZCD_I_BOOKING_M
{
  key     travel_id       as TravelID,
  key     booking_id      as BookingID,
          booking_date    as BookingDate,
          customer_id     as CustomerID,
          @ObjectModel.text.element: ['CarrierName']
          carrier_id      as CarrierID,
          _Carrier.Name   as CarrierName,
          connection_id   as ConnectionID,
          flight_date     as FlightDate,
          @Semantics.amount.currencyCode: 'CurrencyCode'
          flight_price    as FlightPrice,
          currency_code   as CurrencyCode,
          booking_status  as BookingStatus,
          /* Admininstrative fields */
          last_changed_at as LastChangedAt,
          /* Associations */
          _Travel : redirected to parent ZCD_C_TRAVEL_A,
          _Customer,
          _Carrier
}
