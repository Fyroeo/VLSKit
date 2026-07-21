import Foundation

// MARK: - Station

/// This service wraps the private, authenticated station list and detail endpoints.
///
/// This is a real-time mirror of the public station data. Use `GBFSClient` or
/// `OpenDataClient` instead, if you do not need an authenticated session.
public struct StationService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets one station by its number.
    /// - Parameter number: The station's number.
    /// - Returns: The station data.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Station`.
    public func station(number: Int) async throws -> Station {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/stations/\(number)",
            headers: ["Accept": "application/vnd.station.v4+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the list of stations for the contract.
    /// - Parameter bonus: True to get only stations that give a reward bonus. Pass `nil`
    ///   to get all stations. Default is `nil`.
    /// - Returns: The list of matching stations.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Station]`.
    public func stations(bonus: Bool? = nil) async throws -> [Station] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/stations",
            queryItems: queryItems(["bonus": bonus]),
            headers: ["Accept": "application/vnd.station.v4+json"]
        )
        return try await httpClient.send(endpoint)
    }
}

// MARK: - Station Bookmarks

/// This service wraps the "star" feature for a station.
///
/// Use this service to add or remove a station bookmark for an account.
public struct StationBookmarkService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Adds a station bookmark for an account.
    /// - Parameters:
    ///   - stationId: The number of the station to bookmark.
    ///   - accountId: The unique ID of the account.
    /// - Throws: `VLSError` if the request fails.
    public func add(stationId: Int, accountId: UUID) async throws {
        let endpoint = Endpoint(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/stationbookmarks/\(stationId)/",
            headers: ["Accept": "application/vnd.account.v4+json"]
        )
        try await httpClient.sendVoid(endpoint)
    }

    /// Removes a station bookmark for an account.
    /// - Parameters:
    ///   - stationId: The number of the station to remove the bookmark from.
    ///   - accountId: The unique ID of the account.
    /// - Throws: `VLSError` if the request fails.
    public func remove(stationId: Int, accountId: UUID) async throws {
        let endpoint = Endpoint(
            method: .delete,
            path: "contracts/\(contract)/accounts/\(accountId)/stationbookmarks/\(stationId)/",
            headers: ["Accept": "application/vnd.account.v4+json"]
        )
        try await httpClient.sendVoid(endpoint)
    }
}
