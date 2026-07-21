import Foundation

// MARK: - Offers

/// A purchasable subscription or pass offer.
/// The API returns this type from `GET /contracts/{contract}/offers[/{offerId}]` (`vg.k`).
public struct Offer: Codable, Sendable, Identifiable {
    /// The unique identifier of the offer.
    public let id: Int64
    /// The code of the contract (bike-share network) that owns this offer.
    public let contractCode: String
    /// The title of the offer. This value can be absent.
    public let title: String?
    /// The full description of the offer. This value can be absent.
    public let description: String?
    /// The short description of the offer. This value can be absent.
    public let shortDescription: String?
    /// The duration of the offer. This value can be absent.
    public let duration: Int?
    /// The price of the offer. This value can be absent.
    public let price: Int64?
    /// The subscription type of the offer. This value can be absent.
    public let type: SubscriptionType?
    /// The minimum age allowed for this offer. This value can be absent.
    public let ageMin: Int16?
    /// The maximum age allowed for this offer. This value can be absent.
    public let ageMax: Int16?
    /// The date when the offer becomes valid. This value can be absent.
    public let validityStart: Date?
    /// The date when the offer stops being valid. This value can be absent.
    public let validityEnd: Date?
    /// The list of badges linked to this offer. This value can be absent.
    public let badges: [Badge]?
    /// True if the offer has one or more active campaigns. This value can be absent.
    public let hasCampaigns: Bool?
    /// The list of platforms that can sell this offer. This value can be absent.
    public let platforms: [Platform]?
    /// The list of payment methods accepted for this offer. This value can be absent.
    public let paymentMethods: [PaymentMethod]?
    /// The payment frequency for this offer. This value can be absent.
    public let paymentFrequency: PaymentFrequency?
    /// The list of proof documents required for this offer.
    /// The full `Proof` type is unknown, so this value decodes permissively as opaque JSON.
    public let proofs: [JSONValue]?
    /// The renewal configuration for this offer.
    /// The JSON key is `renewal`. This property uses the Swift name `renewalConfig` for
    /// clarity. The exact shape is unknown, so this value decodes permissively as
    /// opaque JSON.
    public let renewalConfig: JSONValue?
    /// The number of tickets included in this offer. This value can be absent.
    public let nbTickets: Int?
    /// The account type required for this offer. This value can be absent.
    public let accountType: AccountType?
    /// The list of option identifiers available with this offer. This value can be
    /// absent.
    public let optionIds: [Int64]?
    /// The list of offers related to this offer. This value can be absent.
    public let relatedOffers: [Offer]?
    /// The list of offers that a user can migrate to from this offer. This value can be absent.
    public let offersMigration: [Offer]?
    /// The delay before this offer appears on an invoice. This value can be absent.
    public let invoicingLag: Int?

    enum CodingKeys: String, CodingKey {
        case id, contractCode, title, description, shortDescription, duration, price, type
        case ageMin, ageMax, validityStart, validityEnd, badges, hasCampaigns, platforms
        case paymentMethods, paymentFrequency, proofs
        case renewalConfig = "renewal"
        case nbTickets, accountType
        case optionIds
        case relatedOffers, offersMigration, invoicingLag
    }
}

// MARK: - Offer Groups

/// A group of offers.
/// The API returns this type from `GET /contracts/{contract}/offerGroups[/{group}/offers]` (`vg.k`).
public struct Grouping: Codable, Sendable, Identifiable {
    /// The unique identifier of the group.
    public let id: Int64
    /// The code of the contract that owns this group.
    public let contractCode: String
    /// The title of the group. This value can be absent.
    public let title: String?
    /// The description of the group. This value can be absent.
    public let description: String?
    /// The list of platforms that show this group.
    public let platforms: [Platform]
    /// The list of offer identifiers that belong to this group.
    public let offerIds: [Int64]
    /// The display position of the group, used to sort a list of groups.
    public let position: Int
}

// MARK: - Badges

/// A badge for an offer.
/// The API returns a badge as part of `Offer.badges`, or on its own from
/// `GET /contracts/{contract}/badges/{badgeId}[/logo]`.
public struct Badge: Codable, Sendable, Identifiable {
    /// The unique identifier of the badge.
    public let id: Int64
    /// The name of the badge. This value can be absent.
    public let name: String?
    /// The description of the badge. This value can be absent.
    public let description: String?
    /// The category of the badge.
    public let type: BadgeType
    /// The list of payment methods accepted for the badge. This value can be absent.
    public let paymentMethods: [PaymentMethod]?
    /// The date when the badge becomes valid. This value can be absent.
    public let validityStart: Date?
    /// The date when the badge stops being valid. This value can be absent.
    public let validityEnd: Date?
    /// The identifier of the rate plan linked to the badge. This value can be absent.
    public let ratePlanId: UUID?
    /// The fee amount to reissue the badge. This value can be absent.
    public let amountReedit: Int64?
    /// True if a controlled plug-in process applies to this badge.
    public let isControlledPlugIn: Bool
    /// The sort order of the badge in a list.
    public let badgeOrder: Int16
    /// True if a user can order this badge.
    public let canBeOrdered: Bool
}

/// The category of a badge.
/// The API also uses this type for `RewardPromoCode.badgeType`.
public enum BadgeType: String, Codable, Sendable {
    /// A badge that belongs to the account owner.
    case owner = "OWNER"
    /// A badge issued by an external system.
    case external = "EXTERNAL"
    /// A badge linked to a ticket.
    case ticket = "TICKET"
    /// No badge is linked.
    case noBadge = "NO_BADGE"
}

// MARK: - Bike Models

/// A bike model available for an offer.
/// The API returns this type from `GET /contracts/{contract}/bikemodels`.
public struct BikeModel: Codable, Sendable, Identifiable {
    /// The unique identifier of the bike model.
    public let id: Int64
    /// The code of the contract that owns this bike model.
    public let contractCode: String
    /// The name of the bike model.
    public let name: String
    /// The description of the bike model. This value can be absent.
    public let description: String?
    /// The characteristics of the bike model, as free text.
    public let characteristics: String
    /// The price of the bike model.
    public let price: Int
    /// The date when the bike model becomes available.
    public let availabilityStart: Date
    /// The number of units of the bike model available.
    public let supply: Int
    /// The estimated availability of the bike model, as free text. This value can be absent.
    public let availabilityEstimation: String?
}

// MARK: - Offer Options

/// An option that a user can add to an offer.
/// The API returns this type from `GET /contracts/{contract}/options`.
public struct OfferOption: Codable, Sendable, Identifiable {
    /// The unique identifier of the option.
    public let id: Int64
    /// The name of the option.
    public let name: String
    /// The description of the option.
    public let description: String
    /// The category of the option. The JSON key is `optionType`. This value can be absent.
    public let type: OptionType?
    /// A more specific classification of the option. The JSON key is `optionSubtype`.
    /// This value can be absent.
    public let subType: OptionSubType?
    /// Where payment happens for the option. This value can be absent.
    public let paymentPlace: PaymentPlace?
    /// The price of the option.
    public let amount: Double
    /// The payment frequency for the option. This value can be absent.
    public let paymentFrequency: PaymentFrequency?
    /// The date when the option becomes valid.
    public let validityStart: Date
    /// The date when the option stops being valid. This value can be absent.
    public let validityEnd: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case type = "optionType"
        case subType = "optionSubtype"
        case paymentPlace, amount, paymentFrequency, validityStart, validityEnd
    }

    /// The category of an offer option.
    public enum OptionType: String, Codable, Sendable {
        /// Physical equipment, for example a child seat.
        case equipment = "EQUIPMENT"
        /// A service, for example maintenance.
        case service = "SERVICE"
        /// An insurance option.
        case insurance = "INSURANCE"
        /// A delivery option.
        case delivery = "DELIVERY"
    }

    /// Further detail for an option of type `delivery`.
    public enum OptionSubType: String, Codable, Sendable {
        /// Delivery to a shop for pickup.
        case deliveryShop = "DELIVERY_SHOP"
        /// Delivery to the user's home.
        case deliveryHome = "DELIVERY_HOME"
    }
}

// MARK: - Purchase Packages

/// A pricing breakdown for a possible purchase.
/// The API returns this type from `POST .../offers/{offerId}/packages`, and from the
/// related badge and supplement package endpoints.
public struct PackageInfo: Codable, Sendable {
    /// The identifier of the offer this package is for.
    public let offerId: Int64
    /// The identifier of the pricing subtype for the offer.
    public let subtypeKiwiId: Int64
    /// The price of the offer before any reduction. This value can be absent.
    public let initialPrice: Int?
    /// The amount deducted from the initial price. This value can be absent.
    public let reductionAmount: Int?
    /// The price of the offer after the reduction. This value can be absent.
    public let finalPrice: Int?
    /// The total price of the selected options when paid online. This value can be absent.
    public let optionOnlinePrice: Int?
    /// The total price of the selected options when paid in a shop. This value can be absent.
    public let optionShopPrice: Int?
    /// The identifier of the campaign applied to this package. This value can be absent.
    public let campaignId: Int64?
    /// The type of the campaign applied to this package. This value can be absent.
    public let campaignType: Campaign.CampaignType?
    /// The date when the resulting subscription ends. This value can be absent.
    public let subscriptionEndDate: Date?
    /// True if this package blocks the purchase flow. This value can be absent.
    public let isBlocking: Bool?
    /// The list of payment methods accepted for this package. This value can be absent.
    public let paymentMethods: [PaymentMethod]?
    /// The list of deferred payment items for this package.
    /// The full item shape is unknown, so this value decodes permissively as opaque JSON.
    public let deferreds: [JSONValue]?
    /// The list of deferred payment items for an in-shop purchase.
    /// The full item shape is unknown, so this value decodes permissively as opaque JSON.
    public let deferredsShop: [JSONValue]?
    /// The upfront payment information for this package.
    /// The full shape is unknown, so this value decodes permissively as opaque JSON.
    public let sight: JSONValue?
    /// The list of selected option details for this package.
    /// The full shape is unknown, so this value decodes permissively as opaque JSON.
    public let options: [JSONValue]?
    /// The list of selected supplement details for this package.
    /// The full shape is unknown, so this value decodes permissively as opaque JSON.
    public let supplements: [JSONValue]?
    /// The list of item sale details for this package.
    /// The full shape is unknown, so this value decodes permissively as opaque JSON.
    public let itemSales: [JSONValue]?
}

/// The request body for `POST .../offers/{offerId}/packages`.
public struct PackageOptions: Codable, Sendable {
    /// The promotional code to apply. This value can be absent.
    public let promocode: String?
    /// The requested start date for the subscription, sent as plain text rather than
    /// a parsed date. This value can be absent.
    public let subscriptionStart: String?
    /// The user's birth date, sent as plain text rather than a parsed date.
    /// This value can be absent.
    public let birthDate: String?
    /// The identifier of the requested bike model. This value can be absent.
    public let bikeModelId: Int64?
    /// The payment method to use for this package. This value can be absent.
    public let paymentMethod: PaymentMethod?
    /// The list of option identifiers to include in this package. This value can be absent.
    public let optionIds: [Int64]?

    /// Create a request body for a package options request.
    /// - Parameters:
    ///   - promocode: The promotional code to apply. The default value is `nil`.
    ///   - subscriptionStart: The requested start date, as plain text. The default value is `nil`.
    ///   - birthDate: The user's birth date, as plain text. The default value is `nil`.
    ///   - bikeModelId: The identifier of the requested bike model. The default value is `nil`.
    ///   - paymentMethod: The payment method to use. The default value is `nil`.
    ///   - optionIds: The list of option identifiers to include. The default value is `nil`.
    public init(
        promocode: String? = nil,
        subscriptionStart: String? = nil,
        birthDate: String? = nil,
        bikeModelId: Int64? = nil,
        paymentMethod: PaymentMethod? = nil,
        optionIds: [Int64]? = nil
    ) {
        self.promocode = promocode
        self.subscriptionStart = subscriptionStart
        self.birthDate = birthDate
        self.bikeModelId = bikeModelId
        self.paymentMethod = paymentMethod
        self.optionIds = optionIds
    }
}

// MARK: - Supplements

/// The request body for `POST .../offers/{offerId}/supplements/packages`, and for the
/// related badge endpoint.
public struct OfferSupplements: Codable, Sendable {
    /// The list of selected supplements and their chosen items. This value can be absent.
    public let supplements: [SupplementWithItems]?
    /// The promotional code to apply. This value can be absent.
    public let promocode: String?
    /// The requested start date for the subscription, sent as plain text rather than
    /// a parsed date. This value can be absent.
    public let subscriptionStart: String?
    /// The user's birth date, sent as plain text rather than a parsed date.
    /// This value can be absent.
    public let birthDate: String?
    /// The payment method to use. This value can be absent.
    public let paymentMethod: PaymentMethod?
    /// The delivery method for physical supplements. This value can be absent.
    public let deliveryType: DeliveryType?
    /// The identifier of the requested bike model. This value can be absent.
    public let bikeModelId: Int64?
    /// True if this request is for a subscription renewal. This value can be absent.
    public let renewal: Bool?

    /// Create a request body for a supplement package purchase.
    /// - Parameters:
    ///   - supplements: The selected supplements and their chosen items. The default value is `nil`.
    ///   - promocode: The promotional code to apply. The default value is `nil`.
    ///   - subscriptionStart: The requested start date, as plain text. The default value is `nil`.
    ///   - birthDate: The user's birth date, as plain text. The default value is `nil`.
    ///   - paymentMethod: The payment method to use. The default value is `nil`.
    ///   - deliveryType: The delivery method for physical supplements. The default value is `nil`.
    ///   - bikeModelId: The identifier of the requested bike model. The default value is `nil`.
    ///   - renewal: True if this request is for a subscription renewal. The default value is `nil`.
    public init(
        supplements: [SupplementWithItems]? = nil,
        promocode: String? = nil,
        subscriptionStart: String? = nil,
        birthDate: String? = nil,
        paymentMethod: PaymentMethod? = nil,
        deliveryType: DeliveryType? = nil,
        bikeModelId: Int64? = nil,
        renewal: Bool? = nil
    ) {
        self.supplements = supplements
        self.promocode = promocode
        self.subscriptionStart = subscriptionStart
        self.birthDate = birthDate
        self.paymentMethod = paymentMethod
        self.deliveryType = deliveryType
        self.bikeModelId = bikeModelId
        self.renewal = renewal
    }
}

/// The delivery method for a physical supplement item.
public enum DeliveryType: String, Codable, Sendable {
    /// Delivery to the user's home.
    case home = "HOME"
    /// Delivery to a shop for pickup.
    case shop = "SHOP"
}

/// A supplement that a user can add to an offer.
/// The API returns this type from `GET /contracts/{contract}/offers/{offerId}/supplements[?isValid=]`.
public struct Supplement: Codable, Sendable, Identifiable {
    /// The unique identifier of the supplement.
    public let id: UUID
    /// The identifier of the offer this supplement belongs to.
    public let offer: Int64
    /// The code of the contract that owns this supplement.
    public let contractCode: String
    /// The display order of the supplement. This value can be absent.
    public let order: Int?
    /// The label of the supplement. This value can be absent.
    public let label: String?
    /// The description of the supplement. This value can be absent.
    public let description: String?
    /// Where payment happens for the supplement. This value can be absent.
    public let paymentPlace: PaymentPlace?
    /// The payment frequency for the supplement. This value can be absent.
    public let paymentFrequency: PaymentFrequency?
    /// The selection rule for the supplement's items. This value can be absent.
    public let count: SupplementCount?
    /// The list of item identifiers available for this supplement.
    /// These are plain identifiers, not full `OfferItem` objects. Call
    /// `OfferService.supplementItems(offerId:supplementId:isValid:)` to get the full item
    /// details. This value can be absent.
    public let items: [UUID]?
    /// The list of delivery options for this supplement. This value can be absent.
    public let deliveries: [Delivery]?
}

/// The selection rule for a supplement's items.
public enum SupplementCount: String, Codable, Sendable {
    /// The user must include this supplement.
    case mandatory = "MANDATORY"
    /// The user can select exactly one item.
    case one = "ONE"
    /// The user can select more than one item.
    case many = "MANY"
}

/// One available delivery option for a supplement, with its order and price.
public struct Delivery: Codable, Sendable {
    /// The delivery method for this option. This value can be absent.
    public let type: DeliveryType?
    /// The display order of this delivery option. This value can be absent.
    public let order: Int?
    /// The price of this delivery option.
    public let price: Int64
}

/// A selected supplement and its chosen item identifiers, sent as part of `OfferSupplements`.
public struct SupplementWithItems: Codable, Sendable {
    /// The identifier of the selected supplement. This value can be absent.
    public let id: UUID?
    /// The list of chosen item identifiers for the supplement. This value can be absent.
    public let items: [UUID]?

    /// Create a selected supplement with its chosen items.
    /// - Parameters:
    ///   - id: The identifier of the selected supplement. The default value is `nil`.
    ///   - items: The list of chosen item identifiers. The default value is `nil`.
    public init(id: UUID? = nil, items: [UUID]? = nil) {
        self.id = id
        self.items = items
    }
}

/// A purchasable supplement item, for example a helmet or a child seat.
/// The API returns this type from `GET .../supplements/{supplementId}/items`.
public struct OfferItem: Codable, Sendable, Identifiable {
    /// The unique identifier of the item.
    public let id: UUID
    /// The label of the item.
    public let label: String
    /// The description of the item.
    public let description: String
    /// The base price of the item.
    public let basePrice: Int64
    /// The date when the item becomes valid. This value can be absent.
    public let validityStart: Date?
    /// The date when the item stops being valid. This value can be absent.
    public let validityEnd: Date?
    /// A link to more information about the item. This value can be absent.
    public let externalLink: String?
    /// One or more tags for the item, stored as a single text value rather than a list.
    /// This value can be absent.
    public let tags: String?
}

// MARK: - Renewals

/// The available renewal offers for a subscription.
/// The API returns this type from `GET .../subscriptions/{subscriptionId}/renewaloffers`.
public struct RenewalOffers: Codable, Sendable {
    /// The list of offer identifiers available for renewal. This value can be absent.
    public let available: [Int64]?
    /// The identifier of the suggested next offer. This value can be absent.
    public let next: Int64?
}

// MARK: - Terms and Conditions

/// A terms and conditions document.
/// The API returns this type from `GET /contracts/{contract}/cgau[/{type}/...]`.
public struct CGAU: Codable, Sendable {
    /// The version identifier of the document.
    public let version: String
    /// The category of terms and conditions. This value can be absent.
    public let type: CGAUType?
    /// How significant this version is compared to the previous version. This value can be absent.
    public let amendmentLevel: CGAUAmendmentLevel?
    /// The date when this version becomes valid. This value can be absent.
    public let validityStart: Date?
    /// The date when this version stops being valid. This value can be absent.
    public let validityEnd: Date?
    /// True if this version is currently valid. This value can be absent.
    public let isValid: Bool?
    /// The identifier of the underlying document. This value can be absent.
    public let documentId: UUID?
}

/// The category of a terms and conditions document.
public enum CGAUType: String, Codable, Sendable {
    /// Terms for the bike-share service.
    case vls = "VLS"
    /// Terms for the long-term rental service.
    case vld = "VLD"
    /// Terms for the parking service.
    case parking = "PARKING"
}

/// How significant a terms and conditions amendment is, compared to the previous version.
public enum CGAUAmendmentLevel: String, Codable, Sendable {
    case minor = "MINOR"
    case substantial = "SUBSTANTIAL"
    case major = "MAJOR"
}

// MARK: - Campaigns

/// A promotional campaign.
/// The API returns this type from `GET /contracts/{contract}/campaigns/{id}` (`vg.e`).
public struct Campaign: Codable, Sendable, Identifiable {
    /// The unique identifier of the campaign.
    public let id: Int64
    /// The name of the campaign. This value can be absent.
    public let name: String?
    /// Whether the campaign uses one unique code or a generic shared code.
    public let type: CampaignType
    /// How the backend calculates the discount for this campaign.
    public let promotionType: PromotionType
    /// The generic promotional code configuration for this campaign.
    /// The exact shape is unknown, so this value decodes permissively as opaque JSON.
    /// This value can be absent.
    public let genericPromoCode: JSONValue?
    /// The discount value for this campaign. The meaning depends on `promotionType`,
    /// for example a fixed amount or a percentage.
    public let discount: Double
    /// The date when the campaign becomes valid.
    public let validityStart: Date
    /// The date when the campaign stops being valid. This value can be absent.
    public let validityEnd: Date?
    /// The list of offer identifiers this campaign applies to.
    public let offersIds: [Int64]

    enum CodingKeys: String, CodingKey {
        case id, name
        case type = "campaignType"
        case promotionType, genericPromoCode, discount, validityStart, validityEnd, offersIds
    }

    /// Whether a campaign code is unique to one user or shared by many users.
    public enum CampaignType: String, Codable, Sendable {
        /// A code that only one user can use.
        case unique = "UNIQUE"
        /// A code that many users can share.
        case generic = "GENERIC"
    }

    /// How the backend calculates a campaign discount.
    public enum PromotionType: String, Codable, Sendable {
        /// A fixed discount amount.
        case fixAmount = "FIX_AMOUNT"
        /// A discount as a percentage.
        case percentage = "PERCENTAGE"
    }
}
