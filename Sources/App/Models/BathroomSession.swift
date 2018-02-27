import Foundation
import FluentMySQL
import Vapor

final public class BathroomSession: Content {
    public var id: UUID?
    public var date: Date
    public var length: Double
    
    init(date: Date=Date(), length: Double=0) {
        self.date = date
        self.length = length
    }
}

extension BathroomSession: MySQLUUIDModel, Migration {
}

extension BathroomSession: Parameter {}
