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
    var currentAppItem: NSMenuItem!
    var skipTrackingItem: NSMenuItem!
    var setAppTrackingItem: NSMenuItem!
    var setTitleTrackingItem: NSMenuItem!
    var togglePauseItem: NSMenuItem!
    let appProvider = CocoaApps()
    var statisticsWindow: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("Startup")
        NSApplication.shared.setActivationPolicy(.accessory)
        
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

        togglePauseItem = NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "")
        menu.addItem(togglePauseItem)
        updatePauseState()
        //todo scheduled pause / unpause
        menu.addItem(NSMenuItem.separator())

        currentAppItem = NSMenuItem(title: "{Current app}", action: nil, keyEquivalent: "")
        currentAppItem.isEnabled = false
        skipTrackingItem = NSMenuItem(title: "Skip", action: #selector(setAppTracking), keyEquivalent: "")
        setAppTrackingItem = NSMenuItem(title: "Track app name", action: #selector(setAppTracking), keyEquivalent: "")
        setTitleTrackingItem = NSMenuItem(title: "Track window names", action: #selector(setAppTracking), keyEquivalent: "")
        menu.addItem(currentAppItem)
        menu.addItem(skipTrackingItem)
        menu.addItem(setAppTrackingItem)
        menu.addItem(setTitleTrackingItem)
        updateCurrentApp()

//        let startAtLogin = NSMenuItem(title: "Start at login", action: #selector(toggleStartAtLogin(_:)), keyEquivalent: "")
//        startAtLogin.state = LaunchAtLoginController().launchAtLogin ? .on : .off
//        menu.addItem(startAtLogin)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        statusItem.menu = menu
    }
    
    @objc func openUI() {
        self.statisticsWindow?.close()
        tracker.persist()
        let statisticsViewModel = ViewModel()
        statisticsViewModel.loadDate = { [weak self, weak statisticsViewModel] date in
            statisticsViewModel?.dateLogs = self?.storage.fetchLogs(since: date.dateBegin, till: date.dateBegin.nextDay) ?? []
            statisticsViewModel?.chosenDate = date
        }
        statisticsViewModel.loadDate(Date())
        let vc = NSHostingController(rootView: StatisticsView(viewModel: statisticsViewModel))
        self.statisticsWindow = NSWindow(contentViewController: vc)
        self.statisticsWindow?.title = "Timeline"
        self.statisticsWindow?.setContentSize(.init(width: 760, height: 600))
        self.statisticsWindow?.makeKeyAndOrderFront(self)
        self.statisticsWindow?.setIsVisible(true)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc func setAppTracking(_ source: NSMenuItem) {
        let newTracking = [skipTrackingItem: TrackingMode.skip, setAppTrackingItem: .app, setTitleTrackingItem: .titles][source] ?? .app
        let newApp = AppStruct(id: appProvider.currentApp.appId, trackingMode: newTracking)
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
        currentAppItem.title = appProvider.currentApp.appName
        let trackingMode = storage.fetchApps()[appProvider.currentApp.appId]?.trackingMode ?? .app
        skipTrackingItem.state = trackingMode == .skip ? .on : .off
        setAppTrackingItem.state = trackingMode == .app ? .on : .off
        setTitleTrackingItem.state = trackingMode == .titles ? .on : .off
    }
}
