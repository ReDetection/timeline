import SwiftUI
import TimelineCore

class ViewModel: ObservableObject {
    @Published var chosenDate: Date = Date()
    @Published var dateLogs: [Log] = []
    @Published var interval: TimeInterval = 15*60
    var loadDate: (Date)->() = { _ in }
}

extension AppColor {
    var uiColor: Color {
        switch self {
        case .top1: return Color(red: 98.0/255, green: 148.0/255, blue: 255.0/255)
        case .top2: return Color(red: 234.0/255, green: 124.0/255, blue: 207.0/255)
        case .top3: return Color(red: 154.0/255, green: 90.0/255, blue: 96.0/255)
        case .top4: return Color(red: 111.0/255, green: 249.0/255, blue: 255.0/255)
        case .top5: return Color(red: 220.0/255, green: 203.0/255, blue: 116.0/255)
        case .otherEven: return .white
        case .otherOdd: return .gray
        }
    }
}

struct StatisticsView: View {
    @StateObject var viewModel: ViewModel
    var body: some View {
        VStack(alignment: .center) {
            HStack(alignment: .firstTextBaseline, spacing: 140) {
                DateSelector(date: viewModel.chosenDate, didSelect: viewModel.loadDate)
                    .frame(width: 200, alignment: .leading)
                Spacer()
                Text("Total: \(viewModel.dateLogs.grandTotal.readableTime)")
            }
            .padding()
            let totals = viewModel.dateLogs.totals
            let colorConfiguration = Dictionary(uniqueKeysWithValues: totals.map { (AppKey(appId: $0.appId, activity: $0.activity), $0.assignedColor.uiColor) } )
            TimeStacksView(date: viewModel.chosenDate, stacks: viewModel.dateLogs.timeslots(alignInterval: viewModel.interval), alignInterval: viewModel.interval, colors: colorConfiguration, appOrder: totals.map { $0.appId } )
            Spacer(minLength: 16)
            TopAppsView(topApps: totals, colors: colorConfiguration)
        }
    }
}

struct DateSelector: View {
    @State var date: Date
    var didSelect: (Date) -> ()
    var body: some View {
        DatePicker("Show date", selection: $date, in: ...Date(), displayedComponents: .date)
            .onChange(of: date, perform: { newValue in
                didSelect(newValue)
            })
    }
}

struct TimeStacksView: View {
    var date: Date
    var stacks: [Date: [Log]]
    var alignInterval: TimeInterval
    let secondsInHour: TimeInterval = 60*60
    let fitFactor = 1.0/5.0
    let colors: [AppKey: Color]
    let appOrder: [String]
    
    func hourView(hourBegin: Date) -> some View {
        let timeslots = (0..<Int(secondsInHour / alignInterval)).map { hourBegin.addingTimeInterval(alignInterval * TimeInterval($0)) }
        return HStack(alignment: .bottom, spacing: 2) {
            Rectangle()
                .fill(Color.gray)
                .frame(width: 1, height: 5*60 * fitFactor)
            
            ForEach(timeslots) { slot in
                VStack(alignment: .center, spacing: 0) {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 5, height: 0, alignment: .bottom)
                    let sortedTotals = stacks[slot]?.totals.sorted { appOrder.firstIndex(of: $0.appId) ?? 99999 > appOrder.firstIndex(of: $1.appId) ?? 99999 }
                    ForEach(sortedTotals ?? []) { total in
                        Rectangle()
                            .fill(colors[AppKey(appId: total.appId, activity: total.activity)] ?? .green)
                            .frame(width: 5, height: total.duration * fitFactor, alignment: .bottom)
                            .contextMenu {
                                Text("\(total.activity): \(total.duration.readableTime)")
                            }
                    }
                }
                .frame(height: alignInterval * fitFactor, alignment: .bottom)
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
        .frame(width: 800, alignment: .center)
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
    var topApps: [AppTotal] = []
    let colors: [AppKey: Color]
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Spacer()
                ForEach(topApps) { app in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(colors[AppKey(appId: app.appId, activity: app.activity)] ?? .clear)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.horizontal, 8)
                        Text(app.activity)
                        Spacer()
                        Text(app.duration.readableTime)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                Spacer()
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

extension AppTotal: Identifiable {
    public var id: String {
        return appId + activity
    }
}
