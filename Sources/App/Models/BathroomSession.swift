import Foundation
import FluentMySQL
import Vapor

final public class BathroomSession: Content, MySQLUUIDModel, Migration, Parameter  {
    public var id: UUID?
    public var date: Date
    public var length: Double
    public var isOpen: Int // Using a int instead of a bool because mysql is missing support for Bools at the moment
    
    init(date: Date=Date(), length: Double=0, isOpen: Int=0) {
        self.date = date
        self.length = length
        self.isOpen = isOpen
    }
}

