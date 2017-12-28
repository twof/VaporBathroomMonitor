import App
import Dispatch
import XCTest
import Vapor
import HTTP

@available(OSX 10.11, *)
final class AppTests : XCTestCase {
    var config = Config.default()
    var env = Environment.detect()
    var services = Services.default()
    
    var app: Application!
    var client: Client!
    
    override func setUp() {
        super.setUp()
        CommandLine.arguments = [CommandLine.arguments[0]]
        
        do {
            app = try Application(config: config, environment: env, services: services)
            client = try app.make(Client.self)
            try App.boot(app)
            try app.run()
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testNothing() throws {
        XCTAssert(true)
    }
    
//    func testIsAvailable() throws {
//        client.get("http://localhost:8080/hello").flatMap(to: String.self) { (connectedClient) in
//            print(connectedClient.http)
//            return Future("hello")
//        }
//    }

    static let allTests = [
        ("testNothing", testNothing),
    ]
}
