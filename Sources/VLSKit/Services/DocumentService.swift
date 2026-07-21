import Foundation

/// Uploads and deletes account documents, and gets a stored document asset.
public struct DocumentService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets a stored document asset by its ID.
    ///
    /// This method returns the full `RemoteDocument` payload, with a UUID ID and byte
    /// content. This is different from `RemoteDocumentReference`, which uses a String ID.
    /// `OfferService` returns `RemoteDocumentReference` from its offer, badge, and CGAU
    /// file endpoints.
    /// - Parameter documentId: The unique ID of the document asset.
    /// - Returns: The document asset, with its raw byte content.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `RemoteDocument`.
    public func asset(documentId: UUID) async throws -> RemoteDocument {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/assets/\(documentId)",
            headers: ["Accept": "application/vnd.document.v3+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Deletes documents for an account.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - documentIds: The unique IDs of the documents to delete.
    /// - Throws: `VLSError` if the request fails. Throws an encoding error if the
    ///   request body cannot convert to JSON.
    public func delete(accountId: UUID, documentIds: [UUID]) async throws {
        let endpoint = try Endpoint.json(
            method: .delete,
            path: "contracts/\(contract)/accounts/\(accountId)/documents",
            headers: ["Content-Type": "application/vnd.document.v3+json"],
            body: DeleteDocuments(documentIds: documentIds)
        )
        try await httpClient.sendVoid(endpoint)
    }

    /// Uploads a file for an account, for example a photo of a defect or proof of
    /// address.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - filename: The file name to send with the upload.
    ///   - mimeType: The MIME type of the file, for example `image/jpeg`.
    ///   - data: The raw bytes of the file.
    /// - Returns: The unique ID of the new document, wrapped in a `DocumentCreated` value.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `DocumentCreated`.
    public func upload(accountId: UUID, filename: String, mimeType: String, data: Data) async throws -> DocumentCreated {
        var form = MultipartFormData()
        form.addFile(name: "attachment", filename: filename, mimeType: mimeType, data: data)

        let endpoint = Endpoint(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/documents",
            headers: ["Content-Type": form.contentTypeHeader],
            body: form.httpBody
        )
        return try await httpClient.send(endpoint)
    }
}
