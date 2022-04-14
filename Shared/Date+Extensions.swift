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

}
