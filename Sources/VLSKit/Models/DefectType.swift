import Foundation

/// A "report a defect" category from `GET /contracts/{contract}/defect-types`.
///
/// This endpoint returns `403 role.not.allowed` for all accounts today. This includes
/// real logged-in accounts. Treat this endpoint as unusable until JCDecaux changes
/// the backend permissions.
public struct DefectType: Codable, Sendable, Identifiable {
    /// The unique ID of the defect type.
    public let id: UUID
    /// The severity rating of the defect type.
    public let rating: Int
    /// The sort order of the defect type in a list.
    public let order: Int
    /// The short code that identifies the defect type.
    public let code: String
    /// True when the defect type applies to an electric bike.
    public let isElectricBike: Bool
}

/// The domain filter for `defectTypes(domain:category:)`.
public enum DefectTypeDomain: String, Codable, Sendable {
    /// A bike-related defect.
    case bike = "BIKE"
    /// A stand-related defect.
    case stand = "STAND"
    /// A station-related defect.
    case station = "STATION"
    /// An unrecognized domain value.
    case unknown = "UNKNOWN"
}

/// The category filter for `defectTypes(domain:category:)`.
public enum DefectTypeCategory: String, Codable, Sendable {
    /// A defect declared by an agent.
    case declaredAgent = "DECLARED_AGENT"
    /// A defect declared by a customer.
    case declaredCustomer = "DECLARED_CUSTOMER"
}
