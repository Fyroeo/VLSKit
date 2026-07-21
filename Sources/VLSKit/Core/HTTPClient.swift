import Foundation

// MARK: - Token Providing

/// A type that gives the HTTP client a current Cyclocity Bearer token.
///
/// A conforming type refreshes the token first, if needed. `AuthSession` is the real
/// implementation. Tests can use a stub instead.
public protocol BearerTokenProviding: Sendable {
    /// Gets the current access token, and refreshes it first if the token looks stale.
    /// - Returns: A valid access token.
    /// - Throws: `VLSError.notAuthenticated` if no session exists.
    func currentAccessToken() async throws -> String
    /// Forces a token refresh, for example after a 401 response, and returns the new
    /// token.
    /// - Returns: The new access token.
    func refreshedAccessToken() async throws -> String
}

// MARK: - Auth Header Style

/// How an `HTTPClient` puts its token or tokens into a request.
///
/// The authenticated Cyclocity API uses 2 separate tokens under 2 separate headers.
/// It does not reuse one token for both headers. The `Identity: <token>` header carries
/// the Keycloak access token, with no scheme prefix. This header alone is enough for a
/// read call. A write call, for example `releaseBike`, also needs an
/// `Authorization: Taknv1 <token>` header. This second header carries a different token:
/// the same anonymous device token that `AnonymousSession` creates. If you send the
/// Keycloak token under `Authorization` instead, every call fails, not only write calls.
/// The server returns `403 Invalid Takn` in this case. See API_REFERENCE.md in this
/// package, section "Authentication flow", for more detail.
public enum AuthHeaderStyle: Sendable {
    /// Sends `Authorization: Bearer <token>` only.
    ///
    /// This is the anonymous device-token flow. `AnonymousSession` and `BikeDetailClient`
    /// use this style on their own.
    case authorizationBearer
    /// Sends `Identity: <token>` from `tokenProvider`, plus `Authorization: Taknv1
    /// <token>` from `secondaryTokenProvider`.
    ///
    /// The `Identity` token is the Keycloak session. The `Authorization` token is the
    /// anonymous device token. VLSKit uses this style for authenticated per-user calls.
    case identity
}

// MARK: - HTTP Client

/// A thin async/await wrapper around `URLSession`.
///
/// `HTTPClient` resolves each `Endpoint` against a base URL. It attaches authentication
/// and versioning headers. It maps each non-2xx response to a `VLSError`.
///
/// Use one `HTTPClient` per base URL. VLSKit uses one authenticated client for
/// `api.cyclocity.fr`. It uses separate, lightweight clients with no authentication for
/// the public Open Data and GBFS hosts.
public final class HTTPClient: Sendable {
    /// Base URL that every endpoint on this client resolves against.
    public let baseURL: URL
    private let session: URLSession
    private let tokenProvider: BearerTokenProviding?
    /// Used only by `AuthHeaderStyle.identity`, for the separate `Authorization: Taknv1`
    /// header. See the doc comment on that case for why it needs a separate token and
    /// provider.
    private let secondaryTokenProvider: BearerTokenProviding?
    private let authHeaderStyle: AuthHeaderStyle

    // MARK: Initialization

    /// Creates an HTTP client for one base URL.
    /// - Parameters:
    ///   - baseURL: Base URL that every endpoint on this client resolves against.
    ///   - tokenProvider: Provider for the primary authentication token. Default is
    ///     `nil`.
    ///   - secondaryTokenProvider: Provider for the secondary token that
    ///     `AuthHeaderStyle.identity` uses. Default is `nil`.
    ///   - authHeaderStyle: How this client attaches its token or tokens to a request.
    ///     Default is `.authorizationBearer`.
    ///   - session: `URLSession` to use for requests. Default is `.shared`.
    public init(
        baseURL: URL,
        tokenProvider: BearerTokenProviding? = nil,
        secondaryTokenProvider: BearerTokenProviding? = nil,
        authHeaderStyle: AuthHeaderStyle = .authorizationBearer,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.secondaryTokenProvider = secondaryTokenProvider
        self.authHeaderStyle = authHeaderStyle
        self.session = session
    }

    // MARK: Sending Requests

    /// Runs an endpoint and decodes the JSON response as `Response`.
    /// - Parameters:
    ///   - endpoint: Endpoint to run.
    ///   - type: Type to decode the response body as. Default is `Response.self`.
    /// - Returns: The decoded response.
    /// - Throws: `VLSError` if the request fails or the response fails to decode.
    @discardableResult
    public func send<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type = Response.self) async throws -> Response {
        let data = try await sendRaw(endpoint)
        do {
            return try JSONDecoder.vls.decode(Response.self, from: data)
        } catch {
            throw VLSError.decodingFailed(underlying: error, body: data)
        }
    }

    /// Runs an endpoint and ignores its response body.
    ///
    /// Use this method for a call that returns no useful body, for example a `204`
    /// response or a fire-and-forget `POST` request.
    /// - Parameter endpoint: Endpoint to run.
    /// - Throws: `VLSError` if the request fails.
    public func sendVoid(_ endpoint: Endpoint) async throws {
        _ = try await sendRaw(endpoint, allowEmptyBody: true)
    }

    /// Runs an endpoint and returns the raw response body.
    ///
    /// Use this method for a binary download, RSS or XML data, or any response you want to
    /// decode yourself.
    /// - Parameters:
    ///   - endpoint: Endpoint to run.
    ///   - allowEmptyBody: True if an empty response body is a valid, non-error result.
    ///     Default is `false`.
    /// - Returns: The raw response body.
    /// - Throws: `VLSError` if the request fails.
    @discardableResult
    public func sendRaw(_ endpoint: Endpoint, allowEmptyBody: Bool = false) async throws -> Data {
        var attempt = 0
        while true {
            attempt += 1
            let request = try await buildRequest(for: endpoint, forceRefresh: attempt > 1)
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw VLSError.httpError(statusCode: -1, body: data)
            }

            if (http.statusCode == 401 || http.statusCode == 403), endpoint.requiresAuth, attempt == 1, tokenProvider != nil {
                // An expired or invalid token surfaces as `403 Invalid Takn` on this API,
                // not 401 — retry on both so a short-lived Keycloak access token gets
                // refreshed transparently instead of failing every call until re-login.
                continue
            }

            guard (200..<300).contains(http.statusCode) else {
                throw VLSError.httpError(statusCode: http.statusCode, body: data)
            }

            if data.isEmpty && !allowEmptyBody {
                return Data("null".utf8) // let callers decoding e.g. Optional<T> succeed
            }
            return data
        }
    }

    // MARK: Building Requests

    private func buildRequest(for endpoint: Endpoint, forceRefresh: Bool) async throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw VLSError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + endpoint.queryItems
        }
        guard let url = components.url else {
            throw VLSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if endpoint.requiresAuth {
            guard let tokenProvider else {
                throw VLSError.notAuthenticated
            }
            let token = forceRefresh ? try await tokenProvider.refreshedAccessToken() : try await tokenProvider.currentAccessToken()
            switch authHeaderStyle {
            case .authorizationBearer:
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            case .identity:
                request.setValue(token, forHTTPHeaderField: "Identity")
                if let secondaryTokenProvider {
                    let authToken = forceRefresh ? try await secondaryTokenProvider.refreshedAccessToken() : try await secondaryTokenProvider.currentAccessToken()
                    request.setValue("Taknv1 \(authToken)", forHTTPHeaderField: "Authorization")
                }
            }
        }

        return request
    }
}
