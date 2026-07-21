import Foundation

/// This service searches the FAQ entries in the app.
public struct FaqService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Searches the FAQ entries that match the given criteria.
    /// - Parameter criterias: The search criteria, for example a topic or language filter.
    /// - Returns: The list of matching FAQ entries.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Faq]`. Throws an encoding error if `criterias` cannot convert to JSON.
    public func search(_ criterias: FaqsCriterias) async throws -> [Faq] {
        let endpoint = try Endpoint.json(method: .post, path: "contracts/\(contract)/faqs/search", body: criterias)
        return try await httpClient.send(endpoint)
    }
}
