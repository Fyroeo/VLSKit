# Getting Started with VLSKit

Set up VLSKit, read public station data, then log in and make one
authenticated call.

## Overview

This article shows the first steps to use VLSKit in an app. Follow the steps
in order. Each step builds on the step before it. See <doc:VLSKit> for the
full API list.

### Step 1: Create a VLSEnvironment

``VLSEnvironment`` holds the backend URLs and settings VLSKit needs. Use
the default `.lyon` value unless you connect to a different JCDecaux city.

```swift
import VLSKit

let environment = VLSEnvironment.lyon
```

### Step 2: Create a VLSClient

``VLSClient`` is the main entry point for the authenticated API. Give it a
``TokenStore`` to save and load login tokens. Use ``KeychainTokenStore`` in a
real app. Use ``InMemoryTokenStore`` for a quick test, because it does not
save tokens between app launches.

```swift
let tokenStore = KeychainTokenStore()
let client = VLSClient(environment: environment, tokenStore: tokenStore)
```

### Step 3: Call the public station feed with no login

You do not need a login to read station data. Create a ``GBFSClient`` and
call `stationInformation()`. This call works before the user signs in.

```swift
let gbfsClient = GBFSClient(environment: environment)
let feed = try await gbfsClient.stationInformation()
print(feed.data.stations.count)
```

### Step 4: Log in with beginLogin and completeLogin

An authenticated call needs a login. The login flow has 2 steps.

1. Call ``VLSClient/beginLogin()``. This method returns a
   ``PendingAuthorization`` value. Use this value to open a login web page
   for the user. The separate VLSKitUI library product supplies a ready-made
   `LoginView` for this web page.
2. After the user signs in, the web page redirects to a callback URL. Pass
   this URL and the pending authorization to
   ``VLSClient/completeLogin(callbackURL:pending:)``. This method finishes
   the login and saves the new tokens to your token store.

```swift
let pending = await client.beginLogin()

// Show a login web page for pending.authorizeURL.
// The web page redirects to a callback URL after the user signs in.

let tokens = try await client.completeLogin(callbackURL: callbackURL, pending: pending)
```

### Step 5: Make one authenticated call

After login, ``VLSClient`` carries a valid session. Use any service
property on the client to call an authenticated endpoint. This example
calls the authenticated station list through ``VLSClient/stations``.

```swift
let stations = try await client.stations.stations()
print(stations.count)
```

## See Also

- <doc:VLSKit>
