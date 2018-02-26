import Routing
import Vapor
import Foundation
import HTTP
import FluentMySQL
import FluentSQLite
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
        router.post("update") { (req) -> Future<Response> in
            return try req.content["occupied"]
                .unwrap(or: Abort(.badRequest, reason: "Missing occupied field in body"))
                .do { isOccupied in
                    self.bathroomOccupied = isOccupied
                }.map(to: HTTPStatus.self) { _ in
                    return .ok
                }.encode(for: req)
        }
        
        /// retreieves whether or not the bathroom is available
        router.get("isAvailable") { (req) -> Future<Response>  in
            let ses = BathroomSession(date: Date(), length: 10)
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
        
        router.get("session") { (req) -> Future<[BathroomSession]> in
            let allSessionsFuture = BathroomSession
                .query(on: req)
                .all()
            
            allSessionsFuture.catch { print("allSesssions error: ", $0) }
            
            return allSessionsFuture
        }
        
//        router.get("session", BathroomSession.parameter) { (req) -> Future<BathroomSession> in
//            return try req.parameter(BathroomSession.self)
//        }
        
        router.get("session", BathroomSession.parameter) { (req) -> Future<Response> in // Take in a request
            let bathroomSession = try req.parameter(BathroomSession.self) // Turn that request into an ID
            
            return try bathroomSession
                .changeName(to: "Jamie")
                .encode(for: req) // Turn that object into a response, and return that response
        }
        
//        router.delete("reservation") { (req) -> Future<Response> in
//            return try req.content["user"]
//                .unwrap(or: Abort(.badRequest, reason: "Missing user field in body"))
//                .flatMap(to: HTTPStatus.self) { (userName) in
//                    return self.deleteReservation(using: req, withName: userName)
//                }.encode(for: req)
//        }
//        
//        router.post("reservation") { (req) -> Future<Reservation> in
//            if !self.bathroomOccupied {
//
//            }
//
//                guard let userName: String = try req.content.get(at: ["user"]) else {
//                    throw Abort(.badRequest, reason: "Bad JSON data. Expected string \"user\" field")
//                }
//
//                let newReservation = Reservation(user: userName)
//
//                return Reservation.query(on: req).save(newReservation).transform(to: newReservation)
//        }
        
        router.post("reservation") { (req) -> Future<Reservation> in
            let newReservation = Reservation(user: "Test")
            
            return Reservation.query(on: req).save(newReservation).transform(to: newReservation)
        }
        
        router.get("nextReservation") { (req) -> Future<Reservation> in
            return Reservation
                .query(on: req)
                .sort(\Reservation.date, .ascending)
                .first()
                .unwrap(or: Abort(.notFound, reason: "No reservations found"))
        }
        
        router.get("allReservations") { (req) -> Future<[Reservation]> in
            return Reservation.query(on: req).all()
        }
        
        router.get("firstReservation") { req in
            return try Reservation
                .query(on: req)
                .first()
                .unwrap(or: Abort(.notFound, reason: "Reservation not found"))
                .encode(for: req)
        }
        
        router.delete("reservation", String.parameter) { (req) -> Future<HTTPStatus> in
            let name = try req.parameter(String.self)
            return try self.deleteReservation(using: req, withName: name)
        }
    }
    
    func deleteReservation(using databaseConnectable: DatabaseConnectable, withName userName: String) throws -> Future<HTTPStatus> {
        final class Bar: SQLiteModel {
            var id: Int?
            var name: String
        }
        return Reservation
            .query(on: databaseConnectable)
            .filter(\Reservation.user == userName)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No reservations have been made"))
            .delete(on: databaseConnectable)
            .map(to: HTTPStatus.self) { _ in
                return .ok
            }
    }
}

extension Future {
    func join<S>(otherFuture: Future<S>) -> Future<(T, S)> {
        return self.flatMap(to: (T, S).self, { (thisExpectation: T) -> Future<(T, S)> in
            return otherFuture.map(to: (T, S).self, { (otherExpectation: S) in
                return (thisExpectation, otherExpectation)
            })
        })
    }
}

extension QueryBuilder {
    func aside(_ closure: (QueryBuilder) -> ()) -> Self {
        closure(self)
        return self
    }
}

extension Future where T == BathroomSession {
    public func changeName(to: String) -> Future<Expectation> {
        return self.map(to: BathroomSession.self) { (user) in
            user.date = Date()
            return user
        }
    }
}

extension QueryBuilder where Model == Reservation {
    func validNumberOfReservationsInDatabase() -> Self {
        let invalidNumberOfReservationsError = Abort(.badRequest, reason: "There are an unusual number of reservations matching that query in your DB", identifier: "Whoops")
        
        self
            .count()
            .assertEquals(0, 1)
            .guard(elseThrow: invalidNumberOfReservationsError)
        
        return self
    }
}

public extension Future where T: Equatable {
    /// Assert the value being passed along the chain is equal to the value passed in
    /// Return true if it is, false if it's not
    public func assertEquals(_ val: T) -> Future<Bool> {
        return self.map(to: Bool.self) { (currentVal) in
            return currentVal == val
        }
    }
    
    /// Assert the value being passed along the chain is equal to one of many values
    /// Return true if it is, false if it's not
    public func assertEquals(_ vals: T...) -> Future<Bool> {
        return self.map(to: Bool.self) { (currentVal) in
            return vals.contains(currentVal)
        }
    }
}

public extension Future where T == Bool {
    
    /// Acts guards against whatever it's being chained with
    /// If true, continue the chain
    /// Else, throw the supplied error
    @discardableResult
    public func `guard`(elseThrow error: Error) -> Future<Bool> {
        return self.map(to: Bool.self) { (check) in
            guard check else {throw error}
            return check
        }
    }
}

//func registerUser(_ req: Request) throws -> Future<User.PublicUser> {
//    return try req.content
//        .decode(RegisterRequest.self)
//        .flatMap(to: User.PublicUser.self) { registerRequest in
//            let userExistsError = Abort(.badRequest, reason: "User exists!", identifier: "Whoops")
//
//            return User.query(on: req)
//                .filter(\.email == registerRequest.email)
//                .count()
//                .assertEquals(0)
//                .guard(elseThrow: userExistsError)
//                .saveUserWith(
//                    name: registerRequest.name,
//                    email: registerRequest.email,
//                    password: registerRequest.password,
//                    on: req
//                ).map(to: Token.self) { newUser in
//                    print(newUser.id)
//                }
//    }
//}


//extension Future {
//    public func saveUserWith(
//        name: String,
//        email: String,
//        password: String,
//        on connectable: DatabaseConnectable
//    ) -> Future<User.PublicUser> {
//        let hasher = try req.make(BCryptHasher.self)
//        let hashedPassword = try hasher.make(password)
//
//        let newUser = User(name: name, email: email, password: hashedPassword)
//        try connectable.authenticate(newUser)
//        return newUser.save(on: req).map(to: User.PublicUser.self){ aUser in
//            return try aUser.publicUser(token: "test")
//        }
//    }
//}

/// Create a new reservation if one doesn't already exist belonging to that user
func create(_ req: Request) throws -> Future<Reservation> {
    return try req.content.decode(Reservation.self).flatMap(to: Reservation.self) { reservation in
        return Reservation
            .doesUserExist(named: reservation.user, on: req)
            .then(
                save: reservation,
                on: req,
                elseThrow: Abort(HTTPStatus.badRequest, reason: "Reservation Already Exists")
        )
    }
}

extension Future where T == Bool{
    public func then<U: Model>(
        save model: U, on connectable: DatabaseConnectable,
        elseThrow error: Error
    ) -> Future<U> where U.Database: QuerySupporting {
        return self.flatMap(to: U.self) { (isTrue) in
            if (isTrue) { return model.save(on: connectable) } else { throw error }
        }
    }
}

extension String: Error {}

extension Future {
    func testThrows() throws -> Future<T> {
        if 1 != 1 {
            throw "This is a test error"
        }
        return self
    }
}

extension Content {
    public func json() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
}


extension Future where T: Model, T.Database: QuerySupporting {
    public func delete(on connectable: DatabaseConnectable) -> Future<T> {
        return self.flatMap(to: T.self) { (model) in
            return model.delete(on: connectable).transform(to: model)
        }
    }
}

extension Reservation {
    public static func doesUserExist(named user: String, on connectable: DatabaseConnectable) -> Future<Bool> {
        return query(on: connectable)
            .filter(\Reservation.user == user)
            .first()
            .map(to: Bool.self) { (user) in
                return user != nil
            }
    }
}


