import WebKit
import VLSKit

#if os(iOS)
import UIKit
/// Platform base class for `LoginWebViewController`. On iOS, this type is `UIViewController`.
public typealias PlatformViewController = UIViewController
#elseif os(macOS)
import AppKit
/// Platform base class for `LoginWebViewController`. On macOS, this type is `NSViewController`.
public typealias PlatformViewController = NSViewController
#endif

#if os(iOS) || os(macOS)
/// Shows the Keycloak login page in a web view.
///
/// This view controller calls `onRedirect` with the callback URL when the user finishes
/// login. It also calls `onRedirect` if the user cancels, or if Keycloak returns an error.
/// Pass the callback URL to `AuthSession.completeLogin(callbackURL:pending:)`.
///
/// Usage (iOS, presented modally):
/// ```swift
/// let pending = await authSession.beginLogin()
/// let vc = LoginWebViewController(pending: pending, redirectURI: environment.oidcRedirectURI) { url in
///     Task { try await authSession.completeLogin(callbackURL: url, pending: pending) }
///     presentingViewController.dismiss(animated: true)
/// }
/// present(vc, animated: true)
/// ```
public final class LoginWebViewController: PlatformViewController {
    // MARK: - Properties

    private let pending: PendingAuthorization
    private let redirectURI: URL
    private let onRedirect: (URL) -> Void

    private var webView: WKWebView!
    private var interceptor: RedirectInterceptor!

    // MARK: - Initialization

    /// Creates a login view controller for the given pending authorization.
    ///
    /// - Parameters:
    ///   - pending: The pending authorization request from `AuthSession.beginLogin()`.
    ///   - redirectURI: The redirect URI that marks the end of the login flow.
    ///   - onRedirect: The closure to call with the callback URL after login finishes,
    ///     cancels, or Keycloak returns an error.
    public init(pending: PendingAuthorization, redirectURI: URL, onRedirect: @escaping (URL) -> Void) {
        self.pending = pending
        self.redirectURI = redirectURI
        self.onRedirect = onRedirect
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - View Lifecycle

    #if os(iOS)
    /// Creates the web view and sets it as this view controller's root view.
    public override func loadView() {
        let webView = WKWebView(frame: .zero)
        self.webView = webView
        self.view = webView
    }

    /// Configures the redirect interceptor and starts loading the login page.
    public override func viewDidLoad() {
        super.viewDidLoad()
        configureAndLoad()
    }
    #elseif os(macOS)
    /// Creates the web view at a fixed size and sets it as this view controller's root view.
    public override func loadView() {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 480, height: 640))
        self.webView = webView
        self.view = webView
    }

    /// Configures the redirect interceptor and starts loading the login page.
    public override func viewDidLoad() {
        super.viewDidLoad()
        configureAndLoad()
    }
    #endif

    // MARK: - Private Helpers

    private func configureAndLoad() {
        interceptor = RedirectInterceptor(redirectURI: redirectURI) { [weak self] url in
            self?.onRedirect(url)
        }
        webView.navigationDelegate = interceptor
        webView.load(URLRequest(url: pending.authorizeURL))
    }
}
#endif
