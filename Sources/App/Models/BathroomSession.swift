import Foundation
import FluentMySQL
import Vapor

final public class BathroomSession: Content, MySQLUUIDModel, Migration, Parameter  {
    public var id: UUID?
    public var date: Date
    public var length: Double
    public var isOngoing: Bool
    
    init(date: Date=Date(), length: Double=0, isOngoing: Bool=true) {
        self.date = date
        self.length = length
        self.isOngoing = isOngoing
    }
}

