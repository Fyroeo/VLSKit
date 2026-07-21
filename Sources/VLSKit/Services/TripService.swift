import Foundation

/// This service wraps the trip endpoints.
///
/// It covers trip history, the GPS route for a trip, and unlocking a bike with
/// `releaseBike`.
public struct TripService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    // MARK: - Trip History

    /// Gets the list of trips for an account.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - statuses: The trip statuses to filter by. Default is empty, which gets trips
    ///     with any status.
    /// - Returns: The list of matching trips.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Trip]`.
    public func trips(accountId: UUID, statuses: [Trip.Status] = []) async throws -> [Trip] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/trips",
            queryItems: statuses.map { URLQueryItem(name: "status", value: $0.rawValue) },
            headers: ["Accept": "application/vnd.trip.v5+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the list of ongoing trips for an account.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The list of ongoing trips.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Trip]`.
    public func ongoingTrips(accountId: UUID) async throws -> [Trip] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/trips/ongoing",
            headers: ["Accept": "application/vnd.trip.v5+json"]
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Route

    /// Gets the GPS route for a trip.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - tripId: The unique ID of the trip.
    /// - Returns: The trip's route, as GeoJSON.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `GeoJSON`.
    public func route(accountId: UUID, tripId: UUID) async throws -> GeoJSON {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/trips/\(tripId)/route",
            headers: ["Accept": "application/vnd.trip.v5+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Uploads the rider's recorded GPS trace for a trip.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - tripId: The unique ID of the trip.
    ///   - points: The ordered list of GPS points recorded during the trip.
    /// - Throws: `VLSError` if the request fails. Throws an encoding error if `points`
    ///   cannot convert to JSON.
    public func uploadRoute(accountId: UUID, tripId: UUID, points: [TripPoint]) async throws {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/trips/\(tripId)/route",
            headers: ["Content-Type": "application/vnd.trip.v5+json"],
            body: points
        )
        try await httpClient.sendVoid(endpoint)
    }

    // MARK: - Releasing a Bike

    /// Unlocks a bike for the rider.
    ///
    /// This method sends the bike and stand details in `request` to the release endpoint.
    /// This action is real, billable, and has a consequence for the account that calls
    /// it. See API_REFERENCE.md in this package, section "Legal / ToS notes."
    /// Read that section before you add this method to a shipped app.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - subscriptionId: The unique ID of the subscription to use for the bike release.
    ///   - request: The bike and stand details for the release.
    /// - Returns: The result of the release, including the transaction state.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `ReleaseBikeResponse`. Throws an encoding error if `request` cannot convert to
    ///   JSON.
    public func releaseBike(accountId: UUID, subscriptionId: UUID, request: ReleaseBikeRequest) async throws -> ReleaseBikeResponse {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/subscriptions/\(subscriptionId)/trips",
            headers: ["Content-Type": "application/vnd.trip.v5+json"],
            body: request
        )
        return try await httpClient.send(endpoint)
    }
}
