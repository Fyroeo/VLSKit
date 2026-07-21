import Foundation

/// A latitude and longitude pair.
///
/// `Station`, `Contract`, and other types share this shape.
public struct Coordinate: Codable, Sendable, Equatable {
    /// Latitude, in degrees.
    public let latitude: Double
    /// Longitude, in degrees.
    public let longitude: Double

    /// Create a coordinate.
    /// - Parameters:
    ///   - latitude: Latitude, in degrees.
    ///   - longitude: Longitude, in degrees.
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// A single point of a rider's GPS trace.
///
/// The app uploads a list of these points to
/// `POST /contracts/{contract}/accounts/{accountId}/trips/{tripId}/route`.
public struct TripPoint: Codable, Sendable, Equatable {
    /// Latitude, in degrees.
    public let latitude: Double
    /// Longitude, in degrees.
    public let longitude: Double
    /// Elevation, in meters.
    public let elevation: Double

    /// Create a trip point.
    /// - Parameters:
    ///   - latitude: Latitude, in degrees.
    ///   - longitude: Longitude, in degrees.
    ///   - elevation: Elevation, in meters.
    public init(latitude: Double, longitude: Double, elevation: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
}

/// GeoJSON payload returned by the trip route endpoint.
///
/// This type models the payload loosely. The shape of a GeoJSON object
/// changes with its geometry type. Decode `type` and `coordinates` yourself
/// for anything more specific than checking if a route exists.
public struct GeoJSON: Codable, Sendable {
    /// GeoJSON geometry type, for example `"LineString"`.
    public let type: String
    /// Raw coordinate data. Decode this yourself based on `type`.
    public let coordinates: JSONValue?
}

/// A JSON value box for a field whose exact shape is unknown.
///
/// Examples of such fields are nested CMS content and GeoJSON geometry.
/// This type decodes any JSON value without failing, so you can inspect the
/// result and tighten the model later if you need to.
public enum JSONValue: Codable, Sendable {
    /// A JSON string value.
    case string(String)
    /// A JSON number value.
    case number(Double)
    /// A JSON boolean value.
    case bool(Bool)
    /// A JSON object, as a dictionary of keys to values.
    case object([String: JSONValue])
    /// A JSON array of values.
    case array([JSONValue])
    /// A JSON null value.
    case null

    /// Create a JSON value from a decoder.
    ///
    /// This initializer tries each JSON type in turn. It falls back to
    /// `.null` if no type matches, so it never fails.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: A decoding error if the underlying container cannot be read.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .null
        }
    }

    /// Write this JSON value to an encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An encoding error if the underlying container cannot be written.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}
