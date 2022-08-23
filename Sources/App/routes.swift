import Fluent
import Vapor
import Foundation

func routes(_ app: Application, _ appConfig: AppConfig) throws {
    app.get { req in
        return "It works!"
    }

    

    app.get("getLines") { req async throws -> Response in
        let lines = try await LineParser(appConfig).parseVI2022(req)
        return try await GameMatcher().load(req, appConfig: appConfig, lines: lines)

    }

}
