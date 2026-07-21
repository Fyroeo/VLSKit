import Foundation

// MARK: - Subscription

/// A rider's subscription (pass) for the contract.
///
/// The endpoint `GET /contracts/{contract}/accounts/{accountId}/subscriptions` returns a
/// list of this type. The endpoint
/// `GET /contracts/{contract}/accounts/{accountId}/subscriptions/{id}` returns one value
/// of this type.
public struct Subscription: Codable, Sendable, Identifiable {
    /// The subscription's unique identifier.
    public let id: UUID
    /// The subscription's reference in an external system. This value can be absent.
    public let externalRef: String?
    /// The external system that owns `externalRef`, if any.
    public let externalSrc: ExternalSource?
    /// The subscription reference shown to the rider, if the backend sent one.
    public let displayRef: String?
    /// The email address of the account that owns this subscription.
    public let accountEmail: String
    /// The identifier of the account that owns this subscription.
    public let accountId: UUID
    /// The code of the contract (bike-share network) this subscription belongs to.
    public let contractCode: String
    /// The kind of subscription, if the backend sent one.
    public let type: SubscriptionType?
    /// The list of billing and validity periods for this subscription.
    public let periods: [SubscriptionPeriod]
    /// The identifier of the badge linked to this subscription.
    public let badgeId: Int64
    /// True if the rider cannot currently use this subscription.
    public let isLocked: Bool

    /// An external system that can own a subscription reference.
    public enum ExternalSource: String, Codable, Sendable {
        /// The Kiwi external system.
        case kiwi = "KIWI"
    }
}

/// The kind of subscription a rider holds.
public enum SubscriptionType: String, Codable, Sendable {
    /// A long-term subscription.
    case longTerm = "LT"
    /// A short-term subscription.
    case shortTerm = "ST"
    /// A subscription with the backend code "UB". The exact meaning of this code is not
    /// known.
    case ub = "UB"
    /// A parking subscription.
    case parking = "PARKING"
    /// A subscription for battery service, for example a swap or rental plan.
    case battery = "BATTERY"
}

// MARK: - Subscription Period

/// A billing and validity period within a subscription.
public struct SubscriptionPeriod: Codable, Sendable, Identifiable {
    /// The period's unique identifier.
    public let id: UUID
    /// The identifier of the subscription this period belongs to.
    public let subscriptionId: UUID
    /// The identifier of the offer that priced this period.
    public let offerId: Int64
    /// The period's renewal state, if the backend sent one.
    public let renewalDetails: RenewalDetails?
    /// The date and time this period starts.
    public let validityStart: Date
    /// The date and time this period ends.
    public let validityEnd: Date
    /// Whether this period is in the past, current, or future, if the backend sent a
    /// value.
    public let type: PeriodType?

    /// Whether a subscription period is in the past, current, or future.
    public enum PeriodType: String, Codable, Sendable {
        /// The period already ended.
        case past = "PAST"
        /// The period is active now.
        case current = "CURRENT"
        /// The period has not started yet.
        case future = "FUTURE"
    }
}

/// The renewal state for a `SubscriptionPeriod`.
///
/// The backend's JSON keys do not match their true meaning. The key `autoRenewalValue`
/// means "is auto-renewal on". The key `autoRenewalBtn` means "can the user toggle
/// auto-renewal". The key `autoRenewalMsg` means "is a renewal in progress". The key
/// `manuRenewalBtn` means "can the user start a manual renewal". This type keeps
/// accurate property names and maps them to the backend's keys through `CodingKeys`.
///
/// All four properties default to `false` when the backend response does not include
/// them.
public struct RenewalDetails: Codable, Sendable {
    /// True if auto-renewal is on for this period. Decodes from the wire key
    /// `autoRenewalValue`.
    public let isAutoRenewal: Bool
    /// True if the rider can toggle auto-renewal for this period. Decodes from the wire
    /// key `autoRenewalBtn`.
    public let canAutoRenewal: Bool
    /// True if a renewal is currently in progress for this period. Decodes from the wire
    /// key `autoRenewalMsg`.
    public let renewalInProgress: Bool
    /// True if the rider can start a manual renewal for this period. Decodes from the
    /// wire key `manuRenewalBtn`.
    public let canManualRenewal: Bool

    enum CodingKeys: String, CodingKey {
        case isAutoRenewal = "autoRenewalValue"
        case canAutoRenewal = "autoRenewalBtn"
        case renewalInProgress = "autoRenewalMsg"
        case canManualRenewal = "manuRenewalBtn"
    }

    /// Create a renewal-details value by decoding it from the backend response.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the response format is invalid.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isAutoRenewal = try container.decodeIfPresent(Bool.self, forKey: .isAutoRenewal) ?? false
        canAutoRenewal = try container.decodeIfPresent(Bool.self, forKey: .canAutoRenewal) ?? false
        renewalInProgress = try container.decodeIfPresent(Bool.self, forKey: .renewalInProgress) ?? false
        canManualRenewal = try container.decodeIfPresent(Bool.self, forKey: .canManualRenewal) ?? false
    }
}

// MARK: - Via Request

/// A request body for the "ask for 15 more minutes" feature.
///
/// The endpoint
/// `POST /contracts/{contract}/accounts/{accountId}/subscriptions/{subscriptionId}/via`
/// takes this type as its request body. JCDecaux's internal name for this feature is
/// "via".
///
/// This feature grants 15 extra free ride minutes when the rider's destination station
/// has no free docks. The backend rejects the request if the named station is not
/// actually full.
///
/// This client assumes the `stationId` property holds the same station number used
/// elsewhere, for example `Station.number` or `Booking.stationNumber`, cast to `Int64`.
/// This assumption is unverified.
public struct CreateVia: Codable, Sendable {
    /// The number of the full station the rider wants 15 more minutes to reach, cast to
    /// `Int64`.
    public let stationId: Int64?

    /// Create a "15 more minutes" request body.
    /// - Parameter stationId: The number of the full destination station, cast to
    ///   `Int64`. Pass `nil` to omit it.
    public init(stationId: Int64? = nil) {
        self.stationId = stationId
    }
}

// MARK: - Subscription Status

/// A subscription's status, as returned by the backend.
///
/// The endpoint
/// `GET /contracts/{contract}/accounts/{accountId}/subscriptions/{id}/statuses` returns
/// this type.
public struct SubscriptionStatus: Codable, Sendable {
    /// The subscription's current status, if the backend sent one.
    public let value: Status?
    /// True if the backend is locking the subscription. The backend does not always
    /// include this field.
    public let locking: Bool?

    /// A subscription status code from the backend.
    public enum Status: String, Codable, Sendable {
        /// The subscription is closed.
        case closed = "CLOSED"
        /// The rider's registration file is incomplete.
        case incompleteFile = "INCOMPLETE_FILE"
        /// The subscription has expired.
        case expired = "EXPIRED"
        /// The rider's address is missing.
        case addressEmpty = "ADDRESS_EMPTY"
        /// The subscription is not valid yet.
        case notValidYet = "NOT_VALID_YET"
        /// The rider's badge order is in progress.
        case badgeOrderInProgress = "BADGE_ORDER_IN_PROGRESS"
        /// The subscription is waiting for a badge to link to it.
        case badgeWaitingAssociation = "BADGE_WAITING_ASSOCIATION"
        /// The subscription is waiting for a required badge link.
        case badgeWaitingMandatoryAssociation = "BADGE_WAITING_MANDATORY_ASSOCIATION"
        /// A temporary badge is linked to the subscription.
        case badgeTemporaryAssociated = "BADGE_TEMPORARY_ASSOCIATED"
    }
}

// MARK: - Auto-Renewal Toggle

/// A request body to toggle auto-renewal for a subscription.
///
/// The endpoint `PATCH /contracts/{contract}/accounts/{accountId}/subscriptions/{id}`
/// takes this type as its request body.
public struct SubscriptionAutoRenewal: Codable, Sendable {
    /// True to turn auto-renewal on, false to turn it off.
    public let isAutoRenewal: Bool

    /// Create an auto-renewal toggle request.
    /// - Parameter isAutoRenewal: True to turn auto-renewal on, false to turn it off.
    public init(isAutoRenewal: Bool) {
        self.isAutoRenewal = isAutoRenewal
    }
}
