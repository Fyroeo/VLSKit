import Foundation

// MARK: - GBFS feed wrapper

/// A GBFS (General Bikeshare Feed Specification) feed wrapper.
///
/// `GET /contracts/{contract}/gbfs/v3/station_information.json` and
/// `station_status.json` return this shape. These feeds do not need auth. The field
/// names on the wire use GBFS snake_case, unlike the JCDecaux camelCase endpoints.
public struct GBFSFeed<Data: Codable & Sendable>: Codable, Sendable {
    /// The GBFS specification version the feed follows, for example `3.0`.
    public let version: String
    /// The feed payload.
    public let data: Data

    enum CodingKeys: String, CodingKey {
        case version
        case data
    }
}

// MARK: - Station lists

/// The list of stations returned by the GBFS `station_information.json` feed.
public struct GBFSStationInformationList: Codable, Sendable {
    /// The stations in the feed.
    public let stations: [GBFSStationInformation]
}

/// The list of stations returned by the GBFS `station_status.json` feed.
public struct GBFSStationStatusList: Codable, Sendable {
    /// The stations in the feed.
    public let stations: [GBFSStationStatus]
}

// MARK: - Lenient station ID decoding

/// Get a station ID and normalize it to a string.
///
/// The GBFS specification defines `station_id` as a string. Some feeds send a bare
/// number instead. This method accepts either shape and returns a `String`.
/// - Parameter key: The coding key for the station ID field.
/// - Returns: The station ID as a string.
/// - Throws: `DecodingError.typeMismatch` if the value is neither a string nor an integer.
public extension KeyedDecodingContainer {
    func decodeLenientStationID(forKey key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) { return value }
        if let value = try? decode(Int.self, forKey: key) { return String(value) }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(codingPath: codingPath + [key], debugDescription: "station id was neither a String nor an Int")
        )
    }
}

// MARK: - Station information

/// A bike station from the GBFS `station_information.json` feed.
///
/// This type has a custom `Codable` conformance. It normalizes `station_id` through
/// `decodeLenientStationID(forKey:)` and defaults `is_bonus` to `false` when the
/// server omits the field.
public struct GBFSStationInformation: Codable, Sendable, Identifiable {
    /// The unique ID of the station, normalized to a string.
    public let id: String
    /// The name of the station, in one or more languages.
    public let name: [LocalizedName]
    /// The latitude of the station.
    public let latitude: Double
    /// The longitude of the station.
    public let longitude: Double
    /// The street address of the station. This value can be missing.
    public let address: String?
    /// The total number of docks at the station. This value can be missing.
    public let capacity: Int?
    /// The payment methods the station accepts. This value can be missing.
    public let rentalMethods: [RentalMethod]?
    /// True when the station is a bonus station. The default value is false when the
    /// server does not send this field.
    public let isBonus: Bool

    enum CodingKeys: String, CodingKey {
        case id = "station_id"
        case name
        case latitude = "lat"
        case longitude = "lon"
        case address, capacity
        case rentalMethods = "rental_methods"
        case isBonus = "is_bonus"
    }

    /// Create a station from decoded GBFS data.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: A decoding error if a required field is missing or has the wrong type.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeLenientStationID(forKey: .id)
        name = try container.decode([LocalizedName].self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        capacity = try container.decodeIfPresent(Int.self, forKey: .capacity)
        rentalMethods = try container.decodeIfPresent([RentalMethod].self, forKey: .rentalMethods)
        // Absent on some stations in production — default false when missing.
        isBonus = try container.decodeIfPresent(Bool.self, forKey: .isBonus) ?? false
    }

    /// Write the station to an encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An encoding error if a value fails to encode.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(capacity, forKey: .capacity)
        try container.encodeIfPresent(rentalMethods, forKey: .rentalMethods)
        try container.encode(isBonus, forKey: .isBonus)
    }

    /// The name of a station in one language.
    public struct LocalizedName: Codable, Sendable {
        /// The station name text.
        public let text: String
        /// The language of the text, for example `fr`.
        public let language: String
    }

    /// A payment method a station accepts.
    ///
    /// The GBFS specification defines lowercase values, for example `creditcard`, `key`,
    /// `applepay`, `androidpay`, `transitcard`, `accountnumber`, and `phone`. Only
    /// `creditcard` has been observed in practice. The `other` case keeps decoding from
    /// failing on any other value.
    public enum RentalMethod: Codable, Sendable, Equatable {
        /// The station accepts payment by credit card.
        case creditCard
        /// A rental method value the client does not recognize yet.
        case other(String)

        /// Create a rental method from a decoded string.
        /// - Parameter decoder: The decoder to read the raw value from.
        /// - Throws: A decoding error if the value is not a string.
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = raw == "creditcard" ? .creditCard : .other(raw)
        }

        /// Write the rental method to an encoder as its raw string value.
        /// - Parameter encoder: The encoder to write the value to.
        /// - Throws: An encoding error if the value fails to encode.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .creditCard: try container.encode("creditcard")
            case .other(let raw): try container.encode(raw)
            }
        }
    }
}

// MARK: - Station status

/// The live status of a bike station from the GBFS `station_status.json` feed.
///
/// This type has a custom `Codable` conformance. It normalizes `station_id` through
/// `decodeLenientStationID(forKey:)` and accepts 2 wire formats for `last_reported`.
public struct GBFSStationStatus: Codable, Sendable, Identifiable {
    /// The unique ID of the station, normalized to a string.
    public let id: String
    /// The number of vehicles available to rent at the station.
    public let numVehiclesAvailable: Int
    /// The count of available vehicles, broken down by vehicle type.
    public let vehicleTypesAvailable: [VehicleAvailability]
    /// The number of disabled vehicles at the station. This value can be missing.
    public let numVehiclesDisabled: Int?
    /// The number of empty docks available at the station.
    public let numDocksAvailable: Int
    /// The number of disabled docks at the station. This value can be missing.
    public let numDocksDisabled: Int?
    /// True when the station is installed and in service.
    public let isInstalled: Bool
    /// True when the station currently allows bike rentals.
    public let isRenting: Bool
    /// True when the station currently allows bike returns.
    public let isReturning: Bool
    /// The date and time the station last reported its status.
    ///
    /// The GBFS specification defines this field as Unix epoch seconds. Some feeds send
    /// an ISO 8601 string instead. The decoder accepts either format.
    public let lastReported: Date

    enum CodingKeys: String, CodingKey {
        case id = "station_id"
        case numVehiclesAvailable = "num_vehicles_available"
        case vehicleTypesAvailable = "vehicle_types_available"
        case numVehiclesDisabled = "num_vehicles_disabled"
        case numDocksAvailable = "num_docks_available"
        case numDocksDisabled = "num_docks_disabled"
        case isInstalled = "is_installed"
        case isRenting = "is_renting"
        case isReturning = "is_returning"
        case lastReported = "last_reported"
    }

    /// Create a station status from decoded GBFS data.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: A decoding error if a required field is missing or has an
    ///   unrecognized format.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeLenientStationID(forKey: .id)
        numVehiclesAvailable = try container.decode(Int.self, forKey: .numVehiclesAvailable)
        vehicleTypesAvailable = try container.decode([VehicleAvailability].self, forKey: .vehicleTypesAvailable)
        numVehiclesDisabled = try container.decodeIfPresent(Int.self, forKey: .numVehiclesDisabled)
        numDocksAvailable = try container.decode(Int.self, forKey: .numDocksAvailable)
        numDocksDisabled = try container.decodeIfPresent(Int.self, forKey: .numDocksDisabled)
        isInstalled = try container.decode(Bool.self, forKey: .isInstalled)
        isRenting = try container.decode(Bool.self, forKey: .isRenting)
        isReturning = try container.decode(Bool.self, forKey: .isReturning)
        // GBFS spec says Unix epoch seconds, but some feeds send an ISO-8601 string
        // instead — accept either.
        if let epochSeconds = try? container.decode(Double.self, forKey: .lastReported) {
            lastReported = Date(timeIntervalSince1970: epochSeconds)
        } else {
            let raw = try container.decode(String.self, forKey: .lastReported)
            if let date = FlexibleDateDecoding.isoWithFractional.date(from: raw) ?? FlexibleDateDecoding.iso.date(from: raw) {
                lastReported = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .lastReported, in: container, debugDescription: "Unrecognized last_reported format: \(raw)")
            }
        }
    }

    /// Write the station status to an encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An encoding error if a value fails to encode.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(numVehiclesAvailable, forKey: .numVehiclesAvailable)
        try container.encode(vehicleTypesAvailable, forKey: .vehicleTypesAvailable)
        try container.encodeIfPresent(numVehiclesDisabled, forKey: .numVehiclesDisabled)
        try container.encode(numDocksAvailable, forKey: .numDocksAvailable)
        try container.encodeIfPresent(numDocksDisabled, forKey: .numDocksDisabled)
        try container.encode(isInstalled, forKey: .isInstalled)
        try container.encode(isRenting, forKey: .isRenting)
        try container.encode(isReturning, forKey: .isReturning)
        try container.encode(lastReported.timeIntervalSince1970, forKey: .lastReported)
    }

    /// The count of available vehicles of one type at a station.
    public struct VehicleAvailability: Codable, Sendable {
        /// The type of vehicle, for example mechanical or electrical.
        public let vehicleTypeID: VehicleType
        /// The number of vehicles of this type available at the station.
        public let count: Int

        enum CodingKeys: String, CodingKey {
            case vehicleTypeID = "vehicle_type_id"
            case count
        }
    }

    /// A type of vehicle a station can hold.
    ///
    /// The wire value is lowercase, for example `mechanical` or `electrical`, like
    /// `RentalMethod`. The `other` case handles vehicle types JCDecaux may add later.
    /// The private API already tells apart bikes with an internal battery from bikes
    /// with a removable battery.
    public enum VehicleType: Codable, Sendable, Equatable {
        /// A bike with no electric motor.
        case mechanical
        /// A bike with an electric motor.
        case electrical
        /// A vehicle type value the client does not recognize yet.
        case other(String)

        /// Create a vehicle type from a decoded string.
        /// - Parameter decoder: The decoder to read the raw value from.
        /// - Throws: A decoding error if the value is not a string.
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            switch raw {
            case "mechanical": self = .mechanical
            case "electrical": self = .electrical
            default: self = .other(raw)
            }
        }

        /// Write the vehicle type to an encoder as its raw string value.
        /// - Parameter encoder: The encoder to write the value to.
        /// - Throws: An encoding error if the value fails to encode.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .mechanical: try container.encode("mechanical")
            case .electrical: try container.encode("electrical")
            case .other(let raw): try container.encode(raw)
            }
        }
    }
}
