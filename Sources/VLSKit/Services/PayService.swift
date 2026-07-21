import Foundation

/// This service starts a hosted checkout session for an account.
///
/// Use it to let the user add funds or pay an outstanding balance.
public struct PayService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Starts a hosted checkout session for an account.
    ///
    /// The response contains a URL. Redirect the user to this URL to finish payment on
    /// the hosted checkout page.
    /// - Parameters:
    ///   - accountId: The unique ID of the account that pays.
    ///   - body: The checkout options, for example the allowed payment methods and the
    ///     return URL.
    /// - Returns: The checkout session, including the URL to redirect the user to.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `CheckoutInfos`. Throws an encoding error if `body` cannot convert to JSON.
    public func checkout(accountId: UUID, body: GetCheckoutInfosBody) async throws -> CheckoutInfos {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/pay/checkout",
            headers: ["Content-Type": "application/vnd.pay.v1+json"],
            body: body
        )
        return try await httpClient.send(endpoint)
    }
}
