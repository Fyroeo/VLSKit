import Foundation

// MARK: - Complaint type

/// The category of a complaint submitted with `EmailService.sendMail`.
public enum ComplaintType: String, Codable, Sendable {
    /// A complaint about a trip.
    case trip = "TRIP"
    /// A complaint about a subscription.
    case subscription = "SUBSCRIPTION"
    /// A complaint about a payment.
    case payment = "PAYMENT"
    /// A complaint about parking.
    case parking = "PARKING"
}

// MARK: - Attachment

/// An attachment for `EmailService.sendMail`.
public struct EmailAttachment: Sendable {
    /// The file name of the attachment.
    public let filename: String
    /// The MIME type of the attachment, for example `image/jpeg`.
    public let mimeType: String
    /// The raw bytes of the attachment content.
    public let data: Data

    /// Creates an email attachment.
    /// - Parameters:
    ///   - filename: The file name of the attachment.
    ///   - mimeType: The MIME type of the attachment, for example `image/jpeg`.
    ///   - data: The raw bytes of the attachment content.
    public init(filename: String, mimeType: String, data: Data) {
        self.filename = filename
        self.mimeType = mimeType
        self.data = data
    }
}

// MARK: - Email service

/// The in-app "contact us" complaint form.
///
/// This service sends the form data as multipart/form-data.
public struct EmailService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Sends a complaint email for an account.
    ///
    /// This method submits the in-app "contact us" form. It sends the form fields and
    /// any attachments as multipart/form-data.
    /// - Parameters:
    ///   - accountId: The unique ID of the account that sends the complaint.
    ///   - complaintType: The category of the complaint.
    ///   - message: The complaint message text.
    ///   - subscriptionId: The unique ID of the related subscription. The default value
    ///     is nil.
    ///   - tripNumber: The number of the related trip. The form sends this value under
    ///     the field name `tripId`. The default value is nil.
    ///   - transactionId: The unique ID of the related transaction. The default value is
    ///     nil.
    ///   - amount: The amount related to the complaint. The default value is nil.
    ///   - date: The date related to the complaint, as text. The default value is nil.
    ///   - status: The invoice status related to the complaint. The default value is nil.
    ///   - parkId: The unique ID of the related parking. The default value is nil.
    ///   - parkNumber: The number of the related parking. The default value is nil.
    ///   - parkName: The name of the related parking. The default value is nil.
    ///   - attachments: The files to attach to the complaint. The default value is an
    ///     empty list.
    /// - Throws: `VLSError` if the request fails.
    public func sendMail(
        accountId: UUID,
        complaintType: ComplaintType,
        message: String,
        subscriptionId: UUID? = nil,
        tripNumber: String? = nil,
        transactionId: UUID? = nil,
        amount: Int? = nil,
        date: String? = nil,
        status: InvoiceStatus? = nil,
        parkId: UUID? = nil,
        parkNumber: Int? = nil,
        parkName: String? = nil,
        attachments: [EmailAttachment] = []
    ) async throws {
        var form = MultipartFormData()
        form.addField(name: "complaintType", value: complaintType.rawValue)
        form.addField(name: "message", value: message)
        if let subscriptionId { form.addField(name: "subscriptionId", value: subscriptionId.uuidString) }
        if let tripNumber { form.addField(name: "tripId", value: tripNumber) }
        if let transactionId { form.addField(name: "transactionId", value: transactionId.uuidString) }
        if let amount { form.addField(name: "amount", value: String(amount)) }
        if let date { form.addField(name: "date", value: date) }
        if let status { form.addField(name: "status", value: status.rawValue) }
        if let parkId { form.addField(name: "parkingId", value: parkId.uuidString) }
        if let parkNumber { form.addField(name: "parkingNumber", value: String(parkNumber)) }
        if let parkName { form.addField(name: "parkingName", value: parkName) }
        for attachment in attachments {
            form.addFile(name: "attachments", filename: attachment.filename, mimeType: attachment.mimeType, data: attachment.data)
        }

        let endpoint = Endpoint(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/mail",
            headers: ["Content-Type": form.contentTypeHeader, "Accept": "multipart/form-data"],
            body: form.httpBody
        )
        try await httpClient.sendVoid(endpoint)
    }
}
