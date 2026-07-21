import Foundation

// MARK: - Reward Configuration

/// The number of reward points that a given action is worth.
/// The API returns this type from `GET /contracts/{contract}/rewards/configurations` (`ri.j`).
public struct RewardConfiguration: Codable, Sendable, Identifiable {
    /// The unique identifier of the configuration. This value can be absent.
    public let id: UUID?
    /// The name of the contract that owns this configuration.
    public let contractName: String
    /// The action that this configuration rewards. This value can be absent.
    public let name: Name?
    /// The category of the configuration. This value can be absent.
    public let type: Kind?
    /// The localization key for the configuration's display text.
    public let i18nKey: String
    /// True if this configuration is active.
    public let enable: Bool
    /// The number of points this action is worth.
    public let reward: Int

    /// The action that a reward configuration applies to.
    public enum Name: String, Codable, Sendable {
        /// The user starts a trip from a full station.
        case startStationFull = "START_STATION_FULL"
        /// The user ends a trip at an empty station.
        case endStationEmpty = "END_STATION_EMPTY"
        /// The user rates a bike.
        case rateBike = "RATE_BIKE"
        /// The user starts a trip using overflow capacity.
        case startTripOverflow = "START_TRIP_OVERFLOW"
        /// A bonus tied to completing a trip.
        case tripBonus = "TRIP_BONUS"
        /// A bonus tied to migrating to a new subscription.
        case migrateBonus = "MIGRATE_BONUS"
        /// A cash-equivalent currency reward.
        case currency = "CURRENCY"
        /// A reward tied to a promotional code.
        case promocode = "PROMOCODE"
        /// A reward tied to booking a bike in advance.
        case bikeBooking = "BIKE_BOOKING"
        /// An action that this client does not recognize yet.
        case unknown = "UNKNOWN"
    }

    /// The category of a reward configuration.
    public enum Kind: String, Codable, Sendable {
        /// A fixed rule-based reward.
        case rule = "RULE"
        /// A reward computed from a valuation.
        case valuation = "VALUATION"
        /// A category that this client does not recognize yet.
        case unknown = "UNKNOWN"
    }
}

// MARK: - Rewards

/// A user's reward point balance.
/// The API returns this type from `GET /contracts/{contract}/accounts/{accountId}/rewards`.
public struct Reward: Codable, Sendable {
    /// The name of the contract this balance applies to. This value can be absent.
    public let contractName: String?
    /// The unique identifier of the account. This value can be absent.
    public let accountId: UUID?
    /// The current number of reward points.
    public let balance: Int
    /// True if the account automatically spends reward points when possible.
    public let autoSpend: Bool
}

/// A promotional code created by spending reward points.
/// The API returns this type from `POST .../rewards/consume/promocode`.
public struct RewardPromoCode: Codable, Sendable {
    /// The generated promotional code.
    public let promoCode: String
    /// The identifier of the offer the code applies to.
    public let offerId: Int64
    /// The identifier of the badge the code applies to.
    public let badgeId: Int64
    /// The category of the badge the code applies to.
    public let badgeType: BadgeType
    /// The number of reward points spent to create this code.
    public let rewardsSpent: Int
}

/// The request body for `PATCH /contracts/{contract}/accounts/{accountId}/rewards`.
public struct UpdateReward: Codable, Sendable {
    /// The new automatic-spend setting for reward points. This value can be absent.
    public let autoSpend: Bool?

    /// Create a request to update the reward settings for an account.
    /// - Parameters:
    ///   - autoSpend: The new automatic-spend setting for reward points.
    public init(autoSpend: Bool?) {
        self.autoSpend = autoSpend
    }
}
