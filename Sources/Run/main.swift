import App
import Service
import Vapor
import Foundation

var config = Config.default()
var env = Environment.detect()
var services = Services.default()

private let commandLineKey = "--port="
var serverConfig: EngineServerConfig = EngineServerConfig()

for arg in CommandLine.arguments {
    if arg.hasPrefix(commandLineKey) {
        var string = arg
        string.removeFirst(commandLineKey.count)
        guard let port = UInt16(string) else {continue}
        serverConfig = EngineServerConfig(port: port)
    }
}

services.register { container in
    return serverConfig
}

try App.configure(&config, &env, &services)

let app = try Application(
    config: config,
    environment: env,
    services: services
)

try App.boot(app)

try app.run()



