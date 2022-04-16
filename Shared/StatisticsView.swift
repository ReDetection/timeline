import SwiftUI
import TimelineCore

class ViewModel: ObservableObject {
    @Published var chosenDate: Date = Date()
    @Published var dateLogs: [Log] = []
    @Published var interval: TimeInterval = 15*60
}

struct StatisticsView: View {
    @StateObject var viewModel: ViewModel
    var body: some View {
        VStack {
            //todo date selector
            TimeStacksView(date: viewModel.chosenDate, stacks: viewModel.dateLogs.timeslots(alignInterval: viewModel.interval), alignInterval: viewModel.interval)
            Spacer(minLength: 16)
            TopAppsView(topApps: viewModel.dateLogs.totals)
        }
    }
}

struct TimeStacksView: View {
    @State var date: Date
    @State var stacks: [Date: [Log]]
    @State var alignInterval: TimeInterval
    let secondsInHour: TimeInterval = 60*60
    
    func hourView(hourBegin: Date) -> some View {
        let timeslots = (0..<Int(secondsInHour / alignInterval)).map { hourBegin.addingTimeInterval(alignInterval * TimeInterval($0)) }
        return HStack(alignment: .bottom, spacing: 2) {
            Rectangle()
                .fill(Color.gray)
                .frame(width: 1, height: 30)
            
            ForEach(timeslots) { slot in
                VStack(alignment: .center, spacing: 2) {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 5, height: 0, alignment: .bottom)
                    ForEach(stacks[slot]?.totals ?? [], id: \.appId) { total in
                        Rectangle()
                            .fill(total.appId.colorize)
                            .frame(width: 5, height: total.duration / 5, alignment: .bottom)
                            .contextMenu {
                                Text("\(total.activity): \(total.duration.readableTime)")
                            }
                    }
                }
            }
        }
    }
    
    var body: some View {
        let hours = stride(from: date.dateBegin.secondsSince2001, to: date.dateBegin.nextDay.secondsSince2001, by: Int(secondsInHour))
            .map { Date(timeIntervalSinceReferenceDate: TimeInterval($0)) }
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(hours) { hour in
                VStack(alignment: .leading) {
                    hourView(hourBegin: hour)
                    Text("\(hour.hour)")
                        .lineLimit(1)
                        .scaledToFill()
                }
            }
        }
        .frame(minWidth: 400, minHeight: 200, alignment: .bottom)
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
            LogStruct(timelineId: "qwe", timeslotStart: Date().alignedToHour, appId: "123", activityName: "eger", duration: 50),
            LogStruct(timelineId: "qwe", timeslotStart: Date().alignedToHour, appId: "app2", activityName: "demo2", duration: 230),
            LogStruct(timelineId: "qwe", timeslotStart: Date().alignedToHour, appId: "app3", activityName: "time", duration: 20),
            LogStruct(timelineId: "qwe", timeslotStart: Date().alignedToHour, appId: "123", activityName: "eger", duration: 50),
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
        ScrollView {
            LazyVStack {
                ForEach(topApps) { app in
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(app.appId.colorize)
                            .frame(width: 20, height: 20, alignment: .center)
                        Text(app.activity)
                        Spacer()
                        Text(app.duration.readableTime)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

extension TimeInterval {
    var readableTime: String {
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
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

extension String {
    var colorize: Color {
        return [Color.blue, .brown, .cyan, .gray, .green, .orange, .pink, .purple, .red , .yellow, .black, .white, .mint, .indigo][abs(self.hashValue) % 14]
    }
}
