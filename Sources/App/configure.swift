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
    let directoryConfig = DirectoryConfig.default()
    services.instance(directoryConfig)
    
    try services.provider(FluentProvider())
    
    services.instance(FluentMySQLConfig())
    
    var databaseConfig = DatabaseConfig()
    
    var (username, password, host, database) = ("root", "pass", "localhost", "bathroom")
    
    if let databaseURL = ProcessInfo().environment["DATABASE_URL"] {
        let tokens = databaseURL
            .replacingOccurrences(of: "mysql://", with: "")
            .replacingOccurrences(of: "?reconnect=true", with: "")
            .split { ["@", "/", ":"].contains(String($0)) }
        
        (username, password, host, database) = (String(tokens[0]), String(tokens[1]), String(tokens[2]), String(tokens[3]))
    }
    
    print(username, password, host, database)
    
    let db = MySQLDatabase(hostname: host, user: username, password: password, database: database)
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
