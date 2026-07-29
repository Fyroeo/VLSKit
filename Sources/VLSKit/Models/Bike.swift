import Foundation

/// A single bike on a contract.
///
/// This is the response body for `GET /contracts/{contract}/bikes?number=`
/// and for `GET /contracts/{contract}/bikes?stationNumber=`.
public struct Bike: Codable, Sendable, Identifiable {
    // MARK: - Identity and status

    /// Unique ID of the bike.
    public let id: UUID
    /// Number of the bike, as shown to the rider.
    public let number: Int
    /// Name of the contract that owns this bike.
    public let contractName: String
    /// Type of the bike, mechanical or electrical. See `BikeType`.
    public let type: BikeType
    /// ID of the bike's frame.
    public let frameId: String
    /// Number of the station where the bike is docked. This value can be missing.
    public let stationNumber: Int?
    /// Number of the stand where the bike is docked, if any.
    public let standNumber: Int?
    /// Current status of the bike. See `Status`.
    public let status: Status
    /// French label for `status`, meant for display, for example `"Accroché"`
    /// for `AVAILABLE`.
    public let statusLabel: String

    // MARK: - Battery and lock

    /// True if this bike has a propulsion battery. This is true for electric bikes.
    public let hasBattery: Bool
    /// Propulsion battery details for this bike. This field is present only
    /// when `hasBattery` is true, on electric bikes.
    public let battery: Battery?
    /// True if this bike has a lock.
    public let hasLock: Bool
    /// Lock details for this bike. The wire shape of this field is unknown.
    /// No observed bike had `hasLock` set to true. The decoder accepts any
    /// JSON value here.
    public let lock: JSONValue?

    // MARK: - Rating and record metadata

    /// Rider ratings for this bike. See `Rating`.
    public let rating: Rating
    /// True if the bike passed a check. The exact check this refers to is unknown.
    public let checked: Bool
    /// Date and time the server created this bike record.
    public let createdAt: Date
    /// Date and time the server last updated this bike record.
    public let updatedAt: Date
    /// Last time the bike's onboard electronics sent data to the server.
    public let lastDataFrameDate: Date?

    // MARK: - Firmware and hardware versions

    /// Software version of the bike's top controller.
    public let bikeTopSwVersion: String?
    /// Hardware version of the bike's top controller.
    public let bikeTopHwVersion: String?
    /// Software version of the motor controller. This field applies to
    /// electric bikes only.
    public let motorControllerSwVersion: String?
    /// Hardware version of the motor controller. This field applies to
    /// electric bikes only.
    public let motorControllerHwVersion: String?
    /// Software version of the firmware that runs the battery management
    /// system. This field applies to electric bikes only.
    public let bmsSwVersion: String?
    /// Software version of the bike's zed subsystem. The exact meaning of
    /// `zed` is unknown.
    public let zedSwVersion: String?
    /// Voltage of the bike's low-power lock and tracker battery, in
    /// millivolts. This field applies to mechanical bikes only. It is a
    /// separate battery from the electric propulsion battery in `battery`.
    public let bikeBatteryMv: Int?

    // MARK: - Reservation and service history (vnd.bikes.v4)

    /// True if the bike is currently held by a booking. Present on `v4`; `nil` on the
    /// older `v3` payload.
    public let isReserved: Bool?
    /// Backend-defined energy-source code. Only `0` has been observed. `nil` on `v3`.
    public let energySource: Int?
    /// Time of the bike's last completed trip, if the server reported one.
    public let lastTripDateTime: Date?
    /// Time of the bike's last field control, if any.
    public let lastControlDateTime: Date?
    /// Time of the bike's last workshop revision, if any.
    public let lastRevisionDateTime: Date?
    /// When the bike is next due for a workshop revision.
    public let nextReview: Date?
    /// When the bike is next due for a field control.
    public let nextCheck: Date?

    // MARK: - Nested types

    /// Current status of a bike.
    public enum Status: String, Codable, Sendable {
        /// The bike is new and is waiting to bind to its onboard electronics.
        case waitingForBinding = "WAITING_FOR_BINDING"
        /// The bike is in a test period before it enters service.
        case tested = "TESTED"
        /// The bike passed validation and is ready to enter service.
        case validated = "VALIDATED"
        /// The bike is docked at a stand and ready to rent.
        case available = "AVAILABLE"
        /// The bike is rented to a rider.
        case rented = "RENTED"
        /// The bike is rented under a short-term, minute-based drop-off state.
        case rentedMinuteDepose = "RENTED_MINUTE_DEPOSE"
        /// The bike is blocked and not available to rent.
        case blocked = "BLOCKED"
        /// The bike is reported stolen.
        case stolen = "STOLEN"
        /// The bike is out of service for maintenance.
        case maintenance = "MAINTENANCE"
        /// The server cannot reach the bike's onboard electronics.
        case unreachable = "UNREACHABLE"
        /// The bike record is deleted.
        case deleted = "DELETED"
        /// The bike's onboard electronics are powered off.
        case poweredOff = "POWERED_OFF"
        /// The bike is reserved for a rider through a booking.
        case reserved = "RESERVED"
        /// The status of the bike is not known.
        case unknown = "UNKNOWN"
    }

    /// Propulsion battery details for an electric bike.
    public struct Battery: Codable, Sendable {
        /// Charge level of the battery, from 0 to 100.
        public let percentage: Int
        /// Kind of battery. The only value observed on the wire is
        /// `INTERNAL`. A removable battery might use the value `REMOVABLE`,
        /// by analogy with the internal and removable battery types on
        /// `Station`, but this value is unknown. The type stays a `String`,
        /// not an enum, since the full set of values is unknown.
        public let type: String
        /// Battery level shown as a whole number from 0 to 4 bars. This
        /// number is roughly `percentage` divided by 20.
        public let level: Int
    }

    /// Rider ratings summary for a bike.
    public struct Rating: Codable, Sendable {
        /// Percentage of positive ratings, from 0 to 100. This field is
        /// `nil` on a bike with no ratings yet. The wire payload sends an
        /// empty object, `rating: {}`, in that case. The decoder reads this
        /// as `nil` instead of failing.
        public let value: Double?
        /// Number of ratings received. This field is 0 when the wire
        /// payload omits it.
        public let count: Int
        /// Date and time of the most recent rating, if any.
        public let lastRatingDateTime: Date?

        enum CodingKeys: String, CodingKey {
            case value, count, lastRatingDateTime
        }

        /// Create a rating from a decoder.
        ///
        /// This initializer reads a missing `count` value as 0, so it does
        /// not fail when a bike has no ratings yet.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: A decoding error if the payload does not match the expected shape.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            value = try container.decodeIfPresent(Double.self, forKey: .value)
            count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
            lastRatingDateTime = try container.decodeIfPresent(Date.self, forKey: .lastRatingDateTime)
        }
    }
}

// `BikeType` (MECHANICAL/ELECTRICAL/UNKNOWN, uppercase) is declared in Trip.swift and
// shared with this model.

/// Request body for `POST .../trips/{tripId}/rate`.
///
/// The app sends this request after a ride, as the rider's rating prompt.
public struct Rate: Codable, Sendable {
    /// ID of the bike used on the ride.
    public let bikeId: Int
    /// True if the rider recommends this bike.
    public let recommended: Bool
    /// Name of the contract for the ride.
    public let contract: String
    /// Code that identifies the ride's charge record (CDR), if the ride has one.
    public let cdrCode: String?

    /// Create a bike rating.
    /// - Parameters:
    ///   - bikeId: ID of the bike used on the ride.
    ///   - recommended: True if the rider recommends this bike.
    ///   - contract: Name of the contract for the ride.
    ///   - cdrCode: Code that identifies the ride's charge record. The default is `nil`.
    public init(bikeId: Int, recommended: Bool, contract: String, cdrCode: String? = nil) {
        self.bikeId = bikeId
        self.recommended = recommended
        self.contract = contract
        self.cdrCode = cdrCode
    }
}
