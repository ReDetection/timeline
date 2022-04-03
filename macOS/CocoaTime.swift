import AppKit
import TimelineCore

class CocoaTime: TimeDependency {
    var currentTime: Date {
        return Date()
    }
    var notifySignificantTimeChange: () -> () = {}
    
    init() {
        let handler: (Notification)->() = { [weak self] _ in
            self?.notifySignificantTimeChange()
        }
        NotificationCenter.default.addObserver(forName: NSLocale.currentLocaleDidChangeNotification, object: nil, queue: .main, using: handler)
        NotificationCenter.default.addObserver(forName: .NSSystemClockDidChange, object: nil, queue: .main, using: handler)
        NotificationCenter.default.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main, using: handler)        
    }
    
}
