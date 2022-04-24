import Foundation

public class FilteredAppsStorage: Storage {
    let innerStorage: Storage
    let overrides: [String: App]
    
    public init(_ storage: Storage, overridenApps: [String: App]) {
        self.overrides = overridenApps
        self.innerStorage = storage
    }
    
    public func store(log: Log) {
        innerStorage.store(log: log)
    }
    
    public func store(app: App) {
        innerStorage.store(app: app)
    }
    
    public func store(timeline: Timeline) {
        innerStorage.store(timeline: timeline)
    }
    
    public func fetchLogs(since: Date, till: Date) -> [Log] {
        return innerStorage.fetchLogs(since: since, till: till)
    }
    
    public func fetchApps() -> [String : App] {
        return innerStorage.fetchApps().merging(overrides, uniquingKeysWith: { orig, overridenApp in
            return overridenApp
        })
    }
    
    public func fetchTimeline(id: String) -> Timeline? {
        return innerStorage.fetchTimeline(id: id)
    }
    
}
