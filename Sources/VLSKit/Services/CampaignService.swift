import Foundation

/// Promotional campaigns.
public struct CampaignService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets a promotional campaign by ID.
    /// - Parameter id: The unique ID of the campaign.
    /// - Returns: The campaign data.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Campaign`.
    public func campaign(id: Int64) async throws -> Campaign {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/campaigns/\(id)")
        return try await httpClient.send(endpoint)
    }
}
