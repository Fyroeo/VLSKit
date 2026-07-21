import Foundation

/// A push-notification device registration (`ri.c` in the app).
public struct Device: Codable, Sendable {
    /// The push-notification token for the device.
    public let deviceToken: String
    /// The platform of the device, for example iOS.
    public let platform: DevicePlatform

    /// Create a device registration.
    /// - Parameters:
    ///   - deviceToken: The push-notification token for the device.
    ///   - platform: The platform of the device. The default is `.ios`.
    public init(deviceToken: String, platform: DevicePlatform = .ios) {
        self.deviceToken = deviceToken
        self.platform = platform
    }
}
