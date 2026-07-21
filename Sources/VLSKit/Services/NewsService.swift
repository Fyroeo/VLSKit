import Foundation

/// This service gets the RSS news feed.
///
/// This is the only endpoint in this API that sends XML instead of JSON.
public struct NewsService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the RSS news feed for a platform.
    ///
    /// This method parses the raw XML response body into an `RSSFeed`.
    /// - Parameter platform: The platform to get the news feed for.
    /// - Returns: The parsed news feed.
    /// - Throws: `VLSError` if the request fails. Throws an `XMLParser` error if the
    ///   response body is not valid RSS XML.
    public func feed(platform: Platform) async throws -> RSSFeed {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/news/feed/\(platform.rawValue)",
            headers: ["Accept": "application/rss+xml"]
        )
        let data = try await httpClient.sendRaw(endpoint)
        return try RSSParser.parse(data)
    }
}
