import Foundation

/// A minimal `multipart/form-data` body builder.
///
/// This builder supports only what the document-upload and "contact us" email endpoints
/// need. These are the only calls in this API that use a multipart body.
public struct MultipartFormData: Sendable {
    // MARK: Properties

    /// Unique boundary string that separates each part of the body.
    public let boundary: String = "VLSKit-\(UUID().uuidString)"
    private var parts: [Data] = []

    // MARK: Initialization

    /// Creates an empty multipart form body.
    public init() {}

    // MARK: Adding Parts

    /// Adds a text field to the form body.
    /// - Parameters:
    ///   - name: Field name.
    ///   - value: Field value.
    public mutating func addField(name: String, value: String) {
        var part = Data()
        part.append("--\(boundary)\r\n")
        part.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        part.append("\(value)\r\n")
        parts.append(part)
    }

    /// Adds a file field to the form body.
    /// - Parameters:
    ///   - name: Field name.
    ///   - filename: File name to send with the part.
    ///   - mimeType: MIME type of the file data, for example `"image/jpeg"`.
    ///   - data: Raw file data.
    public mutating func addFile(name: String, filename: String, mimeType: String, data: Data) {
        var part = Data()
        part.append("--\(boundary)\r\n")
        part.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        part.append("Content-Type: \(mimeType)\r\n\r\n")
        part.append(data)
        part.append("\r\n")
        parts.append(part)
    }

    // MARK: Building the Body

    /// The complete multipart body, with every part and the closing boundary.
    public var httpBody: Data {
        var body = Data()
        parts.forEach { body.append($0) }
        body.append("--\(boundary)--\r\n")
        return body
    }

    /// The `Content-Type` header value to send with this body, including the boundary.
    public var contentTypeHeader: String {
        "multipart/form-data; boundary=\(boundary)"
    }
}

// MARK: - Data Helpers

extension Data {
    fileprivate mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
