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
    
//    print(ProcessInfo().environment["DB_MYSQL_BATHROOMDB"])
    let directoryConfig = DirectoryConfig.default()
    services.instance(directoryConfig)
    
    try services.provider(FluentProvider())
    
    services.instance(FluentMySQLConfig())
    
    var databaseConfig = DatabaseConfig()
    
    let username = "dbae11482d5c44"
    let password = "12e1b4f5006073fc"
    let database = "dbae11482d5c44"
    let port: UInt16 = 1514
    
    let db = MySQLDatabase(hostname: "database-test1.Ldy57S.db.eu.vapor.cloud", port: port, user: username, password: password, database: database)
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
