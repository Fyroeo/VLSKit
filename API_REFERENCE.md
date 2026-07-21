# JCDecaux VLS API Reference

This document describes the API of the official app for a JCDecaux VLS (Vélos en Libre
Service) bike-share system.

Each city runs its own instance of the same client, with its own contract name (for
example `lyon` or `paris`) and its own app branding. This document covers the shared
JCDecaux backend surface. Only the `contract` value (`lyon`) and a few example defaults
below are specific to one example city.

> ⚠️ **Scope note**: This document describes what the client calls. It does not
> grant any right to call the API. Read [Legal / ToS notes](#legal--tos-notes) at
> the end of this document before you build anything that talks to the private API.

This file is part of the VLSKit package. It contains a Swift implementation of this
whole API surface. Use `OpenDataClient` and `GBFSClient` for the public, no-login
path. Use `VLSClient` for the full authenticated path: login, bookings, unlock,
and payment. See `README.md` in this package for more information.

## Contents
- [Backend domains](#backend-domains)
- [Authentication flow](#authentication-flow)
- [Media-type versioning](#media-type-versioning)
- [Public / open-data APIs](#public--open-data-apis-safe-to-use-directly)
- [Private Cyclocity API (`api.cyclocity.fr`)](#private-cyclocity-api-apicyclocityfr)
- [Per-bike detail](#per-bike-detail)
- [Cargoroo / TOMP integration](#cargoroo--tomp-integration-cargo-bikes)
- [Third-party SDKs bundled in the app](#third-party-sdks-bundled-in-the-app-not-jcdecaux-api)
- [Legal / ToS notes](#legal--tos-notes)

---

## Backend domains

This list comes from the official app's own configuration.

| Purpose | Base URL | Auth |
|---|---|---|
| Main Cyclocity backend (account/booking/trip/subscription/…) | `https://api.cyclocity.fr/` | Bearer token (Cyclocity access token) |
| Login identity provider (Keycloak) | `https://iam.cyclocity.fr/realms/vls-default/protocol/openid-connect` | OIDC / Authorization Code + PKCE |
| Public JCDecaux Open Data API (station list, GBFS-adjacent) | `https://api.jcdecaux.com/` | `apiKey` query param (free, self-service key from developer.jcdecaux.com) |
| Cargoroo cargo-bike partner (TOMP-API) | `https://api.cargoroo.eu/` | OAuth2 client_credentials |
| Analytics (Matomo) | `https://matomo-vls.jcdecaux.com/matomo/matomo.php` | n/a |
| In-app support chat | `https://jcdecauxvls.my.salesforce-scrt.com` | Salesforce Messaging-in-App SDK, unrelated to this API |

The app does not use `PUT`, `HEAD`, or `OPTIONS` anywhere.

---

## Authentication flow

1. **Login (Keycloak / OIDC, Authorization Code + PKCE)**
   - `client_id = vls-android-lyon` for the Lyon example city. This is a public
     client, with no secret. Each other city has its own client ID.
   - `scope = openid email`
   - Realm: `vls-default`, at the `iam_url` shown above. This realm gives the
     standard Keycloak endpoints (`/auth`, `/token`, `/logout`) under that base URL.
   - `redirect_uri` in production is `https://velov.grandlyon.com/openid_connect_login`
     for the Lyon example. The app builds this value from a base URL in its own
     configuration. It adds a path suffix: `openid_connect_login` for sign-in,
     `openid_connect_logout` for the end-session request, and `openid_connect_email`
     for the change-email flow.

     The bare-host URI alone does not work. This call:
     ```
     GET .../protocol/openid-connect/auth?...&redirect_uri=https%3A%2F%2Fvelov.grandlyon.com%2F
     ```
     returns `400`, with body `Paramètre invalide : redirect_uri`. Appending
     `openid_connect_login` returns a real `200` login form. It can instead return a
     `302` back to the same redirect URI if `code_challenge` is malformed. Keycloak
     checks `redirect_uri` before it checks any other parameter. This order explains
     why people can easily misread the bare-host failure as a PKCE or client-ID
     problem instead of a path problem.

     The app registers as the App Link handler for the host only (matched
     independent of path). It intercepts the redirect instead of letting the
     redirect load in a real browser.
   - Token response (standard OIDC): `IamToken { access_token, refresh_token, id_token }`
   - The ID token has no `email` claim. Decoding a real ID token payload gives
     these keys: `acr`, `at_hash`, `aud`, `auth_time`,
     `azp`, `email_verified`, `exp`, `iat`, `iss`, `jti`, `locale`,
     `preferred_username`, `sid`, `sub`, `typ`. There is no `email` key, even though
     the app requests `scope=openid email`. This realm sets the username to the
     email address. So both `sub` and `preferred_username` hold the email address
     directly, for example `sub: "jane@example.com"`. Read `sub`, not a field
     literally named `email`.

2. **A logged-in session authorizes every private-API call with 2 different tokens,
   under 2 different headers**: `Identity` (the Keycloak access token) and
   `Authorization: Taknv1 <token>` (the anonymous device token). The anonymous
   device token is the same token that `AnonymousSession` and `BikeDetailClient`
   use. This is the real mechanism:
   ```
   GET /contracts/lyon/accounts/{email}/id
   Identity: <keycloak access_token, verbatim JWT, no "Bearer " prefix>
   Authorization: Taknv1 <anonymous device access_token, from client_tokens/access_tokens>
   → 200 <account UUID>
   ```
   A real browser session sends only the `Identity` header on every post-login
   call, with no `Authorization` header. This one header is enough for reads:
   account lookup, account details, and stations/shops/sponsoring all work with
   `Identity` alone. The browser is not a native app. It probably gets its own
   basic-access authorization through Origin/CORS instead of a device token.

   A write call needs more than the `Identity` header. `POST
   .../subscriptions/{id}/trips` (`releaseBike`, that is, unlocking a bike) returned:
   ```
   401 {"code":"accounts.exception.unauthorized.access","message":"Need authorization to access this resource"}
   ```
   with only `Identity` sent. The official app sends both headers unconditionally,
   for reads and writes alike. The `Identity` header carries the Keycloak token.
   The `Authorization` header
   separately carries `Taknv1 <token>`. This second token comes from the anonymous
   device-token flow. The app caches this token locally, and refreshes it through
   the same `client_tokens`/`access_tokens` calls that `AnonymousSession`
   implements, not through Keycloak.

   Reusing the Keycloak JWT for both headers returns `403 Invalid Takn` on every
   call, not only on writes. The 2 headers need 2 different tokens, not the same
   token twice. Sending the correct anonymous device token under `Authorization`
   fixes the write call. Keycloak-side
   refresh is a standard `grant_type=refresh_token` call to `/token`. The anonymous
   device token refreshes through `/auth/access_tokens`, described in step 3 below.
   The 2 tokens are independent. Each token refreshes on its own schedule.

   These approaches do not work. This document keeps a record of them here, so
   nobody tries them again:
   - `POST /auth/access_tokens` with `{"refreshToken": "<keycloak refresh_token>"}`
     returns `401
     {"code":"auth.error.token.badRefreshToken","message":"Unknown refresh token"}`.
     Cyclocity's own refresh-token store only recognizes tokens that it issued
     through the anonymous `client_tokens` flow (step 3). It never recognizes
     Keycloak tokens.
   - The Keycloak access token, or the ID token, sent as `Authorization: Bearer
     <token>` or `Authorization: Taknv1 <token>` alone, with no `Identity` header,
     returns `403 {"message": "Invalid Tákn"}`.
   - The Keycloak access token reused under both `Identity` and `Authorization:
     Taknv1` returns `403 {"message": "Invalid Takn"}` on every call.
     `Authorization: Taknv1` specifically needs the anonymous device token, not a
     second copy of the Keycloak token.

3. **Device/anonymous client token.** Use this token only for calls that do not need
   a real user, for example per-bike detail in `BikeDetailClient`. A real account
   lookup with only this token gets a bare, non-JSON `403 Forbidden`. See
   `AnonymousSession`'s documentation comment.
   ```
   POST https://api.cyclocity.fr/auth/environments/{environment}/client_tokens
   Body: { "code": "...", "key": "..." }
   → { "refreshToken": "...", "accessToken": "..." }
   ```
   Once you have a `refreshToken` from this call, refresh it cheaply:
   ```
   POST https://api.cyclocity.fr/auth/access_tokens
   Body: { "refreshToken": "<refreshToken from above>" }
   → { "accessToken": "<new bearer token>" }
   ```
   Send this `accessToken` as `Authorization: Bearer <token>`. The official app
   instead sends it as `Taknv1 <token>`. A plain `Bearer` prefix also works
   against the live API. In production, `environment = prd`.

---

## Media-type versioning

Many endpoints fix a specific API version through the `Accept` or `Content-Type`
header, instead of through a `/v2/` path segment. For example:

```
Accept: application/vnd.account.v4+json
Accept: application/vnd.station.v4+json
Accept: application/vnd.subscription.v6+json
Accept: application/vnd.trip.v5+json
Accept: application/vnd.bikes.v3+json
Accept: application/vnd.offer.v2+json
Accept: application/vnd.cgau.v2+json
Accept: application/vnd.payment.v3+json
Accept: application/vnd.rewards.v5+json
Accept: application/vnd.parkings.v2+json
Accept: application/vnd.balance.v1+json / vnd.sale.v1+json / vnd.transaction.v1+json
Accept: application/vnd.stats.v1+json
Accept: application/vnd.message.v2+json
Accept: application/vnd.document.v3+json
Accept: application/vnd.defect-type.v1+json
```
A community client must send these headers explicitly. Without them, the server can
behave differently, or it can reject the call.

---

## Public / open-data APIs (safe to use directly)

These endpoints need your own free API key. Register at
https://developer.jcdecaux.com/. Do not use a key you find elsewhere. No hardcoded
key exists in the app, so this path likely already needs a self-service key in
production.

```
GET https://api.jcdecaux.com/vls/v3/stations?contract={contract}&apiKey={key}
GET https://api.jcdecaux.com/vls/v3/stations/{id}?contract={contract}&apiKey={key}
GET https://api.jcdecaux.com/parking/v1/contracts/{contract}/parks?apiKey={key}
```
For Lyon, `contract` is `lyon`. This is JCDecaux's long-standing public Open Data API.
JCDecaux already documents it officially. It is the right foundation for a read-only
community client: live station name, location, and bike and stand counts.

**GBFS** (General Bikeshare Feed Specification) is a standard, open feed with no
authentication. The private host also serves it, per contract, with no session
required:
```
GET https://api.cyclocity.fr/contracts/{contract}/gbfs/v3/station_information.json
GET https://api.cyclocity.fr/contracts/{contract}/gbfs/v3/station_status.json
```
Test whether these calls need zero authentication in production. The GBFS spec
requires public feeds. This feed is probably the best data source for a live map.
It is more standard and more detailed than the v3 open-data endpoint.

---

## Private Cyclocity API (`api.cyclocity.fr`)

All paths below are relative to `https://api.cyclocity.fr/`. `{contract}` = `lyon`.
Every call here needs the Bearer `accessToken` from the [auth flow](#authentication-flow),
except where a note says otherwise.

### Contract
- `GET /contracts/{contract}` — contract/system metadata

### Account
- `GET  /contracts/{contract}/accounts/{accountId}`
- `PATCH /contracts/{contract}/accounts/{accountId}` — body `PatchAccount`
- `PATCH /contracts/{contract}/accounts/{accountId}` — body `CompleteAccount` (same path, a different payload, for profile completion)
- `GET  /contracts/{contract}/accounts/{email}/id` — resolve account UUID from email
- `GET  /contracts/{contract}/accounts/{accountId}/payment`
- `GET  /contracts/{contract}/accounts/{accountId}/alerts`
- `GET  /contracts/{contract}/accounts/{accountId}/cgau` — accepted terms/conditions
- `GET  /contracts/{contract}/accounts/{accountId}/offerGroups/{group}/offers`
- `GET  /contracts/{contract}/accounts/{accountId}/offers`

### Auth — see [Authentication flow](#authentication-flow)
- `POST /auth/access_tokens`
- `POST /auth/environments/{environment}/client_tokens`

### Bikes
- `GET /contracts/{contract}/bikes?number={bikeNumber}` — lookup a specific bike
- `GET /contracts/{contract}/bikes?stationNumber={stationNumber}` — bikes at a station.
  **This response includes full per-bike detail**: type, status, battery percentage,
  ratings, and firmware versions. See [Per-bike detail](#per-bike-detail) for the
  response shape and how to call this endpoint without a real user login.
- `POST /contracts/{contract}/accounts/{accountId}/trips/{tripId}/rate` — body `Rate`

### Bookings
- `GET  /contracts/{contract}/accounts/{accountId}/bookings`
- `POST /contracts/{contract}/accounts/{accountId}/bookings` — body `CreateBooking`

### Campaigns
- `GET /contracts/{contract}/campaigns/{id}`

### Contents / CMS
- `GET /contracts/{contract}/contents?contentType={type}`

### Defect types
- `GET /contracts/{contract}/defect-types?domain={domain}&category={category}&active={bool}`

### Devices / push
- `POST   /contracts/{contract}/accounts/{accountId}/devices` — body `Device` (register push token)
- `DELETE /contracts/{contract}/accounts/{accountId}/devices` — body `Device` (a DELETE request with a JSON body)

### Documents
- `GET    /contracts/{contract}/assets/{documentId}`
- `DELETE /contracts/{contract}/accounts/{accountId}/documents` — body `DeleteDocuments`
- `POST   /contracts/{contract}/accounts/{accountId}/documents` — multipart upload

### Email / complaints
- `POST /contracts/{contract}/accounts/{accountId}/mail` — a multipart form. Fields:
  complaint type, message, subscriptionId, tripId, transactionId, amount, date,
  status, parking id/number/name, and file attachments. This is the in-app
  "contact us" form.

### Events
- `GET /contracts/{contract}/events/{eventId}`
- `GET /contracts/{contract}/events?page={page}&size={size}` — paginated station/service events

### FAQs
- `POST /contracts/{contract}/faqs/search` — body `FaqsCriterias`

### GBFS — see [public APIs](#public--open-data-apis-safe-to-use-directly)

### Invoices / transactions / balance
- `GET /contracts/{contract}/accounts/{accountId}/transactions?showRegulationId={bool}`
- `GET /contracts/{contract}/accounts/{accountId}/transactions/{transactionId}`
- `GET /contracts/{contract}/accounts/{accountId}/transactions/{transactionId}/bill` — binary (PDF), streamed
- `GET /contracts/{contract}/accounts/{accountId}/balance`
- `GET /contracts/{contract}/accounts/{accountId}/sales?infoType=&natures=&saleDateAfter=&status=&direction=`

### News
- `GET /contracts/{contract}/news/feed/{platform}` — RSS/XML

### Offers, badges, options, CGAU, packages, supplements — largest group
- `GET /contracts/{contract}/offers/{offerId}`
- `GET /contracts/{contract}/offers`
- `GET /contracts/{contract}/accounts/{accountId}/offers` (offer ids the account is eligible for)
- `GET /contracts/{contract}/cgau/{type}/versions/{version}/file`
- `POST /contracts/{contract}/offers/{offerId}/packages` — body `PackageOptions` (subscribe or purchase)
- `GET /contracts/{contract}/bikemodels?isValid={bool}`
- `GET /contracts/{contract}/badges/{badgeId}/logo`
- `GET /contracts/{contract}/offers/{offerId}/supplements/{supplementId}/items?isValid={bool}`
- `GET /contracts/{contract}/cgau/{type}/valid`
- `GET /contracts/{contract}/offers/{offerId}/supplements?isValid={bool}`
- `GET /contracts/{contract}/cgau/{type}/valid/file`
- `GET /contracts/{contract}/offerGroups?platform={platform}`
- `GET /contracts/{contract}/items/{itemId}/logo`
- `GET /contracts/{contract}/cgau` — list
- `GET /contracts/{contract}/offerGroups/{group}/offers`
- `GET /contracts/{contract}/accounts/{accountId}/subscriptions/{subscriptionId}/renewaloffers?platform={platform}`
- `GET /contracts/{contract}/options?offerId=&optionType=&isValid=`
- `GET /contracts/{contract}/proofs/{proofId}/content`
- `POST /contracts/{contract}/offers/{offerId}/badges/{badgeId}/packages` — body `PackageOptions`
- `GET /contracts/{contract}/badges/{badgeId}`
- `POST /contracts/{contract}/offers/{offerId}/supplements/packages` — body `OfferSupplements`
- `POST /contracts/{contract}/offers/{offerId}/supplements/badges/{badgeId}/packages` — body `OfferSupplements`

### Open Data proxy — see [public APIs](#public--open-data-apis-safe-to-use-directly)
(the app calls `api.jcdecaux.com` directly for this path, not `api.cyclocity.fr`)

### Processes
- `POST /contracts/{contract}/accounts/{accountId}/processes` — body `Process`, query
  `returns=` (varargs). This starts a generic async workflow or state machine, for
  example account creation steps or KYC.

### Reports
- `POST /contracts/{contract}/accounts/{accountIdentifier}/subscriptions/{subscriptionId}/periods/{periodId}/reports`

### Parkings
- `GET  /contracts/{contract}/parkings`
- `GET  /contracts/{contract}/parkings?number={n}`
- `POST /contracts/{contractName}/accounts/{accountId}/parkings/{parkId}/open` — opens a parking gate remotely

### Pay / checkout
- `POST /contracts/{contract}/accounts/{accountId}/pay/checkout` — body `GetCheckoutInfosBody`

### Rewards
- `GET   /contracts/{contract}/accounts/{accountId}/rewards`
- `POST  /contracts/{contract}/accounts/{accountId}/rewards/consume/promocode`
- `GET   /contracts/{contract}/rewards/configurations`
- `PATCH /contracts/{contract}/accounts/{accountId}/rewards` — body `UpdateReward`

### Shops
- `GET /contracts/{contract}/shops`

### Sponsoring / referral
- `GET /contracts/{contract}/sponsoring?platform=&type=&active={bool}`

### Station bookmarks
- `DELETE /contracts/{contract}/accounts/{accountId}/stationbookmarks/{stationId}/`
- `POST   /contracts/{contract}/accounts/{accountId}/stationbookmarks/{stationId}/`

### Stations
- `GET /contracts/{contract}/stations/{station_number}`
- `GET /contracts/{contract}/stations?bonus={bool}` — the full station list, in real
  time. The `bonus` query parameter filters "bonus" or relay stations. Use this
  endpoint, or the GBFS feed above, for a live station map.

### Statistics
- `GET /contracts/{contract}/accounts/{accountId}/stats?startDate=&endDate=&period=&statsType=`

### Subscriptions
- `GET   /contracts/{contract}/accounts/{accountId}/subscriptions/{id}/statuses`
- `GET   /contracts/{contract}/accounts/{accountId}/subscriptions/{id}?periods=`
- `GET   /contracts/{contract}/accounts/{accountId}/subscriptions?periods=&typeList=&isLocked=`
- `POST   /contracts/{contract}/accounts/{accountId}/subscriptions/{subscriptionId}/via` — body `CreateVia(stationId)`. This is the **"ask for 15 more minutes"** feature. JCDecaux calls this feature "via" internally. It grants 15 extra free minutes when the rider's destination station has no free docks. The server validates the request and rejects it if the target station is not full.
- `PATCH  /contracts/{contract}/accounts/{accountId}/subscriptions/{id}` — body `SubscriptionAutoRenewal`
- `GET   /contracts/{contract}/accounts/{accountId}/periods?periodIds=`

### Trips
- `GET  /contracts/{contract}/accounts/{accountId}/trips?status=`
- `GET  /contracts/{contract}/accounts/{accountId}/trips/{tripId}/route` — `GeoJson`
- `POST /contracts/{contract}/accounts/{accountId}/trips/{tripId}/route` — body `List<Point>` (client-side GPS trace upload)
- `POST /contracts/{contract}/accounts/{accountId}/subscriptions/{subscriptionId}/trips` — body `ReleaseBikeRequest` (**this is "unlock a bike"**)
- `GET  /contracts/{contract}/accounts/{accountId}/trips/ongoing`

---

## Per-bike detail

`GET /contracts/{contract}/bikes?stationNumber={n}` (documented above under
[Bikes](#bikes)) returns much richer data than a station-list call alone. Sample
response for one bike:

```json
{
  "id": "e5d182ca-4e3f-4d4d-94e3-6c64f24af36e",
  "number": 52009,
  "contractName": "lyon",
  "type": "ELECTRICAL",
  "frameId": "SW2401523",
  "stationNumber": 3058,
  "standNumber": 5,
  "status": "AVAILABLE",
  "statusLabel": "Accroché",
  "hasBattery": true,
  "battery": { "percentage": 83, "type": "INTERNAL", "level": 4 },
  "hasLock": false,
  "rating": { "value": 99.48, "count": 235, "lastRatingDateTime": "2026-07-10T20:56:40.044123" },
  "checked": false,
  "createdAt": "2024-12-26T08:15:38.991457",
  "updatedAt": "2026-07-10T21:47:28.081586828",
  "lastDataFrameDate": "2026-07-10T21:40:03",
  "bikeTopSwVersion": "002.023",
  "bikeTopHwVersion": "E",
  "motorControllerSwVersion": "028.002",
  "motorControllerHwVersion": "M410 2",
  "bmsSwVersion": "000.038",
  "zedSwVersion": "004.004"
}
```

Mechanical bikes omit `battery`, `motorController*`, and `bms*` entirely. Instead,
they carry a `bikeBatteryMv` field. This field holds the voltage of the bike's own
low-power lock/tracker battery. This battery is distinct from an e-bike's propulsion
battery. Timestamps here have **no timezone designator**. They also have
arbitrary-precision fractional seconds. `VLSKit` handles this format; see
`Core/JSONCoding.swift`.

### This endpoint needs a Bearer token, but not a real user login

Calling this endpoint with no `Authorization` header returns:
```json
{ "statusCode": "403", "code": "role.not.allowed", "message": "Access forbidden: role not allowed" }
```
So the endpoint requires a Bearer token. The public website itself does not make
visitors log in to see this data. The website calls `POST
/auth/environments/PRD/client_tokens` with a fixed, non-user-specific credential
pair, in this shape:

```json
{ "code": "<web client code>", "key": "<web client key>" }
```

The public website ships a real value for this pair in plain text to every
visitor. This document does not reproduce that value. `VLSEnvironment`'s
`webClientCode`/`webClientKey` fields have no default value for the same reason;
supply your own if you use this feature. See the doc comment on those fields.

That call returns an anonymous `accessToken`. The website then sends this token as
`Authorization: Bearer …` on the `bikes` call. This is the exact mechanism behind
the "Station(1) / bike 52009 / ★★★ 235 reviews" detail panel. The site shows this
panel to any logged-out visitor who clicks a station on the map.
`VLSKit.AnonymousSession` implements this same flow. `VLSKit.BikeDetailClient` (in
`PublicAPI/`) wraps this flow for per-bike lookups.

Note that `env` is `"PRD"` (uppercase) here.

**ToS framing**: this situation differs from the public GBFS/Open Data APIs
(JCDecaux-documented, meant for third parties) and from reading the private API's
`403` response (no credential used at all). Here, a client uses a specific
credential that JCDecaux embedded for its own web client, extracted from its own
public website. This credential happens to grant exactly the same "anonymous
visitor" capability that the public website itself exposes to everyone. This flow
does not involve any real user's credentials or personal data. Even so, this
remains a case of a third party using a credential that JCDecaux did not publish
for that purpose. Treat it accordingly. It is fine for a personal or hobby client
that mirrors what the website already shows anyone. Do not scale it up, for example
by sending far more calls than a browsing human would generate. JCDecaux could
rotate or rate-limit this specific key at any time, because it is not a contract
with third-party integrators.

---

## Cargoroo / TOMP integration (cargo bikes)

This system offers Cargoroo cargo-bikes as a bolt-on feature in some cities. This
feature talks to `https://api.cargoroo.eu/` using the open **TOMP-API** standard
(Transport Operator MaaS Provider API, v1.3.0 in the version tested). See the spec
at https://github.com/TOMP-WG/TOMP-API.

```
POST auth/token/          (form-urlencoded: grant_type=client_credentials, client_id, client_secret)
GET  operator/available-assets?regionId=&stationId=
```
The client credentials for this integration are empty in the public app build. The
build process likely injects the real values at build or release time. These values
are not present in the public app, so this part of the flow is not reproducible
without them.

---

## Third-party SDKs bundled in the app (not JCDecaux API)

The official app bundles these SDKs. They are **not** part of this system's own
API. Skip these when you build a community client:
- `com.salesforce.android.smi.*`: Salesforce "Messaging for In-App/Web" (the support
  chat widget). It talks to `jcdecauxvls.my.salesforce-scrt.com`
  (`/iamessage/v1/...`, `/miaw/auth/accesstoken`). This is a standard Salesforce
  SDK, unrelated to bike-share data.
- The Wemap routing/itinerary SDK: `POST compute-itineraries`. The app uses this
  SDK for in-app walking and cycling directions.
- Google Places/Maps, Firebase (Crashlytics, Remote Config, Cloud Messaging), and
  Didomi (consent management): standard third-party infrastructure, not
  JCDecaux-specific.

---

## Legal / ToS notes

- The **public Open Data API** (`api.jcdecaux.com`) and the **GBFS feed** are the
  intended, documented, low-risk foundation for a community client. They give
  real-time station and bike availability with no account needed. Get your own key
  at developer.jcdecaux.com. Do not reuse another person's key.
- The **private Cyclocity API** (`api.cyclocity.fr`) is JCDecaux's internal backend
  for its own app. Nothing here suggests JCDecaux intends this API for third-party
  use. Replicating login, booking, payment, or unlock flows against it, on behalf
  of real user accounts, raises real risk. This risk covers ToS compliance,
  security (handling other people's credentials and payment data), and possibly
  contracts and law. This risk profile differs greatly from reading public station
  data. Treat the private-API section as documentation of how the official app
  works. Do not treat it as an invitation to build an unlock-a-bike client against
  production without sign-off from JCDecaux.
- This document does not extract or reproduce any secret, API key, or credential
  beyond what the official app or its public website already ship to every
  end-user.

---

## Notable findings

A few other facts are worth flagging on their own:

- **Login OIDC client**: `client_id = vls-android-lyon` for the Lyon example
  (public, no secret), scope `openid email`, realm `vls-default`.
- **3 separate `Platform` enums exist, not 1 shared type.** This is a naming collision,
  not a shared type. The general enum is `WEB, MOBILE, TERMINAL, PRIVATE`, used by
  offers, sponsoring filters, and sales. A second enum is push-notification-only:
  `ANDROID, IOS`. `Sponsoring` has its own nested enum: `WEB, MOBILE, TERMINAL` (no
  `PRIVATE`).
- **`Process` (`POST .../processes`) has 21 known process types**:
  `ACCOUNT_UNSUBSCRIBE`, `REGISTER_PAYMENT_METHOD`, `SHORT_TERM_SUBSCRIPTION_V2`,
  `LONG_TERM_SUBSCRIPTION_V2`, `ADP_SUBSCRIPTION`, `MANUAL_RESUBSCRIPTION_V2`,
  `CHANGE_BADGE`, `STATION_SUBSCRIPTION`, `CREATE_BIKE_DEFECT`,
  `INVOICE_TRANSACTION`, `BATTERY_SUBSCRIPTION`, `CREATE_CAB`,
  `PARKING_SUBSCRIPTION`, `VLD_SUBSCRIPTION`, `PARKING_RESUBSCRIPTION`,
  `CREATE_SALESFORCE_CASE`, `SELFCARE_RETURNED_BIKE`, `REDEFINE_ACCOUNT_EMAIL`,
  `SELFCARE_TRIP_AMOUNT`, `SELFCARE_RESCIND_SUBSCRIPTION`,
  `CREATE_SPONSORSHIP_PROMOCODE`. This list is effectively the full menu of actions
  a user can take on their own account. Several of these actions, for example
  defect reports, unsubscribe, and badge changes, have no other exposed REST verb.
- **The private API's Open Data-mirror endpoint returns a richer, nested shape**
  than JCDecaux's classic public-docs schema for `api.jcdecaux.com`. It returns
  per-tier `totalStands`, `mainStands`, and `overflowStands` objects, rather than
  flat `bike_stands` and `available_bikes` integers. Either the public API has
  evolved past its classic documentation, or this call hits a newer or different
  endpoint under the same path. Run a live check before you depend on this shape.
- **One endpoint returns XML, not JSON**: `GET .../news/feed/{platform}` is a
  standard RSS 2.0 feed. Every other endpoint in this API returns JSON.
- Two unrelated `Document` model shapes share the same name. One is an
  account/offer-side *reference* (`String id`, no bytes: badge logos, CGAU files,
  proofs). The other is this API's own upload *payload* model (`UUID id` plus
  actual `byte[] content`). Do not conflate them.
- The server's own JSON has at least one typo. The wire format keeps this typo:
  `Sale.saleAdditionnalInfo` (double n).

## GBFS wire-format notes

The GBFS feed's actual wire format differs from what a strict model would expect,
in several places:

- `station_id` is a **string** on the wire (`"10001"`), not a number. This matches
  the GBFS v2.3+/v3 spec.
- `is_bonus` is **sometimes absent** on `station_information`, even though a
  strict model might treat this field as always present.
- `rental_methods` values and `vehicle_type_id` are **lowercase**
  (`creditcard`, `mechanical`, `electrical`), not uppercase.
- The server sends `last_reported` as an **ISO-8601 string**, not as the
  Unix-epoch-seconds number that the GBFS spec implies instead.

`Sources/VLSKit/Models/GBFS.swift` in this package now decodes all of these fields
leniently. It accepts either shape, and it falls back gracefully on unrecognized
enum values. This handling is a concrete illustration of why this API's real
behavior can diverge from what a spec or a naive model expects. Verify anything you
assume about this API against a live call before you trust it.
