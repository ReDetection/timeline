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

let tracker = Tracker(timeDependency: time, storage: storage, snapshotter: try! X11Apps())


tracker.active = true

signal(SIGINT, SIG_IGN) // // Make sure the signal does not terminate the application.

let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigintSrc.setEventHandler {
    print("Got SIGINT")
    // ...
    tracker.persist()
    exit(0)
}
sigintSrc.resume()


RunLoop.main.run(until: .init(timeIntervalSinceNow: 5.0))
tracker.persist()
