import Foundation

public protocol Timeline {
    var id: String { get }
    var deviceName: String { get }
    var deviceSystem: String { get }
    var timezoneName: String { get }
    var timezoneShift: TimeInterval { get }
    var dateStart: Date { get }
}

public enum TrackingMode: String {
    case skip
    case app
    case titles
}

public protocol App {
    ///usually a bundle id
    var id: String { get }
    var trackingMode: TrackingMode { get }
}

public protocol Log {
    var timelineId: String { get }
    var timeslotStart: Date { get }
    var appId: String { get }
    var trackedIdentifier: String { get }
    var duration: TimeInterval { get }
}

public struct AppStruct: App {
    public let id: String
    public let trackingMode: TrackingMode
}
