import Foundation
import FluentMySQL
import Vapor

public final class Reservation: Content {
    public var id: UUID?
    public var user: String
    public var date: Date
    
    init(user: String, date: Date=Date()) {
        self.user = user
        self.date = date
    }
}

extension Reservation: MySQLUUIDModel, Migration {
}

