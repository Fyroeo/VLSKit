import Foundation

/// Token response from Keycloak's `/token` endpoint.
///
/// This is the standard OIDC token shape. It is the wire model for the
/// token endpoint at `iam.cyclocity.fr`, at path
/// `.../protocol/openid-connect/token`.
struct IamTokenResponse: Decodable {
    /// Bearer access token issued by Keycloak.
    let accessToken: String
    /// Refresh token used to get a new access token later.
    let refreshToken: String
    /// OIDC ID token that holds the user's identity claims.
    let idToken: String
    /// Number of seconds until `accessToken` expires.
    let expiresIn: Int?
    /// Number of seconds until `refreshToken` expires.
    let refreshExpiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case expiresIn = "expires_in"
        case refreshExpiresIn = "refresh_expires_in"
    }
}

/// Request body for `POST /auth/access_tokens`.
struct CreateAccessTokenRequest: Encodable {
    /// Refresh token used to ask for a new Cyclocity access token.
    let refreshToken: String
}

/// Response body for `POST /auth/access_tokens`.
///
/// This token is the Bearer token for the Cyclocity backend.
struct AccessTokenResponse: Decodable {
    /// Bearer access token for the Cyclocity backend.
    let accessToken: String
}

/// Request body for `POST /auth/environments/{environment}/client_tokens`.
///
/// This request starts an anonymous device session. The app uses this
/// session to read public data without a user login.
public struct CreateClientRefreshTokenRequest: Encodable, Sendable {
    /// Client code that identifies the app.
    public let code: String
    /// Client key used together with `code` to start the session.
    public let key: String

    /// Create a refresh token request for a client.
    /// - Parameters:
    ///   - code: Client code that identifies the app.
    ///   - key: Client key used together with `code` to start the session.
    public init(code: String, key: String) {
        self.code = code
        self.key = key
    }
}

/// Response body for `POST /auth/environments/{environment}/client_tokens`.
public struct ClientRefreshTokenResponse: Decodable, Sendable {
    /// Refresh token for the anonymous session, when the server returns one.
    public let refreshToken: String?
    /// Bearer access token for the anonymous session.
    public let accessToken: String
}
