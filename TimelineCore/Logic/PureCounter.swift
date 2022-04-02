import Foundation

public class Counter<Key: Hashable> {
    public var statistics: [Key: TimeInterval] {
        if active, let lastKey = lastKey {
            start(key: lastKey)
        }
        return stats
    }
    private(set) var active = false
    private let queue = DispatchQueue(label: "Counter")
    private var stats: [Key: TimeInterval] = [:]
    private var lastStateChange: Date
    private var lastKey: Key?
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
        if active, let lastKey = lastKey {
            let timeInPreviousState = time().timeIntervalSince(lastStateChange)
            let previouslySavedInterval = stats[lastKey] ?? 0
            stats[lastKey] = previouslySavedInterval + timeInPreviousState
        }
        lastStateChange = time()
        lastKey = newValue
        active = true
    }
    
    public func pause() {
        queue.sync {
            if active, let lastKey = lastKey {
                startUnsafe(key: lastKey)
            }
            active = false
        }
    }
    
    public func clearAndPause() {
        queue.sync {
            self.stats = [:]
            self.lastKey = nil
            self.active = false
        }
    }
    
}
