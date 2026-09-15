import Foundation
import AppKit
import UserNotifications
import TimelineCore

class CocoaAlerter: NSObject, Alerter, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var didRequestAuthorization = false
    private var notificationsAllowed = false
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    func showAlert(title: String, message: String) {
        authorizeIfNeeded { [weak self] in
            self?.postNotification(title: title, message: message)
        }
    }
    
    private func authorizeIfNeeded(onAuthorized: @escaping () -> Void) {
        if didRequestAuthorization {
            if notificationsAllowed {
                onAuthorized()
            }
            return
        }
        didRequestAuthorization = true
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.notificationsAllowed = granted
                if granted {
                    onAuthorized()
                }
            }
        }
    }
    
    private func postNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
