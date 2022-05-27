import Foundation

public enum AppColor {
    case top1
    case top2
    case top3
    case top4
    case top5
    case otherEven
    case otherOdd
    
    static var topColors: [AppColor] = [.top1, .top2, .top3, .top4, .top5]
}

public extension Array where Element == Log {
    var totals: [AppTotal] {
        var sortedTotals = Dictionary(grouping: self) { log in
                return AppKey(appId: log.appId, activity: log.activityName)
            }
        .map { (app, logs) -> AppTotal in
            return AppTotal(appId: app.appId, activity: app.activity, duration: logs.reduce(0.0 as TimeInterval, {
                return $0 + $1.duration
            }), assignedColor: .otherEven)
        }
        .sorted { l, r in
            l.duration > r.duration
        }
        for i in 0..<sortedTotals.count {
            sortedTotals[i].assignedColor = i < AppColor.topColors.count ? AppColor.topColors[i] : i % 2 == 0 ? .otherEven : .otherOdd
        }
        return sortedTotals
    }
    func timeslots(alignInterval: TimeInterval) -> [Date: [Log]] {
        return Dictionary(grouping: self, by: { $0.timeslotStart.aligned(to: alignInterval) })
            .mapValues { logs in
                return logs.sorted { l, r in
                    if l.timelineId == r.timelineId {
                        return l.appId < r.appId
                    }
                    return l.timelineId < r.timelineId
                }
            }
    }
    var grandTotal: TimeInterval {
        return self.reduce(0.0 as TimeInterval) { $0 + $1.duration }
    }
}

public struct AppTotal {
    public var appId: String
    public var activity: String
    public var duration: TimeInterval
    public var assignedColor: AppColor
}
