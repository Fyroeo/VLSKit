import Foundation

/// Gets per-bike detail for a station or for one specific bike.
///
/// The detail includes bike type, status, battery level, ratings, and firmware version.
/// This client needs no real user login. It uses `AnonymousSession` internally.
/// `AnonymousSession` uses the same anonymous web-client credential as the public
/// velov.grandlyon.com site. The public site uses this credential for visitors who are
/// not logged in.
///
/// Read the "Per-bike detail" section of API_REFERENCE.md in this package before you
/// ship this client in a public product. JCDecaux built this credential for its own web
/// app. JCDecaux did not publish this credential for external integrators to use.
public struct BikeDetailClient: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    /// Creates a client that gets per-bike detail with no real user login.
    /// - Parameters:
    ///   - environment: the VLS environment and contract to call. The default is `.lyon`.
    ///   - urlSession: the URL session to use for network calls. The default is the shared session.
    public init(environment: VLSEnvironment = .lyon, urlSession: URLSession = .shared) {
        let anonymousSession = AnonymousSession(environment: environment, urlSession: urlSession)
        self.httpClient = HTTPClient(baseURL: environment.apiBaseURL, tokenProvider: anonymousSession, session: urlSession)
        self.contract = environment.contract
    }

    /// Gets all bikes currently docked at the given station.
    /// - Parameters:
    ///   - stationNumber: the station number.
    /// - Returns: The list of bikes at the station.
    /// - Throws: A `VLSError` if the request fails.
    public func bikes(atStationNumber stationNumber: Int) async throws -> [Bike] {
        // Kept on v3: the authenticated `BikeService` uses v4 (confirmed against the live
        // web app), but the anonymous role has not been observed on v4, so this stays v3.
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/bikes",
            queryItems: queryItems(["stationNumber": stationNumber]),
            headers: ["Accept": "application/vnd.bikes.v3+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets one specific bike by its number.
    ///
    /// The bike frame shows the bike number.
    /// - Parameters:
    ///   - number: the bike number.
    /// - Returns: A list with the matching bike. The list is empty if no bike matches.
    /// - Throws: A `VLSError` if the request fails.
    public func bike(number: Int) async throws -> [Bike] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/bikes",
            queryItems: queryItems(["number": number]),
            headers: ["Accept": "application/vnd.bikes.v3+json"]
        )
        return try await httpClient.send(endpoint)
    }
}
