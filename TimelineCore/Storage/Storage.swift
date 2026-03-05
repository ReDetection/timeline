import Foundation

public enum StorageError: Error {
    case diskFull(reason: String)
    case cantWrite(reason: String)
    case cantOpen(reason: String)
}

extension StorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .diskFull(let reason):
            return reason.isEmpty ? "No space left on disk" : "No space left on disk: \(reason)"
        case .cantWrite(let reason):
            return "Failed to write tracking data: \(reason)"
        case .cantOpen(let reason):
            return "Failed to open tracking storage: \(reason)"
        }
    }
}

public protocol Storage {
    func store(log: Log) throws
    func store(app: App) throws
    func store(timeline: Timeline) throws
    
    func fetchLogs(since: Date, till: Date) -> [Log]
    func fetchApps() -> [String: App]
    func fetchTimeline(id: String) -> Timeline?
}
