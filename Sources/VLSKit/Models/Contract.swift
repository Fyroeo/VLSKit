import Foundation

/// System metadata for a contract, for example the Lyon contract, which uses
/// `contract=lyon`.
///
/// This is the response body for `GET /contracts/{contract}`. The
/// `createdAt` and `updatedAt` fields are plain strings here, not `Date`,
/// unlike most other timestamp fields in this API.
public struct Contract: Codable, Sendable, Identifiable {
    // MARK: - Properties

    /// Unique ID of the contract.
    public let id: Int
    /// Technical name of the contract, for example `"lyon"`.
    public let name: String?
    /// Commercial (display) name of the contract.
    public let commercialName: String?
    /// Default language code of the contract.
    public let language: String?
    /// Name of the contract in the Kiwi external system.
    public let kiwiName: String?
    /// Currency code used by the contract, for example `"EUR"`.
    public let currency: String?
    /// Time zone identifier of the contract, for example `"Europe/Paris"`.
    public let timezone: String?
    /// Public website URL of the contract.
    public let url: String?
    /// Date and time the server created the contract, as a plain string, not a `Date`.
    public let createdAt: String?
    /// Date and time the server last updated the contract, as a plain string, not a `Date`.
    public let updatedAt: String?
    /// Alternate names for the contract.
    public let aliases: [Alias]
    /// Languages available for the contract.
    public let contractLanguages: [ContractLanguage]
    /// Geographic center point of the contract.
    public let geoPosition: Coordinate?
    /// Feature flags enabled for the contract.
    public let features: [Feature]

    // MARK: - Nested types

    /// Alternate name for a contract in a given context.
    public struct Alias: Codable, Sendable {
        /// Context this alias applies to, for example an app or a platform name.
        public let context: String
        /// Alternate name of the contract in this context.
        public let name: String
    }

    /// A language available for a contract.
    public struct ContractLanguage: Codable, Sendable {
        /// Technical name of the contract this language belongs to.
        public let contract: String
        /// True if this is the default language for the contract.
        public let defaultLanguage: Bool
        /// Unique ID of this contract language entry.
        public let id: Double
        /// Locale code for this language, for example `"fr-FR"`.
        public let locale: String
    }

    /// A named feature flag for a contract.
    public struct Feature: Codable, Sendable {
        /// Description of the feature.
        public let description: String?
        /// Name of the feature.
        public let name: String?
    }
}
