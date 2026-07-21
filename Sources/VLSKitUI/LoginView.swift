import SwiftUI
import VLSKit

#if os(iOS)
/// Wraps `LoginWebViewController` for use in SwiftUI.
///
/// Present this view in a `.sheet`. Call `AuthSession.completeLogin` from the `onRedirect`
/// closure.
public struct LoginView: UIViewControllerRepresentable {
    // MARK: - Properties

    /// The pending authorization request from `AuthSession.beginLogin()`.
    public let pending: PendingAuthorization

    /// The redirect URI that marks the end of the login flow.
    public let redirectURI: URL

    /// The closure this view calls with the callback URL after login finishes.
    public let onRedirect: (URL) -> Void

    // MARK: - Initialization

    /// Creates a login view for the given pending authorization.
    ///
    /// - Parameters:
    ///   - pending: The pending authorization request from `AuthSession.beginLogin()`.
    ///   - redirectURI: The redirect URI that marks the end of the login flow.
    ///   - onRedirect: The closure to call with the callback URL after login finishes.
    public init(pending: PendingAuthorization, redirectURI: URL, onRedirect: @escaping (URL) -> Void) {
        self.pending = pending
        self.redirectURI = redirectURI
        self.onRedirect = onRedirect
    }

    // MARK: - UIViewControllerRepresentable

    /// Creates the underlying `LoginWebViewController`.
    ///
    /// - Parameter context: The representable context. This method does not use it.
    /// - Returns: A new `LoginWebViewController` configured with this view's properties.
    public func makeUIViewController(context: Context) -> LoginWebViewController {
        LoginWebViewController(pending: pending, redirectURI: redirectURI, onRedirect: onRedirect)
    }

    /// Updates the underlying view controller.
    ///
    /// This method does nothing. `LoginWebViewController` does not need updates after the
    /// view creates it.
    ///
    /// - Parameters:
    ///   - uiViewController: The existing `LoginWebViewController` instance.
    ///   - context: The representable context.
    public func updateUIViewController(_ uiViewController: LoginWebViewController, context: Context) {}
}
#elseif os(macOS)
/// Wraps `LoginWebViewController` for use in SwiftUI.
///
/// Present this view in a `.sheet`. Call `AuthSession.completeLogin` from the `onRedirect`
/// closure.
public struct LoginView: NSViewControllerRepresentable {
    // MARK: - Properties

    /// The pending authorization request from `AuthSession.beginLogin()`.
    public let pending: PendingAuthorization

    /// The redirect URI that marks the end of the login flow.
    public let redirectURI: URL

    /// The closure this view calls with the callback URL after login finishes.
    public let onRedirect: (URL) -> Void

    // MARK: - Initialization

    /// Creates a login view for the given pending authorization.
    ///
    /// - Parameters:
    ///   - pending: The pending authorization request from `AuthSession.beginLogin()`.
    ///   - redirectURI: The redirect URI that marks the end of the login flow.
    ///   - onRedirect: The closure to call with the callback URL after login finishes.
    public init(pending: PendingAuthorization, redirectURI: URL, onRedirect: @escaping (URL) -> Void) {
        self.pending = pending
        self.redirectURI = redirectURI
        self.onRedirect = onRedirect
    }

    // MARK: - NSViewControllerRepresentable

    /// Creates the underlying `LoginWebViewController`.
    ///
    /// - Parameter context: The representable context. This method does not use it.
    /// - Returns: A new `LoginWebViewController` configured with this view's properties.
    public func makeNSViewController(context: Context) -> LoginWebViewController {
        LoginWebViewController(pending: pending, redirectURI: redirectURI, onRedirect: onRedirect)
    }

    /// Updates the underlying view controller.
    ///
    /// This method does nothing. `LoginWebViewController` does not need updates after the
    /// view creates it.
    ///
    /// - Parameters:
    ///   - nsViewController: The existing `LoginWebViewController` instance.
    ///   - context: The representable context.
    public func updateNSViewController(_ nsViewController: LoginWebViewController, context: Context) {}
}
#endif
