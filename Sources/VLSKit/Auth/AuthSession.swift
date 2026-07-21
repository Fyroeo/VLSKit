import Foundation

/// Manages the Keycloak PKCE login lifecycle.
///
/// After login, this actor provides the token that authorizes every private Cyclocity
/// API call. A logged-in call carries the Keycloak access token as-is in an
/// `Identity: <token>` header. This header has no scheme prefix. This header alone is
/// enough to authorize a read call.
///
/// A write call, for example `releaseBike`, needs one more header:
/// `Authorization: Taknv1 <token>`. This header carries a different token: the anonymous
/// device token from `AnonymousSession`. It does not reuse the Keycloak token. See
/// `HTTPClient.AuthHeaderStyle.identity` for how the client attaches both headers
/// together. See API_REFERENCE.md in this package, section "Authentication flow", for
/// more detail.
///
/// `AuthSession` conforms to `BearerTokenProviding`. This lets `HTTPClient` attach this
/// actor through the `tokenProvider` slot of `AuthHeaderStyle.identity`. See
/// `VLSClient` for the setup.
public actor AuthSession: BearerTokenProviding {
    private let environment: VLSEnvironment
    private let tokenStore: TokenStore
    private let iamHTTPClient: HTTPClient

    private var tokens: VLSTokens?

    /// Creates an auth session for one VLS environment.
    /// - Parameters:
    ///   - environment: The VLS environment to sign in to.
    ///   - tokenStore: The store this session uses to save and load tokens.
    ///   - urlSession: The URL session to use for network calls. The default value is
    ///     `.shared`.
    public init(environment: VLSEnvironment, tokenStore: TokenStore, urlSession: URLSession = .shared) {
        self.environment = environment
        self.tokenStore = tokenStore
        self.iamHTTPClient = HTTPClient(baseURL: environment.iamBaseURL, session: urlSession)
        self.tokens = tokenStore.load()
    }

    /// A Boolean value that indicates whether the session has a signed-in user.
    public var isAuthenticated: Bool {
        tokens != nil
    }

    // MARK: - BearerTokenProviding

    /// Returns the current Keycloak access token for the signed-in user.
    /// - Returns: The cached Keycloak access token.
    /// - Throws: `VLSError.notAuthenticated` if no user is signed in.
    public func currentAccessToken() async throws -> String {
        guard let tokens else { throw VLSError.notAuthenticated }
        return tokens.iamAccessToken
    }

    /// Gets a new Keycloak access token with a refresh-token grant.
    /// Call this method after a call fails with a `401` status code. You can also call
    /// it on your own before the cached token becomes stale.
    /// - Returns: A new Keycloak access token.
    /// - Throws: `VLSError.notAuthenticated` if no user is signed in. This method also
    ///   throws an error if the refresh call fails.
    public func refreshedAccessToken() async throws -> String {
        guard let tokens else { throw VLSError.notAuthenticated }
        let refreshed = try await refreshKeycloakToken(refreshToken: tokens.iamRefreshToken)
        let updated = VLSTokens(
            iamAccessToken: refreshed.accessToken,
            iamRefreshToken: refreshed.refreshToken,
            iamIDToken: refreshed.idToken
        )
        self.tokens = updated
        try tokenStore.save(updated)
        return refreshed.accessToken
    }

    /// The signed-in user's email address.
    ///
    /// This property decodes the email address from the `sub` claim of the saved
    /// Keycloak ID token. The session does not verify the token signature. Keycloak
    /// issues this token directly to the app over TLS, so the app already trusts it.
    /// This property is `nil` when no user is signed in.
    ///
    /// This realm's ID token has no separate `email` claim. The `sub` claim, and also
    /// the `preferred_username` claim, hold the account's email address directly. For
    /// example, the `sub` claim can hold the value `"jane@example.com"`.
    public var currentEmail: String? {
        tokens.flatMap { Self.subject(fromIDToken: $0.iamIDToken) }
    }

    /// Starts the login flow. This is step 1 of 2.
    /// This method builds the Keycloak authorize URL and the PKCE material together.
    /// - Returns: A `PendingAuthorization` value. Pass its `authorizeURL` to
    ///   `VLSKitUI.LoginWebViewController`, or to your own web view. Keep the whole
    ///   value. Pass it to `completeLogin(callbackURL:pending:)` after the web view
    ///   gets the redirect.
    public func beginLogin() -> PendingAuthorization {
        AuthorizationRequestBuilder.build(environment: environment)
    }

    /// Finishes the login flow. This is step 2 of 2.
    /// Call this method after the login web view redirects back to
    /// `environment.oidcRedirectURI` with a `code` query parameter.
    /// - Parameters:
    ///   - callbackURL: The redirect URL the login web view received.
    ///   - pending: The `PendingAuthorization` value that `beginLogin()` returned.
    /// - Returns: The new `VLSTokens` for the signed-in user.
    /// - Throws: `VLSError.authenticationFailed` if the callback URL has no valid
    ///   code, or if its state value does not match `pending.state`. This method also
    ///   throws an error if the token exchange call fails.
    @discardableResult
    public func completeLogin(callbackURL: URL, pending: PendingAuthorization) async throws -> VLSTokens {
        guard let (code, state) = AuthorizationRequestBuilder.extractCode(from: callbackURL, redirectURI: environment.oidcRedirectURI) else {
            throw VLSError.authenticationFailed(underlying: nil)
        }
        if let state, state != pending.state {
            throw VLSError.authenticationFailed(underlying: nil)
        }

        let iamResponse = try await exchangeAuthorizationCode(code, codeVerifier: pending.codeVerifier)
        let newTokens = VLSTokens(
            iamAccessToken: iamResponse.accessToken,
            iamRefreshToken: iamResponse.refreshToken,
            iamIDToken: iamResponse.idToken
        )
        tokens = newTokens
        try tokenStore.save(newTokens)
        return newTokens
    }

    /// Ends the local session, and also ends the Keycloak SSO session on the server.
    ///
    /// This method ends the local session. It also sends a best-effort RP-initiated
    /// logout call to end the Keycloak SSO session on the server. This step stops a
    /// later login from silently reusing a leftover SSO cookie.
    ///
    /// Without this step, "log out then log back in" on the same device can look like a
    /// no-op to the user. The user sees no fresh credential prompt, because Keycloak
    /// automatically re-issues a code for the session that is still alive. This also
    /// means a fresh device registration never happens. This can show as a confusing
    /// "this account is already used on another device" message on the next real login
    /// attempt on another device.
    ///
    /// Callers on iOS and macOS must also clear the login `WKWebView` cookies for the
    /// host in `environment.iamBaseURL`. See `VLSKitUI` for this step. This step is
    /// necessary because the web view holds a separate, client-side copy of the same
    /// session cookie.
    public func logout() async {
        if let tokens {
            try? await endKeycloakSession(idToken: tokens.iamIDToken)
        }
        tokens = nil
        tokenStore.clear()
    }

    private func endKeycloakSession(idToken: String) async throws {
        let endpoint = Endpoint(
            method: .get,
            path: "logout",
            queryItems: [
                URLQueryItem(name: "client_id", value: environment.oidcClientID),
                URLQueryItem(name: "post_logout_redirect_uri", value: environment.oidcRedirectURI.absoluteString),
                URLQueryItem(name: "id_token_hint", value: idToken),
            ],
            requiresAuth: false
        )
        _ = try await iamHTTPClient.sendRaw(endpoint, allowEmptyBody: true)
    }

    // MARK: - Private

    private func exchangeAuthorizationCode(_ code: String, codeVerifier: String) async throws -> IamTokenResponse {
        let form = FormBody([
            "grant_type": "authorization_code",
            "client_id": environment.oidcClientID,
            "code": code,
            "redirect_uri": environment.oidcRedirectURI.absoluteString,
            "code_verifier": codeVerifier,
        ])
        let endpoint = Endpoint(
            method: .post,
            path: "token",
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: form.data,
            requiresAuth: false
        )
        return try await iamHTTPClient.send(endpoint)
    }

    private func refreshKeycloakToken(refreshToken: String) async throws -> IamTokenResponse {
        let form = FormBody([
            "grant_type": "refresh_token",
            "client_id": environment.oidcClientID,
            "refresh_token": refreshToken,
        ])
        let endpoint = Endpoint(
            method: .post,
            path: "token",
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: form.data,
            requiresAuth: false
        )
        return try await iamHTTPClient.send(endpoint)
    }

    /// Reads the `sub` claim out of a JWT's payload without verifying the signature.
    private static func subject(fromIDToken idToken: String) -> String? {
        let segments = idToken.split(separator: ".")
        guard segments.count >= 2 else { return nil }
        var base64 = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let data = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return payload["sub"] as? String
    }
}

/// Builds a minimal `application/x-www-form-urlencoded` body for the Keycloak `/token`
/// request. The Keycloak `/token` endpoint does not accept a JSON body.
private struct FormBody {
    let data: Data

    init(_ fields: [String: String]) {
        let encoded = fields.map { key, value in
            "\(Self.percentEncode(key))=\(Self.percentEncode(value))"
        }.joined(separator: "&")
        self.data = Data(encoded.utf8)
    }

    private static func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
