import Vapor
import FluentMySQL
import Foundation

extension MySQLDatabaseConfig {
    /// Initialize MySQLDatabase with a DB URL
    public init?(_ databaseURL: String) {
        guard let url = URL(string: databaseURL),
            url.scheme == "mysql",
            url.pathComponents.count == 2,
            let hostname = url.host,
            let username = url.user
            else {return nil}
        
        let password = url.password
        let database = url.pathComponents[1]
        self.init(hostname: hostname, username: username, password: password, database: database)
    }

}

/// Called before your application initializes.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    services.register(EngineServerConfig.default())
    
    try services.register(FluentMySQLProvider())

    var databaseConfig = DatabaseConfig()
    var db: MySQLDatabase

    if let databaseURL = ProcessInfo.processInfo.environment["CLEARDB_DATABASE_URL"],
        let databaseConfig = MySQLDatabaseConfig(databaseURL) {
        db = MySQLDatabase(config: databaseConfig)
    } else {
        let (username, password, host, database) = ("root", "pass", "localhost", "bathroom")

        let dbConfig = MySQLDatabaseConfig(hostname: host, port: 3306, username: username, password: password, database: database)
        db = MySQLDatabase(config: dbConfig)
    }

    databaseConfig.add(database: db, as: .mysql)
    databaseConfig.enableLogging(on: .mysql)
    services.register(databaseConfig)
    
    var migrationConfig = MigrationConfig()
    migrationConfig.add(model: BathroomSession.self, database: .mysql)
    migrationConfig.add(model: Reservation.self, database: .mysql)
    services.register(migrationConfig)
}
