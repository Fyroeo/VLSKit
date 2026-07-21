import Foundation

/// A referral-program asset or configuration value for the contract.
///
/// The endpoint `GET /contracts/{contract}/sponsoring` (`ri.l`) returns this type.
public struct Sponsoring: Codable, Sendable, Identifiable {
    /// The record's unique identifier.
    public let id: Int64
    /// The code of the contract (bike-share network) this record belongs to.
    public let contractCode: String
    /// The platform this record applies to.
    public let platform: SponsoringPlatform
    /// The kind of sponsoring asset this record holds.
    public let type: SponsoringType
    /// The identifier of the associated document, for example an image file.
    public let documentId: UUID
    /// True if the backend currently uses this record.
    public let active: Bool
    /// The date and time the backend created this record.
    public let createdAt: Date
    /// The date and time the backend last updated this record.
    public let updatedAt: Date
}

/// The kind of referral-program asset a `Sponsoring` record holds.
public enum SponsoringType: String, Codable, Sendable {
    /// A welcome image shown as part of the referral program.
    case welcomeImage = "WELCOME_IMAGE"
}
