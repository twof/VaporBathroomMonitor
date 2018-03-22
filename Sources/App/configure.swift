import Vapor
import FluentMySQL
import Foundation

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
    
    try services.register(EngineServerConfig.detect())
    
    try services.register(FluentMySQLProvider())

    var databaseConfig = DatabaseConfig()
    var db: MySQLDatabase
    let dbConfig: MySQLDatabaseConfig

//    if let databaseURL = ProcessInfo.processInfo.environment["DATABASE_URL"],
//        let databaseConfig = MySQLDatabaseConfig(
//        let database = MySQLDatabase(config: databaseURL) {
//        db = database
//    } else {
    let (username, password, host, database) = ("root", "pass", "localhost", "bathroom")

    dbConfig = MySQLDatabaseConfig(hostname: host, port: 3306, username: username, password: password, database: database)
    db = MySQLDatabase(config: dbConfig)
//    }

    databaseConfig.add(database: db, as: .mysql)
    services.register(databaseConfig)
    
    var migrationConfig = MigrationConfig()
    migrationConfig.add(model: BathroomSession.self, database: .mysql)
    migrationConfig.add(model: Reservation.self, database: .mysql)
    services.register(migrationConfig)
}
