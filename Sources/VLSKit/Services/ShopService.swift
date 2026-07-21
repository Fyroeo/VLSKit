import Foundation

/// This service gets the partner shops for a contract, for example a badge pickup
/// point or a repair shop.
public struct ShopService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the list of partner shops for the contract.
    /// - Returns: The list of partner shops.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Shop]`.
    public func shops() async throws -> [Shop] {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/shops")
        return try await httpClient.send(endpoint)
    }
}
