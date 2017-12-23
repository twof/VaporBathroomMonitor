import Foundation
import FluentSQLite
import Vapor

final class Reservation: Content {
    public var id: UUID?
    public var user: String
    public var date: Date
    
    init(user: String, date: Date=Date()) {
        self.user = user
        self.date = date
    }
}

extension Reservation: Model, Migration {
    typealias Database = SQLiteDatabase
    typealias ID = UUID
    
    static var idKey: ReferenceWritableKeyPath<BathroomSession, UUID?> {
        return \.id
    }
}

