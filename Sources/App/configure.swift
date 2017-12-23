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
    // configure your application here
    
    print(ProcessInfo().environment["DB_MYSQL_BATHROOMDB"])
    let directoryConfig = DirectoryConfig.default()
    services.instance(directoryConfig)
    
    try services.provider(FluentProvider())
    
    services.instance(FluentMySQLConfig())
    
    var databaseConfig = DatabaseConfig()
    
    let username = "root"
    let password = "pass"
    let database = "bathroom"
    
    let db = MySQLDatabase(hostname: "localhost", user: username, password: password, database: database)
    databaseConfig.add(database: db, as: .mysql)
    services.instance(databaseConfig)
    
    var migrationConfig = MigrationConfig()
    migrationConfig.add(model: BathroomSession.self, database: .mysql)
    services.instance(migrationConfig)
}

extension DatabaseIdentifier {
    static var mysql: DatabaseIdentifier<MySQLDatabase> {
        return .init("mysql")
    }
}
