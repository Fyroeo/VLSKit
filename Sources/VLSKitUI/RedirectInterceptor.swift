import Foundation
import WebKit
import VLSKit

/// Watches web view navigations for the OAuth redirect and hands the URL back to the caller.
///
/// `ASWebAuthenticationSession` can auto-intercept a redirect only if the app has claimed
/// that URL through Associated Domains. Associated Domains needs the domain owner's
/// cooperation to set up. The Keycloak `redirect_uri` here is `https://velov.grandlyon.com/`.
/// This is JCDecaux's own domain, so a third-party app cannot register it.
///
/// VLSKit instead loads the login flow in a plain `WKWebView`. `RedirectInterceptor` watches
/// each navigation. When a navigation matches the redirect URI, it cancels that navigation
/// before the web view loads it. It then gives the URL to the caller instead.
///
/// This is a common technique for OAuth login when the app does not own the redirect URI.
final class RedirectInterceptor: NSObject, WKNavigationDelegate {
    private let redirectURI: URL
    private let onRedirect: (URL) -> Void

    init(redirectURI: URL, onRedirect: @escaping (URL) -> Void) {
        self.redirectURI = redirectURI
        self.onRedirect = onRedirect
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if url.scheme == redirectURI.scheme, url.host == redirectURI.host {
            decisionHandler(.cancel)
            onRedirect(url)
            return
        }
        decisionHandler(.allow)
    }
}
