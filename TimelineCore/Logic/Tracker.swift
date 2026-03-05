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
    private let alerter: Alerter
    private let timer: AlignedTimer
    private let alignInterval: TimeInterval
    private var lastAlertText: String?
    public var currentTimelineId: String = UUID().uuidString
    public var fillTimelineDeviceInfo: (inout TimelineStruct)->() = { _ in }
    
    public init(timeDependency: TimeDependency, storage: Storage, snapshotter: Snapshotter, alerter: Alerter, alignInterval: TimeInterval = 5*60) {
        self.storage = storage
        self.time = timeDependency
        self.snapshotter = snapshotter
        self.alerter = alerter
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
        do {
            try storage.store(app: app)
            lastAlertText = nil
        } catch {
            reportStorageError(error, action: "storing app")
        }
        return app
    }
    
    public func persist() {
        let previousTimeslotAnyMoment = time.currentTime.addingTimeInterval(-5)
        let passed = previousTimeslotAnyMoment.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: alignInterval)
        let timestotStart = previousTimeslotAnyMoment.addingTimeInterval(-passed)
        var log = LogStruct(timelineId: currentTimelineId, timeslotStart: timestotStart, appId: "to be replaced", activityName: "to be replaced", duration: 0)
        if storage.fetchTimeline(id: currentTimelineId) == nil {
            var timeline = TimelineStruct(id: currentTimelineId, dateStart: time.currentTime)
            fillTimelineDeviceInfo(&timeline)
            do {
                try storage.store(timeline: timeline)
                lastAlertText = nil
            } catch {
                reportStorageError(error, action: "storing timeline")
                if isDiskFull(error) {
                    counter.clearAndPause()
                    if active {
                        tickAppCounter()
                    }
                    return
                }
            }
        }
        for (appKey, duration) in counter.statistics {
            log.appId = appKey.appId
            log.activityName = appKey.activity
            log.duration = duration
            do {
                try storage.store(log: log)
                lastAlertText = nil
            } catch {
                reportStorageError(error, action: "storing log")
                if isDiskFull(error) {
                    break
                }
            }
        }
        counter.clearAndPause()
        if active {
            tickAppCounter()
        }
    }
    
    private func refreshTimeline() {
        print("Significant time change!")
        //TODO: IMPLEMENT
    }
    
    private func isDiskFull(_ error: Error) -> Bool {
        guard let storageError = error as? StorageError else {
            return false
        }
        if case .diskFull = storageError {
            return true
        }
        return false
    }
    
    private func reportStorageError(_ error: Error, action: String) {
        let title: String
        let message: String
        if isDiskFull(error) {
            title = "Timeline paused: disk is full"
            message = "No space left on disk. Free up space, then Timeline will resume saving data."
        } else {
            title = "Timeline storage error"
            message = "Failed while \(action): \(error.localizedDescription)"
        }
        let text = title + "|" + message
        guard text != lastAlertText else {
            return
        }
        lastAlertText = text
        fputs("[timeline] \(title): \(message)\n", stderr)
        alerter.showAlert(title: title, message: message)
    }
    
}


public struct AppKey: Hashable {
    public var appId: String
    public var activity: String
    
    public init(appId: String, activity: String) {
        self.appId = appId
        self.activity = activity
    }
}
