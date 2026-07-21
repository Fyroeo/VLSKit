import Foundation

// MARK: - Invoice status

/// The status of a `Sale` or a `Transaction`.
public enum InvoiceStatus: String, Codable, Sendable {
    /// The item is waiting for control before invoicing.
    case toControl = "TO_CONTROL"
    /// The item is waiting to be invoiced.
    case toInvoice = "TO_INVOICE"
    /// The item is waiting to be processed.
    case toDo = "TO_DO"
    /// The item is currently being processed.
    case doing = "DOING"
    /// The item is cancelled.
    case cancelled = "CANCELLED"
    /// The item is rejected.
    case rejected = "REJECTED"
    /// The item is paid.
    case paid = "PAID"
    /// The item is refunded to the customer.
    case paybacked = "PAYBACKED"
    /// The item is partially refunded to the customer.
    case partiallyPaybacked = "PARTIALLY_PAYBACKED"
    /// The status value is not recognized.
    case unknown = "UNKNOWN"
}

// MARK: - Balance

/// The account balance from `GET /contracts/{contract}/accounts/{accountId}/balance`
/// (`ri.f` in the app).
public struct Balance: Codable, Sendable {
    /// The amount due on the account.
    public let due: Int
    /// The amount due on the account that is still waiting for control.
    public let dueToControl: Int
    /// The credit balance available on the account.
    public let credit: Int
}

// MARK: - Sales

/// The direction of a sale or transaction amount.
public enum InvoiceDirection: String, Codable, Sendable {
    /// The amount is a debit, taken from the account.
    case debit = "DEBIT"
    /// The amount is a credit, added to the account.
    case credit = "CREDIT"
}

/// A single line item in a `Transaction`.
///
/// The server can also return a `Sale` on its own, through `.../sales`, without a
/// parent `Transaction`.
public struct Sale: Codable, Sendable, Identifiable {
    /// The unique ID of the sale.
    public let id: UUID
    /// The code of the contract the sale belongs to.
    public let contractCode: String
    /// The unique ID of the account the sale belongs to.
    public let accountId: UUID
    /// The unique ID of the subscription the sale relates to. This value can be missing.
    public let subscriptionId: UUID?
    /// An external reference for the sale. This value can be missing.
    public let externalRef: String?
    /// The nature of the sale. This value can be missing.
    public let nature: Nature?
    /// The date of the sale.
    public let saleDate: Date
    /// The date the server created the sale. This value can be missing.
    public let createdAt: Date?
    /// The date the server last updated the sale. This value can be missing.
    public let updatedAt: Date?
    /// The amount of the sale.
    public let amount: Int
    /// The direction of the sale amount, debit or credit. This value can be missing.
    public let direction: InvoiceDirection?
    /// The status of the sale. This value can be missing.
    public let status: InvoiceStatus?
    /// The unique ID of the parent transaction. This value can be missing.
    public let transactionId: UUID?
    /// The type of subscription the sale relates to. This value can be missing.
    public let subscriptionType: SubscriptionType?
    /// Extra information about the sale. The shape of this value is unknown, so the
    /// client decodes it permissively.
    ///
    /// The server's own JSON key has a typo, `saleAdditionnalInfo` with a double n.
    /// This package keeps the typo on the wire.
    public let saleAdditionalInfo: JSONValue?
    /// The payment card key used for the sale. This value can be missing.
    public let pankey: String?
    /// The unique ID of the parent sale, when this sale is part of a group. This value
    /// can be missing.
    public let parentId: UUID?
    /// The type of account the sale belongs to. This value can be missing.
    public let accountType: AccountType?
    /// The platform the sale was made on. This value can be missing.
    public let platform: Platform?
    /// An external reference for the station related to the sale. This value can be
    /// missing.
    public let stationExternalRef: String?
    /// The amount refunded to the customer for the sale.
    public let paybackAmount: Double
    /// The label of the station related to the sale. This value can be missing.
    public let stationLabel: String?

    enum CodingKeys: String, CodingKey {
        case id, contractCode, accountId, subscriptionId, externalRef, nature
        case saleDate = "date"
        case createdAt, updatedAt, amount, direction, status, transactionId, subscriptionType
        case saleAdditionalInfo = "saleAdditionnalInfo"
        case pankey, parentId, accountType, platform, stationExternalRef, paybackAmount, stationLabel
    }

    /// The nature of a `Sale`, for example a subscription or a consumption charge.
    public enum Nature: String, Codable, Sendable {
        /// A caution deposit.
        case caution = "CAUTION"
        /// A refund.
        case refund = "REFUND"
        /// A new badge purchase.
        case newBadge = "NEW_BADGE"
        /// A new subscription.
        case subscription = "SUBSCRIPTION"
        /// A subscription renewal.
        case renewal = "RENEWAL"
        /// A ride consumption charge.
        case consumption = "CONSUMPTION"
        /// A reduction applied to a subscription.
        case subscriptionReduction = "SUBSCRIPTION_REDUCTION"
        /// A reduction applied to a renewal.
        case renewalReduction = "RENEWAL_REDUCTION"
        /// A reduction applied to a consumption charge.
        case consumptionReduction = "CONSUMPTION_REDUCTION"
        /// A service charge.
        case service = "SERVICE"
        /// A credit recovery entry.
        case creditRecovery = "CREDIT_RECOVERY"
        /// A debit recovery entry.
        case debitRecovery = "DEBIT_RECOVERY"
        /// A regularization entry.
        case regularization = "REGULARIZATION"
        /// A bike purchase or charge.
        case bike = "BIKE"
        /// An option charge.
        case option = "OPTION"
        /// An insurance charge.
        case insurance = "INSURANCE"
        /// An equipment charge.
        case equipment = "EQUIPMENT"
    }
}

// MARK: - Transactions

/// The response for
/// `GET /contracts/{contract}/accounts/{accountId}/transactions[/{transactionId}]`.
public struct Transaction: Codable, Sendable, Identifiable {
    /// The unique ID of the transaction.
    public let id: UUID
    /// The code of the contract the transaction belongs to.
    public let contractCode: String
    /// The unique ID of the account the transaction belongs to.
    public let accountId: UUID
    /// The status of the transaction. This value can be missing.
    public let status: InvoiceStatus?
    /// The nature of the transaction. This value can be missing.
    public let nature: Nature?
    /// The amount of the transaction.
    public let amount: Int
    /// The payment card key used for the transaction. This value can be missing.
    public let pankey: String?
    /// The date the server created the transaction. This value can be missing.
    public let createdAt: Date?
    /// The date the server last updated the transaction. This value can be missing.
    public let updatedAt: Date?
    /// The unique ID of the parent transaction, when this transaction is part of a
    /// group. This value can be missing.
    public let parentId: UUID?
    /// The unique ID of the regulation this transaction relates to. This value can be
    /// missing.
    public let regulationId: UUID?
    /// The unique ID of the offer this transaction relates to. This value can be missing.
    public let offerId: Int64?
    /// The sales included in this transaction. This value can be missing.
    public let sales: [Sale]?
    /// The payment provider reference for the transaction. This value can be missing.
    public let paymentRef: String?
    /// The payment provider used for the transaction. The shape of this value is
    /// unknown.
    public let paymentProvider: String?
    /// The date the customer submitted the transaction. This value can be missing.
    public let submissionDate: Date?
    /// The submission number of the transaction. This value can be missing.
    public let submissionNumber: Int16?
    /// The amount refunded to the customer for the transaction.
    public let paybackAmount: Int
    /// The reason for the refund. This value can be missing.
    public let paybackReason: String?

    /// The nature of a `Transaction`, for example a subscription or a consumption charge.
    public enum Nature: String, Codable, Sendable {
        /// A regularization entry.
        case regularization = "REGULARIZATION"
        /// A refund.
        case refund = "REFUND"
        /// A new subscription.
        case subscription = "SUBSCRIPTION"
        /// A ride consumption charge.
        case consumption = "CONSUMPTION"
        /// A caution deposit.
        case caution = "CAUTION"
        /// A subscription renewal.
        case renewal = "RENEWAL"
        /// A transaction that mixes more than one nature.
        case mixed = "MIXTE"
    }
}
