import Routing
import Vapor
import Foundation
import HTTP
import FluentSQLite
/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
final class Routes: RouteCollection {
    /// Use this to create any services you may
    /// need for your routes.
    let app: Application
    
    var bathroomOccupied = false {
        didSet {
            if oldValue == true {
                currentSession.length = Date().timeIntervalSince1970 - currentSession.date.timeIntervalSince1970
                app.withConnection(to: .sqlite) { (db) -> Future<BathroomSession> in
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
    func boot(router: Router) throws {
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
            return req.withConnection(to: .sqlite) { (db: SQLiteConnection) in
                return try db
                    .query(BathroomSession.self)
                    .sort(\BathroomSession.length, QuerySortDirection.descending)
                    .first()
                    .map(to: BathroomSession.self) { (session) in
                        guard let session = session else {
                            throw Abort(.notFound, reason: "Could not find parking.")
                        }
                        
                        return session
                }
            }
        }
    }
}
