import Foundation

/// Gets metadata for the current contract.
public struct ContractService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the metadata for the current contract.
    /// - Returns: The contract metadata, for example its name, currency, and timezone.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Contract`.
    public func fetch() async throws -> Contract {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)")
        return try await httpClient.send(endpoint)
    }
}
