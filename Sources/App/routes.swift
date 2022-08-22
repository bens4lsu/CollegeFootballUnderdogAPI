import Fluent
import Vapor
import Foundation

func routes(_ app: Application, _ appConfig: AppConfig) throws {
    app.get { req in
        return "It works!"
    }

    app.get("getLines") { req async throws -> Response in
        let lines = try await LineParser(appConfig)
        return try await lines.parseVI2022(req)
    }

    app.get("test") { req async throws -> HTTPResponseStatus in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd H:mm"
        guard let result = formatter.date(from: "2022-08-27 18:32") else {
            throw Abort(.internalServerError, reason: "could not convert string to date.")
        }
        return HTTPResponseStatus.ok
    }
}
