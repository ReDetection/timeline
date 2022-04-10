import SwiftUI
import TimelineCore

class ViewModel: ObservableObject {
    @Published var chosenDate: Date = Date()
    @Published var dateLogs: [Log] = []
}

struct StatisticsView: View {
    @StateObject var viewModel: ViewModel
    var body: some View {
        VStack {
            //todo date selector
            //todo stacked time bars
            TopAppsView(topApps: viewModel.dateLogs.totals)
                .padding()
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static let model: ViewModel = {
        let result = ViewModel()
        result.dateLogs = [
            LogStruct(timelineId: "qwe", timeslotStart: Date(), appId: "123", trackedIdentifier: "eger", duration: 50),
            LogStruct(timelineId: "qwe", timeslotStart: Date(), appId: "app2", trackedIdentifier: "demo2", duration: 230),
            LogStruct(timelineId: "qwe", timeslotStart: Date(), appId: "app3", trackedIdentifier: "time", duration: 20),
            LogStruct(timelineId: "qwe", timeslotStart: Date(), appId: "123", trackedIdentifier: "eger", duration: 50),
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
                return AppKey(appId: log.appId, activity: log.trackedIdentifier)
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
