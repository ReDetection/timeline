import Foundation

public class Counter {
    public var statistics: [String: TimeInterval] {
        if active {
            start(name: lastName)
        }
        return stats
    }
    private(set) var active = false
    private let queue = DispatchQueue(label: "Counter")
    private var stats: [String: TimeInterval] = [:]
    private var lastStateChange: Date
    private var lastName = ""
    let time: () -> Date
    
    public init(timeDependency: @escaping () -> Date = { return Date() }) {
        time = timeDependency
        lastStateChange = time()
    }
    
    public func start(name newValue: String) {
        queue.sync {
            self.startUnsafe(name: newValue)
        }
    }
    
    private func startUnsafe(name newValue: String) {
        if active {
            let timeInPreviousState = time().timeIntervalSince(lastStateChange)
            let previouslySavedInterval = stats[lastName] ?? 0
            stats[lastName] = previouslySavedInterval + timeInPreviousState
        }
        lastStateChange = time()
        lastName = newValue
        active = true
    }
    
    public func pause() {
        queue.sync {
            if active {
                startUnsafe(name: lastName)
            }
            active = false
        }
    }
    
    public func clearAndPause() {
        queue.sync {
            self.stats = [:]
            self.lastName = ""
            self.active = false
        }
    }
    
}
