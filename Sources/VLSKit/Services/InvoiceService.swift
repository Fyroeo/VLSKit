import Foundation

/// This service wraps the balance, transaction, and sale (invoice line item) endpoints
/// for an account.
public struct InvoiceService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    // MARK: - Balance

    /// Gets the balance for an account.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The balance for the account.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Balance`.
    public func balance(accountId: UUID) async throws -> Balance {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/balance",
            headers: ["Accept": "application/vnd.balance.v1+json"]
        )
        return try await httpClient.send(endpoint)
    }

    // MARK: - Transactions

    /// Gets the list of transactions for an account.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - showRegulationId: True to ask the server to include the regulation ID field in
    ///     each transaction. The default value is nil.
    /// - Returns: The list of transactions for the account.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Transaction]`.
    public func transactions(accountId: UUID, showRegulationId: Bool? = nil) async throws -> [Transaction] {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/transactions",
            queryItems: queryItems(["showRegulationId": showRegulationId]),
            headers: ["Accept": "application/vnd.transaction.v1+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Gets one transaction for an account.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - transactionId: The unique ID of the transaction.
    /// - Returns: The transaction.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Transaction`.
    public func transaction(accountId: UUID, transactionId: UUID) async throws -> Transaction {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/transactions/\(transactionId)",
            headers: ["Accept": "application/vnd.transaction.v1+json"]
        )
        return try await httpClient.send(endpoint)
    }

    /// Downloads the PDF bill for a transaction.
    ///
    /// This method returns the raw PDF bytes. The original app marked this endpoint
    /// `@Streaming`. Write the bytes to a file, or pass them to a PDF viewer.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - transactionId: The unique ID of the transaction.
    /// - Returns: The raw bytes of the PDF bill.
    /// - Throws: `VLSError` if the request fails.
    public func bill(accountId: UUID, transactionId: UUID) async throws -> Data {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/transactions/\(transactionId)/bill",
            headers: ["Content-Type": "application/vnd.transaction.v1+json"]
        )
        return try await httpClient.sendRaw(endpoint)
    }

    // MARK: - Sales

    /// Gets the list of sale line items for an account, with optional filters.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - infoType: A filter value for the sale info type. The exact meaning of this
    ///     field is unknown. The default value is nil.
    ///   - natures: The sale natures to filter by. The default value is nil.
    ///   - saleDateAfter: Return only sales dated after this value. The default value is
    ///     nil.
    ///   - status: The sale statuses to filter by. The default value is nil.
    ///   - direction: The direction to filter by, debit or credit. The default value is
    ///     nil.
    /// - Returns: The list of matching sale line items.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Sale]`.
    public func sales(
        accountId: UUID,
        infoType: String? = nil,
        natures: [Sale.Nature]? = nil,
        saleDateAfter: String? = nil,
        status: [InvoiceStatus]? = nil,
        direction: InvoiceDirection? = nil
    ) async throws -> [Sale] {
        var items = queryItems(["infoType": infoType, "saleDateAfter": saleDateAfter, "direction": direction?.rawValue])
        natures?.forEach { items.append(URLQueryItem(name: "natures", value: $0.rawValue)) }
        status?.forEach { items.append(URLQueryItem(name: "status", value: $0.rawValue)) }

        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/accounts/\(accountId)/sales",
            queryItems: items,
            headers: ["Accept": "application/vnd.sale.v1+json"]
        )
        return try await httpClient.send(endpoint)
    }
}
