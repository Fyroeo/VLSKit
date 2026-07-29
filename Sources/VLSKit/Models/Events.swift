import Foundation

/// A service or station event from `GET /contracts/{contract}/events[/{eventId}]`.
///
/// `type` and `nature` are still free strings — the observed values are `CLOSING`/`WORKS`,
/// but the full set is unknown. `content` and `stations` are decoded permissively: a
/// shape that does not match leaves them nil/empty rather than failing the whole page,
/// since one bad event would otherwise drop every event in the feed.
public struct DisplayableEvent: Codable, Sendable, Identifiable {
    /// The unique ID of the event.
    public let id: UUID
    /// The event type, for example `CLOSING`.
    public let type: String
    /// The event nature, for example `WORKS`.
    public let nature: String
    /// The date the event starts. This value can be missing.
    public let startDate: Date?
    /// The date the event ends. This value can be missing.
    public let endDate: Date?
    /// True when the app must show the event with high priority. This value can be missing.
    public let highPriority: Bool?
    /// The stations the event applies to.
    public let stations: [EventStation]
    /// The localized title and description.
    public let content: EventContent?

    /// The localized text of an event.
    public struct EventContent: Codable, Sendable {
        /// Language tag of `title`/`description`, for example `fr`.
        public let language: String?
        public let title: String?
        public let description: String?
    }

    /// A station an event applies to.
    public struct EventStation: Codable, Sendable {
        public let code: String?
        /// Display label, for example `"10122 - VERDUN / DESGRAND"`.
        public let label: String?

        /// The station number parsed from the leading digits of `label`, so an event can
        /// be linked back to a station on the map.
        public var stationNumber: Int? {
            guard let label else { return nil }
            let digits = label.prefix { $0.isNumber }
            return Int(digits)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, nature, startDate, endDate, highPriority, stations, content
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        nature = try container.decode(String.self, forKey: .nature)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        highPriority = try container.decodeIfPresent(Bool.self, forKey: .highPriority)
        // Tolerant on purpose: the single-event endpoint may shape these differently, and
        // a mismatch here should not discard the event.
        stations = (try? container.decodeIfPresent([EventStation].self, forKey: .stations)) ?? []
        content = try? container.decodeIfPresent(EventContent.self, forKey: .content)
    }
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
