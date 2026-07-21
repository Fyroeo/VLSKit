import Foundation

/// This service gets service and station events for the app's notification feed.
public struct EventService: Sendable {
    private let httpClient: HTTPClient
    private let contract: String

    init(httpClient: HTTPClient, contract: String) {
        self.httpClient = httpClient
        self.contract = contract
    }

    /// Gets one event by its ID.
    /// - Parameter eventId: The unique ID of the event.
    /// - Returns: The event.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `DisplayableEvent`.
    public func event(eventId: UUID) async throws -> DisplayableEvent {
        let endpoint = Endpoint(method: .get, path: "contracts/\(contract)/events/\(eventId)")
        return try await httpClient.send(endpoint)
    }

    /// Gets a page of events.
    /// - Parameters:
    ///   - page: The zero-based index of the page to get.
    ///   - size: The number of events per page.
    /// - Returns: A page of events.
    /// - Throws: `VLSError` if the request fails or the response body does not match
    ///   `Page<DisplayableEvent>`.
    public func events(page: Int, size: Int) async throws -> Page<DisplayableEvent> {
        let endpoint = Endpoint(
            method: .get,
            path: "contracts/\(contract)/events",
            queryItems: queryItems(["page": page, "size": size])
        )
        return try await httpClient.send(endpoint)
    }
}
