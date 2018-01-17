import Routing
import Vapor
import Foundation
import HTTP
import FluentMySQL
/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public final class Routes: RouteCollection {
    /// Use this to create any services you may
    /// need for your routes.
    let app: Application
    
    var bathroomOccupied = false {
        didSet {
            if oldValue == true {
                currentSession.length = Date().timeIntervalSince1970 - currentSession.date.timeIntervalSince1970
                app.withConnection(to: .mysql) { (db) -> Future<BathroomSession> in
                    self.currentSession.save(on: db).transform(to: self.currentSession)
                }.catch {
                    print($0)
                }
            } else {
                currentSession = BathroomSession()
            }
        }
    }
    var currentSession: BathroomSession = BathroomSession()

    /// Create a new Routes collection with
    /// the supplied application.
    init(app: Application) {
        self.app = app
    }

    /// See RouteCollection.boot
    public func boot(router: Router) throws {
        router.get("hello") { req in
            return Future("Hello, world!")
        }
        
        /// updates isOccupied
        router.post("update") { (req) -> Future<String> in
            guard let isOccupied: Bool = try? req.content.get(at: ["occupied"]) else {
                throw Abort(.badRequest, reason: "Bad JSON data. Expected boolean \"occupied\" field")
            }
            self.bathroomOccupied = isOccupied
            return Future(String(describing: self.bathroomOccupied))
        }
        
        /// retreieves whether or not the bathroom is available
        router.get("isAvailable") { (req) -> Future<Response>  in
           
            let res: Response = Response(using: req)
            try res.content.encode(["isOccupied":self.bathroomOccupied], as: .json)
            return Future(res)
        }
        
        /// returns the BathroomSession with the longest time
        router.get("highScore") { (req) -> Future<BathroomSession> in
            return req.withConnection(to: .mysql) { (db: MySQLConnection) in
                db
                    .query(BathroomSession.self)
                    .max(\BathroomSession.length)
                    .flatMap(to: BathroomSession?.self) { (maxVal) in
                        return db
                            .query(BathroomSession.self)
                            .filter(\BathroomSession.length == maxVal).first()
                    }.unwrap(or: Abort(.notFound, reason: "No BathroomSessions in DB"))
                }
        }
        
        router.get("allSessions") { (req) -> Future<[BathroomSession]> in
            let allSessionsFuture =  BathroomSession
                .query(on: req)
                .all()
            
            allSessionsFuture.catch { print("allSesssions error: ", $0) }
            
            return allSessionsFuture
        }
        
        router.delete("reservation") { (req) -> Future<HTTPStatus> in
            guard let userName: String = try req.content.get(at: ["user"]) else {
                throw Abort(.badRequest, reason: "Bad JSON data. Expected string \"user\" field")
            }
            
            return Reservation
                .query(on: req)
                .filter(\Reservation.user == userName)
                .first()
                .unwrap(or: Abort(.notFound, reason: "No reservations have been made"))
                .map(to: HTTPStatus.self) { _ in
                    return .ok
                }
        }
        
        router.post("reservation") { (req) -> Future<Reservation> in
            if !self.bathroomOccupied {
                
            }
            
            guard let userName: String = try req.content.get(at: ["user"]) else {
                throw Abort(.badRequest, reason: "Bad JSON data. Expected string \"user\" field")
            }
            
            let newReservation = Reservation(user: userName)
            
            return Reservation.query(on: req).save(newReservation).transform(to: newReservation)
        }
        
        router.get("nextReservation") { (req) -> Future<Reservation> in
            return Reservation
                .query(on: req)
                .sort(\Reservation.date, .ascending)
                .first()
                .flatMap(to: Reservation.self) { (reservation) in
                    guard let reservation = reservation else {
                        throw Abort(.notFound, reason: "No reservations found")
                    }
                    
                    return Future(reservation)
            }
        }
        
        router.get("allReservations") { (req) -> Future<[Reservation]> in
            return Reservation.query(on: req).all()
        }
    }
}

//protocol OptionalType { }
//
//extension Optional: OptionalType {}
//
//extension Future<Optional<T>> {
//
//}
//
//extension Future where T: Optional {
//    func unwrapOrAbort<Unwrapped>(to: Unwrapped.Type, _ status: HTTPStatus, reason: String?=nil, identifier: String?=nil) throws -> Future<Unwrapped> {
//        return self.map(to: Unwrapped.self) { (input) -> Unwrapped in
//
//            if input == nil {
//                throw Abort(status, reason: reason, identifier: identifier)
//            }
//
//            return input as! Unwrapped
//        }
//    }
//}

