import Foundation

/// The request body for `POST /contracts/{contract}/accounts/{accountId}/pay/checkout`.
public struct GetCheckoutInfosBody: Codable, Sendable {
    /// The list of accepted payment methods, for example `"CB"` for a card.
    public let paymentMethods: [String]
    /// The URL the checkout page redirects to after payment.
    public let returnUrl: String

    /// Create a request body for a checkout information request.
    /// - Parameters:
    ///   - paymentMethods: The list of accepted payment methods. The default value is `["CB"]`.
    ///   - returnUrl: The URL to redirect to after payment.
    public init(paymentMethods: [String] = ["CB"], returnUrl: String) {
        self.paymentMethods = paymentMethods
        self.returnUrl = returnUrl
    }
}

/// A hosted checkout page for the user to complete payment.
public struct CheckoutInfos: Codable, Sendable {
    /// The unique identifier of the checkout session.
    public let id: String
    /// The URL of the hosted checkout page. Redirect the user to this URL.
    public let redirectUrl: String
}
