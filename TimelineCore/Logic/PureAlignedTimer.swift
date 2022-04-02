import Foundation

//fixme timers DGAF about our time dependency!
class AlignedTimer {
    let time: () -> Date
    let alignInterval: TimeInterval
    var fire: () -> () = {}
    private var timer: Timer? {
        didSet {
            oldValue?.invalidate()
            if let timer = timer {
                RunLoop.current.add(timer, forMode: .default)
            }
        }
    }
    
    init(alignInterval: TimeInterval, timeDependency: @escaping () -> Date = { return Date() }) {
        self.alignInterval = alignInterval
        self.time = timeDependency
    }
    
    var active = false {
        didSet {
            timer = active ? createTimer() : nil
        }
    }
    
    private func createTimer() -> Timer {
        let passed = time().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: alignInterval)
        let remaining = alignInterval - passed
        return Timer(fire: Date(timeIntervalSinceNow: remaining), interval: alignInterval, repeats: true) { [weak self] _ in
            self?.fire()
        }
    }
}
