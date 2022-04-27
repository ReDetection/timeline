import Foundation
import TimelineCore
import testing_utils

class LinuxTime: TimeDependency {
    var currentTime: Date {
        return Date()
    }
    
    var notifySignificantTimeChange: () -> () = {}
}

let time = LinuxTime()
let storage = MemoryStorage()
storage.logStores = true

class LinuxApps: Snapshotter {
    var currentApp: AppSnapshot {
        return self
    }
    var notifyChange: () -> () = {}
}

extension LinuxApps: AppSnapshot {
    var appId: String {
        return "Ok"
    }
    
    var appName: String {
        return "Ok"
    }
    
    var windowTitle: String {
        return "title"
    }
}

let apps = LinuxApps()

let tracker = Tracker(timeDependency: time, storage: storage, snapshotter: apps)

tracker.active = true

sleep(20)
tracker.persist()
