import SwiftUI
import TimelineCore

class ViewModel: ObservableObject {
    @Published var chosenDate: Date = Date()
    @Published var dateLogs: [Log] = []
    @Published var interval: TimeInterval = 5*60
}

struct StatisticsView: View {
    @StateObject var viewModel: ViewModel
    var body: some View {
        VStack {
            //todo date selector
            TimeStacksView(date: viewModel.chosenDate, stacks: viewModel.dateLogs.timeslots, alignInterval: viewModel.interval)
            TopAppsView(topApps: viewModel.dateLogs.totals)
                .padding()
        }
    }
}

struct TimeStacksView: View {
    @State var date: Date
    @State var stacks: [Date: [Log]]
    @State var alignInterval: TimeInterval
    var body: some View {
        let timeslots = stride(from: date.dateBegin.secondsSince2001, to: date.dateBegin.nextDay.secondsSince2001, by: Int(alignInterval))
            .map { Date(timeIntervalSinceReferenceDate: TimeInterval($0)) }
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(timeslots) { slot in
                    VStack(alignment: .center, spacing: 2) {
                        ForEach(stacks[slot]?.totals ?? [], id: \.appId) { total in
                            Rectangle().frame(width: 5, height: total.duration / 3, alignment: .bottom)
                        }
                    }
                }
            }
        }
    }
}

extension Date: Identifiable {
    public typealias ID = Int
    public var id: ID {
        return secondsSince2001
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static let model: ViewModel = {
        let result = ViewModel()
        result.dateLogs = [
            LogStruct(timelineId: "qwe", timeslotStart: Date(), appId: "123", activityName: "eger", duration: 50),
            LogStruct(timelineId: "qwe", timeslotStart: Date(), appId: "app2", activityName: "demo2", duration: 230),
            LogStruct(timelineId: "qwe", timeslotStart: Date(), appId: "app3", activityName: "time", duration: 20),
            LogStruct(timelineId: "qwe", timeslotStart: Date(), appId: "123", activityName: "eger", duration: 50),
        ]
        return result
    }()
    
    static var previews: some View {
        StatisticsView(viewModel: model)
    }
}

struct TopAppsView: View {
    @State var topApps: [AppTotal] = []
    var body: some View {
        ForEach(topApps.prefix(5)) { app in
            HStack {
                Text(app.activity)
                Spacer()
                Text(app.duration.readableTime)
            }
        }
    }
}

extension TimeInterval {
    var readableTime: String {
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: self)!
    }
}

extension Array where Element == Log {
    var totals: [AppTotal] {
        return Dictionary(grouping: self) { log in
                return AppKey(appId: log.appId, activity: log.activityName)
            }
        .map { (app, logs) -> AppTotal in
            return AppTotal(appId: app.appId, activity: app.activity, duration: logs.reduce(0.0 as TimeInterval, {
                return $0 + $1.duration
            }))
        }
        .sorted { l, r in
            l.duration > r.duration
        }
    }
    var timeslots: [Date: [Log]] {
        return Dictionary(grouping: self, by: { $0.timeslotStart })
            .mapValues { logs in
                return logs.sorted { l, r in
                    if l.timelineId == r.timelineId {
                        return l.appId < r.appId
                    }
                    return l.timelineId < r.timelineId
                }
            }
    }
}

struct AppTotal {
    var appId: String
    var activity: String
    var duration: TimeInterval
}

extension AppTotal: Identifiable {
    var id: String {
        return appId + activity
    }
}
