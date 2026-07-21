import Foundation

/// A bike held at a stand for a rider to walk over and collect.
///
/// This is the response body for
/// `GET /contracts/{contract}/accounts/{accountId}/bookings`.
public struct Booking: Codable, Sendable, Identifiable {
    /// Unique ID of the booking.
    public let id: UUID
    /// Name of the contract for this booking.
    public let contractName: String
    /// ID of the account that holds this booking.
    public let accountId: UUID
    /// ID of the subscription used for this booking.
    public let subscriptionId: UUID
    /// ID of the station where the booked bike is held, if known.
    public let stationId: UUID?
    /// Number of the station where the booked bike is held, if known.
    public let stationNumber: Int?
    /// Number of the stand that holds the booked bike, if known.
    public let standNumber: Int16?
    /// ID of the booked bike.
    public let bikeId: UUID
    /// Date and time the booking ends.
    public let endTime: Date
}

/// Request body for `POST /contracts/{contract}/accounts/{accountId}/bookings`.
public struct CreateBooking: Codable, Sendable {
    /// ID of the station where the bike to book is held.
    public let stationId: UUID
    /// Number of the station where the bike to book is held.
    public let stationNumber: Int
    /// Number of the stand that holds the bike to book.
    public let standNumber: Int16
    /// ID of the subscription to use for this booking.
    public let subscriptionId: UUID
    /// ID of the bike to book.
    public let bikeId: UUID

    /// Create a booking request.
    /// - Parameters:
    ///   - stationId: ID of the station where the bike to book is held.
    ///   - stationNumber: Number of the station where the bike to book is held.
    ///   - standNumber: Number of the stand that holds the bike to book.
    ///   - subscriptionId: ID of the subscription to use for this booking.
    ///   - bikeId: ID of the bike to book.
    public init(stationId: UUID, stationNumber: Int, standNumber: Int16, subscriptionId: UUID, bikeId: UUID) {
        self.stationId = stationId
        self.stationNumber = stationNumber
        self.standNumber = standNumber
        self.subscriptionId = subscriptionId
        self.bikeId = bikeId
    }
}
