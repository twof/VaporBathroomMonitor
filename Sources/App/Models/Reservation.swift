import Foundation
import FluentMySQL
import Vapor

public final class Reservation: Content {
    public var id: UUID?
    public var user: String
    public var date: Date
    public var isInQueue: Bool
    
    init(user: String, date: Date=Date(), isInQueue: Bool=true) {
        self.user = user
        self.date = date
        self.isInQueue = isInQueue
    }
    
    public struct PublicIncomingReservation: Content {
        public var user: String
        
        public func toReservation() -> Reservation {
            return Reservation(user: self.user)
        }
    }
}

extension Reservation: MySQLUUIDModel, Migration, Parameter {
}

