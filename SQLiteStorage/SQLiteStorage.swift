import Foundation
import SQLite
import TimelineCore

public class SQLiteStorage: Storage {
    let db: Connection
    
    let appsTable = Table("apps")
    let idColumn = Expression<String>("id")
    let trackingMode = Expression<TrackingMode>("trackingMode")
    
    let timelinesTable = Table("timelines")
    let deviceName = Expression<String>("deviceName")
    let deviceSystem = Expression<String>("deviceSystem")
    let timezoneName = Expression<String>("timezoneName")
    let timezoneShift = Expression<TimeInterval>("timezoneShift")
    let dateStart = Expression<Date>("dateStart")
    
    let logsTable = Table("logs")
    let timelineId = Expression<String>("timelineId")
    let timeslotStart = Expression<Date>("timeslotStart")
    let appId = Expression<String>("appId")
    let activityName = Expression<String>("activityName")
    let duration = Expression<TimeInterval>("duration")

    public init(filepath: String) throws {
        db = try Connection(filepath)
        try db.run(appsTable.create(ifNotExists: true) {
            $0.column(idColumn, primaryKey: true)
            $0.column(trackingMode)
        })
        try db.run(appsTable.createIndex(idColumn, unique: true, ifNotExists: true))
        try db.run(timelinesTable.create(ifNotExists: true) {
            $0.column(idColumn, primaryKey: true)
            $0.column(deviceName)
            $0.column(deviceSystem)
            $0.column(timezoneName)
            $0.column(timezoneShift)
            $0.column(dateStart)
        })
        try db.run(timelinesTable.createIndex(idColumn, unique: true, ifNotExists: true))
        try db.run(logsTable.create(ifNotExists: true) {
            $0.column(timelineId)
            $0.column(timeslotStart)
            $0.column(appId)
            $0.column(activityName)
            $0.column(duration)
            $0.foreignKey(timelineId, references: timelinesTable, idColumn)
            $0.foreignKey(appId, references: appsTable, idColumn)
        })
        try db.run(logsTable.createIndex(timeslotStart, unique: false, ifNotExists: true))
    }
    
    public func store(log: Log) {
        try! db.run(logsTable.insert(
            timelineId <- log.timelineId,
            timeslotStart <- log.timeslotStart,
            appId <- log.appId,
            activityName <- log.activityName,
            duration <- log.duration
        ))
    }
    
    public func store(app: App) {
        try! db.run(appsTable.upsert(
            idColumn <- app.id,
            trackingMode <- app.trackingMode,
            onConflictOf: idColumn))
    }
    
    public func store(timeline: Timeline) {
        try! db.run(timelinesTable.upsert(
            idColumn <- timeline.id,
            deviceName <- timeline.deviceName,
            deviceSystem <- timeline.deviceSystem,
            timezoneName <- timeline.timezoneName,
            timezoneShift <- timeline.timezoneShift,
            dateStart <- timeline.dateStart,
            onConflictOf: idColumn))
    }
    
    public func fetchLogs(since: Date, till: Date) -> [Log] {
        let logs: [LogStruct] = try! db.prepare(logsTable.filter(timeslotStart >= since && timeslotStart < till))
            .map { try $0.decode() }
        return logs
    }
    
    public func fetchApps() -> [String : App] {
        let apps: [AppStruct] = try! db.prepare(appsTable).map { row -> AppStruct in
            return AppStruct(id: try! row.get(idColumn), trackingMode: try! row.get(trackingMode))
        }
        return Dictionary(grouping: apps) { $0.id } .mapValues { $0[0] }
    }
    
    public func fetchTimeline(id: String) -> Timeline? {
        let timelines: [TimelineStruct] = try! db.prepare(timelinesTable.filter(idColumn == id).limit(1)).map { try $0.decode() }
        return timelines.first
    }
}

extension TrackingMode: Value {
    public typealias Datatype = String
    public static var declaredDatatype: String = String.declaredDatatype

    public static func fromDatatypeValue(_ datatypeValue: String) -> TrackingMode {
        return TrackingMode(rawValue: datatypeValue) ?? .app
    }

    public var datatypeValue: String {
        return self.rawValue
    }
}
