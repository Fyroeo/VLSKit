import Foundation

// MARK: - Parks

/// A bike parking spot.
/// The API returns this type from `GET /contracts/{contract}/parkings` (`ri.h`).
/// This type is distinct from `OpenDataPark`, the car park type on the public API.
public struct Park: Codable, Sendable, Identifiable {
    /// The unique identifier of the park.
    public let id: UUID
    /// The name of the park.
    public let name: String
    /// The number of the park within its contract.
    public let number: Int
    /// The date when the park started operating.
    public let startDate: Date
    /// True if the park has sensors that report live occupancy.
    public let hasSensors: Bool
    /// The street address of the park. This value can be absent.
    public let address: String?
    /// The postal code of the park. This value can be absent.
    public let zipCode: String?
    /// The city of the park. This value can be absent.
    public let city: String?
    /// The latitude of the park, in degrees. This value can be absent.
    public let latitude: Double?
    /// The longitude of the park, in degrees. This value can be absent.
    public let longitude: Double?
    /// How a user gets access to the park. This value can be absent.
    public let accessType: AccessType?
    /// The type of locker at the park. This value can be absent.
    public let lockerType: LockerType?
    /// The open or closed state of the park. This value can be absent.
    public let status: Status?
    /// The total capacity of the park. This value can be absent.
    public let capacity: Int?
    /// True if the park has electric bike charging support. This value can be absent.
    public let hasElectricSupport: Bool?
    /// The number of electric bike charging spots. This value can be absent.
    public let electricCapacity: Int?
    /// True if the park has surveillance. This value can be absent.
    public let hasSurveillance: Bool?
    /// True if the park has a staffed physical reception. The JSON key is `physicalReception`.
    /// This value can be absent.
    public let hasPhysicalReception: Bool?
    /// True if the park is free to use. This value can be absent.
    public let isFree: Bool?
    /// True if the park is off the street, for example in a dedicated lot. This value can be absent.
    public let isOffStreet: Bool?
    /// The opening hours of the park, as free text. This value can be absent.
    public let openingHours: String?
    /// The name of the park manager. This value can be absent.
    public let managerName: String?
    /// Free-text comments about the park. This value can be absent.
    public let comments: String?
    /// The list of sensor tags used to identify the park's sensors. This value can be absent.
    public let sensorsTags: [String]?
    /// The identifier of the gate that controls entry to the park. This value can be absent.
    public let gateId: String?
    /// True if the park has a controlled opening mechanism, for example a gate.
    public let hasControlledOpening: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, number, startDate, hasSensors, address, zipCode, city, latitude, longitude
        case accessType, lockerType, status, capacity, hasElectricSupport, electricCapacity, hasSurveillance
        case hasPhysicalReception = "physicalReception"
        case isFree, isOffStreet, openingHours, managerName, comments, sensorsTags, gateId, hasControlledOpening
    }

    /// How a user gets access to a park.
    public enum AccessType: String, Codable, Sendable {
        /// Anyone can enter without a check.
        case freeAccess = "FREE_ACCESS"
        /// Entry needs a security check, for example a badge.
        case secured = "SECURED"
    }

    /// The type of locker at a park.
    public enum LockerType: String, Codable, Sendable {
        /// A single, individual locker.
        case single = "SINGLE"
        /// A shared, collective locker area.
        case collective = "COLLECTIVE"
    }

    /// The open or closed state of a park.
    public enum Status: String, Codable, Sendable {
        case open = "OPEN"
        case closed = "CLOSED"
        case inactive = "INACTIVE"
    }
}
