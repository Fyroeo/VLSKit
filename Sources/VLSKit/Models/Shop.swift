import Foundation

/// A partner shop for the contract, for example a badge pickup point or a repair shop.
///
/// The endpoint `GET /contracts/{contract}/shops` (`ri.k`) returns this type. Reverse
/// engineering did not fully expand the nested shapes for `address`, `businessHours`,
/// `services`, and `content`. This type decodes them permissively as
/// `JSONValue`. Tighten these fields to specific types if you need their exact shape.
///
/// The backend sends `createdAt` and `updatedAt` as a Java `LocalDateTime` value, with no
/// time zone. This type keeps both fields as plain strings. Decoding them as `Date` could
/// apply the wrong time zone.
public struct Shop: Codable, Sendable, Identifiable {
    /// The shop's unique identifier.
    public let id: UUID
    /// The name of the contract (bike-share network) the shop belongs to.
    public let contractName: String
    /// The shop's display name.
    public let name: String
    /// The shop's street address. This value decodes permissively as `JSONValue`.
    public let address: JSONValue?
    /// The shop's opening hours. This value decodes permissively as `JSONValue`.
    public let businessHours: [JSONValue]?
    /// The list of services the shop offers. Each value decodes permissively as
    /// `JSONValue`.
    public let services: [JSONValue]?
    /// The shop's current open or closed status.
    public let status: Status?
    /// Extra display content for the shop, for example marketing text or images. Each
    /// value decodes permissively as `JSONValue`.
    public let content: [JSONValue]?
    /// The date and time the backend created this record, as a Java `LocalDateTime`
    /// string with no time zone.
    public let createdAt: String?
    /// The date and time the backend last updated this record, as a Java
    /// `LocalDateTime` string with no time zone.
    public let updatedAt: String?

    // MARK: - Status

    /// The shop's open or closed status.
    public enum Status: String, Codable, Sendable {
        /// The shop is open.
        case open = "OPEN"
        /// The shop is closed.
        case closed = "CLOSED"
        /// The shop is closed for a short time, for example for a holiday.
        case temporarilyClosed = "TEMPORARILY_CLOSED"
        /// The backend did not report a known status value.
        case unknown = "UNKNOWN"
    }
}
