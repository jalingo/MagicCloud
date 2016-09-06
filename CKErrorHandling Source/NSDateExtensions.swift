//
//  NSDateExtensions.swift
//  TestableVoyager
//
//  Created by Jimmy Lingo on 5/21/16.
//  Copyright © 2016 Stellar Software. All rights reserved.
//

import Foundation

/**
 * This extension to NSDate allows for simplified series of methods that handle
 * comparisons and convenience methods to add days / hours.
 */
extension Date {
    
    /// Returns true if 'dateToCompare' is after current NSDate.
    func isAfter(_ dateToCompare: Date) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    /// Returns true if 'dateToCompare' is before current NSDate.
   func isBefore(_ dateToCompare: Date) -> Bool {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    /// Returns true if 'dateToCompare' is equal to current NSDate.
    func isTheSame(_ dateToCompare: Date) -> Bool {
        //Declare Variables
        var isEqualTo = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedSame {
            isEqualTo = true
        }
        
        //Return Result
        return isEqualTo
    }
    
    /// Returns NSDate instance that is 'dayToAdd' days later than current NSDate.
    func addDays(_ daysToAdd: Int) -> Date {
        let secondsInDays: TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded: Date = self.addingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    /// Returns NSDate instance that is 'hoursToAdd' hours later than current NSDate.
    func addHours(_ hoursToAdd: Int) -> Date {
        let secondsInHours: TimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded: Date = self.addingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
    
    /// Returns difference between current and 'dateToCompare' in minutes.
    /// Expected return value is an absolute (positive) number, -1 being a failure...
    /// Needs to be tested, beta playground keeps crashing :(
    func differenceFrom(_ dateToCompare: Date) -> Int {
        guard self != dateToCompare else { return 0 }
        
        var from: Date
        var to: Date
        
        if self.isAfter(dateToCompare) {
            from = dateToCompare
            to = self
        } else {
            from = self
            to = dateToCompare
        }
        
        return Calendar.current.dateComponents([.minute, .day, .month, .year], from: from, to: to).minute ?? -1
        
//        return NSCalendar.current.components(.minute, from: from, to: to, options: NSCalendar.Options(rawValue: 0)).minute ?? -1
    }
}
