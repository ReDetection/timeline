import X11
import Foundation
import TimelineCore

class X11Apps: Snapshotter {
    private let display: UnsafeMutablePointer<Display>
    private let pidAtom: Atom
    private var timer: Timer?
    
    init() throws {
        guard let d = XOpenDisplay(nil) else { throw X11Error.noDisplay }
        display = d
        pidAtom = XInternAtom(display, "_NET_WM_PID".cString(using: .utf8), 1)
        let rootWindow: Window = XDefaultRootWindow(display)
        
        XSelectInput(display, rootWindow, FocusChangeMask)
        let timer = Timer(timeInterval: 3, repeats: true) { [weak self] _ in
            let event = UnsafeMutablePointer<XEvent>.allocate(capacity: 1)
            repeat {
                event.pointee.xfocus.display = nil
                let result = XCheckTypedEvent(d, FocusIn, event)
                guard result != 0, event.pointee.xfocus.display != nil else { break }
                self?.notifyChange()
            } while true
        }
        RunLoop.current.add(timer, forMode: .default)
        self.timer = timer
    }
    
    deinit {
        XCloseDisplay(display)
    }
    
    var currentApp: AppSnapshot {
        return self
    }
    var notifyChange: () -> () = {}
}

extension X11Apps: AppSnapshot {
    var appId: String {
        var window: Window = 0
        var param: Int32 = 0
        XGetInputFocus(display, &window, &param)
        guard window != 0 else { return "{no focused window information}" }
        let offset = 0
        let length = 2
        var actual_type: Atom = 0
        var actual_format: Int32 = 0
        var actual_32_length: UInt = 255
        var bytes_remaining: UInt = 0
        var bytes_ref: UnsafeMutablePointer<UInt8>?
        XGetWindowProperty(display, window, pidAtom, offset, length, 0, 0, &actual_type, &actual_format, &actual_32_length, &bytes_remaining, &bytes_ref)
        guard let ref = bytes_ref else { return "{ no active pid}" }
        defer {
            bytes_ref?.deallocate()
        }
        let refAny = UnsafeMutableRawPointer(ref)
        let pid = refAny.load(as: Int32.self)
        let url = URL(fileURLWithPath: "/proc/\(pid)/exe").resolvingSymlinksInPath()
        return url.path
    }
    
    var appName: String {
        return "Ok"
    }
    
    var windowTitle: String {
        return "title"
    }
}

enum X11Error: Error {
    case noDisplay
}
