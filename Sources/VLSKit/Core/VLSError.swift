import Foundation

// MARK: - VLS Error

/// Errors this kit throws for authentication, network, and decoding failures.
public enum VLSError: Error, Sendable {
    /// This call needs an authenticated session. Call `VLSClient.beginLogin()` and
    /// `VLSClient.completeLogin(...)` before you call this method again.
    case notAuthenticated
    /// The server returned a status code outside the 200-299 range.
    ///
    /// `body` holds the raw response payload, if any. Use `body` to diagnose the many
    /// `application/vnd.*+json` media-type mismatches this API can return.
    case httpError(statusCode: Int, body: Data?)
    /// The response body did not match the expected model.
    case decodingFailed(underlying: Error, body: Data?)
    /// The user cancelled the OAuth/OIDC login flow, or the flow failed before it
    /// returned a code.
    case authenticationCancelled
    /// The OAuth/OIDC login flow failed. `underlying` holds the original error, if any.
    case authenticationFailed(underlying: Error?)
    /// The client tried to refresh the token, but no refresh token exists.
    case noRefreshToken
    /// VLSKit could not build a valid URL for the request.
    case invalidURL
}

// MARK: - Localized Description

extension VLSError: LocalizedError {
    /// A human-readable description of this error, for `LocalizedError`.
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "This call requires an authenticated session. Complete VLSClient.beginLogin()/completeLogin() first."
        case .httpError(let statusCode, let body):
            let bodyString = body.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
            return "HTTP \(statusCode): \(bodyString)"
        case .decodingFailed(let underlying, _):
            return "Failed to decode response: \(underlying)"
        case .authenticationCancelled:
            return "Login was cancelled."
        case .authenticationFailed(let underlying):
            return "Login failed: \(underlying?.localizedDescription ?? "unknown error")"
        case .noRefreshToken:
            return "No refresh token available; the user must log in again."
        case .invalidURL:
            return "Could not construct a valid request URL."
        }
    }
}
