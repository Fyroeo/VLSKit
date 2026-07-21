import Foundation

// MARK: - Open Data Stations

/// A bike-share station, from the public JCDecaux open data API.
/// The API returns this type from `GET https://api.jcdecaux.com/vls/v3/stations[/{id}]`.
///
/// **Note**: JCDecaux's public developer documentation historically describes a flatter
/// schema than the nested shape modeled here. The flatter schema uses plain integers for
/// `bike_stands`, `available_bike_stands`, and `available_bikes`. If a live response does
/// not match this nested shape, decoding fails loudly instead of silently mapping the
/// wrong fields. Verify this shape against a live response before you rely on it for a
/// public client.
public struct OpenDataStation: Codable, Sendable, Identifiable {
    /// The station number, used as the stable identifier.
    public var id: Int64 { number }
    /// The number of the station within its contract.
    public let number: Int64
    /// The name of the contract (bike-share network) that owns this station.
    public let contractName: String
    /// The name of the station. This value can be absent.
    public let name: String?
    /// The street address of the station. This value can be absent.
    public let address: String?
    /// The geographic position of the station. This value can be absent.
    public let position: OpenDataPosition?
    /// True if the station accepts card payment. This value can be absent.
    public let isBanking: Bool?
    /// True if the station is a bonus station. This value can be absent.
    public let isBonus: Bool?
    /// The open or closed state of the station. This value can be absent.
    public let status: Status?
    /// The date and time of the last update to the station data. This value can be absent.
    public let lastUpdate: Date?
    /// True if the station currently reports live data. This value can be absent.
    public let isConnected: Bool?
    /// True if the station has an overflow area for extra bikes.
    public let hasOverflow: Bool
    /// The physical outline of the station, as a list of positions. This value can be absent.
    public let shape: Shape?
    /// The total stand availability across the main area and any overflow area.
    public let totalStands: Stands
    /// The stand availability in the main station area.
    public let mainStands: Stands
    /// The stand availability in the overflow area. This value can be absent.
    public let overflowStands: Stands?

    enum CodingKeys: String, CodingKey {
        case number, contractName, name, address, position
        case isBanking = "banking"
        case isBonus = "bonus"
        case status
        case lastUpdate = "last_update"
        case isConnected = "connected"
        case hasOverflow = "overflow"
        case shape, totalStands, mainStands, overflowStands
    }

    /// The open or closed state of a station.
    public enum Status: String, Codable, Sendable {
        case open = "OPEN"
        case closed = "CLOSED"
    }

    /// The physical outline of a station, as a list of geographic positions.
    public struct Shape: Codable, Sendable {
        /// The ordered list of positions that form the outline of the station.
        public let vertices: [OpenDataPosition]
    }

    /// A count of available stands and bikes, together with total capacity.
    public struct Stands: Codable, Sendable {
        /// The current breakdown of free stands and available bikes.
        public let availabilities: Availability
        /// The total number of stands in this area.
        public let capacity: Int
    }

    /// The current count of free stands and available bikes at a station.
    /// This type follows the private `Station.Availability` shape by analogy,
    /// because the API uses the same `stands`/`bikes` breakdown pattern in both places.
    /// Verify this shape against a live response.
    public struct Availability: Codable, Sendable {
        /// The number of free stands.
        public let stands: Int
        /// The breakdown of available bikes, for example by mechanical and electric type.
        public let bikes: Station.BikesAvailability
    }
}

/// A geographic position, as a latitude and longitude pair.
public struct OpenDataPosition: Codable, Sendable {
    /// The latitude, in degrees.
    public let latitude: Double
    /// The longitude, in degrees.
    public let longitude: Double
}

// MARK: - Open Data Parks

/// A car park, from the public JCDecaux open data API.
/// The API returns this type from
/// `GET https://api.jcdecaux.com/parking/v1/contracts/{contract}/parks`.
public struct OpenDataPark: Codable, Sendable {
    /// The name of the contract that owns this park.
    public let contractName: String
    /// The name of the park.
    public let name: String
    /// The number of the park within its contract.
    public let number: Int
    /// The open or closed state of the park. This value can be absent.
    public let status: Status?
    /// The geographic position of the park. This value can be absent.
    public let position: OpenDataPosition?
    /// How a user gets access to the park, as plain text.
    /// The private `Park.AccessType` enum models the same concept with fixed cases.
    /// This value can be absent.
    public let accessType: String?
    /// The type of locker at the park, as plain text.
    /// The private `Park.LockerType` enum models the same concept with fixed cases.
    /// This value can be absent.
    public let lockerType: String?
    /// True if the park has surveillance.
    public let hasSurveillance: Bool
    /// True if the park is free to use.
    public let isFree: Bool
    /// The street address of the park. This value can be absent.
    public let address: String?
    /// The postal code of the park. This value can be absent.
    public let zipCode: String?
    /// The city of the park. This value can be absent.
    public let city: String?
    /// True if the park is off the street, for example in a dedicated lot. This value can be absent.
    public let isOffStreet: Bool?
    /// True if the park has electric bike charging support. This value can be absent.
    public let hasElectricSupport: Bool?
    /// True if the park has a staffed physical reception. This value can be absent.
    public let hasPhysicalReception: Bool?
    /// The total capacity of the park. This value can be absent.
    public let capacity: Int?
    /// The number of currently available spots. This value can be absent.
    public let availableSpots: Int?

    /// The open or closed state of a park.
    public enum Status: String, Codable, Sendable {
        case open = "OPEN"
        case closed = "CLOSED"
        case inactive = "INACTIVE"
    }
}
