import Foundation

/// This service manages the reward points that an account earns and spends.
///
/// The backend gives points for actions that help the bike-share system, for example
/// returning a bike to an empty station or rating a bike after a trip.
public struct RewardService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the reward point balance for an account.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The reward point balance and settings for the account.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Reward`.
    public func reward(accountId: UUID) async throws -> Reward {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/rewards",
            headers: ["Accept": "application/vnd.rewards.v5+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Spends reward points to get a promo code for an account.
    ///
    /// This method is a real, consequential action. It spends reward points from the
    /// account balance and returns a new promo code.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The new promo code, and the number of reward points it spent.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `RewardPromoCode`.
    public func consumePromoCode(accountId: UUID) async throws -> RewardPromoCode {
        let endpoint = Endpoint(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/rewards/consume/promocode",
            headers: ["Accept": "application/vnd.rewards.v5+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the list of reward point configurations for the contract.
    ///
    /// Each configuration entry states how many reward points a specific action is
    /// worth, for example returning a bike to an empty station.
    /// - Returns: The list of reward point configurations.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[RewardConfiguration]`.
    public func configurations() async throws -> [RewardConfiguration] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/rewards/configurations",
            headers: ["Accept": "application/vnd.rewards.v5+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Updates the auto-spend setting for an account's reward points.
    /// - Parameters:
    ///   - accountId: The unique ID of the account to update.
    ///   - autoSpend: True to let the backend spend reward points automatically.
    /// - Returns: The updated reward point balance and settings.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Reward`. Throws an encoding error if the request body cannot convert to JSON.
    public func update(accountId: UUID, autoSpend: Bool) async throws -> Reward {
        let endpoint = try Endpoint.json(
            method: .patch,
            path: "contracts/\(contract)/accounts/\(accountId)/rewards",
            headers: ["Content-Type": "application/vnd.rewards.v5+json"],
            body: UpdateReward(autoSpend: autoSpend)
        )
        return try await httpClient.send(endpoint)
    }
}
