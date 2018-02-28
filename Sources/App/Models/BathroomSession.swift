import Foundation
import FluentMySQL
import Vapor

final public class BathroomSession: Content, MySQLUUIDModel, Migration, Parameter  {
    public var id: UUID?
    public var date: Date
    public var length: Double
    public var isOngoing: Int // Using a int instead of a bool because mysql is missing support for Bools at the moment
    
    init(date: Date=Date(), length: Double=0, isOngoing: Int=1) {
        self.date = date
        self.length = length
        self.isOngoing = isOngoing
    }
}

