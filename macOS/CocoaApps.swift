import AppKit
import TimelineCore

class CocoaApps: Snapshotter {
    let currentApp: AppSnapshot = CocoaSnapshotProvider()
    var notifyChange: () -> () = {}
    
    init() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateCurrentApp), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateCurrentApp), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateCurrentApp), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
    
    @objc private func updateCurrentApp() {
        notifyChange()
    }
}

class CocoaSnapshotProvider: AppSnapshot {
    var appId: String {
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "{desktop}"
    }
    
    var appName: String {
        return NSWorkspace.shared.frontmostApplication?.localizedName ?? "{desktop}"
    }
    
    var windowTitle: String {
        guard let appPid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return "{desktop}" }
        guard let windowsInfo = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID) as? [[String : Any]],
              let window = windowsInfo.first,
              let windowOwner = window[kCGWindowOwnerPID as String] as? UInt32,
              windowOwner == appPid else { return "{unknown}" }
                
        return window[kCGWindowName as String] as? String ?? "{unknown}"
    }
}
