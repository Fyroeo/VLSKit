import Foundation

// MARK: - Processes

/// A generic asynchronous workflow trigger.
/// The API accepts this type at `POST /contracts/{contract}/accounts/{accountId}/processes`.
/// A process can be an account creation step, a subscription, a defect report, or another
/// backend workflow.
public struct Process: Codable, Sendable {
    /// The type of workflow to start.
    public let type: ProcessType
    /// The input parameters for the workflow. Each process type expects different keys.
    public let parameters: [String: JSONValue]

    /// Create a process trigger request.
    /// - Parameters:
    ///   - type: The type of workflow to start.
    ///   - parameters: The input parameters for the workflow. The default value is an empty dictionary.
    public init(type: ProcessType, parameters: [String: JSONValue] = [:]) {
        self.type = type
        self.parameters = parameters
    }
}

/// The type of an asynchronous workflow.
/// The backend supports 21 process types, listed here.
public enum ProcessType: String, Codable, Sendable {
    case accountUnsubscribe = "ACCOUNT_UNSUBSCRIBE"
    case registerPaymentMethod = "REGISTER_PAYMENT_METHOD"
    case shortTermSubscriptionV2 = "SHORT_TERM_SUBSCRIPTION_V2"
    case longTermSubscriptionV2 = "LONG_TERM_SUBSCRIPTION_V2"
    case adpSubscription = "ADP_SUBSCRIPTION"
    case manualResubscriptionV2 = "MANUAL_RESUBSCRIPTION_V2"
    case changeBadge = "CHANGE_BADGE"
    case stationSubscription = "STATION_SUBSCRIPTION"
    case createBikeDefect = "CREATE_BIKE_DEFECT"
    case invoiceTransaction = "INVOICE_TRANSACTION"
    case batterySubscription = "BATTERY_SUBSCRIPTION"
    case createCab = "CREATE_CAB"
    case parkingSubscription = "PARKING_SUBSCRIPTION"
    case vldSubscription = "VLD_SUBSCRIPTION"
    case parkingResubscription = "PARKING_RESUBSCRIPTION"
    case createSalesforceCase = "CREATE_SALESFORCE_CASE"
    case selfcareReturnedBike = "SELFCARE_RETURNED_BIKE"
    case redefineAccountEmail = "REDEFINE_ACCOUNT_EMAIL"
    case selfcareTripAmount = "SELFCARE_TRIP_AMOUNT"
    case selfcareRescindSubscription = "SELFCARE_RESCIND_SUBSCRIPTION"
    case createSponsorshipPromocode = "CREATE_SPONSORSHIP_PROMOCODE"
}

/// The result of an asynchronous workflow.
public struct ProcessResult: Codable, Sendable {
    /// The unique identifier of this workflow execution.
    public let executionId: Int64
    /// The type of workflow that ran. This value can be absent.
    public let type: ProcessType?
    /// True if the workflow ended in an error.
    public let inError: Bool
    /// The error code, if the workflow ended in an error. This value can be absent.
    public let errorCode: String?
    /// True if the caller can resume this workflow.
    public let toResume: Bool
    /// The start time of the workflow, as raw text. This value can be absent.
    public let startTime: String?
    /// The end time of the workflow, as raw text. This value can be absent.
    public let endTime: String?
    /// The output values of the workflow. This value can be absent.
    public let results: [String: JSONValue]?
    /// The error details, if the workflow ended in an error.
    /// The exact shape is unknown, so this value decodes permissively as opaque JSON.
    public let error: JSONValue?
}
