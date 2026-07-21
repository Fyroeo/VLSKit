import Foundation

// MARK: - FAQ entry

/// A FAQ entry from `POST /contracts/{contract}/faqs/search` (`vg.i` in the app).
public struct Faq: Codable, Sendable, Identifiable {
    /// The unique ID of the FAQ entry. This value can be missing.
    public let id: UUID?
    /// The unique ID of the FAQ topic. This value can be missing.
    public let topicId: UUID?
    /// The code of the FAQ topic. This value can be missing.
    public let topicCode: FaqTopicCode?
    /// The name of the contract the FAQ entry belongs to. This value can be missing.
    public let contractName: String?
    /// The sort rank of the FAQ entry in a list. This value can be missing.
    public let rank: Int?
    /// The localized question and response pairs for the FAQ entry. This value can be
    /// missing.
    public let contents: [Content]?

    /// A single localized question and response pair for a FAQ entry.
    public struct Content: Codable, Sendable {
        /// The question text. This value can be missing.
        public let question: String?
        /// The response text. This value can be missing.
        public let response: String?
        /// The language of the question and response, for example `fr`. This value can
        /// be missing.
        public let language: String?
    }
}

// MARK: - FAQ topic

/// The topic code for a FAQ entry.
public enum FaqTopicCode: String, Codable, Sendable {
    /// The topic covers payment.
    case pay = "PAY"
    /// The topic covers subscriptions.
    case subscription = "ABO"
    /// The topic covers rides.
    case ride = "RIDE"
    /// The topic covers the VLS bike-share service.
    case vls = "VLS"
    /// The topic covers parking.
    case parking = "PARKING"
}

// MARK: - FAQ search

/// The search criteria for a `Faq` search request.
public struct FaqsCriterias: Codable, Sendable {
    /// The unique ID of the FAQ topic to filter by. This value can be missing.
    public let topicId: UUID?
    /// The language to filter by, for example `fr`. This value can be missing.
    public let language: String?
    /// The topic code to filter by. This value can be missing.
    public let code: FaqTopicCode?

    /// Creates search criteria for a FAQ search request.
    /// - Parameters:
    ///   - topicId: The unique ID of the FAQ topic to filter by. The default value is nil.
    ///   - language: The language to filter by. The default value is nil.
    ///   - code: The topic code to filter by. The default value is nil.
    public init(topicId: UUID? = nil, language: String? = nil, code: FaqTopicCode? = nil) {
        self.topicId = topicId
        self.language = language
        self.code = code
    }
}
