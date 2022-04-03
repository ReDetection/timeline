import Foundation
import AppKit
import TimelineCore

class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var isBlockedApp: Bool = false
    var tracker: Tracker!
    var storage: Storage!
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("Startup")
        statusItem.button?.image = NSImage(systemSymbolName: "stopwatch", accessibilityDescription: nil)
        createMenu()
        
        tracker = Tracker(timeDependency: CocoaTime(), storage: <#T##Storage#>, snapshotter: <#T##Snapshotter#>, alignInterval: 5*60)
        tracker.active = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentApp), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentApp), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentApp), name: NSWorkspace.didActivateApplicationNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentApp), name: NSWorkspace.willPowerOffNotification, object: nil) //todo a case of reboot within align interval

    }

    func createMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Show", action: #selector(openUI), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        let toggleTracking = NSMenuItem(title: "Track current app", action: #selector(toggleAppTracking), keyEquivalent: "")
        toggleTracking.state = isBlockedApp ? .on : .off
        menu.addItem(toggleTracking)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        statusItem.menu = menu
    }
    
    @objc func openUI() {
        //todo
    }
    
    @objc func toggleAppTracking() {
        //todo
    }
    
    @objc func updateCurrentApp() {
        
    }
}
