import Foundation

/// A bike station for the contract.
///
/// The endpoints `GET /contracts/{contract}/stations` and
/// `GET /contracts/{contract}/stations/{station_number}` return this type.
///
/// The properties `isOpen`, `isConnected`, `hasBonus`, and `hasOverflow` decode from the
/// shorter wire keys `open`, `connected`, `bonus`, and `overflow`. See `CodingKeys` for
/// the exact mapping.
public struct Station: Codable, Sendable, Identifiable {
    // MARK: Properties

    /// The station's unique identifier.
    public let id: UUID
    /// The name of the contract (bike-share network) the station belongs to.
    public let contractName: String
    /// The station's number. Riders and other endpoints use this number to identify the
    /// station.
    public let number: Int
    /// True if the station is open for use. This value decodes from the wire key `open`.
    public let isOpen: Bool
    /// True if the station is online and reports live data. This value decodes from the
    /// wire key `connected`.
    public let isConnected: Bool?
    /// The station's physical furniture identifier, if the backend sent one.
    public let furnitureId: FurnitureID?
    /// The station's display name.
    public let name: String
    /// The station's stand capacity, split into main and overflow counts.
    public let capacity: Capacity
    /// True if the station gives a reward bonus. This value decodes from the wire key
    /// `bonus`.
    public let hasBonus: Bool
    /// A description of the station, if the backend sent one.
    public let description: String?
    /// The station's coordinates, if the backend sent them.
    public let location: Coordinate?
    /// True if the station has a mapped physical shape.
    public let hasShape: Bool
    /// The station's physical shape, as a list of coordinates, if the backend sent one.
    public let shape: Shape?
    /// True if the station has an overflow area. This value decodes from the wire key
    /// `overflow`.
    public let hasOverflow: Bool
    /// The station's current bike and stand availability, if the backend sent it.
    public let availabilities: Availabilities?
    /// The date and time the backend created this record.
    public let createdAt: Date
    /// The date and time the backend last updated this record.
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, contractName, number
        case isOpen = "open"
        case isConnected = "connected"
        case furnitureId, name, capacity
        case hasBonus = "bonus"
        case description, location, hasShape, shape
        case hasOverflow = "overflow"
        case availabilities, createdAt, updatedAt
    }

    // MARK: - Nested Types

    /// The station's physical furniture identifier, made of a country, agency, and
    /// district code.
    public struct FurnitureID: Codable, Sendable {
        /// The furniture's country code.
        public let country: Int16
        /// The furniture's agency code.
        public let agency: Int16
        /// The furniture's district code.
        public let district: Int16
    }

    /// The station's stand capacity, split into a main area and an overflow area.
    public struct Capacity: Codable, Sendable {
        /// The number of stands in the station's main area.
        public let main: Int
        /// The number of stands in the station's overflow area.
        public let overflow: Int
    }

    /// The station's physical shape, as an ordered list of coordinates.
    public struct Shape: Codable, Sendable {
        /// The ordered list of coordinates that outline the station's shape.
        public let vertices: [Coordinate]
    }

    /// The station's current bike and stand availability, for the main area and the
    /// overflow area.
    public struct Availabilities: Codable, Sendable {
        /// The availability of the station's main area.
        public let main: Availability
        /// The availability of the station's overflow area.
        public let overflow: Availability
    }

    /// The number of free stands and available bikes in a station area.
    public struct Availability: Codable, Sendable {
        /// The number of free stands in this area.
        public let stands: Int
        /// The number of available bikes in this area, split by bike type.
        public let bikes: BikesAvailability
    }

    /// The number of available bikes in a station area, split by bike type.
    public struct BikesAvailability: Codable, Sendable {
        /// The number of available mechanical bikes.
        public let mechanical: Int
        /// The number of available electrical bikes.
        public let electrical: Int
        /// The number of available electrical bikes with a built-in battery.
        public let electricalInternalBattery: Int
        /// The number of available electrical bikes with a removable battery.
        public let electricalRemovableBattery: Int
    }
}
