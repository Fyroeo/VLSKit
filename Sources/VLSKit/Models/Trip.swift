import Foundation

// MARK: - Trip

/// A user's bike trip.
///
/// The endpoints `GET /contracts/{contract}/accounts/{accountId}/trips` and
/// `GET /contracts/{contract}/accounts/{accountId}/trips/ongoing` return this type.
///
/// Every property is optional. This design avoids a guess about which fields the
/// backend always sends.
public struct Trip: Codable, Sendable, Identifiable {
    /// The trip's unique identifier. This value can be absent.
    public let id: UUID?
    /// The trip's reference in the movement-tracking system, if the backend sent one.
    public let movementRef: String?
    /// The identifier of the subscription used for this trip, if the backend sent one.
    public let subscriptionId: UUID?
    /// The reference of the subscription used for this trip, if the backend sent one.
    public let subscriptionRef: String?
    /// The name of the contract (bike-share network) this trip belongs to, if the
    /// backend sent one.
    public let contractName: String?
    /// The email address of the account that made this trip, if the backend sent one.
    public let accountEmail: String?
    /// The trip's current status, if the backend sent one.
    public let status: Status?
    /// The number of the bike used for this trip, if the backend sent one.
    public let bikeNumber: Int?
    /// The date and time the trip started, if the backend sent one.
    public let startDateTime: Date?
    /// The number of the station where the trip started, if the backend sent one.
    public let startStation: Int?
    /// The name of the station where the trip started, if the backend sent one.
    public let startStationName: String?
    /// The date and time the trip ended, if the backend sent one.
    public let endDateTime: Date?
    /// The number of the station where the trip ended, if the backend sent one.
    public let endStation: Int?
    /// The name of the station where the trip ended, if the backend sent one.
    public let endStationName: String?
    /// The trip's duration, if the backend sent one.
    public let duration: Int?
    /// The number of rewards the rider earned from this trip, if the backend sent one.
    public let rewardsEarned: Int?
    /// The number of rewards the rider spent on this trip, if the backend sent one.
    public let rewardsSpent: Int?
    /// The trip's price, if the backend sent one.
    public let price: Int64?
    /// The trip's reduced price, if the backend sent one.
    public let reducedPrice: Int64?
    /// The discount applied to this trip, if the backend sent one.
    public let discount: Int64?
    /// True if this trip is under dispute, if the backend sent a value.
    public let litigious: Bool?
    /// True if this trip is a special trip, if the backend sent a value.
    public let isSpecial: Bool?
    /// True if the rider already rated this trip, if the backend sent a value.
    public let isRated: Bool?
    /// A token associated with this trip, if the backend sent one.
    public let token: String?
    /// The bike's propulsion type for this trip, if known.
    ///
    /// Trip-history responses send this value as a plain `Int`. The value `0` means
    /// mechanical, and any other value means electrical. This differs from `Bike.type`,
    /// which uses the strings "MECHANICAL" and "ELECTRICAL". A direct decode as
    /// `BikeType` fails and breaks the whole trip-list decode. This field's decoder reads
    /// either shape and normalizes the result to `BikeType`.
    public let bikeType: BikeType?
    /// The count of electrical-bike trips, if the backend sent one.
    public let elecTripsNb: Int?
    /// The maximum number of trips allowed before an overcharge applies, if the backend
    /// sent one.
    public let overchargeMaxTrips: Int?
    /// The overcharge amount, if the backend sent one.
    public let overchargeAmount: Int64?

    /// A trip's status code from the backend.
    public enum Status: String, Codable, Sendable {
        /// The rider requested the trip, but it has not started yet.
        case requested = "REQUESTED"
        /// The trip is in progress.
        case started = "STARTED"
        /// The rider ended the trip normally.
        case finished = "FINISHED"
        /// The backend rejected the trip request.
        case rejected = "REJECTED"
        /// The trip request timed out.
        case timeout = "TIMEOUT"
        /// The trip is paused.
        case paused = "PAUSED"
        /// The backend ended the trip automatically.
        case autoFinished = "AUTO_FINISHED"
        /// The trip ended in an error.
        case error = "ERROR"
        /// The trip has a warning condition.
        case warning = "WARNING"
        /// The backend reversed the trip.
        case reversed = "REVERSED"
    }

    enum CodingKeys: String, CodingKey {
        case id, movementRef, subscriptionId, subscriptionRef, contractName, accountEmail,
             status, bikeNumber, startDateTime, startStation, startStationName, endDateTime,
             endStation, endStationName, duration, rewardsEarned, rewardsSpent, price,
             reducedPrice, discount, litigious, isSpecial, isRated, token, bikeType, elecTripsNb,
             overchargeMaxTrips, overchargeAmount
    }

    /// Create a trip by decoding it from the backend response.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the response format is invalid.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        movementRef = try container.decodeIfPresent(String.self, forKey: .movementRef)
        subscriptionId = try container.decodeIfPresent(UUID.self, forKey: .subscriptionId)
        subscriptionRef = try container.decodeIfPresent(String.self, forKey: .subscriptionRef)
        contractName = try container.decodeIfPresent(String.self, forKey: .contractName)
        accountEmail = try container.decodeIfPresent(String.self, forKey: .accountEmail)
        status = try container.decodeIfPresent(Status.self, forKey: .status)
        bikeNumber = try container.decodeIfPresent(Int.self, forKey: .bikeNumber)
        startDateTime = try container.decodeIfPresent(Date.self, forKey: .startDateTime)
        startStation = try container.decodeIfPresent(Int.self, forKey: .startStation)
        startStationName = try container.decodeIfPresent(String.self, forKey: .startStationName)
        endDateTime = try container.decodeIfPresent(Date.self, forKey: .endDateTime)
        endStation = try container.decodeIfPresent(Int.self, forKey: .endStation)
        endStationName = try container.decodeIfPresent(String.self, forKey: .endStationName)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        rewardsEarned = try container.decodeIfPresent(Int.self, forKey: .rewardsEarned)
        rewardsSpent = try container.decodeIfPresent(Int.self, forKey: .rewardsSpent)
        price = try container.decodeIfPresent(Int64.self, forKey: .price)
        reducedPrice = try container.decodeIfPresent(Int64.self, forKey: .reducedPrice)
        discount = try container.decodeIfPresent(Int64.self, forKey: .discount)
        litigious = try container.decodeIfPresent(Bool.self, forKey: .litigious)
        isSpecial = try container.decodeIfPresent(Bool.self, forKey: .isSpecial)
        isRated = try container.decodeIfPresent(Bool.self, forKey: .isRated)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        if let stringValue = try? container.decodeIfPresent(BikeType.self, forKey: .bikeType) {
            bikeType = stringValue
        } else if let code = try? container.decodeIfPresent(Int.self, forKey: .bikeType) {
            bikeType = code == 0 ? .mechanical : .electrical
        } else {
            bikeType = nil
        }
        elecTripsNb = try container.decodeIfPresent(Int.self, forKey: .elecTripsNb)
        overchargeMaxTrips = try container.decodeIfPresent(Int.self, forKey: .overchargeMaxTrips)
        overchargeAmount = try container.decodeIfPresent(Int64.self, forKey: .overchargeAmount)
    }
}

// MARK: - Bike Type

/// A bike's propulsion type. The `bikes` endpoints also use this type.
public enum BikeType: String, Codable, Sendable {
    /// A mechanical (pedal-only) bike.
    case mechanical = "MECHANICAL"
    /// An electrical (pedal-assist) bike.
    case electrical = "ELECTRICAL"
    /// The backend did not report a known bike type.
    case unknown = "UNKNOWN"
}

// MARK: - Release Bike

/// A request body to unlock and release a bike.
///
/// The endpoint
/// `POST /contracts/{contract}/accounts/{accountId}/subscriptions/{subscriptionId}/trips`
/// takes this type as its request body.
///
/// The properties `stationNumber`, `standNumber`, and `bikeNumber` identify which bike to
/// release, and from which stand.
public struct ReleaseBikeRequest: Codable, Sendable {
    /// The number of the station to release the bike from.
    public let stationNumber: Int?
    /// The number of the stand to release the bike from.
    public let standNumber: Int?
    /// The number of the bike to release.
    public let bikeNumber: Int?
    /// The kind of device or channel making this request.
    public let typeFrom: TypeFrom?

    /// Create a release-bike request.
    /// - Parameters:
    ///   - stationNumber: The number of the station to release the bike from.
    ///   - standNumber: The number of the stand to release the bike from.
    ///   - bikeNumber: The number of the bike to release.
    ///   - typeFrom: The kind of device or channel making this request. Defaults to
    ///     `.smartphone`.
    public init(stationNumber: Int? = nil, standNumber: Int? = nil, bikeNumber: Int? = nil, typeFrom: TypeFrom? = .smartphone) {
        self.stationNumber = stationNumber
        self.standNumber = standNumber
        self.bikeNumber = bikeNumber
        self.typeFrom = typeFrom
    }

    /// The kind of device or channel that makes a release-bike request.
    public enum TypeFrom: String, Codable, Sendable {
        /// An unknown channel.
        case unknown = "UNKNOWN"
        /// A station terminal, using rider credentials.
        case stationWithCredentials = "STATION_WITH_CREDENTIALS"
        /// A station terminal, using a badge.
        case stationWithBadge = "STATION_WITH_BADGE"
        /// The web app.
        case web = "WEB"
        /// An internal system process.
        case system = "SYSTEM"
        /// The mobile app.
        case smartphone = "SMARTPHONE"
        /// A payment or access card.
        case card = "CARD"
    }
}

/// The response to a release-bike request.
public struct ReleaseBikeResponse: Codable, Sendable {
    /// The state of the unlock transaction.
    public let transactionState: TransactionState
}

// MARK: - Transaction State

/// The state of a bike-release transaction.
///
/// The backend sends the misspelled value "UNKNOW", not "UNKNOWN", for the unknown case.
/// This type keeps that exact spelling because the backend sends and expects it.
public enum TransactionState: String, Codable, Sendable {
    /// The station terminal is not connected.
    case notConnected = "NOT_CONNECTED"
    /// The transaction state is unknown. The backend sends this value as "UNKNOW".
    case unknown = "UNKNOW"
    /// The transaction has not started yet.
    case unstarted = "UNSTARTED"
    /// The transaction is in progress.
    case running = "RUNNING"
    /// The transaction finished successfully.
    case ok = "OK"
    /// The transaction failed.
    case nok = "NOK"
    /// The transaction aborted.
    case abort = "ABORT"
    /// The transaction timed out.
    case timeOut = "TIME_OUT"
}
