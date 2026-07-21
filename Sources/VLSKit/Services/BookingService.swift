import Foundation

/// Hold a bike at a stand for later pickup.
public struct BookingService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets the list of bookings for an account.
    /// - Parameter accountId: The unique ID of the account.
    /// - Returns: The list of bookings for the account.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `[Booking]`.
    public func bookings(accountId: UUID) async throws -> [Booking] {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/accounts/\(accountId)/bookings")
        return try await httpClient.send(endpoint)
    }

    /// Creates a new booking for an account.
    /// - Parameters:
    ///   - accountId: The unique ID of the account that makes the booking.
    ///   - booking: The details of the booking to create.
    /// - Returns: The created booking.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Booking`. Throws an encoding error if `booking` cannot convert to JSON.
    public func createBooking(accountId: UUID, booking: CreateBooking) async throws -> Booking {
        let endpoint = try Endpoint.json(
            method: .post,
            path: "contracts/\(contract)/accounts/\(accountId)/bookings",
            body: booking
        )
        return try await httpClient.send(endpoint)
    }
}
