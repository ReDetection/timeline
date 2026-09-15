import Foundation
import TimelineCore

class LinuxAlerter: Alerter {
    func showAlert(title: String, message: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["zenity", "--warning", "--title=\(title)", "--text=\(message)"]
        do {
            try task.run()
        } catch {
            fputs("[timeline] Failed to show Linux notification: \(error.localizedDescription)\n", stderr)
        }
    }
}
