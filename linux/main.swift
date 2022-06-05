import Foundation
import TimelineCore
import SQLiteStorage
import VertexGUI

class LinuxTime: TimeDependency {
    var currentTime: Date {
        return Date()
    }
    
    var notifySignificantTimeChange: () -> () = {}
}

let time = LinuxTime()
let configPath = NSHomeDirectory() + "/.timeline"
try? FileManager.default.createDirectory(atPath: configPath, withIntermediateDirectories: true, attributes: nil)

var storage: Storage = try! SQLiteStorage(filepath: configPath + "/store.sqlite")
storage = FilteredAppsStorage(storage, overridenApps: ["{no active pid}": AppStruct(id: "{no active pid}", trackingMode: .skip)])
let tracker = Tracker(timeDependency: time, storage: storage, snapshotter: try! X11Apps())

let terminalNotifier = try! X11Apps()
terminalNotifier.notifyChange = { [weak terminalNotifier] in
    print(terminalNotifier!.currentApp.appId)
}


tracker.active = true

signal(SIGINT, SIG_IGN) // // Make sure the signal does not terminate the application.

let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigintSrc.setEventHandler {
    print("Got SIGINT")
    tracker.persist()
    exit(0)
}
sigintSrc.resume()

let app = try VertexGUI.Application()
try! app.createWindow(widgetRoot: Root(rootWidget: MainView(storage: storage)))

do {
  try app.start()
} catch {
  print("an error occurred while running the app:", error)
}
tracker.persist()
