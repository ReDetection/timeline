import Foundation

public protocol Storage {
    func store(log: Log)
    func store(app: App)
    func store(timeline: Timeline)
    func fetchLogs(since: Date, till: Date) -> [Log]
    func fetchApps() -> [String: App]
    func fetchTimeline(id: String) -> Timeline?
}
