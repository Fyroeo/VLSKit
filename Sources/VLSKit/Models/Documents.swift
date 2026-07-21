import Foundation

// MARK: - Document reference

/// A lightweight reference to a document, for example a badge logo, a CGAU PDF, or
/// proof-of-address content.
///
/// Several offer endpoints return this type. The `id` property is a plain `String`
/// here. Other document types in this package use a `UUID` for their `id`.
public struct RemoteDocumentReference: Codable, Sendable, Identifiable {
    /// The unique ID of the document, as a string.
    public let id: String
    /// The file name of the document. This value can be missing.
    public let filename: String?
    /// The MIME type of the document, for example `application/pdf`.
    public let mimeType: String
    /// The translation of the document content, if the server sent one.
    public let translations: Translation?

    /// A translation of a document reference's content.
    public struct Translation: Codable, Sendable {
        /// The unique ID of the translation.
        public let id: Int64
        /// The locale of the translation, for example `fr-FR`. This value can be missing.
        public let locale: String?
        /// The translated content of the document.
        public let content: String
    }
}

// MARK: - Document payload

/// The full document payload, distinct from `RemoteDocumentReference` above.
///
/// The `content` property is base64-encoded raw bytes on the wire. The default
/// `Codable` conformance of `Data` decodes this correctly.
public struct RemoteDocument: Codable, Sendable, Identifiable {
    /// The unique ID of the document.
    public let id: UUID
    /// The file name of the document.
    public let filename: String
    /// The MIME type of the document, for example `application/pdf`.
    public let mimeType: String
    /// The raw bytes of the document content, decoded from base64 on the wire.
    public let content: Data
    /// The date the document expires. This value can be missing.
    public let expiredAt: Date?
    /// The date the server created the document.
    public let createdAt: Date
    /// The date the server last updated the document.
    public let updatedAt: Date
}

// MARK: - Document management

/// The response body for `POST /contracts/{contract}/accounts/{accountId}/documents`.
public struct DocumentCreated: Codable, Sendable {
    /// The unique ID of the created document.
    public let documentId: UUID
}

/// The request body for `DELETE /contracts/{contract}/accounts/{accountId}/documents`.
public struct DeleteDocuments: Codable, Sendable {
    /// The IDs of the documents to delete. This value can be missing.
    public let documentIds: [UUID]?
    /// The IDs of the accounts whose documents to delete. This value can be missing.
    public let accountIds: [UUID]?

    /// Create a request body to delete documents.
    /// - Parameters:
    ///   - documentIds: The IDs of the documents to delete. The default value is nil.
    ///   - accountIds: The IDs of the accounts whose documents to delete. The default value is nil.
    public init(documentIds: [UUID]? = nil, accountIds: [UUID]? = nil) {
        self.documentIds = documentIds
        self.accountIds = accountIds
    }
}
