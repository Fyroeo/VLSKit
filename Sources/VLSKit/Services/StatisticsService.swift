import Foundation

/// This service gets the usage statistics for the app's "your impact" screen.
public struct StatisticsService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the usage statistics for an account over a date range.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - startDate: The start date of the range to query.
    ///   - endDate: The end date of the range to query.
    ///   - period: The time period to group the statistics by, for example week, month,
    ///     or year.
    ///   - types: The kinds of statistics to get, for example trip count or CO2 saved.
    /// - Returns: The list of matching usage statistics.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Statistics]`.
    public func statistics(
        accountId: UUID,
        startDate: String,
        endDate: String,
        period: StatisticsPeriod,
        types: [StatisticsType]
    ) async throws -> [Statistics] {
        var items = queryItems(["startDate": startDate, "endDate": endDate, "period": period.rawValue])
        types.forEach { items.append(URLQueryItem(name: "statsType", value: $0.rawValue)) }

        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/stats",
            queryItems: items,
            headers: ["Accept": "application/vnd.stats.v1+json"]
        )
        return try await httpClient.send(endpoint)
    }
}
