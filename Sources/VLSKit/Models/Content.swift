import Foundation

/// In-app CMS content, for example a legal notice, a privacy policy, or an
/// accessibility report.
///
/// This is the response body for
/// `GET /contracts/{contract}/contents?contentType=`. The original app names
/// this type `ri.a`.
public struct Content: Codable, Sendable, Identifiable {
    /// Unique ID of the content item.
    public let id: UUID
    /// Date and time the server created the content item.
    public let createdAt: Date
    /// Author who created the content item.
    public let createdAuthor: String
    /// Author of the last edit to the content item.
    public let lastEditionAuthor: String
    /// Date and time of the last edit to the content item.
    public let lastEditionAt: Date
    /// Locale of the content item, for example `"fr-FR"`.
    public let locale: String
    /// Name of the contract that owns this content item.
    public let contractName: String
    /// Type of this content item.
    public let contentType: ContentType
    /// Content body, for example HTML or plain text.
    public let object: String

    enum CodingKeys: String, CodingKey {
        case id, createdAt, createdAuthor, lastEditionAuthor, lastEditionAt, locale, contractName, contentType
        case object = "object"
    }
}

/// Type of CMS content served by the contents endpoint.
public enum ContentType: String, Codable, Sendable {
    /// Legal notice text.
    case legalNotice = "LEGAL_NOTICE"
    /// Privacy policy text.
    case privacyPolicy = "PRIVACY_POLICY"
    /// Accessibility report text for the Android app.
    case accessibilityReportAndroid = "ACCESSIBILITY_REPORT_ANDROID"
}
