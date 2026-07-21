import Foundation

/// This service wraps the offer endpoints for a contract.
///
/// It handles offers, badges, options, CGAU documents, packages, and supplements.
/// This is the largest service in this API.
public struct OfferService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    // MARK: - Offers

    /// Gets one offer by its ID.
    /// - Parameter offerId: The unique ID of the offer.
    /// - Returns: The offer.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Offer`.
    public func offer(offerId: Int64) async throws -> Offer {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/offers/\(offerId)",
            headers: ["Accept": "application/vnd.offer.v2+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the list of all offers for the contract.
    /// - Returns: The list of offers.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Offer]`.
    public func offers() async throws -> [Offer] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/offers",
            headers: ["Accept": "application/vnd.offer.v2+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the offer groups shown on a platform.
    /// - Parameter platform: The platform to filter by.
    /// - Returns: The list of offer groups.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Grouping]`.
    public func offerGroups(platform: Platform) async throws -> [Grouping] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/offerGroups",
            queryItems: queryItems(["platform": platform.rawValue])
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the offers that belong to a group.
    /// - Parameter group: The unique ID of the offer group.
    /// - Returns: The list of offers in the group.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Offer]`.
    public func offers(inGroup group: Int64) async throws -> [Offer] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/offerGroups/\(group)/offers",
            headers: ["Accept": "application/vnd.offer.v2+json"]
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Bike Models

    /// Gets the list of bike models available for an offer.
    /// - Parameter isValid: True to return only bike models that are currently valid.
    /// - Returns: The list of bike models.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[BikeModel]`.
    public func bikeModels(isValid: Bool) async throws -> [BikeModel] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/bikemodels",
            queryItems: queryItems(["isValid": isValid])
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Badges

    /// Gets one badge by its ID.
    /// - Parameter badgeId: The unique ID of the badge.
    /// - Returns: The badge.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Badge`.
    public func badge(badgeId: Int64) async throws -> Badge {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/badges/\(badgeId)")
        return try await httpClient.send(endpoint)
    }

    /// Gets the logo document reference for a badge.
    /// - Parameter badgeId: The unique ID of the badge.
    /// - Returns: A reference to the badge logo document.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `RemoteDocumentReference`.
    public func badgeLogo(badgeId: Int64) async throws -> RemoteDocumentReference {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/badges/\(badgeId)/logo")
        return try await httpClient.send(endpoint)
    }

    // MARK: - Items

    /// Gets the logo document reference for a supplement item.
    /// - Parameter itemId: The unique ID of the item.
    /// - Returns: A reference to the item logo document.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `RemoteDocumentReference`.
    public func itemLogo(itemId: UUID) async throws -> RemoteDocumentReference {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/items/\(itemId)/logo")
        return try await httpClient.send(endpoint)
    }

    // MARK: - Options

    /// Gets the options available for an offer.
    /// - Parameters:
    ///   - offerId: The unique ID of the offer.
    ///   - type: The option category to filter by.
    ///   - isValid: True to return only options that are currently valid.
    /// - Returns: The list of matching options.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[OfferOption]`.
    public func options(offerId: Int64, type: OfferOption.OptionType, isValid: Bool) async throws -> [OfferOption] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/options",
            queryItems: queryItems(["offerId": offerId, "optionType": type.rawValue, "isValid": isValid])
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - CGAU

    /// Gets the list of all CGAU documents for the contract.
    /// - Returns: The list of CGAU documents.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[CGAU]`.
    public func cgauList() async throws -> [CGAU] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/cgau",
            headers: ["Accept": "application/vnd.cgau.v2+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the current valid terms and conditions document for a category.
    /// - Parameter type: The category of terms and conditions to get.
    /// - Returns: The current valid CGAU document.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `CGAU`.
    public func currentCGAU(type: CGAUType) async throws -> CGAU {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/cgau/\(type.rawValue)/valid",
            headers: ["Accept": "application/vnd.cgau.v2+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets a reference to the file for the current valid CGAU document in a category.
    /// - Parameter type: The category of terms and conditions to get.
    /// - Returns: A reference to the CGAU file.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `RemoteDocumentReference`.
    public func currentCGAUFile(type: CGAUType) async throws -> RemoteDocumentReference {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/cgau/\(type.rawValue)/valid/file",
            headers: ["Accept": "application/vnd.cgau.v2+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets a reference to the file for a specific CGAU document version.
    /// - Parameters:
    ///   - type: The category of terms and conditions to get.
    ///   - version: The version identifier of the document.
    /// - Returns: A reference to the CGAU file.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `RemoteDocumentReference`.
    public func cgauFile(type: CGAUType, version: String) async throws -> RemoteDocumentReference {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/cgau/\(type.rawValue)/versions/\(version)/file",
            headers: ["Accept": "application/vnd.cgau.v2+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets a reference to the content of a proof document.
    /// - Parameter proofId: The unique ID of the proof document.
    /// - Returns: A reference to the proof content.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `RemoteDocumentReference`.
    public func proof(proofId: Int64) async throws -> RemoteDocumentReference {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/proofs/\(proofId)/content")
        return try await httpClient.send(endpoint)
    }

    // MARK: - Supplements

    /// Gets the supplements available for an offer.
    /// - Parameters:
    ///   - offerId: The unique ID of the offer.
    ///   - isValid: True to return only supplements that are currently valid.
    /// - Returns: The list of matching supplements.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Supplement]`.
    public func supplements(offerId: Int64, isValid: Bool) async throws -> [Supplement] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/offers/\(offerId)/supplements",
            queryItems: queryItems(["isValid": isValid])
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets the purchasable items for a supplement.
    /// - Parameters:
    ///   - offerId: The unique ID of the offer.
    ///   - supplementId: The unique ID of the supplement.
    ///   - isValid: True to return only items that are currently valid.
    /// - Returns: The list of matching items.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[OfferItem]`.
    public func supplementItems(offerId: Int64, supplementId: UUID, isValid: Bool) async throws -> [OfferItem] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/offers/\(offerId)/supplements/\(supplementId)/items",
            queryItems: queryItems(["isValid": isValid])
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Purchase / package pricing

    /// Gets the pricing breakdown for a possible purchase of an offer.
    /// - Parameters:
    ///   - offerId: The unique ID of the offer.
    ///   - options: The requested purchase options, for example a promo code or bike
    ///     model.
    /// - Returns: The pricing breakdown for the purchase.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `PackageInfo`. Throws an encoding error if `options` cannot convert to JSON.
    public func packages(offerId: Int64, options: PackageOptions) async throws -> PackageInfo {
        let endpoint = try Endpoint.json(method: .post, path: "contracts/\(contract)/offers/\(offerId)/packages", body: options)
        return try await httpClient.send(endpoint)
    }

    /// Gets the pricing breakdown for a possible purchase of an offer with a badge.
    /// - Parameters:
    ///   - offerId: The unique ID of the offer.
    ///   - badgeId: The unique ID of the badge.
    ///   - options: The requested purchase options, for example a promo code or bike
    ///     model.
    /// - Returns: The pricing breakdown for the purchase.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `PackageInfo`. Throws an encoding error if `options` cannot convert to JSON.
    public func badgePackages(offerId: Int64, badgeId: Int64, options: PackageOptions) async throws -> PackageInfo {
        let endpoint = try Endpoint.json(method: .post, path: "contracts/\(contract)/offers/\(offerId)/badges/\(badgeId)/packages", body: options)
        return try await httpClient.send(endpoint)
    }

    /// Gets the pricing breakdown for a possible purchase of an offer with supplements.
    /// - Parameters:
    ///   - offerId: The unique ID of the offer.
    ///   - supplements: The selected supplements and their chosen items.
    /// - Returns: The pricing breakdown for the purchase.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `PackageInfo`. Throws an encoding error if `supplements` cannot convert to JSON.
    public func supplementPackages(offerId: Int64, supplements: OfferSupplements) async throws -> PackageInfo {
        let endpoint = try Endpoint.json(method: .post, path: "contracts/\(contract)/offers/\(offerId)/supplements/packages", body: supplements)
        return try await httpClient.send(endpoint)
    }

    /// Gets the pricing breakdown for a possible purchase of an offer with a badge and
    /// supplements.
    /// - Parameters:
    ///   - offerId: The unique ID of the offer.
    ///   - badgeId: The unique ID of the badge.
    ///   - supplements: The selected supplements and their chosen items.
    /// - Returns: The pricing breakdown for the purchase.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `PackageInfo`. Throws an encoding error if `supplements` cannot convert to JSON.
    public func supplementBadgePackages(offerId: Int64, badgeId: Int64, supplements: OfferSupplements) async throws -> PackageInfo {
        let endpoint = try Endpoint.json(method: .post, path: "contracts/\(contract)/offers/\(offerId)/supplements/badges/\(badgeId)/packages", body: supplements)
        return try await httpClient.send(endpoint)
    }

    // MARK: - Account-scoped offer eligibility / renewal

    /// Gets the available renewal offers for a subscription.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - subscriptionId: The unique ID of the subscription to renew.
    ///   - platform: The platform to filter by.
    /// - Returns: The available renewal offers.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `RenewalOffers`.
    public func renewalOffers(accountId: UUID, subscriptionId: UUID, platform: Platform) async throws -> RenewalOffers {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/subscriptions/\(subscriptionId)/renewaloffers",
            queryItems: queryItems(["platform": platform.rawValue]),
            headers: ["Accept": "application/vnd.renewalOffer.v2+json"]
        )
        return try await httpClient.send(endpoint)
    }
}
