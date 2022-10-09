import Fluent
import Vapor
import Foundation

func routes(_ app: Application, _ appConfig: AppConfig) throws {
    app.get { req in
        return "It works!"
    }

    

    app.get("getLines") { req async throws -> Response in
        let lines = try await LineParser(appConfig).parseVI2022(req)
        let week = try await currentWeek(req)
        let gameMatcherResponse = try await GameMatcher().load(req, appConfig: appConfig, lines: lines, week: week)
        return try await gameMatcherResponse.encodeResponse(for: req)
    }
    
    app.get("getLines", ":poolUserId") { req async throws -> Response in
        guard let poolUserParam = req.parameters.get("poolUserId"),
            let poolUserId = Int(poolUserParam)
        else {
            throw Abort(.badRequest, reason: "invalid request vecotor unless poolUserId parameter is provided")
        }
        let lines = try await LineParser(appConfig).parseVI2022(req)
        let week = try await currentWeek(req)
        let gameMatcherResponse = try await GameMatcher().load(req, appConfig: appConfig, lines: lines, week: week)
                                                         .exceptPickFor(req, user: poolUserId, week: week)
        return try await gameMatcherResponse.encodeResponse(for: req)
    }
    
    app.post("newMessage") { req async throws -> Response in
        struct NewMessagePost: Codable {
            var user: Int
            var message: String
            var messageParent: Int
            var poolId: Int
        }
        
        let newMessage = try req.content.decode(NewMessagePost.self)
        let poolMessage = PoolMessage(poolId: newMessage.poolId, parentPoolMessageId: newMessage.messageParent, message: newMessage.message, enteredBy: newMessage.user)
        try await poolMessage.save(on: req.db)
        return try await "ok".encodeResponse(for: req)
    }
    
    
    
    func currentWeek(_ req: Request) async throws -> Week {
        guard let week = try await Week.query(on: req.db)
                                        .filter(\.$weekDateStart < Date())
                                        .filter(\.$weekDateEnd >= Date())
                                        .sort(\.$weekDateEnd)
                                        .first()
        else {
            throw Abort(.internalServerError, reason: "No weeks configured that correspond to the current date.")
        }
        return week
    }

}
