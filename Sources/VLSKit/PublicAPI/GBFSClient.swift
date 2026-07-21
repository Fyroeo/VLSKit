import Foundation

/// A client for the per-contract GBFS feed.
///
/// GBFS stands for General Bikeshare Feed Specification. This feed comes from the
/// private Cyclocity host. The GBFS specification does not require authentication for
/// this feed. Confirm that this holds in production before you rely on it. See the GBFS
/// note in API_REFERENCE.md, in this package, for more detail.
public struct GBFSClient: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    /// Creates a client for the given contract and environment.
    /// - Parameters:
    ///   - contract: the JCDecaux contract name, for example `"lyon"`. The default is
    ///     `environment`'s own contract name.
    ///   - environment: the VLS environment to call. The default is `.lyon`.
    ///   - session: the URL session to use for network calls. The default is the shared session.
    public init(contract: String? = nil, environment: VLSEnvironment = .lyon, session: URLSession = .shared) {
        self.httpClient = HTTPClient(baseURL: environment.apiBaseURL, session: session)
        self.contract = contract ?? environment.contract
    }

    /// Gets the GBFS `station_information` feed for this contract.
    ///
    /// This feed lists static station data: name, location, and capacity.
    /// - Returns: The station information feed.
    /// - Throws: A `VLSError` if the request fails.
    public func stationInformation() async throws -> GBFSFeed<GBFSStationInformationList> {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/gbfs/v3/station_information.json", requiresAuth: false)
        return try await httpClient.send(endpoint)
    }

    /// Gets the GBFS `station_status` feed for this contract.
    ///
    /// This feed lists live station data: available bikes, available docks, and station state.
    /// - Returns: The station status feed.
    /// - Throws: A `VLSError` if the request fails.
    public func stationStatus() async throws -> GBFSFeed<GBFSStationStatusList> {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/gbfs/v3/station_status.json", requiresAuth: false)
        return try await httpClient.send(endpoint)
    }
}
