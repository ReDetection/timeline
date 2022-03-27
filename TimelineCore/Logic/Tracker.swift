import Foundation

public protocol TimeDependency: AnyObject {
    var currentTime: Date { get }
    var notifySignificantTimeChange: () -> () { get set }
}

public protocol Snapshotter: AnyObject {
    var currentApp: AppSnapshot { get }
    var notifyChange: () -> () { get set }
}

public protocol AppSnapshot {
    var appId: String { get }
    var appName: String { get }
    var windowTitle: String { get }
}

public class Tracker {
    private let counter: Counter
    private let storage: Storage
    private let time: TimeDependency
    private let snapshotter: Snapshotter
    
    public init(timeDependency: TimeDependency, storage: Storage, snapshotter: Snapshotter) {
        self.storage = storage
        self.time = timeDependency
        self.snapshotter = snapshotter
        self.counter = Counter(timeDependency: {
            return timeDependency.currentTime
        })
        self.snapshotter.notifyChange = { [weak self] in
            self?.tickAppCounter()
        }
        self.time.notifySignificantTimeChange = { [weak self] in
            self?.refreshTimeline()
        }
    }
    
    public var active = false {
        didSet {
            tickAppCounter()
        }
    }
    
    private func tickAppCounter() {
        guard active else {
            counter.pause()
            return
        }
        let snapshot = self.snapshotter.currentApp
        let app = storage.fetchApps()[snapshot.appId] ?? self.store(app: snapshot)
        switch app.trackingMode {
        case .skip: counter.pause()
        case .app: counter.start(name: snapshot.appName) //todo: generic counter with both app id and name of activity
        case .titles: counter.start(name: snapshot.appName + ": " + snapshot.windowTitle)
        }
    }
    
    private func store(app: AppSnapshot) -> App {
        let app = AppStruct(id: app.appId, trackingMode: .app)
        storage.store(app: app)
        return app
    }
    
    private func refreshTimeline() {
        fatalError() //TODO: IMPLEMENT
    }
    
}
