import Routing
import Vapor
import Foundation
import HTTP
import FluentMySQL

extension Bool: Content {}

//extension FoundationClient {
//    public func get() {
//    }
//}

public func routes(_ router: Router) throws {
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    /// updates isOccupied
    router.post("update") { (req) -> Future<Response> in
        return try req.content[Bool.self, at:"occupied"]
            .unwrap(or: Abort(.notFound, reason: "Bad input. Looking for {\"occupied\":bool}"))
            .flatMap(to: Response.self) { isOccupied in
                if isOccupied {
                    return try BathroomSession
                        .query(on: req)
                        .filter(\.isOngoing == true)
                        .first()
                        .isNil(or: Abort(.notFound, reason: "There is already an ongoing session"))
                        .flatMap(to: BathroomSession.self) { _ in
                            let newSession = BathroomSession()
                            return newSession.save(on: req)
                        }.encode(for: req)
                } else {
                    return try BathroomSession
                        .query(on: req)
                        .filter(\.isOngoing == true)
                        .first()
                        .unwrap(or: Abort(.notFound, reason: "No Ongoing Sessions Found"))
                        .flatMap(to: BathroomSession.self) { (session: BathroomSession) in
                            session.isOngoing = false
                            session.length = Date().timeIntervalSince1970 - session.date.timeIntervalSince1970
                            return session.update(on: req)
                        }.flatMap(to: Reservation.self) { _ in
                            return try Reservation
                                .query(on: req)
                                .filter(\Reservation.isInQueue == true)
                                .sort(\Reservation.date, .ascending)
                                .first()
                                .unwrap(or: Abort(.notFound, reason: "No reservations found"))
                        }.map(to: Reservation.self) { (res) in
                            let updated = res
                            updated.isInQueue = false
                            return updated
                        }.update(on: req)
                        .flatMap(to: String.self) { reservation in
                            guard let botToken = ProcessInfo.processInfo.environment["SLACK_BOT_TOKEN"]
                                else { throw Abort(.notFound) }

                            let client = try req.make(Client.self)

                            struct OpenConversationParams: Content {
                                static var defaultMediaType: MediaType = .urlEncodedForm
                                
                                let token: String
                                let userId: String

                                enum CodingKeys: String, CodingKey {
                                    case token
                                    case userId = "user"
                                }
                            }

                            let params = OpenConversationParams(token: botToken, userId: reservation.user)

                            return client
                                .post("https://slack.com/api/im.open", content: params)
                                .map(to: String.self) { response in
                                    let channel = try response.content.syncGet(String.self, at: "channel", "id")
                                    return channel
                                }
                        }.flatMap(to: Response.self) { channel in
                            return try sendSlackMessage(on: req, message: "The restroom is ready for you", channel: channel)
                        }
                }
            }
    }
    
    /// retreieves whether or not the bathroom is available
    router.get("isAvailable") { (req) in
        return try BathroomSession
            .query(on: req)
            .filter(\.isOngoing == true)
            .first()
            .map(to: Bool.self) { (session) -> Bool in
                return session == nil
            }.map(to: [String:Bool].self) { (isAvailable) in
                return ["isAvailable":isAvailable]
            }
    }
    
    /// returns the BathroomSession with the longest time
    router.get("highScore") { (req) -> Future<BathroomSession> in
        return req.withConnection(to: .mysql) { (db: MySQLConnection) in
            try db
                .query(BathroomSession.self)
                .max(\BathroomSession.length)
                .flatMap(to: BathroomSession?.self) { (maxVal) in
                    return try db
                        .query(BathroomSession.self)
                        .filter(\BathroomSession.length == maxVal).first()
                }.unwrap(or: Abort(.notFound, reason: "No BathroomSessions in DB"))
        }
    }
    
    router.get("session") { (req) -> Future<[BathroomSession]> in
        return BathroomSession
            .query(on: req)
            .all()
            .catch { print("allSesssions error: ", $0) }
    }
    
    router.get("session", BathroomSession.parameter) { (req) -> Future<BathroomSession> in
        let bathroomSession = try req.parameter(BathroomSession.self)
        
        return bathroomSession
    }
    
    router.post(Reservation.PublicIncomingReservation.self, at: "reservation", use: ReservationController.saveReservation)
    
    router.get("nextReservation") { (req) -> Future<Reservation> in
        return try Reservation
            .query(on: req)
            .filter(\.isInQueue == true)
            .sort(\Reservation.date, .ascending)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No reservations found"))
    }
    
    router.put("reservation", Reservation.parameter, "fulfill") { (req) -> Future<Reservation> in
        let reservation = try req.parameter(Reservation.self)
        
        return reservation.map(to: Reservation.self) { (res) in
            let updated = res
            updated.isInQueue = false
            return updated
        }.update(on: req)
    }
    
    router.get("reservation") { (req) -> Future<[Reservation]> in
        return Reservation.query(on: req).all()
    }
    
    router.get("test") { (req) -> [String: String] in
        let dict = ["hello": "world"]
        return dict
    }

    let slackGroup = router.grouped("slack")

    slackGroup.post(SlashCommand.self, at: "available") { (req, command) -> Future<SlashCommandResponse> in
        guard ProcessInfo.processInfo.environment["SLACK_VERIFICATION_TOKEN"] == command.token
            else { throw Abort(HTTPResponseStatus.unauthorized) }

        return try BathroomSession
            .query(on: req)
            .filter(\.isOngoing == true)
            .first()
            .map(to: Bool.self) { (session) -> Bool in
                return session == nil
            }.map(to: SlashCommandResponse.self) { (isAvailable) in
                return (isAvailable)
                    ? SlashCommandResponse(responseType: .ephemeral, text: "The bathroom is available")
                    : SlashCommandResponse(responseType: .ephemeral, text: "The bathroom is not available")
        }
    }

    slackGroup.post(SlashCommand.self, at: "queue") { (req, command) -> Future<String> in
        let newReservation = Reservation.PublicIncomingReservation(user: command.userId)

        return try ReservationController
            .saveReservation(req: req, pubReservation: newReservation)
            .map(to: String.self) { _ in
                return "Welcome to the queue! You'll be notified when a bathroom is available"
            }
    }
}

func sendSlackMessage(on request: Request, message: String, channel: String) throws -> Future<Response> {
    struct SendMessageParams: Content {
        static var defaultMediaType: MediaType = .urlEncodedForm
        
        let token: String
        let channel: String
        let text: String
        let asUser: Bool
        
        enum CodingKeys: String, CodingKey {
            case token
            case channel
            case text
            case asUser = "as_user"
        }
    }
    
    guard let botToken = ProcessInfo.processInfo.environment["SLACK_BOT_TOKEN"]
        else { throw Abort(.notFound) }
    let client = try request.make(Client.self)
    
    let sendMessageParams = SendMessageParams(
        token: botToken,
        channel: channel,
        text: message,
        asUser: true
    )
    
    return client
        .post("https://slack.com/api/chat.postMessage", content: sendMessageParams)
        .map { resp in
            print(resp)
            return resp
    }
}

extension Client {
    func get<T: Content>(_ url: URLRepresentable, query: T, headers: HTTPHeaders = .init()) -> Future<Response> {
        let queryMirror = Mirror(reflecting: query)
        let url = "\(url)?"
        var queryStrings = [String]()
        
        for child in queryMirror.children {
            queryStrings.append("\(child.label!)=\(child.value)")
        }
        
        return self.get("\(url)\(queryStrings.joined(separator: "&"))", headers: headers)
    }
}

func deleteReservation(using databaseConnectable: DatabaseConnectable, withName userName: String) throws -> Future<HTTPStatus> {
    return try Reservation
        .query(on: databaseConnectable)
        .filter(\Reservation.user == userName)
        .first()
        .unwrap(or: Abort(.notFound, reason: "No reservations have been made"))
        .delete(on: databaseConnectable)
        .map(to: HTTPStatus.self) { _ in
            return .ok
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

public extension Future where Expectation: OptionalType {
    func isNil(or error: Error) -> Future<Expectation> {
        return self.map(to: Expectation.self) { (optional) in
            if optional.wrapped == nil {
                return optional
            } else {
                throw error
            }
        }
    }
}

extension Future where T: OptionalType {
    
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

/// Create a new reservation if one doesn't already exist belonging to that user
func create(_ req: Request) throws -> Future<Reservation> {
    return try req.content.decode(Reservation.self).flatMap(to: Reservation.self) { reservation in
        return try Reservation
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
    public static func doesUserExist(named user: String, on connectable: DatabaseConnectable) throws -> Future<Bool> {
        return try query(on: connectable)
            .filter(\Reservation.user == user)
            .first()
            .map(to: Bool.self) { (user) in
                return user != nil
            }
    }
}


