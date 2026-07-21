import Foundation

/// A usage statistic for an account, shown on the app's "your impact" screen.
///
/// The endpoint `GET /contracts/{contract}/accounts/{accountId}/stats` (`vg.q`) returns
/// this type.
public struct Statistics: Codable, Sendable {
    /// The kind of statistic this value represents, for example trip count or CO2 saved.
    public let statsType: StatisticsType
    /// The total value for the current period.
    public let periodTotal: Int
    /// The time period this statistic covers, for example week, month, or year.
    public let periodicity: StatisticsPeriod
    /// The statistic's value for each sub-period, keyed by a backend-defined label.
    public let values: [String: Int]
}

// MARK: - Supporting Enums

/// The time period a `Statistics` value covers.
public enum StatisticsPeriod: String, Codable, Sendable {
    /// A one-week period.
    case week = "WEEK"
    /// A one-month period.
    case month = "MONTH"
    /// A one-year period.
    case year = "YEAR"
}

/// The kind of usage statistic an account can request.
public enum StatisticsType: String, Codable, Sendable {
    /// The total duration of the account's trips.
    case tripsDurations = "TRIPS_DURATIONS"
    /// The total number of the account's trips.
    case tripsCounts = "TRIPS_COUNTS"
    /// The number of the account's trips made on an electrical bike.
    case tripsCountsElectric = "TRIPS_COUNTS_ELEC"
    /// The number of the account's trips made on a mechanical bike.
    case tripsCountsMechanical = "TRIPS_COUNTS_MECA"
    /// The total rewards the account earned from trips.
    case tripsRewards = "TRIPS_REWARDS"
    /// The total distance of the account's trips.
    case tripsDistance = "TRIPS_DISTANCE"
    /// The total CO2 the account's trips saved, compared to driving a car.
    case tripsCO2 = "TRIPS_CO2"
    /// The total calories the account's trips burned.
    case tripsCalories = "TRIPS_CALORIES"
}
