import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("getLines") { req async throws -> Response in
        let lines = try await EspnLines(req, AppConfig())
        return try await lines.value(req)
    }

    //try app.register(collection: TodoController())
}
