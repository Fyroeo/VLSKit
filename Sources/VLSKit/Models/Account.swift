import Foundation

// MARK: - Address

/// Street address for `Account` and `PatchAccount`.
///
/// The `zipCode`, `city`, and `country` fields live on the parent `Account`
/// type. `Address` holds only the street line and a complement line.
/// This shape is a best-effort guess. Check it against a real
/// `GET .../accounts/{id}` response and adjust it if it does not match.
public struct Address: Codable, Sendable {
    /// Street line of the address, for example the house number and street name.
    public let street: String?
    /// Extra address line, for example an apartment or building number.
    public let complement: String?

    /// Create a street address.
    /// - Parameters:
    ///   - street: Street line of the address. The default is `nil`.
    ///   - complement: Extra address line. The default is `nil`.
    public init(street: String? = nil, complement: String? = nil) {
        self.street = street
        self.complement = complement
    }
}

// MARK: - Enumerations

/// Sex value stored on an account.
public enum Sex: String, Codable, Sendable {
    /// Sex is not known or not set.
    case unknown = "UNKNOWN"
    /// Male.
    case male = "M"
    /// Female.
    case female = "F"
    /// A value other than male or female.
    case other = "O"
}

/// State of an opt-in prompt on an account, for example `Account.optInSystem`.
public enum OptIn: String, Codable, Sendable {
    /// The user has not seen the prompt yet.
    case unseen = "UNSEEN"
    /// The user has seen the prompt.
    case seen = "SEEN"
    /// The user has turned on the opt-in.
    case activated = "ACTIVATED"
}

/// Type of account on a contract.
public enum AccountType: String, Codable, Sendable {
    /// A VIP account.
    case vip = "VIP"
    /// An enterprise (business) account.
    case enterprise = "ENTERPRISE"
    /// A normal end-user account.
    case endUser = "END_USER"
}

// MARK: - Account

/// A rider account on a contract.
///
/// This is the response body for `GET /contracts/{contract}/accounts/{accountId}`.
public struct Account: Codable, Sendable, Identifiable {
    /// Unique ID of the account.
    public let id: UUID?
    /// Email address of the account.
    public let email: String
    /// Date and time the server created the account.
    public let createdAt: Date?
    /// Code of the contract that owns this account.
    public let contractCode: String
    /// First name of the account holder.
    public let firstName: String?
    /// Last name of the account holder.
    public let lastName: String?
    /// Personal identifier of the account holder, for example a national ID number.
    public let personalIdentifier: String?
    /// Sex of the account holder.
    public let sex: Sex?
    /// Phone number of the account holder.
    public let phoneNumber: String?
    /// Date of birth of the account holder.
    public let birthDate: Date?
    /// Street address of the account holder.
    public let address: Address?
    /// Postal code of the account holder's address.
    public let zipCode: String?
    /// City of the account holder's address.
    public let city: String?
    /// Country of the account holder's address.
    public let country: String?
    /// Default locale for this account, for example `"fr-FR"`.
    public let defaultLocale: String?
    /// State of the system opt-in for this account.
    public let optInSystem: OptIn?
    /// State of the partner opt-in for this account.
    public let optInPartner: OptIn?
    /// IDs of the child accounts linked to this account.
    public let children: [UUID]
    /// Fraction of the account profile that is complete.
    public let completion: Double?
    /// ID of the payment information linked to this account.
    public let paymentInfosId: String?
    /// Numbers of the stations linked to this account.
    public let stations: Set<Int>
    /// True if this is an anonymous account.
    public let isAnonymous: Bool?
    /// True if the account is locked.
    public let isLocked: Bool
    /// Free-form tags attached to the account.
    public let tags: Set<String>?
    /// Type of this account.
    public let type: AccountType
}

// MARK: - Account updates

/// Partial update body for `PATCH /contracts/{contract}/accounts/{accountId}`.
///
/// Every field is optional. Send only the fields that changed. The
/// `birthDate` field is a plain string here, not a `Date`, unlike
/// `Account.birthDate`.
public struct PatchAccount: Codable, Sendable {
    /// New sex value for the account.
    public var sex: Sex?
    /// New last name for the account.
    public var lastName: String?
    /// New first name for the account.
    public var firstName: String?
    /// New date of birth for the account, as a plain string, not a `Date`.
    public var birthDate: String?
    /// New phone number for the account.
    public var phoneNumber: String?
    /// New user name for the account.
    public var userName: String?
    /// New street address for the account.
    public var address: Address?
    /// New postal code for the account.
    public var zipCode: String?
    /// New city for the account.
    public var city: String?
    /// New country for the account.
    public var country: String?
    /// New state for the system opt-in.
    public var optInSystem: Bool?
    /// New state for the partner opt-in.
    public var optInPartner: Bool?

    /// Create a partial account update.
    /// - Parameters:
    ///   - sex: New sex value for the account. The default is `nil`.
    ///   - lastName: New last name for the account. The default is `nil`.
    ///   - firstName: New first name for the account. The default is `nil`.
    ///   - birthDate: New date of birth, as a plain string. The default is `nil`.
    ///   - phoneNumber: New phone number for the account. The default is `nil`.
    ///   - userName: New user name for the account. The default is `nil`.
    ///   - address: New street address for the account. The default is `nil`.
    ///   - zipCode: New postal code for the account. The default is `nil`.
    ///   - city: New city for the account. The default is `nil`.
    ///   - country: New country for the account. The default is `nil`.
    ///   - optInSystem: New state for the system opt-in. The default is `nil`.
    ///   - optInPartner: New state for the partner opt-in. The default is `nil`.
    public init(
        sex: Sex? = nil,
        lastName: String? = nil,
        firstName: String? = nil,
        birthDate: String? = nil,
        phoneNumber: String? = nil,
        userName: String? = nil,
        address: Address? = nil,
        zipCode: String? = nil,
        city: String? = nil,
        country: String? = nil,
        optInSystem: Bool? = nil,
        optInPartner: Bool? = nil
    ) {
        self.sex = sex
        self.lastName = lastName
        self.firstName = firstName
        self.birthDate = birthDate
        self.phoneNumber = phoneNumber
        self.userName = userName
        self.address = address
        self.zipCode = zipCode
        self.city = city
        self.country = country
        self.optInSystem = optInSystem
        self.optInPartner = optInPartner
    }
}

/// Profile-completion body for `PATCH /contracts/{contract}/accounts/{accountId}`.
///
/// The app sends this shape right after signup, to complete the rider's
/// profile. This differs from later edits, which use `PatchAccount`. Both
/// requests use the same path, with a different payload shape.
public struct CompleteAccount: Codable, Sendable {
    /// Sex of the account holder.
    public var sex: Sex?
    /// Last name of the account holder.
    public var lastName: String?
    /// First name of the account holder.
    public var firstName: String?
    /// Date of birth of the account holder, as a plain string, not a `Date`.
    public var birthDate: String?
    /// Phone number of the account holder.
    public var phoneNumber: String?
    /// Personal identifier of the account holder, for example a national ID number.
    public var personalIdentifier: String?

    /// Create a profile-completion request.
    /// - Parameters:
    ///   - sex: Sex of the account holder. The default is `nil`.
    ///   - lastName: Last name of the account holder. The default is `nil`.
    ///   - firstName: First name of the account holder. The default is `nil`.
    ///   - birthDate: Date of birth, as a plain string. The default is `nil`.
    ///   - phoneNumber: Phone number of the account holder. The default is `nil`.
    ///   - personalIdentifier: Personal identifier of the account holder. The default is `nil`.
    public init(
        sex: Sex? = nil,
        lastName: String? = nil,
        firstName: String? = nil,
        birthDate: String? = nil,
        phoneNumber: String? = nil,
        personalIdentifier: String? = nil
    ) {
        self.sex = sex
        self.lastName = lastName
        self.firstName = firstName
        self.birthDate = birthDate
        self.phoneNumber = phoneNumber
        self.personalIdentifier = personalIdentifier
    }
}
