import Foundation
import FluentSQLite
import Vapor

final class BathroomSession: Content {
    public var id: UUID?
    public var date: Date
    public var length: Double
    
    init(date: Date=Date(), length: Double=0) {
        self.date = date
        self.length = length
    }
}

extension BathroomSession: Model, Migration {
    typealias Database = SQLiteDatabase
    typealias ID = UUID
    
    static var idKey: ReferenceWritableKeyPath<BathroomSession, UUID?> {
        return \.id
    }
}
