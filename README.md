# VLSKit

VLSKit is an unofficial Swift client for a JCDecaux VLS bike-share system. VLSKit talks
to 2 parts of this backend. The first part is the public, documented open-data feeds. The
second part is the private account API that the official Android and iOS apps use. This
document is the usage-focused developer guide. See [API_REFERENCE.md](API_REFERENCE.md)
for the full API surface, and for the Legal and ToS notes.

> **Read the Legal and ToS notes in API_REFERENCE.md before you ship a product built on
> this kit.** The public station-data path (`OpenDataClient` and `GBFSClient`) is safe and
> documented. JCDecaux intends third parties to use it. The private, authenticated path
> (`VLSClient`, login, bookings, bike unlock, payment) replicates JCDecaux's own internal
> app backend. JCDecaux has not clearly sanctioned this path for third-party use. Use it to
> automate your own account. Do not use it to build a public product without JCDecaux's
> sign-off.

## Requirements

VLSKit needs the following:

- Swift tools version 5.9 or later.
- iOS 15 or later, or macOS 12 or later.
- No external dependencies. VLSKit uses only Foundation and platform SDKs.

## Installation

VLSKit uses Swift Package Manager. Add the package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "<repo-url>", from: "1.0.0")
]
```

Then add `VLSKit` as a dependency of your target. Add `VLSKitUI` too if your app needs the
built-in login screen:

```swift
.target(
    name: "YourApp",
    dependencies: ["VLSKit", "VLSKitUI"]
)
```

`VLSKit` has no UI dependency. It runs on any platform that supports Swift Concurrency and
Foundation, for example a command-line tool or a server. `VLSKitUI` needs `WebKit`, so it
runs on iOS and macOS only.

## Quick start

### Public station data, no login

This is the smallest working example. It reads the standard GBFS feed. GBFS stands for
General Bikeshare Feed Specification. This feed needs no API key and no login.

```swift
import VLSKit

let gbfs = GBFSClient()
let status = try await gbfs.stationStatus()
print(status.data.stations.count)
```

### Login, then one authenticated call

This example logs in a user, then reads that user's account ID.

```swift
import VLSKit
import VLSKitUI // for LoginView

let vls = VLSClient(tokenStore: KeychainTokenStore())

// Step 1: start the login flow.
let pending = await vls.beginLogin()

// Step 2: present LoginView(pending:redirectURI:onRedirect:) in a sheet.
// LoginView loads the Keycloak login page in a WKWebView. It calls onRedirect
// with the callback URL after the user logs in. See "VLSKitUI" below.

// Step 3: finish the login flow with the callback URL from onRedirect.
try await vls.completeLogin(callbackURL: callbackURL, pending: pending)

// Step 4: make an authenticated call.
let accountId = try await vls.account.accountId(email: "me@example.com")
```

## Architecture

VLSKit organizes its source into 5 areas:

- **Core**: `HTTPClient`, `Endpoint`, JSON coding helpers, and `VLSError`. This is the
  networking layer every other area uses.
- **Auth**: `AuthSession` for the Keycloak login flow, `AnonymousSession` for the anonymous
  device token, and PKCE helper functions.
- **Models**: Codable types for each API domain, for example `Station`, `Bike`, and
  `Account`.
- **Services**: one thin wrapper struct per API domain, for example `StationService` and
  `TripService`. `VLSClient` creates and exposes one instance of each.
- **PublicAPI**: `GBFSClient`, `OpenDataClient`, and `BikeDetailClient`. These clients need
  no login.

### The dual-token authentication mechanism

The private Cyclocity API checks 2 separate tokens on most authenticated calls. Each
token travels in its own HTTP header.

1. The `Identity` header carries the Keycloak access token. VLSKit sends this token with no
   scheme prefix. This token is enough for read calls, for example a call that lists
   subscriptions.
2. The `Authorization: Taknv1 <token>` header carries a second, different token: the
   anonymous device token from `AnonymousSession`. Write calls need this second header in
   addition to the first. `releaseBike(accountId:subscriptionId:request:)`, which unlocks a
   bike, is one example of a write call.

Do not confuse the 2 tokens. The Keycloak access token and the anonymous device token are
not interchangeable. `HTTPClient` attaches both headers automatically when you use
`VLSClient`, so you do not manage this yourself.

## Usage examples

### Public data

`GBFSClient` reads the standard GBFS feed from the Cyclocity backend. It needs no API key.

```swift
let gbfs = GBFSClient()
let info = try await gbfs.stationInformation()
let status = try await gbfs.stationStatus()
```

`OpenDataClient` reads JCDecaux's officially documented Open Data API. Get a free API key
at [developer.jcdecaux.com](https://developer.jcdecaux.com) before you use it.

```swift
let openData = OpenDataClient(apiKey: "YOUR_OWN_JCDECAUX_KEY")
let stations = try await openData.stations()
```

`BikeDetailClient` reads per-bike detail, for example bike type, status, and battery level.
It uses an anonymous token, not a real user login. Treat calls to this client with the same
care as a person browsing the public website, because it is not a documented third-party
integration point.

```swift
let bikeDetails = BikeDetailClient()
let bikes = try await bikeDetails.bikes(atStationNumber: 3058)
for bike in bikes {
    print(bike.number, bike.type, bike.status)
}
```

### Authentication

Create one `VLSClient` instance and reuse it for the life of your app. Pass a
`TokenStore` so the client can save and load login tokens. `KeychainTokenStore` saves
tokens in the Keychain. `InMemoryTokenStore` keeps tokens in memory only, which is useful
for tests.

```swift
let vls = VLSClient(tokenStore: KeychainTokenStore())

let pending = await vls.beginLogin()
// Present LoginView, then get callbackURL from its onRedirect closure.
try await vls.completeLogin(callbackURL: callbackURL, pending: pending)

let loggedIn = await vls.isAuthenticated // true

await vls.logout()
```

`VLSClient` also accepts an `environment` parameter. Use this parameter to point the
client at a different JCDecaux city, because the same backend serves several JCDecaux
Cyclocity systems.

```swift
let paris = VLSEnvironment(contract: "paris", oidcClientID: "vls-android-paris")
let client = VLSClient(environment: paris, tokenStore: KeychainTokenStore())
```

Check the target city's own app for the correct `oidcClientID` value before you use it.

### Stations and bikes

`vls.stations` reads the real-time station list from the authenticated backend. Use
`GBFSClient` or `OpenDataClient` instead if your call does not need a login.

```swift
let station = try await vls.stations.station(number: 3058)
let allStations = try await vls.stations.stations(bonus: true)
```

`vls.bikes` looks up bikes by number or by station.

```swift
let bikesAtStation = try await vls.bikes.bikes(atStationNumber: 3058)
let bikeByNumber = try await vls.bikes.bike(number: 12345)
```

### Bookings and trips

A booking holds a bike at a stand so a user can pick it up later.

```swift
let bookings = try await vls.bookings.bookings(accountId: accountId)

let newBooking = try await vls.bookings.createBooking(
    accountId: accountId,
    booking: CreateBooking(
        stationId: stationId,
        stationNumber: 3058,
        standNumber: 3,
        subscriptionId: subscriptionId,
        bikeId: bikeId
    )
)
```

`releaseBike(accountId:subscriptionId:request:)` unlocks a bike. This is a real,
consequential action against the caller's own account. It needs the `Authorization:
Taknv1` header described above, in addition to the `Identity` header.

```swift
let response = try await vls.trips.releaseBike(
    accountId: accountId,
    subscriptionId: subscriptionId,
    request: ReleaseBikeRequest(stationNumber: 1001, standNumber: 3, bikeNumber: 42)
)
print(response.transactionState)
```

`vls.trips` also reads trip history and the GPS route for one trip.

```swift
let trips = try await vls.trips.trips(accountId: accountId)
let ongoing = try await vls.trips.ongoingTrips(accountId: accountId)
```

### Account and subscriptions

```swift
let accountId = try await vls.account.accountId(email: "me@example.com")
let account = try await vls.account.account(accountId: accountId)
```

A rider needs a subscription to unlock a bike. `vls.subscriptions.subscriptions(...)`
combines several filtered variants of the underlying endpoint into one method.

```swift
let subscriptions = try await vls.subscriptions.subscriptions(accountId: accountId)
let firstSubscription = subscriptions[0]
```

## Error handling

Every VLSKit method that can fail throws a `VLSError`. Check the case to decide how to
respond.

- `notAuthenticated`: this call needs a login. Call `beginLogin()` and
  `completeLogin(callbackURL:pending:)` first.
- `httpError(statusCode:body:)`: the server returned a status code outside the 200 to 299
  range. `body` holds the raw response, when the server sent one. Use `body` to diagnose a
  media-type mismatch or an unexpected error payload.
- `decodingFailed(underlying:body:)`: the response body did not match the expected model.
  `body` holds the raw response, so you can compare it against the model's `CodingKeys`.
- `authenticationCancelled`: the user cancelled the login flow, or the flow failed before
  it returned a code.
- `authenticationFailed(underlying:)`: the OIDC login flow failed. `underlying` holds the
  original error, when one exists.
- `noRefreshToken`: the client tried to refresh the login token, but no refresh token
  exists. The user must log in again.
- `invalidURL`: VLSKit could not build a valid URL for the request.

## VLSKitUI

`VLSKitUI` is a separate library product. It gives you a ready-made login screen, so you do
not have to build one from the Keycloak redirect flow yourself. It contains 4 types:

- `LoginView`: a SwiftUI view. It wraps `LoginWebViewController`.
- `LoginWebViewController`: a `WKWebView`-based view controller for UIKit and AppKit.
- `RedirectInterceptor`: watches page navigation for the login callback URL.
- `LoginSessionCleaner`: clears the leftover Keycloak single sign-on cookie after logout.

VLSKit uses a `WKWebView` for login, not `ASWebAuthenticationSession`. JCDecaux owns the
OIDC redirect URI. A third-party app cannot register a domain it does not own for
system-level callback routing. `RedirectInterceptor` watches every page navigation instead,
and cancels the one that matches the redirect URI.

```swift
import SwiftUI
import VLSKit
import VLSKitUI

struct LoginSheet: View {
    let pending: PendingAuthorization
    let redirectURI: URL
    let onRedirect: (URL) -> Void

    var body: some View {
        LoginView(pending: pending, redirectURI: redirectURI, onRedirect: onRedirect)
    }
}
```

Call `vls.completeLogin(callbackURL:pending:)` from your `onRedirect` closure to finish
the login flow.

## Testing

Run the test suite with:

```
swift test
```

The test suite includes model-decode tests, for example a real GBFS station payload and
the RFC 7636 PKCE test vector, plus authentication-flow unit tests.

If your machine has only the Command Line Tools installed, it may not have XCTest in that
toolchain. Point the test run at a full Xcode install instead:

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## Full API reference

See [API_REFERENCE.md](API_REFERENCE.md) for the full API surface: every endpoint path,
model field, and the login flow. API_REFERENCE.md also holds the Legal and ToS notes.
Read those notes before you ship anything built on the
private, authenticated path.
