import Foundation

// MARK: - Flexible Date Decoding

/// Date parsing logic shared by the JSON encoder and decoder, tuned to match the
/// backend's Jackson serialization.
///
/// The backend does not use one consistent date format. This decoder tries several
/// formats in order: ISO-8601 with fractional seconds, plain ISO-8601, then epoch
/// milliseconds. If you see a decoding failure on a `Date` field, capture the raw
/// response and add a new format to `FlexibleDateDecoding` below.
enum FlexibleDateDecoding {
    static let isoWithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let localNoTimezoneFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// A calendar date with no time part, for example `"2003-08-07"`. This is the shape
    /// of `Account.birthDate`.
    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Parses a timestamp with no time zone marker and fractional seconds of any length,
    /// for example microseconds or nanoseconds.
    ///
    /// `ISO8601DateFormatter` rejects this shape. The kit sees this shape in the `bikes`
    /// endpoint fields `createdAt`, `updatedAt`, and `lastDataFrameDate`, and in
    /// `rating.lastRatingDateTime`. This method assumes UTC, the same zone as every other
    /// timestamp in this API.
    /// - Parameter raw: Raw timestamp string to parse.
    /// - Returns: The parsed date, or `nil` if `raw` does not match this shape.
    private static func parseLocalNoTimezoneDate(_ raw: String) -> Date? {
        let parts = raw.split(separator: ".", maxSplits: 1)
        guard let baseDate = localNoTimezoneFormatter.date(from: String(parts[0])) else { return nil }
        guard parts.count > 1, let fraction = Double("0.\(parts[1])") else { return baseDate }
        return baseDate.addingTimeInterval(fraction)
    }

    static func decode(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            if let date = isoWithFractional.date(from: string) { return date }
            if let date = iso.date(from: string) { return date }
            if let date = parseLocalNoTimezoneDate(string) { return date }
            if let date = dateOnlyFormatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date string: \(string)")
        }
        if let millis = try? container.decode(Double.self) {
            return Date(timeIntervalSince1970: millis / 1000)
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date was neither a string nor a number")
    }

    static func encode(_ date: Date, to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(isoWithFractional.string(from: date))
    }
}

// MARK: - JSON Decoder

extension JSONDecoder {
    /// The shared decoder for VLS and Cyclocity JSON responses.
    ///
    /// This decoder decodes `Date` values with the flexible logic in
    /// `FlexibleDateDecoding`.
    public static var vls: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            try FlexibleDateDecoding.decode(decoder)
        }
        return decoder
    }
}

// MARK: - JSON Encoder

extension JSONEncoder {
    /// The shared encoder for VLS and Cyclocity JSON request bodies.
    ///
    /// This encoder encodes `Date` values with the ISO-8601 format that includes
    /// fractional seconds.
    public static var vls: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            try FlexibleDateDecoding.encode(date, to: encoder)
        }
        return encoder
    }
}
