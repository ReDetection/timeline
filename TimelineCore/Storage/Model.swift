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

public struct LogStruct: Log {
    public var timelineId: String
    public var timeslotStart: Date
    public var appId: String
    public var trackedIdentifier: String
    public var duration: TimeInterval
}

public struct TimelineStruct: Timeline {
    public var id: String = UUID().uuidString
    public var deviceName: String = ""
    public var deviceSystem: String = ""
    public var timezoneName: String = ""
    public var timezoneShift: TimeInterval = 0
    public var dateStart: Date
}
