import Foundation

public class Counter<Key: Hashable> {
    public var statistics: [Key: TimeInterval] {
        if case .active(let lastKey) = active {
            start(key: lastKey)
        }
        return stats
    }
    private(set) var active: Status = .off
    private let queue = DispatchQueue(label: "Counter")
    private var stats: [Key: TimeInterval] = [:]
    private var lastStateChange: Date
    let time: () -> Date
    
    public init(timeDependency: @escaping () -> Date = { return Date() }) {
        time = timeDependency
        lastStateChange = time()
    }
    
    public func start(key newValue: Key) {
        queue.sync {
            self.startUnsafe(key: newValue)
        }
    }
    
    private func startUnsafe(key newValue: Key) {
        if case .active(let lastKey) = active {
            let timeInPreviousState = time().timeIntervalSince(lastStateChange)
            let previouslySavedInterval = stats[lastKey] ?? 0
            stats[lastKey] = previouslySavedInterval + timeInPreviousState
        }
        lastStateChange = time()
        active = .active(key: newValue)
    }
    
    public func pause() {
        queue.sync {
            if case .active(let lastKey) = active {
                startUnsafe(key: lastKey)
            }
            active = .off
        }
    }
    
    public func clearAndPause() {
        queue.sync {
            self.stats = [:]
            self.active = .off
        }
    }
    
    enum Status {
        case active(key: Key)
        case off
    }
}
