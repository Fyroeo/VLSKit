import Foundation

/// A service or station event from `GET /contracts/{contract}/events[/{eventId}]`.
///
/// The app shows these events in its notification feed. The shape of `type`, `nature`,
/// `stations`, and `content` is not fully known. The client decodes these fields
/// permissively instead of guessing a fixed shape.
public struct DisplayableEvent: Codable, Sendable, Identifiable {
    /// The unique ID of the event.
    public let id: UUID
    /// The event type. The set of possible values is not fully known.
    public let type: String
    /// The event nature. The set of possible values is not fully known.
    public let nature: String
    /// The date the event starts. This value can be missing.
    public let startDate: Date?
    /// The date the event ends. This value can be missing.
    public let endDate: Date?
    /// True when the app must show the event with high priority. This value can be missing.
    public let highPriority: Bool?
    /// The stations the event applies to. The client decodes this as raw JSON because
    /// the shape is not fully known.
    public let stations: [JSONValue]
    /// The event content. The client decodes this as raw JSON because the shape is not
    /// fully known.
    public let content: JSONValue
}

/// A pagination wrapper shaped like a Spring Data `Page` object.
public struct Page<Element: Codable & Sendable>: Codable, Sendable {
    /// The total number of pages.
    public let totalPages: Int
    /// The total number of elements across all pages.
    public let totalElements: Int
    /// True when this page is the last page.
    public let last: Bool
    /// The number of elements in this page.
    public let numberOfElements: Int
    /// True when this page is the first page.
    public let first: Bool
    /// The requested page size.
    public let size: Int
    /// The zero-based index of this page.
    public let number: Int
    /// The elements in this page.
    public let content: [Element]
}
