import Foundation

/// The "report a defect" category list.
///
/// This endpoint returns `403 role.not.allowed` for all accounts today. This includes
/// real logged-in accounts. Treat this endpoint as unusable until JCDecaux changes the
/// backend permissions.
public struct DefectTypeService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the list of "report a defect" categories for the current contract.
    /// - Parameters:
    ///   - domain: The domain to filter by, for example bike, stand, or station. Pass
    ///     `nil` to get every domain. The default value is nil.
    ///   - category: The category to filter by, for example agent-declared or
    ///     customer-declared. Pass `nil` to get every category. The default value is nil.
    ///   - isActive: Whether to get only active defect types. The default value is `true`.
    /// - Returns: The list of matching defect types.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[DefectType]`.
    public func defectTypes(domain: DefectTypeDomain? = nil, category: DefectTypeCategory? = nil, isActive: Bool = true) async throws -> [DefectType] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/defect-types",
            queryItems: queryItems(["domain": domain?.rawValue, "category": category?.rawValue, "active": isActive]),
            headers: ["Accept": "application/vnd.defect-type.v1+json"]
        )
        return try await httpClient.send(endpoint)
    }
}
