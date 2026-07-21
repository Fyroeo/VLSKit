import Foundation

/// In-app CMS content.
public struct ContentService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the list of CMS content items, with an optional type filter.
    /// - Parameter contentType: The content type to filter by. Pass `nil` to get every
    ///   content type.
    /// - Returns: The list of matching content items.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Content]`.
    public func contents(contentType: ContentType? = nil) async throws -> [Content] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/contents",
            queryItems: queryItems(["contentType": contentType?.rawValue])
        )
        return try await httpClient.send(endpoint)
    }
}
