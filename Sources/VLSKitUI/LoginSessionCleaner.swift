import WebKit
import VLSKit

#if os(iOS) || os(macOS)
/// Clears the login web view's saved cookies and data for the Keycloak host.
///
/// `LoginWebViewController` uses the default `WKWebView` data store. This data store is
/// persistent and shared. A successful login leaves a Keycloak single sign-on (SSO) cookie
/// in that store. The cookie stays there until something removes it.
///
/// A call to `AuthSession.logout()` only ends the local app session. It does not remove
/// this cookie. Without a call to `clearSession(for:)`, the web view finds the SSO cookie
/// on the next login attempt. The web view then resumes the old session. The user does
/// not see a credential prompt, and the app does not register as a new device. Call
/// `clearSession(for:)` together with `AuthSession.logout()` so the next login is new,
/// not resumed.
public enum LoginSessionCleaner {
    /// Removes stored website data for the Keycloak host from the web view's data store.
    ///
    /// Call this method together with `AuthSession.logout()`. This ends the Keycloak SSO
    /// session, not only the local app session.
    ///
    /// - Parameter iamBaseURL: The base URL of the Keycloak realm, for example
    ///   `environment.iamBaseURL`. The method matches stored data records by this URL's
    ///   host name.
    public static func clearSession(for iamBaseURL: URL) async {
        guard let host = iamBaseURL.host else { return }
        let dataStore = WKWebsiteDataStore.default()
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let records: [WKWebsiteDataRecord] = await withCheckedContinuation { continuation in
            dataStore.fetchDataRecords(ofTypes: allTypes) { continuation.resume(returning: $0) }
        }
        let matching = records.filter { $0.displayName == host || host.hasSuffix(".\($0.displayName)") || $0.displayName.hasSuffix(".\(host)") }
        guard !matching.isEmpty else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            dataStore.removeData(ofTypes: allTypes, for: matching) { continuation.resume() }
        }
    }
}
#endif
