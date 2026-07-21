import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Provides Proof Key for Code Exchange (PKCE) helpers for the Keycloak Authorization
/// Code flow.
/// PKCE follows RFC 7636.
enum PKCE {
    /// Creates a random PKCE code verifier.
    /// The verifier is a cryptographically random string with 43 to 128 characters, per
    /// RFC 7636 section 4.1.
    /// - Returns: A new code verifier string.
    static func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytesShim(&bytes)
        precondition(result, "Failed to generate secure random bytes for PKCE verifier")
        return base64URLEncode(Data(bytes))
    }

    /// Creates the S256 code challenge for a PKCE code verifier, per RFC 7636 section
    /// 4.2.
    /// - Parameter verifier: The code verifier from `generateCodeVerifier()`.
    /// - Returns: The S256 code challenge string for the verifier.
    static func codeChallenge(for verifier: String) -> String {
        #if canImport(CryptoKit)
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return base64URLEncode(Data(digest))
        #else
        fatalError("VLSKit's PKCE implementation requires CryptoKit (Apple platforms).")
        #endif
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

#if canImport(Security)
import Security
private func SecRandomCopyBytesShim(_ bytes: inout [UInt8]) -> Bool {
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return status == errSecSuccess
}
#else
private func SecRandomCopyBytesShim(_ bytes: inout [UInt8]) -> Bool {
    for i in bytes.indices { bytes[i] = UInt8.random(in: .min ... .max) }
    return true
}
#endif
