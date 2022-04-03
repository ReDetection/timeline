import Foundation
import TimelineCore

public class MemoryStorage: Storage {
    public var apps: [App] = []
    public var logs: [Log] = []
    public var timelines: [Timeline] = []
    
    public init() {}
    
    public func store(log: Log) {
        if let existingIndex = logs.firstIndex(where: { $0.appId == log.appId && $0.timelineId == log.timelineId && $0.timeslotStart == log.timeslotStart && $0.trackedIdentifier == log.trackedIdentifier }) {
            logs.remove(at: existingIndex)
        }
        logs.append(log)
    }
    
    public func store(app: App) {
        if let existingIndex = apps.firstIndex(where: { $0.id == app.id }) {
            apps.remove(at: existingIndex)
        }
        apps.append(app)
    }
    
    public func store(timeline: Timeline) {
        if let existingIndex = timelines.firstIndex(where: { $0.id == timeline.id }) {
            timelines.remove(at: existingIndex)
        }
        timelines.append(timeline)
    }
    
    public func fetchLogs(since: Date, till: Date) -> [Log] {
        return logs.filter { $0.timeslotStart >= since && $0.timeslotStart < till }
    }
    
    public func fetchApps() -> [String : App] {
        return Dictionary(grouping: apps) { $0.id } .mapValues { $0[0] }
    }
    
    public func fetchTimeline(id: String) -> Timeline? {
        return timelines.first { $0.id == id }
    }
    
    
}
