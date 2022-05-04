import X11
import TimelineCore

class X11Apps: Snapshotter {
    var currentApp: AppSnapshot {
        return self
    }
    var notifyChange: () -> () = {}
}

extension X11Apps: AppSnapshot {
    var appId: String {
        guard let display = XOpenDisplay(nil) else { return "{ no X display}" }
        defer {
            XCloseDisplay(display)
        }
        var window: Window = 0
        var param: Int32 = 0
        var returnCode = XGetInputFocus(display, &window, &param)
        print("window: \(window), returnCode: \(returnCode)")
        guard window != 0 else { return "{no focused window information}" }
        var pidAtom: Atom = 0
        "_NET_WM_PID".withCString {
            pidAtom = XInternAtom(display, $0, 1)
        }
        print("pidatom: \(pidAtom)\n")
        let offset = 0
        let length = 2
        var actual_type: Atom = 0
        var actual_format: Int32 = 0
        var actual_32_length: UInt = 255
        var bytes_remaining: UInt = 0
        var bytes_ref: UnsafeMutablePointer<UInt8>?
        returnCode = XGetWindowProperty(display, window, pidAtom, offset, length, 0, 0, &actual_type, &actual_format, &actual_32_length, &bytes_remaining, &bytes_ref)
        print("windowPropertyReturn: \(returnCode), type: \(actual_type), length: \(actual_32_length), remaining: \(bytes_remaining)")
        guard let ref = bytes_ref else { return "{ no active pid}" }
        let refAny = UnsafeMutableRawPointer(ref)
        let pid = refAny.load(as: Int32.self)
        guard let cmdline = try? String(contentsOfFile: "/proc/\(pid)/cmdline") else { return "{no cmdline}" }
        return cmdline.hasSuffix("\0") ? String(cmdline.dropLast()) : cmdline
    }
    
    var appName: String {
        return "Ok"
    }
    
    var windowTitle: String {
        return "title"
    }
}
