import Foundation

/// This service wraps the subscription endpoints.
///
/// A subscription entitles a rider to unlock bikes.
public struct SubscriptionService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    // MARK: - Subscriptions

    /// Gets the list of subscriptions for an account.
    ///
    /// This method combines several GET variants of this endpoint into one call. Each
    /// variant differs only in which optional filters it sends.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - periods: The period type to filter by, for example current or past. Pass `nil`
    ///     to skip this filter. Default is `nil`.
    ///   - typeList: The list of subscription types to filter by. Pass `nil` to skip this
    ///     filter. Default is `nil`.
    ///   - noStatus: The list of subscription statuses to exclude from the result. Pass
    ///     `nil` to skip this filter. Default is `nil`.
    ///   - isLocked: True to get only locked subscriptions, false to get only unlocked
    ///     subscriptions. Pass `nil` to skip this filter. Default is `nil`.
    /// - Returns: The list of matching subscriptions.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Subscription]`.
    public func subscriptions(
        accountId: UUID,
        periods: SubscriptionPeriod.PeriodType? = nil,
        typeList: [SubscriptionType]? = nil,
        noStatus: [SubscriptionStatus.Status]? = nil,
        isLocked: Bool? = nil
    ) async throws -> [Subscription] {
        var items = queryItems([
            "periods": periods?.rawValue,
            "isLocked": isLocked,
        ])
        typeList?.forEach { items.append(URLQueryItem(name: "typeList", value: $0.rawValue)) }
        noStatus?.forEach { items.append(URLQueryItem(name: "noStatus", value: $0.rawValue)) }

        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/subscriptions",
            queryItems: items,
            headers: ["Accept": "application/vnd.subscription.v6+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets one subscription by its unique ID.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - id: The unique ID of the subscription.
    ///   - periods: The period types to include in the response, for example current or
    ///     past. Default is empty.
    /// - Returns: The subscription data.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Subscription`.
    public func subscription(accountId: UUID, id: UUID, periods: [SubscriptionPeriod.PeriodType] = []) async throws -> Subscription {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/subscriptions/\(id)",
            queryItems: periods.map { URLQueryItem(name: "periods", value: $0.rawValue) },
            headers: ["Accept": "application/vnd.subscription.v6+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the list of statuses for a subscription.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - id: The unique ID of the subscription.
    /// - Returns: The list of statuses for the subscription.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[SubscriptionStatus]`.
    public func statuses(accountId: UUID, id: UUID) async throws -> [SubscriptionStatus] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/subscriptions/\(id)/statuses",
            headers: ["Accept": "application/vnd.subscription.v6+json"]
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Extra Time

    /// Requests 15 extra minutes of ride time for a subscription.
    ///
    /// Call this method when the rider's destination station has no free docks. See the
    /// `CreateVia` documentation for more detail on this feature. The server checks that
    /// the named station is actually full, and rejects the request otherwise. A caller
    /// does not need to check station availability before this call. A caller can still
    /// check first, to avoid a round trip for a station that is clearly not full.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - subscriptionId: The unique ID of the subscription to request extra time for.
    ///   - stationId: The number of the full destination station, cast to `Int64`.
    /// - Returns: The state of the extra-time transaction.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `TransactionState`. Throws an encoding error if the request body cannot convert
    ///   to JSON.
    public func requestExtraTime(accountId: UUID, subscriptionId: UUID, stationId: Int64) async throws -> TransactionState {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/subscriptions/\(subscriptionId)/via",
            headers: ["Content-Type": "application/vnd.subscription.v6+json"],
            body: CreateVia(stationId: stationId)
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Auto-Renewal

    /// Turns auto-renewal on or off for a subscription.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - id: The unique ID of the subscription to update.
    ///   - autoRenewal: The new auto-renewal setting.
    /// - Returns: The updated subscription.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Subscription`. Throws an encoding error if `autoRenewal` cannot convert to JSON.
    public func setAutoRenewal(accountId: UUID, id: UUID, autoRenewal: SubscriptionAutoRenewal) async throws -> Subscription {
        let endpoint = try Endpoint.json(
            method: .patch,
            path: "contracts/\(contract)/accounts/\(accountId)/subscriptions/\(id)",
            headers: ["Content-Type": "application/vnd.subscription.v6+json"],
            body: autoRenewal
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Periods

    /// Gets the billing and validity periods for an account.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - periodIds: The period IDs to filter by, as a raw query value. Pass `nil` to get
    ///     all periods. Default is `nil`.
    /// - Returns: The list of matching subscription periods.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[SubscriptionPeriod]`.
    public func periods(accountId: UUID, periodIds: String? = nil) async throws -> [SubscriptionPeriod] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/periods",
            queryItems: queryItems(["periodIds": periodIds]),
            headers: ["Accept": "application/vnd.subscription.v6+json"]
        )
        return try await httpClient.send(endpoint)
    }
}
