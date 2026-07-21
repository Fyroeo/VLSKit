import Foundation

/// This service wraps the bike parking endpoints for a contract.
///
/// It also sends the remote command that opens a parking gate.
public struct ParkingService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the list of parking spots for the contract.
    /// - Returns: The list of parking spots.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Park]`.
    public func parkings() async throws -> [Park] {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/parkings")
        return try await httpClient.send(endpoint)
    }

    /// Gets the parking spots whose `number` field matches a given value.
    /// - Parameter number: The parking number to filter by.
    /// - Returns: The list of matching parking spots.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Park]`.
    public func parkings(number: Int) async throws -> [Park] {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/parkings", queryItems: queryItems(["number": number]))
        return try await httpClient.send(endpoint)
    }

    /// Remotely opens a parking gate for an account.
    ///
    /// This method sends a real command that opens a physical gate. See API_REFERENCE.md
    /// in this package, section "Legal / ToS notes", for the legal and safety notes about
    /// this kind of call.
    /// - Parameters:
    ///   - parkId: The unique ID of the parking spot to open.
    ///   - accountId: The unique ID of the account that requests the open.
    /// - Throws: `VLSError` if the request fails.
    public func open(parkId: UUID, accountId: UUID) async throws {
        let endpoint = Endpoint(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/parkings/\(parkId)/open",
            headers: ["Accept": "application/vnd.parkings.v2+json"]
        )
        try await httpClient.sendVoid(endpoint)
    }
}
