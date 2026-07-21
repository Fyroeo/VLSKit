import Foundation

/// Holds the data needed to show the Keycloak login screen and later finish the login
/// exchange.
/// Keep this value between the time you show the login screen and the time you call
/// `VLSClient.completeLogin(callbackURL:pending:)`.
public struct PendingAuthorization: Sendable {
    /// The Keycloak authorize URL to open in a web view.
    public let authorizeURL: URL
    /// The random state value sent with the authorize request.
    /// `completeLogin` checks this value against the state value in the callback URL.
    public let state: String
    /// The PKCE code verifier this request generated.
    /// `completeLogin` sends this value to Keycloak to finish the code exchange.
    public let codeVerifier: String
}

enum AuthorizationRequestBuilder {
    /// Builds the Keycloak `/auth` URL for an Authorization Code and PKCE login.
    /// - Parameter environment: The VLS environment to sign in to.
    /// - Returns: The data needed to show the login screen and finish the login flow.
    static func build(environment: VLSEnvironment) -> PendingAuthorization {
        let state = randomURLSafeToken(byteCount: 16)
        let codeVerifier = PKCE.generateCodeVerifier()
        let codeChallenge = PKCE.codeChallenge(for: codeVerifier)

        var components = URLComponents(url: environment.iamBaseURL.appendingPathComponent("auth"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: environment.oidcClientID),
            URLQueryItem(name: "redirect_uri", value: environment.oidcRedirectURI.absoluteString),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: environment.oidcScope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]

        return PendingAuthorization(authorizeURL: components.url!, state: state, codeVerifier: codeVerifier)
    }

    /// Extracts the `code` and `state` values from the intercepted redirect URL.
    /// - Parameters:
    ///   - url: The URL the login web view redirected to.
    ///   - redirectURI: The expected OIDC redirect URI for the environment.
    /// - Returns: The `code` and `state` values, or `nil` if `url` is not the OIDC
    ///   callback. For example, `url` can be an ordinary in-page navigation instead.
    static func extractCode(from url: URL, redirectURI: URL) -> (code: String, state: String?)? {
        guard url.scheme == redirectURI.scheme, url.host == redirectURI.host else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return nil
        }
        let state = components.queryItems?.first(where: { $0.name == "state" })?.value
        return (code, state)
    }

    private static func randomURLSafeToken(byteCount: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        for i in bytes.indices { bytes[i] = UInt8.random(in: .min ... .max) }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
