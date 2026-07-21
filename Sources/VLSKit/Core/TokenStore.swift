import Foundation
#if canImport(Security)
import Security
#endif

// MARK: - VLS Tokens

/// The Keycloak (IAM) tokens the app gets at login, saved across app launches.
///
/// These tokens prove the user's identity. The client sends `iamAccessToken` verbatim as
/// the `Identity` header on authenticated Cyclocity calls. See `AuthSession` for how this
/// works. The subject claim in `iamIDToken` tells VLSKit which Cyclocity account belongs
/// to the user.
public struct VLSTokens: Codable, Sendable, Equatable {
    /// Keycloak access token (OIDC).
    ///
    /// The client sends this token verbatim as the `Identity` header on authenticated
    /// Cyclocity calls. See `AuthSession` for how this works.
    public var iamAccessToken: String
    /// Keycloak refresh token. The client uses this token to get a new access token when
    /// the current one expires.
    public var iamRefreshToken: String
    /// Keycloak ID token (OIDC). Its subject claim tells VLSKit which Cyclocity account
    /// belongs to the user.
    public var iamIDToken: String
    /// Date and time when the client got these tokens.
    public var obtainedAt: Date

    /// Creates a token set.
    /// - Parameters:
    ///   - iamAccessToken: Keycloak access token (OIDC).
    ///   - iamRefreshToken: Keycloak refresh token.
    ///   - iamIDToken: Keycloak ID token (OIDC).
    ///   - obtainedAt: Date and time when the client got these tokens. Default is the
    ///     current date and time.
    public init(
        iamAccessToken: String,
        iamRefreshToken: String,
        iamIDToken: String,
        obtainedAt: Date = Date()
    ) {
        self.iamAccessToken = iamAccessToken
        self.iamRefreshToken = iamRefreshToken
        self.iamIDToken = iamIDToken
        self.obtainedAt = obtainedAt
    }
}

// MARK: - Token Store Protocol

/// A type that saves `VLSTokens` between app launches.
///
/// You can write your own implementation, for example one backed by your app's existing
/// secrets store. On Apple platforms, you can use `KeychainTokenStore` instead.
public protocol TokenStore: Sendable {
    /// Loads the saved tokens, if any exist.
    /// - Returns: The saved tokens, or `nil` if no tokens are saved.
    func load() -> VLSTokens?
    /// Saves the given tokens, and replaces any tokens saved before.
    /// - Parameter tokens: Tokens to save.
    /// - Throws: An error if the save operation fails.
    func save(_ tokens: VLSTokens) throws
    /// Deletes any saved tokens.
    func clear()
}

// MARK: - In-Memory Token Store

/// A `TokenStore` that keeps tokens in memory only.
///
/// The tokens are lost when the process exits. Use this store for CLI tools, tests, and
/// previews. Do not use this store in a real app. Use `KeychainTokenStore` instead.
public final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private let lock = NSLock()
    private var tokens: VLSTokens?

    /// Creates an empty in-memory token store.
    public init() {}

    /// Loads the saved tokens, if any exist.
    /// - Returns: The saved tokens, or `nil` if no tokens are saved.
    public func load() -> VLSTokens? {
        lock.withLock { tokens }
    }

    /// Saves the given tokens in memory.
    /// - Parameter tokens: Tokens to save.
    public func save(_ tokens: VLSTokens) throws {
        lock.withLock { self.tokens = tokens }
    }

    /// Deletes the tokens saved in memory.
    public func clear() {
        lock.withLock { self.tokens = nil }
    }
}

#if canImport(Security)
// MARK: - Keychain Token Store

/// A `TokenStore` that stores tokens in the Keychain, under a service and account pair
/// the caller supplies.
///
/// Use this store in a real app. Keychain items survive app reinstalls, unless you turn
/// that behavior off. Other apps cannot read these items.
public final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String
    private let accessGroup: String?

    /// Creates a Keychain token store.
    /// - Parameters:
    ///   - service: Keychain service name. Default is `"com.openvelov.vlsKit"`.
    ///   - account: Keychain account name. Default is `"default"`.
    ///   - accessGroup: Keychain access group used to share items between apps. Default is
    ///     `nil`.
    public init(service: String = "com.openvelov.vlsKit", account: String = "default", accessGroup: String? = nil) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }

    /// Loads the tokens saved in the Keychain, if any exist.
    /// - Returns: The saved tokens, or `nil` if no tokens are saved or decoding fails.
    public func load() -> VLSTokens? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder.vls.decode(VLSTokens.self, from: data)
    }

    /// Saves the given tokens in the Keychain, and replaces any tokens saved before.
    /// - Parameter tokens: Tokens to save.
    /// - Throws: `VLSError.authenticationFailed` if the Keychain operation fails.
    public func save(_ tokens: VLSTokens) throws {
        let data = try JSONEncoder.vls.encode(tokens)

        var query = baseQuery()
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw VLSError.authenticationFailed(underlying: NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus)))
            }
        } else if updateStatus != errSecSuccess {
            throw VLSError.authenticationFailed(underlying: NSError(domain: NSOSStatusErrorDomain, code: Int(updateStatus)))
        }
    }

    /// Deletes the tokens saved in the Keychain.
    public func clear() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
#endif

// MARK: - NSLock Helpers

extension NSLock {
    fileprivate func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
