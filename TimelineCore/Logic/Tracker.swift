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
    private let counter: Counter<AppKey>
    private let storage: Storage
    private let time: TimeDependency
    private let snapshotter: Snapshotter
    private let timer: AlignedTimer
    private let alignInterval: TimeInterval
    public var currentTimelineId: String = UUID().uuidString
    public var fillTimelineDeviceInfo: (inout TimelineStruct)->() = { _ in }
    
    public init(timeDependency: TimeDependency, storage: Storage, snapshotter: Snapshotter, alignInterval: TimeInterval = 5*60) {
        self.storage = storage
        self.time = timeDependency
        self.snapshotter = snapshotter
        self.counter = Counter(timeDependency: {
            return timeDependency.currentTime
        })
        self.alignInterval = alignInterval
        self.timer = AlignedTimer(alignInterval: alignInterval, timeDependency: {
            return timeDependency.currentTime
        })
        self.timer.fire = { [weak self] in
            guard let `self` = self else { return }
            self.persist()
            if self.active == false {
                self.timer.active = false
            }
        }
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
            if active || counter.statistics.isEmpty {
                timer.active = active
            }
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
        case .app: counter.start(key: AppKey(appId: snapshot.appId, activity: snapshot.appName))
        case .titles: counter.start(key: AppKey(appId: snapshot.appId, activity: snapshot.windowTitle))
        }
    }
    
    private func store(app: AppSnapshot) -> App {
        let app = AppStruct(id: app.appId, trackingMode: .app)
        storage.store(app: app)
        return app
    }
    
    private func persist() {
        let previousTimeslotAnyMoment = time.currentTime.addingTimeInterval(-5)
        let passed = previousTimeslotAnyMoment.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: alignInterval)
        let timestotStart = previousTimeslotAnyMoment.addingTimeInterval(-passed)
        var log = LogStruct(timelineId: currentTimelineId, timeslotStart: timestotStart, appId: "to be replaced", trackedIdentifier: "to be replaced", duration: 0)
        if storage.fetchTimeline(id: currentTimelineId) == nil {
            var timeline = TimelineStruct(id: currentTimelineId, dateStart: time.currentTime)
            fillTimelineDeviceInfo(&timeline)
            storage.store(timeline: timeline)
        }
        for (appKey, duration) in counter.statistics {
            log.appId = appKey.appId
            log.trackedIdentifier = appKey.activity
            log.duration = duration
            storage.store(log: log)
        }
        counter.clearAndPause()
        if active {
            tickAppCounter()
        }
    }
    
    private func refreshTimeline() {
        fatalError() //TODO: IMPLEMENT
    }
    
}


private struct AppKey: Hashable {
    var appId: String
    var activity: String
}
