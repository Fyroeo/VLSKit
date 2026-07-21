import Foundation

// MARK: - HTTP Method

/// HTTP method for a request.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
}

// MARK: - Endpoint

/// A single API call.
///
/// The `HTTPClient` that runs this endpoint supplies the base URL. It resolves `path`
/// against that base URL. Services build endpoints against either the private Cyclocity
/// base URL or the public Open Data base URL.
public struct Endpoint: Sendable {
    /// HTTP method to use for this call.
    public var method: HTTPMethod
    /// Path relative to the client's base URL.
    ///
    /// Replace each `{placeholder}` in the path with its real value before you set this
    /// property. VLSKit does not fill in placeholders itself. The caller must interpolate
    /// each value directly.
    public var path: String
    /// Query items to append to the request URL.
    public var queryItems: [URLQueryItem]
    /// Extra headers to send, in addition to the Authorization header.
    ///
    /// This API often requires an exact `application/vnd.*+json` media type. See
    /// API_REFERENCE.md in this package for the required media type for each endpoint.
    public var headers: [String: String]
    /// Raw HTTP body to send with the request.
    public var body: Data?
    /// True if this call must attach a Cyclocity authentication token.
    public var requiresAuth: Bool

    /// Creates an endpoint.
    /// - Parameters:
    ///   - method: HTTP method to use.
    ///   - path: Path relative to the client's base URL.
    ///   - queryItems: Query items to append to the request URL. Default is empty.
    ///   - headers: Extra headers to send beyond the Authorization header. Default is
    ///     empty.
    ///   - body: Raw HTTP body to send. Default is `nil`.
    ///   - requiresAuth: True if this call must attach an authentication token. Default is
    ///     `true`.
    public init(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        requiresAuth: Bool = true
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
    }

    /// Builds an endpoint with a JSON-encoded body from an `Encodable` value.
    ///
    /// This method sets the `Content-Type` header to `application/json` if the caller
    /// does not set one already.
    /// - Parameters:
    ///   - method: HTTP method to use.
    ///   - path: Path relative to the client's base URL.
    ///   - queryItems: Query items to append to the request URL. Default is empty.
    ///   - headers: Extra headers to send beyond the Authorization header. Default is
    ///     empty.
    ///   - body: Value to encode as the JSON request body.
    ///   - requiresAuth: True if this call must attach an authentication token. Default is
    ///     `true`.
    /// - Returns: An endpoint with the encoded JSON body and headers set.
    /// - Throws: An error if the encoder cannot encode `body`.
    public static func json<Body: Encodable>(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Body,
        requiresAuth: Bool = true
    ) throws -> Endpoint {
        var headers = headers
        headers["Content-Type"] = headers["Content-Type"] ?? "application/json"
        let data = try JSONEncoder.vls.encode(body)
        return Endpoint(method: method, path: path, queryItems: queryItems, headers: headers, body: data, requiresAuth: requiresAuth)
    }
}

// MARK: - Query Item Helpers

/// Builds a list of query items from a dictionary, and drops each `nil` value.
///
/// Use this function to pass optional filters as query items, without a manual
/// `compactMap` call at each call site.
/// - Parameter pairs: Query parameter names and optional values.
/// - Returns: One `URLQueryItem` for each pair whose value is not `nil`.
public func queryItems(_ pairs: [String: CustomStringConvertible?]) -> [URLQueryItem] {
    pairs.compactMap { key, value in
        guard let value else { return nil }
        return URLQueryItem(name: key, value: value.description)
    }
}
