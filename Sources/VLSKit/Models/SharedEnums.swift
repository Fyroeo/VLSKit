import Foundation

// MARK: - Platform Enums

/// The app's channel filter for several endpoints, for example offer groups, renewal
/// offers, and sales.
///
/// This type is not the same as `DevicePlatform` (push registration) or
/// `SponsoringPlatform` (sponsoring). The backend defines three separate enums, and each
/// one uses the name "Platform". Do not use one enum in place of another. At least one
/// call site fails if the code sends the wrong enum's value.
public enum Platform: String, Codable, Sendable {
    case web = "WEB"
    case mobile = "MOBILE"
    case terminal = "TERMINAL"
    case `private` = "PRIVATE"
}

/// The platform for a push-notification device registration.
///
/// Only the `Device` type uses this enum.
public enum DevicePlatform: String, Codable, Sendable {
    case android = "ANDROID"
    case ios = "IOS"
}

/// The platform for a `Sponsoring` record.
///
/// Only the `Sponsoring` type uses this enum. This enum has 3 of the 4 cases in
/// `Platform`. It has no `private` case.
public enum SponsoringPlatform: String, Codable, Sendable {
    case web = "WEB"
    case mobile = "MOBILE"
    case terminal = "TERMINAL"
}

// MARK: - Payment Types

/// A payment method code from the backend.
///
/// The types `Offer`, `Badge`, `PackageInfo`, `PackageOptions`, `OfferSupplements`, and
/// `Transaction` reference this type. The full list of possible values is not known.
/// This type stores the raw string instead of decoding to a fixed enum. This design
/// avoids a decode failure when the server sends an unlisted value.
public struct PaymentMethod: RawRepresentable, Codable, Sendable, Equatable, ExpressibleByStringLiteral {
    /// The raw payment-method string sent by the backend, for example "CB".
    public let rawValue: String

    /// Create a payment method from its raw backend string.
    /// - Parameter rawValue: The raw payment-method string.
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Create a payment method from a string literal.
    /// - Parameter value: The raw payment-method string.
    public init(stringLiteral value: String) { self.rawValue = value }

    /// The "CB" payment method value.
    public static let cb: PaymentMethod = "CB"
}

/// How often the backend charges a payment.
///
/// The full list of possible values is not known. This type decodes the known values
/// below. It falls back to `.other` for any unrecognized value instead of failing to
/// decode.
public enum PaymentFrequency: Codable, Sendable, Equatable {
    /// A single, one-time payment.
    case oneshot
    /// A recurring monthly payment.
    case monthly
    /// A payment frequency this type does not recognize. Holds the raw backend string.
    case other(String)

    /// Create a payment frequency by decoding it from the backend response.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the underlying value is not a string.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "ONESHOT": self = .oneshot
        case "MONTHLY": self = .monthly
        default: self = .other(raw)
        }
    }

    /// Encode this payment frequency back to its raw backend string.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if the underlying container cannot be encoded.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .oneshot: try container.encode("ONESHOT")
        case .monthly: try container.encode("MONTHLY")
        case .other(let raw): try container.encode(raw)
        }
    }
}

/// Where a customer buys something, in an offer supplement or an option.
///
/// Offer supplements and options share this type. Split it into two separate types if
/// you find a call site where the two actually diverge.
public enum PaymentPlace: String, Codable, Sendable {
    case shop = "SHOP"
    case online = "ONLINE"
}
