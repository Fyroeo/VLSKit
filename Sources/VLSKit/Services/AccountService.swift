import Foundation

/// This service wraps the account endpoints under `/contracts/{contract}/accounts/...`.
public struct AccountService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    // MARK: - Account

    /// Gets the account data for an account.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The account data.
    /// - Throws: `VLSError` if the request fails or the response body does not match `Account`.
    public func account(accountId: UUID) async throws -> Account {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)",
            headers: ["Accept": "application/vnd.account.v4+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the account ID for a given email address.
    ///
    /// Call this method right after login. It is useful when you have only the email
    /// address from the ID token.
    /// - Parameter email: The email address of the account.
    /// - Returns: The unique ID of the account.
    /// - Throws: `VLSError` if the request fails or the response body does not match `UUID`.
    public func accountId(email: String) async throws -> UUID {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(email)/id",
            headers: ["Accept": "application/json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Updates an existing account with new field values.
    /// - Parameters:
    ///   - accountId: The unique ID of the account to update.
    ///   - patch: The fields to change on the account.
    /// - Returns: The updated account.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Account`. Throws an encoding error if `patch` cannot convert to JSON.
    public func patch(accountId: UUID, with patch: PatchAccount) async throws -> Account {
        let endpoint = try Endpoint.json(
            method: .patch,
            path: "contracts/\(contract)/accounts/\(accountId)",
            headers: ["Content-Type": "application/vnd.account.v4+json"],
            body: patch
        )
        return try await httpClient.send(endpoint)
    }

    /// Completes a new account profile after signup.
    ///
    /// This method uses the same path as `patch(accountId:with:)`. It sends a different
    /// payload. Call this method right after signup, to complete a profile. Use
    /// `patch(accountId:with:)` to edit an existing profile.
    /// - Parameters:
    ///   - accountId: The unique ID of the account to complete.
    ///   - completion: The profile fields to submit.
    /// - Returns: The completed account.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Account`. Throws an encoding error if `completion` cannot convert to JSON.
    public func complete(accountId: UUID, with completion: CompleteAccount) async throws -> Account {
        let endpoint = try Endpoint.json(
            method: .patch,
            path: "contracts/\(contract)/accounts/\(accountId)",
            headers: ["Content-Type": "application/vnd.account.v4+json"],
            body: completion
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Payment

    /// Gets the stored payment information for an account.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The payment information for the account.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `PaymentInfos`.
    public func paymentInfos(accountId: UUID) async throws -> PaymentInfos {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/payment",
            headers: ["Accept": "application/vnd.payment.v3+json"]
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Alerts and terms

    /// Gets the list of alerts for an account.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The list of alerts for the account.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Alert]`.
    public func alerts(accountId: UUID) async throws -> [Alert] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/alerts",
            headers: ["Accept": "application/vnd.account.v4+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the CGAU (terms and conditions) validation status for an account.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The CGAU validation status for the account.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `AccountCGAUsValidated`.
    public func cgauValidated(accountId: UUID) async throws -> AccountCGAUsValidated {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/cgau",
            headers: ["Accept": "application/vnd.account.v4+json"]
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Offers

    /// Gets the offers in a group that an account is eligible for.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - group: The unique ID of the offer group.
    /// - Returns: The list of offers in the group, each with its eligibility status.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[AccountEligibleOffer]`.
    public func eligibleOffers(accountId: UUID, group: Int64) async throws -> [AccountEligibleOffer] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/offerGroups/\(group)/offers",
            headers: ["Accept": "application/vnd.account.v4+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the IDs of the offers that an account is eligible for.
    ///
    /// This method returns a plain list of IDs. Use `eligibleOffers(accountId:group:)` to
    /// get more detail about each offer.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The list of eligible offer IDs.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Int64]`.
    public func offerIds(accountId: UUID) async throws -> [Int64] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/offers",
            headers: ["Accept": "application/vnd.account.v4+json"]
        )
        return try await httpClient.send(endpoint)
    }
}

// MARK: - Response Models

/// The payment information for an account.
///
/// This shape is a best-effort guess. `Codable` ignores fields it does not recognize.
/// Add any missing fields that you find.
public struct PaymentInfos: Codable, Sendable {
    /// The unique ID of the stored payment method, if known.
    public let id: String?
    /// The type of the payment method, for example a card brand, if known.
    public let type: String?
    /// The last 4 digits of the payment card number, if known.
    public let last4: String?
    /// The expiry month of the payment card, if known.
    public let expiryMonth: Int?
    /// The expiry year of the payment card, if known.
    public let expiryYear: Int?
}

/// A blocking or informational status on an account, from
/// `GET .../accounts/{id}/alerts`.
///
/// The live shape is `{ value, key, isBlockingStatus }` — for example
/// `value: "NO_VALID_SUBSCRIPTIONS"` with `isBlockingStatus: true`, which is what stops
/// an otherwise-signed-in account from renting. Every field is optional so an unexpected
/// entry still decodes.
public struct Alert: Codable, Sendable {
    /// The status code, for example `NO_VALID_SUBSCRIPTIONS`. The full set is unknown.
    public let value: String?
    /// A secondary key the backend attaches to some alerts.
    public let key: String?
    /// True when this status blocks the account from riding.
    public let isBlockingStatus: Bool?

    /// True when this alert blocks riding.
    public var isBlocking: Bool { isBlockingStatus ?? false }
}

/// The CGAU (terms and conditions) validation status for an account.
public struct AccountCGAUsValidated: Codable, Sendable {
    /// Whether the account has validated the current CGAU, if known.
    public let valid: Bool?
}

/// An offer and whether an account is eligible for it.
public struct AccountEligibleOffer: Codable, Sendable {
    /// The unique ID of the offer, if present.
    public let offerId: Int64?
    /// Whether the account is eligible for the offer, if present.
    public let isEligible: Bool?
}
