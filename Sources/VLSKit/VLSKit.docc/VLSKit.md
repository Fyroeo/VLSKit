# ``VLSKit``

A Swift client for a JCDecaux VLS bike-share system.

## Overview

VLSKit talks to the JCDecaux VLS backend. This is the same backend that each
city's official app uses. VLSKit has no external dependencies. It uses only
Foundation and platform SDKs.

VLSKit gives you 3 ways to get data:

- Public feeds. These need no login. Use ``GBFSClient`` or ``OpenDataClient``
  for a station list and station status. Use ``BikeDetailClient`` for detail
  about one bike.
- An authenticated client. Use ``VLSClient`` after a user logs in. This
  client exposes one service property for each API domain, for example
  ``VLSClient/account`` and ``VLSClient/trips``.
- A login UI. The separate VLSKitUI library product supplies a `LoginView` for
  the Keycloak PKCE login flow.

The private Cyclocity API needs 2 tokens under 2 headers. An `Identity` header
carries the Keycloak access token and is enough for read calls. Write calls,
for example ``TripService/releaseBike(accountId:subscriptionId:request:)``,
also need an `Authorization: Taknv1 <token>` header. This second header
carries a different token: the anonymous device token from
``AnonymousSession``, not the Keycloak token again.

``VLSEnvironment`` holds every backend URL and setting VLSKit needs. It
defaults to the Lyon system. Every field is overridable, because JCDecaux
operates the same VLS backend for many cities.

See <doc:GettingStarted> for a short, numbered walkthrough.

## Topics

### Essentials

- <doc:GettingStarted>
- ``VLSClient``
- ``VLSEnvironment``
- ``VLSError``

### Authentication

- ``AuthSession``
- ``AnonymousSession``
- ``VLSTokens``
- ``TokenStore``
- ``InMemoryTokenStore``
- ``KeychainTokenStore``
- ``PendingAuthorization``
- ``AuthorizationRequestBuilder``

### Public Data (No Login Needed)

- ``GBFSClient``
- ``OpenDataClient``
- ``BikeDetailClient``

### Stations and Bikes

- ``StationService``
- ``BikeService``
- ``ParkingService``

### Trips and Bookings

- ``TripService``
- ``BookingService``

### Account and Subscriptions

- ``AccountService``
- ``SubscriptionService``
- ``ContractService``
- ``DeviceService``

### Payments and Rewards

- ``PayService``
- ``InvoiceService``
- ``RewardService``
- ``OfferService``
- ``SponsoringService``

### Content and Support

- ``ContentService``
- ``NewsService``
- ``FaqService``
- ``EmailService``
- ``EventService``
- ``CampaignService``
- ``ShopService``
- ``DefectTypeService``
- ``DocumentService``
- ``ProcessService``
- ``StatisticsService``

### Advanced (Core Types)

- ``HTTPClient``
- ``Endpoint``
- ``MultipartFormData``
