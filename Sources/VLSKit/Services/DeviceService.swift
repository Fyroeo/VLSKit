import Foundation

/// This service registers a device for push notifications.
public struct DeviceService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Registers a device for push notifications.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - device: The device registration to add.
    /// - Returns: The registered device.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Device`. Throws an encoding error if `device` cannot convert to JSON.
    public func register(accountId: UUID, device: Device) async throws -> Device {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/devices",
            headers: ["Content-Type": "application/vnd.message.v2+json"],
            body: device
        )
        return try await httpClient.send(endpoint)
    }

    /// Removes a device registration for push notifications.
    ///
    /// This call uses the DELETE method with a JSON body, unlike a typical DELETE
    /// request.
    /// - Parameters:
    ///   - accountId: The unique ID of the account.
    ///   - device: The device registration to remove.
    /// - Throws: `VLSError` if the request fails. Throws an encoding error if `device`
    ///   cannot convert to JSON.
    public func unregister(accountId: UUID, device: Device) async throws {
        let endpoint = try Endpoint.json(
            method: .delete,
            path: "contracts/\(contract)/accounts/\(accountId)/devices",
            headers: ["Content-Type": "application/vnd.message.v2+json"],
            body: device
        )
        try await httpClient.sendVoid(endpoint)
    }
}
