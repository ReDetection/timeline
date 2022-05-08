import X11
import Foundation
import TimelineCore

class X11Apps: Snapshotter {
    private let display: UnsafeMutablePointer<Display>
    private let pidAtom: Atom
    private let monitorQueue = OperationQueue()
    
    init() throws {
        guard let d = XOpenDisplay(nil) else { throw X11Error.noDisplay }
        display = d
        pidAtom = XInternAtom(display, "_NET_WM_PID".cString(using: .utf8), 1)
        let monitorOperation = X11MonitorOperation() { [weak self] in
            self?.notifyChange()
        }
        monitorQueue.addOperation(monitorOperation)
    }
    
    deinit {
        monitorQueue.cancelAllOperations()
        XCloseDisplay(display)
    }
    
    var notifyChange: () -> () = {}
    var currentApp: AppSnapshot {
        var window: Window = 0
        var param: Int32 = 0
        XGetInputFocus(display, &window, &param)
        guard window != 0 else { return SnapshotStruct(text: "{no focused window information}") }
        
        //todo nice reading of any property
        let offset = 0
        let length = 2
        var actual_type: Atom = 0
        var actual_format: Int32 = 0
        var actual_32_length: UInt = 255
        var bytes_remaining: UInt = 0
        var bytes_ref: UnsafeMutablePointer<UInt8>?
        XGetWindowProperty(display, window, pidAtom, offset, length, 0, 0, &actual_type, &actual_format, &actual_32_length, &bytes_remaining, &bytes_ref)
        guard let ref = bytes_ref else { return SnapshotStruct(text: "{no active pid}") }
        defer {
            bytes_ref?.deallocate()
        }
        let refAny = UnsafeMutableRawPointer(ref)
        let pid = refAny.load(as: Int32.self)
        let url = URL(fileURLWithPath: "/proc/\(pid)/exe").resolvingSymlinksInPath()
        return SnapshotStruct(appId: url.path, appName: url.lastPathComponent, windowTitle: "{todo}")
    }
}

enum X11Error: Error {
    case noDisplay
}

extension SnapshotStruct {
    init(text: String) {
        self.init(appId: text, appName: text, windowTitle: text)
    }
}

class X11MonitorOperation: Operation {
    let notifyChange: ()->()
    
    init(closure: @escaping ()->()) {
        self.notifyChange = closure
    }
    
    override func main() {
        var stderr = FileHandle.standardError
        let event = UnsafeMutablePointer<XEvent>.allocate(capacity: 1)
        while true {
            guard !isCancelled else { return }
            guard let display = XOpenDisplay(nil) else {
                print("Found no X display. Retry in 3 sec", to: &stderr)
                sleep(3)
                continue
            }
            defer {
                XCloseDisplay(display)
            }
            let rootWindow: Window = XDefaultRootWindow(display)
            XSelectInput(display, rootWindow, SubstructureNotifyMask)
            while true {
                event.pointee.xfocus.display = nil
                XNextEvent(display, event)
//                print("event type: \(event.pointee.type)")
                guard !isCancelled else { return }
                if event.pointee.type != ClientMessage {
                    self.notifyChange()
                }
            }
        }
    }
    
}

extension FileHandle: TextOutputStream {
  public func write(_ string: String) {
    let data = Data(string.utf8)
    self.write(data)
  }
}
