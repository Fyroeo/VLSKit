import Foundation

/// A client for the public, official JCDecaux Open Data API.
///
/// See https://developer.jcdecaux.com for the official API documentation. This client
/// needs no login. It needs only your own free API key.
///
/// This client is the recommended starting point for a community app. It gets
/// real-time station data. It has none of the account, security, or terms-of-service
/// concerns of the private API. See API_REFERENCE.md in this package. Read the
/// "Public / open-data APIs" and "Legal / ToS notes" sections for more detail.
public struct OpenDataClient: Sendable {
    private let httpClient: HTTPClient
    private let apiKey: String
    private let contract: String

    // MARK: - Initialization

    /// Creates a client for JCDecaux's public Open Data API.
    /// - Parameters:
    ///   - apiKey: your JCDecaux API key from developer.jcdecaux.com. Use your own key.
    ///     Do not hardcode or share another person's key.
    ///   - contract: the JCDecaux contract name, for example `"lyon"`. The default is
    ///     `environment`'s own contract name.
    ///   - environment: the VLS environment that provides the open-data base URL.
    ///     The default is `.lyon`.
    ///   - session: the URL session to use for network calls. The default is the shared session.
    public init(apiKey: String, contract: String? = nil, environment: VLSEnvironment = .lyon, session: URLSession = .shared) {
        self.httpClient = HTTPClient(baseURL: environment.openDataBaseURL, session: session)
        self.apiKey = apiKey
        self.contract = contract ?? environment.contract
    }

    // MARK: - Stations

    /// Gets all stations for the configured contract.
    /// - Returns: The list of stations.
    /// - Throws: A `VLSError` if the request fails.
    public func stations() async throws -> [OpenDataStation] {
        let endpoint = Endpoint(
            method: .get,
            path: "vls/v3/stations",
            queryItems: queryItems(["contract": contract, "apiKey": apiKey]),
            requiresAuth: false
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets a single station by its station number.
    /// - Parameters:
    ///   - number: the station number.
    /// - Returns: The station.
    /// - Throws: A `VLSError` if the request fails.
    public func station(number: Int) async throws -> OpenDataStation {
        let endpoint = Endpoint(
            method: .get,
            path: "vls/v3/stations/\(number)",
            queryItems: queryItems(["contract": contract, "apiKey": apiKey]),
            requiresAuth: false
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Parks

    /// Gets the car and relay parks for the configured contract.
    /// - Returns: The list of parks.
    /// - Throws: A `VLSError` if the request fails.
    public func parks() async throws -> [OpenDataPark] {
        let endpoint = Endpoint(
            method: .get,
            path: "parking/v1/contracts/\(contract)/parks",
            queryItems: queryItems(["apiKey": apiKey]),
            requiresAuth: false
        )
        return try await httpClient.send(endpoint)
    }
}
