import Foundation
import XCTest
import TimelineCore

func delay(_ seconds: TimeInterval) {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
}

class TrackerTests: XCTestCase {
    let timeTravel = TimeMock()
    let storage = MemoryStorage()
    let apps = AppsMock()
    
    func testFlow() {
        let tracker = Tracker(timeDependency: timeTravel, storage: storage, snapshotter: apps, alignInterval: 10)
        tracker.currentTimelineId = "ABC"
        tracker.active = true
        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 9)
        apps.currentApp = SnapshotMock(appId: "com.demo.IDE", appName: "IDE", windowTitle: "Timeline")
        apps.notifyChange()
        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 10)
        // Damn! timer
        delay(10)
        XCTAssertEqual(storage.timelines.count, 1)
        XCTAssertEqual(Set(storage.apps.map { $0.id }), Set(["com.demo.Folders", "com.demo.IDE"]))
        XCTAssertEqual(Set(storage.logs.map { $0.appId }), Set(["com.demo.Folders", "com.demo.IDE"]))
        XCTAssertEqual(Set(storage.logs.map { $0.duration }), Set([9, 1]))
        
        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 12)
        tracker.active = false
        
        XCTAssertEqual(storage.timelines.count, 1)
        XCTAssertEqual(Set(storage.apps.map { $0.id }), Set(["com.demo.Folders", "com.demo.IDE"]))
        XCTAssertEqual(Set(storage.logs.map { $0.appId }), Set(["com.demo.Folders", "com.demo.IDE"]))
        XCTAssertEqual(Set(storage.logs.map { $0.duration }), Set([9, 1]))
        
        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 20)
        delay(10)
        
        XCTAssertEqual(storage.timelines.map { $0.id }, ["ABC"])
        XCTAssertEqual(Set(storage.apps.map { $0.id }), Set(["com.demo.Folders", "com.demo.IDE"]))
        XCTAssertEqual(Set(storage.logs.map { $0.appId }), Set(["com.demo.Folders", "com.demo.IDE", "com.demo.IDE"]))
        XCTAssertEqual(Set(storage.logs.map { $0.duration }), Set([9, 1, 2]), "storage is \(storage.logs.map {$0.duration} )")
        
    }
    
    func testSimplestTrack() {
        let tracker = Tracker(timeDependency: timeTravel, storage: storage, snapshotter: apps, alignInterval: 2)
        tracker.active = true
        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 2)
        delay(2.5)
        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 2.5)
        XCTAssertEqual(storage.timelines.count, 1)
        XCTAssertEqual(storage.apps.map { $0.id }, ["com.demo.Folders"])
        XCTAssertEqual(storage.logs.map { $0.appId }, ["com.demo.Folders"])
        XCTAssertEqual(storage.logs.map { $0.trackedIdentifier }, ["Folders"])
        XCTAssertEqual(storage.logs.map { $0.duration }, [2])
    }
    
}

class AppsMock: Snapshotter {
    var currentApp: AppSnapshot = SnapshotMock(appId: "com.demo.Folders", appName: "Folders", windowTitle: "Documents")
    var notifyChange: () -> () = {}
}

struct SnapshotMock: AppSnapshot {
    var appId: String
    var appName: String
    var windowTitle: String
}

class TimeMock: TimeDependency {
    func advance(by interval: TimeInterval) {
        currentTime = currentTime.advanced(by: interval)
    }
    var currentTime: Date = Date(timeIntervalSinceReferenceDate: 0)
    var notifySignificantTimeChange: () -> () = {}
}

class MemoryStorage: Storage {
    var apps: [App] = []
    var logs: [Log] = []
    var timelines: [Timeline] = []
    
    func store(log: Log) {
        if let existingIndex = logs.firstIndex(where: { $0.appId == log.appId && $0.timelineId == log.timelineId && $0.timeslotStart == log.timeslotStart && $0.trackedIdentifier == log.trackedIdentifier }) {
            logs.remove(at: existingIndex)
        }
        logs.append(log)
    }
    
    func store(app: App) {
        if let existingIndex = apps.firstIndex(where: { $0.id == app.id }) {
            apps.remove(at: existingIndex)
        }
        apps.append(app)
    }
    
    func store(timeline: Timeline) {
        if let existingIndex = timelines.firstIndex(where: { $0.id == timeline.id }) {
            timelines.remove(at: existingIndex)
        }
        timelines.append(timeline)
    }
    
    func fetchLogs(since: Date, till: Date) -> [Log] {
        return logs.filter { $0.timeslotStart >= since && $0.timeslotStart < till }
    }
    
    func fetchApps() -> [String : App] {
        return Dictionary(grouping: apps) { $0.id } .mapValues { $0[0] }
    }
    
    func fetchTimeline(id: String) -> Timeline? {
        return timelines.first { $0.id == id }
    }
    
    
}
