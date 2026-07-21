import Foundation

/// Gets and refreshes an anonymous Bearer token.
///
/// This actor calls `POST /auth/environments/{env}/client_tokens`. It uses the fixed
/// web-client credential pair from `VLSEnvironment.webClientCode` and `webClientKey`.
/// No real user login happens. This is the same mechanism that velov.grandlyon.com uses
/// to show per-bike detail to logged-out visitors. See API_REFERENCE.md in this package,
/// section "Per-bike detail", for more information.
///
/// `AuthSession` is different. It handles the full Keycloak user-login flow. It
/// authorizes account-specific calls with a different mechanism. This mechanism uses an
/// `Identity` header, not an `Authorization` header. See the `AuthSession` documentation
/// comment for details.
///
/// Use `AnonymousSession` only for calls that the public website makes without a user
/// account. Today this means per-bike detail only. Do not assume that every endpoint
/// that needs some Bearer token accepts this anonymous token. For example, a lookup of a
/// real account by email uses only this token. The lookup gets a bare, non-JSON `403
/// Forbidden` response instead of JSON. A nonexistent email gets a clean `404` response
/// instead. So this token can check if an account does not exist. It never replaces a
/// real logged-in session.
public actor AnonymousSession: BearerTokenProviding {
    private let environment: VLSEnvironment
    private let httpClient: HTTPClient
    private var cachedAccessToken: String?
    private var cachedRefreshToken: String?

    /// Creates an anonymous session for one VLS environment.
    /// - Parameters:
    ///   - environment: The VLS environment to connect to. The default value is `.lyon`.
    ///   - urlSession: The URL session to use for network calls. The default value is
    ///     `.shared`.
    public init(environment: VLSEnvironment = .lyon, urlSession: URLSession = .shared) {
        self.environment = environment
        self.httpClient = HTTPClient(baseURL: environment.apiBaseURL, session: urlSession)
    }

    // MARK: - BearerTokenProviding

    /// Returns the cached anonymous access token, or gets a new one if none is cached.
    /// - Returns: A valid anonymous access token.
    /// - Throws: An error if the network call to get a new token fails.
    public func currentAccessToken() async throws -> String {
        if let cachedAccessToken {
            return cachedAccessToken
        }
        return try await refreshedAccessToken()
    }

    /// Gets a new anonymous access token, and does not return a cached one.
    ///
    /// This method reuses the cached device refresh token to get a new access token
    /// from `/auth/access_tokens`. This call is cheap. If the call fails, for example
    /// because the refresh token expired, this method starts a new device session
    /// instead. It calls `/auth/environments/{env}/client_tokens` to start the new
    /// session.
    /// - Returns: A new anonymous access token.
    /// - Throws: An error if the new-session call also fails.
    public func refreshedAccessToken() async throws -> String {
        if let cachedRefreshToken, let token = try? await accessToken(forRefreshToken: cachedRefreshToken) {
            cachedAccessToken = token
            return token
        }
        let session = try await createClientSession()
        cachedRefreshToken = session.refreshToken
        cachedAccessToken = session.accessToken
        return session.accessToken
    }

    // MARK: - Private

    private func accessToken(forRefreshToken refreshToken: String) async throws -> String {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "auth/access_tokens",
            body: CreateAccessTokenRequest(refreshToken: refreshToken),
            requiresAuth: false
        )
        let response: AccessTokenResponse = try await httpClient.send(endpoint)
        return response.accessToken
    }

    private func createClientSession() async throws -> ClientRefreshTokenResponse {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "auth/environments/\(environment.backendEnvironment)/client_tokens",
            body: CreateClientRefreshTokenRequest(code: environment.webClientCode, key: environment.webClientKey),
            requiresAuth: false
        )
        return try await httpClient.send(endpoint)
    }
}
