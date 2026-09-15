import Foundation
import XCTest
import TimelineCore
import testing_utils

func delay(_ seconds: TimeInterval) {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
}

class TrackerTests: XCTestCase {
    let timeTravel = TimeMock()
    let storage = MemoryStorage()
    let apps = AppsMock()
    
    func testFlow() {
        let tracker = Tracker(timeDependency: timeTravel, storage: storage, snapshotter: apps, alerter: NoopAlerter(), alignInterval: 10)
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
    
    func testDiskFullKeepsCountedTimeForNextPersist() {
        let tracker = Tracker(timeDependency: timeTravel, storage: storage, snapshotter: apps, alerter: NoopAlerter(), alignInterval: 10)
        tracker.currentTimelineId = "ABC"
        tracker.active = true

        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 10)
        storage.storeError = StorageError.diskFull(reason: "test")
        tracker.persist()
        XCTAssertEqual(storage.timelines.count, 0)
        XCTAssertEqual(storage.logs.count, 0)

        storage.storeError = nil
        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 20)
        tracker.persist()
        XCTAssertEqual(storage.timelines.map { $0.id }, ["ABC"])
        XCTAssertEqual(storage.logs.map { $0.appId }, ["com.demo.Folders"])
        XCTAssertEqual(storage.logs.map { $0.duration }, [20], "time counted while the disk was full should be persisted, not dropped")

        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 30)
        tracker.persist()
        XCTAssertEqual(storage.logs.map { $0.duration }, [20, 10], "already persisted time should not be stored again")
    }

    func testSimplestTrack() {
        let tracker = Tracker(timeDependency: timeTravel, storage: storage, snapshotter: apps, alerter: NoopAlerter(), alignInterval: 2)
        tracker.active = true
        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 2)
        delay(2.5)
        timeTravel.currentTime = Date(timeIntervalSinceReferenceDate: 2.5)
        XCTAssertEqual(storage.timelines.count, 1)
        XCTAssertEqual(storage.apps.map { $0.id }, ["com.demo.Folders"])
        XCTAssertEqual(storage.logs.map { $0.appId }, ["com.demo.Folders"])
        XCTAssertEqual(storage.logs.map { $0.activityName }, ["Folders"])
        XCTAssertEqual(storage.logs.map { $0.duration }, [2])
    }
    
}

class AppsMock: Snapshotter {
    var currentApp: AppSnapshot = SnapshotMock(appId: "com.demo.Folders", appName: "Folders", windowTitle: "Documents")
    var notifyChange: () -> () = {}
}

typealias SnapshotMock = SnapshotStruct

class TimeMock: TimeDependency {
    func advance(by interval: TimeInterval) {
        currentTime = currentTime.advanced(by: interval)
    }
    var currentTime: Date = Date(timeIntervalSinceReferenceDate: 0)
    var notifySignificantTimeChange: () -> () = {}
}

class NoopAlerter: Alerter {
    func showAlert(title: String, message: String) {}
}
