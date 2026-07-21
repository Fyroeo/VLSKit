import Foundation

/// Static configuration for one city's official JCDecaux VLS app.
///
/// See API_REFERENCE.md in this package for more detail on each value.
///
/// The JCDecaux "VLS" backend is multi-tenant. The same API serves every city JCDecaux
/// operates, for example Lyon and other, historical "Cyclocity" systems. The API tells
/// each city apart by its `contract` value and by a per-city Keycloak client ID. This
/// struct defaults to the Lyon configuration. You can override every field if you
/// adapt this kit to a sibling JCDecaux system.
public struct VLSEnvironment: Sendable {
    // MARK: Backend URLs

    /// Base URL of the private Cyclocity backend. This backend handles the account,
    /// bookings, trips, and subscriptions.
    public var apiBaseURL: URL
    /// Base URL of the Keycloak realm the OIDC login flow uses.
    public var iamBaseURL: URL
    /// Base URL of the public JCDecaux Open Data API. JCDecaux documents this API
    /// officially, and it serves the station list and parks data.
    ///
    /// You need your own free API key from https://developer.jcdecaux.com to use this
    /// API. Do not hardcode or share another person's key.
    public var openDataBaseURL: URL

    // MARK: Contract and Environment

    /// Contract ID. VLSKit sends this value as the `{contract}` path segment on almost
    /// every endpoint.
    public var contract: String
    /// Cyclocity backend environment segment, for example `"PRD"`. Use uppercase letters.
    public var backendEnvironment: String

    // MARK: OIDC Login

    /// Public OAuth client ID that this city's Android app registers with Keycloak.
    ///
    /// This is a public client. No client secret ships inside the APK. See the README
    /// section "Authentication" for why this matters, and for what this client ID does
    /// and does not let you do.
    public var oidcClientID: String
    /// OAuth scope string to request during the OIDC login flow.
    public var oidcScope: String
    /// URL that Keycloak redirects to after login.
    ///
    /// JCDecaux owns this domain. A third-party app cannot register this domain as a
    /// Universal Link target. VLSKit intercepts the redirect inside a `WKWebView` instead
    /// of using OS-level callback routing. See `VLSKitUI.LoginWebViewController`.
    ///
    /// This URL must include the `/openid_connect_login` path. The bare host is not
    /// enough. The Keycloak client `vls-android-lyon` has this full path registered as a
    /// valid redirect. Keycloak rejects the bare host alone.
    public var oidcRedirectURI: URL

    // MARK: Anonymous Web Client

    /// Half of the anonymous "web client" credential pair. This package ships no default
    /// value for this field, on purpose. Supply your own value if you use
    /// `AnonymousSession` or `BikeDetailClient`.
    ///
    /// The client sends this pair to `POST /auth/environments/{env}/client_tokens` to get
    /// a Bearer token with no real user login. See `AnonymousSession` and
    /// API_REFERENCE.md in this package, section "Per-bike detail", for more detail and
    /// the terms-of-service considerations around its use.
    public var webClientCode: String
    /// Other half of the anonymous "web client" credential pair. This package ships no
    /// default value for this field either. See the doc comment on `webClientCode` for
    /// what this pair does and where to find your own value.
    public var webClientKey: String

    // MARK: Initialization

    /// Creates an environment configuration.
    /// - Parameters:
    ///   - apiBaseURL: Base URL of the private Cyclocity backend. Default is the Lyon
    ///     production URL.
    ///   - iamBaseURL: Base URL of the Keycloak realm. Default is the Lyon production
    ///     realm.
    ///   - openDataBaseURL: Base URL of the public JCDecaux Open Data API. Default is
    ///     `https://api.jcdecaux.com/`.
    ///   - contract: Contract ID. Default is `"lyon"`.
    ///   - backendEnvironment: Cyclocity backend environment segment. Default is `"PRD"`.
    ///   - oidcClientID: Public OAuth client ID for Keycloak. Default is
    ///     `"vls-android-lyon"`.
    ///   - oidcScope: OAuth scope string for the OIDC login flow. Default is
    ///     `"openid email"`.
    ///   - oidcRedirectURI: URL that Keycloak redirects to after login. Default is the
    ///     Lyon redirect URL.
    ///   - webClientCode: Half of the anonymous web-client credential pair. Default is an
    ///     empty string. This library ships no working value; see the property's doc
    ///     comment.
    ///   - webClientKey: Other half of the anonymous web-client credential pair. Default
    ///     is an empty string, for the same reason.
    public init(
        apiBaseURL: URL = URL(string: "https://api.cyclocity.fr/")!,
        iamBaseURL: URL = URL(string: "https://iam.cyclocity.fr/realms/vls-default/protocol/openid-connect")!,
        openDataBaseURL: URL = URL(string: "https://api.jcdecaux.com/")!,
        contract: String = "lyon",
        backendEnvironment: String = "PRD",
        oidcClientID: String = "vls-android-lyon",
        oidcScope: String = "openid email",
        oidcRedirectURI: URL = URL(string: "https://velov.grandlyon.com/openid_connect_login")!,
        webClientCode: String = "",
        webClientKey: String = ""
    ) {
        self.apiBaseURL = apiBaseURL
        self.iamBaseURL = iamBaseURL
        self.openDataBaseURL = openDataBaseURL
        self.contract = contract
        self.backendEnvironment = backendEnvironment
        self.oidcClientID = oidcClientID
        self.oidcScope = oidcScope
        self.oidcRedirectURI = oidcRedirectURI
        self.webClientCode = webClientCode
        self.webClientKey = webClientKey
    }

    // MARK: Presets

    /// The default configuration for Lyon.
    public static let lyon = VLSEnvironment()
}
