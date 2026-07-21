import Foundation

/// This service wraps the referral-program endpoint for the contract.
public struct SponsoringService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the referral-program records for a platform and asset type.
    /// - Parameters:
    ///   - platform: The platform to filter by, for example web or mobile.
    ///   - type: The kind of referral-program asset to filter by.
    ///   - active: True to get only records the backend currently uses. Default is true.
    /// - Returns: The list of matching referral-program records.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Sponsoring]`.
    public func sponsoring(platform: SponsoringPlatform, type: SponsoringType, active: Bool = true) async throws -> [Sponsoring] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/sponsoring",
            queryItems: queryItems(["platform": platform.rawValue, "type": type.rawValue, "active": active])
        )
        return try await httpClient.send(endpoint)
    }
}
