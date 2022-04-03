import Foundation
import AppKit
import TimelineCore

class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var tracker: Tracker!
    var storage: Storage!
    var toggleCurrentAppItem: NSMenuItem!
    let appProvider = CocoaApps()
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("Startup")
        statusItem.button?.image = NSImage(systemSymbolName: "stopwatch", accessibilityDescription: nil)
        createMenu()
        
        tracker = Tracker(timeDependency: CocoaTime(), storage: storage, snapshotter: CocoaApps(), alignInterval: 5*60)
        tracker.active = true
        
        appProvider.notifyChange = { [weak self] in
            self?.updateCurrentApp()
        }
    }

    func createMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Show", action: #selector(openUI), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        toggleCurrentAppItem = NSMenuItem(title: "Track current app", action: #selector(toggleAppTracking), keyEquivalent: "")
        menu.addItem(toggleCurrentAppItem)
        updateCurrentApp()

//        let startAtLogin = NSMenuItem(title: "Start at login", action: #selector(toggleStartAtLogin(_:)), keyEquivalent: "")
//        startAtLogin.state = LaunchAtLoginController().launchAtLogin ? .on : .off
//        menu.addItem(startAtLogin)

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
    
    func updateCurrentApp() {
        print("Active: " + self.appProvider.currentApp.appName)
//        toggleCurrentAppItem.state = isBlockedApp ? .on : .off
        toggleCurrentAppItem.title = "Track app " + appProvider.currentApp.appName
    }
}
