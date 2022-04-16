import Foundation

extension Date {
    
    var dateBegin: Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: dayComponents)!
    }
    var alignedToHour: Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        return calendar.date(from: dayComponents)!
    }
    
    func dateByAddingDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
    
    var nextDay: Date {
        return dateByAddingDays(1)
    }
    
    var secondsSince2001: Int {
        return Int(timeIntervalSinceReferenceDate)
    }
    
    var minute: Int {
        return Calendar.current.component(.minute, from: self)
    }
    
    var hour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    func aligned(to timeInterval: TimeInterval) -> Date {
        return Date(timeIntervalSinceReferenceDate: self.timeIntervalSinceReferenceDate.shrinkDown(within: timeInterval))
    }

}
extension TimeInterval {
    func shrinkDown(within timeInterval: TimeInterval) -> TimeInterval {
        return TimeInterval(floor(self / timeInterval) * timeInterval);
    }
}
