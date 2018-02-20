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
    try services.register(EngineServerConfig.detect())
    try services.register(FluentMySQLProvider())
    
    var databaseConfig = DatabaseConfig()
    let db: MySQLDatabase   
    
    if let databaseURL = ProcessInfo.processInfo.environment["DATABASE_URL"],
        let database = MySQLDatabase(databaseURL: databaseURL) {
        db = database
    } else {
        let (username, password, host, database) = ("root", "pass", "localhost", "bathroom")
        db = MySQLDatabase(hostname: host, user: username, password: password, database: database)
    }

    databaseConfig.add(database: db, as: .mysql)
    services.register(databaseConfig)
    
    var migrationConfig = MigrationConfig()
    migrationConfig.add(model: BathroomSession.self, database: .mysql)
    migrationConfig.add(model: Reservation.self, database: .mysql)
    services.register(migrationConfig)
}

extension DatabaseIdentifier {
    static var mysql: DatabaseIdentifier<MySQLDatabase> {
        return .init("mysql")
    }
}
