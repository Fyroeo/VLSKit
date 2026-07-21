import Foundation

/// This service starts a generic backend workflow for an account.
///
/// The backend uses the same endpoint for many different workflows, for example an
/// account signup step, a subscription change, or a defect report.
public struct ProcessService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Starts a backend workflow for an account.
    /// - Parameters:
    ///   - accountId: The unique ID of the account that starts the workflow.
    ///   - process: The workflow type and its input parameters.
    ///   - returns: Extra result keys to ask the backend to include in the response.
    ///     Default is empty.
    /// - Returns: The workflow result, including whether it ended with an error.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `ProcessResult`. Throws an encoding error if `process` cannot convert to JSON.
    public func trigger(accountId: UUID, process: Process, returns: [String] = []) async throws -> ProcessResult {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/processes",
            queryItems: returns.map { URLQueryItem(name: "returns", value: $0) },
            headers: ["Content-Type": "application/vnd.processes.v2+json"],
            body: process
        )
        return try await httpClient.send(endpoint)
    }
}
