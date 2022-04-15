import Foundation
import AppKit
import TimelineCore
import testing_utils
import SwiftUI
import SQLiteStorage

private let alignInterval: TimeInterval = 5*60

class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var tracker: Tracker!
    var storage: Storage!
    var toggleCurrentAppItem: NSMenuItem!
    var togglePauseItem: NSMenuItem!
    let appProvider = CocoaApps()
    var statisticsWindow: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("Startup")
        
        let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
            + "/" + Bundle.main.bundleIdentifier!
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        storage = try! SQLiteStorage(filepath: path + "/timeline.sqlite")
        
        tracker = Tracker(timeDependency: CocoaTime(), storage: storage, snapshotter: CocoaApps(), alignInterval: alignInterval)
        tracker.active = true

        createMenu()
        appProvider.notifyChange = { [weak self] in
            self?.updateCurrentApp()
        }
    }

    func createMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Show", action: #selector(openUI), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        togglePauseItem = NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "")
        menu.addItem(togglePauseItem)
        updatePauseState()
        //todo scheduled pause / unpause
        
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
        tracker.persist()
        let statisticsViewModel = ViewModel()
        statisticsViewModel.dateLogs = storage.fetchLogs(since: Date().dateBegin, till: Date().dateBegin.nextDay)
        statisticsViewModel.interval = alignInterval
        let vc = NSHostingController(rootView: StatisticsView(viewModel: statisticsViewModel))
        self.statisticsWindow = NSWindow(contentViewController: vc)
        self.statisticsWindow?.title = "Timeline"
        self.statisticsWindow?.setContentSize(.init(width: 700, height: 600))
        self.statisticsWindow?.makeKeyAndOrderFront(nil)
        self.statisticsWindow?.setIsVisible(true)
    }
    
    @objc func toggleAppTracking() {
        let appId = appProvider.currentApp.appId
        let app = storage.fetchApps()[appId]
        let newApp = AppStruct(id: appId, trackingMode: app?.trackingMode == .skip ? .app : .skip)
        storage.store(app: newApp)
        updateCurrentApp()
        tracker.persist()
    }
    
    @objc func togglePause() {
        tracker.active.toggle()
        updatePauseState()
    }
    
    func updatePauseState() {
        togglePauseItem.state = tracker.active ? .off : .on
        statusItem.button?.image = NSImage(systemSymbolName: tracker.active ? "stopwatch" : "pause", accessibilityDescription: nil)
    }
    
    func updateCurrentApp() {
        print("Active: " + self.appProvider.currentApp.appName)
        toggleCurrentAppItem.title = "Track app " + appProvider.currentApp.appName
        toggleCurrentAppItem.state = storage.fetchApps()[appProvider.currentApp.appId]?.trackingMode == .skip ? .off : .on
    }
}
