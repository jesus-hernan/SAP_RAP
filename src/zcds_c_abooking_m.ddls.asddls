@EndUserText.label: 'Approver Consumption Booking'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@UI: {
headerInfo: { typeName: 'Booking',
typeNamePlural: 'Bookings',
title: { type: #STANDARD, value: 'BookingID' }
}
}
@Search.searchable: true
define view entity zcds_c_abooking_m
  as projection on ZCDS_I_BOOK_M
{
          //ZCDS_I_BOOK_M
          @UI.facet: [ { id: 'Booking',
          purpose: #STANDARD,
          type: #IDENTIFICATION_REFERENCE,
          label: 'Booking',
          position: 10 }]
          @Search.defaultSearchElement: true
  key     travel_id       as TravelID,
          @UI: { lineItem: [ { position: 20, importance: #HIGH } ],
          identification: [ { position: 20 } ] }
          @Search.defaultSearchElement: true
  key     booking_id      as BookingID,
          @UI: { lineItem: [ { position: 30, importance: #HIGH } ],
          identification: [ { position: 30 } ] }
          booking_date    as BookingDate,
          @UI: { lineItem: [ { position: 40, importance: #HIGH } ],
          identification: [ { position: 40 } ],
          selectionField: [{ position: 10 }]
          }
          @Search.defaultSearchElement: true
          customer_id     as CustomerID,
          @UI: { lineItem: [ { position: 50, importance: #HIGH } ],
          identification: [ { position: 50 } ] }
          @ObjectModel.text.element: ['CarrierName']
          carrier_id      as CarrierID,
          _Carrier.Name   as CarrierName,
          @UI: { lineItem: [ { position: 60, importance: #HIGH } ],
          identification: [ { position: 60 } ] }
          connection_id   as ConnectionID,
          @UI: { lineItem: [ { position: 70, importance: #HIGH } ],
          identification: [ { position: 70 } ] }
          flight_date     as FlightDate,
          @UI: { lineItem: [ { position: 80, importance: #HIGH } ],
          identification: [ { position: 80 } ] }
          @Semantics.amount.currencyCode: 'CurrencyCode'
          flight_price    as FlightPrice,
          currency_code   as CurrencyCode,
          @UI: { lineItem: [ { position: 90, importance: #HIGH, label: 'Status' } ],
          identification: [ { position: 90, label: 'Status [N(New)| X(Canceled)| B(Booked)]' } ] }
          booking_status  as BookingStatus,
          /* Admininstrative fields */
          @UI.hidden: true
          last_changed_at as LastChangedAt,
          /* Associations */
          _Travel : redirected to parent ZCDS_C_ATRAVEL_M,
          _Customer,
          _Carrier
}
