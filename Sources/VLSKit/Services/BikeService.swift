import Foundation

/// Bike lookup by number or by station, and post-ride ratings.
public struct BikeService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the bikes that match a bike number.
    /// - Parameter number: The bike number to search for.
    /// - Returns: The list of matching bikes.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Bike]`.
    public func bike(number: Int) async throws -> [Bike] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/bikes",
            queryItems: queryItems(["number": number]),
            headers: ["Accept": "application/vnd.bikes.v4+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the bikes docked at a station.
    /// - Parameter stationNumber: The number of the station.
    /// - Returns: The list of bikes at the station.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Bike]`.
    public func bikes(atStationNumber stationNumber: Int) async throws -> [Bike] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/bikes",
            queryItems: queryItems(["stationNumber": stationNumber]),
            headers: ["Accept": "application/vnd.bikes.v4+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Submits a rating for a completed trip.
    /// - Parameters:
    ///   - accountId: The unique ID of the account that took the trip.
    ///   - tripId: The unique ID of the trip to rate.
    ///   - rate: The rating to submit.
    /// - Returns: The submitted rating.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Rate`. Throws an encoding error if `rate` cannot convert to JSON.
    public func rate(accountId: UUID, tripId: UUID, rate: Rate) async throws -> Rate {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/trips/\(tripId)/rate",
            headers: ["Content-Type": "application/vnd.trip.v5+json"],
            body: rate
        )
        return try await httpClient.send(endpoint)
    }
}
