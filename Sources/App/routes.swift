import Fluent
import Vapor
import Foundation

func routes(_ app: Application, _ appConfig: AppConfig) throws {
    app.get { req in
        return "It works!"
    }

    

    app.get("getLines") { req async throws-> Response in
        var response: GameMatcher.GameMatcherResponseAll
        do {
            struct PoolUserEntryContent: Content {
                var poolUserEntryId: String?
            }
            
            let lines = try await LineParser(appConfig).parse(req)

            let week = try await currentWeek(req)

            var gameMatcherResponse = try await GameMatcher().load(req, appConfig: appConfig, lines: lines, week: week)
            if let poolUserParamContent = try? req.query.decode(PoolUserEntryContent.self),
               let poolUserParamStr = poolUserParamContent.poolUserEntryId,
               let poolUserParam = Int(poolUserParamStr)
            {
                gameMatcherResponse = try await gameMatcherResponse.exceptPickFor(req, user: poolUserParam, week: week)
            }
            response = gameMatcherResponse
        }
        catch(let e) {
            let message = Logger.Message(stringLiteral: e.localizedDescription) 
            app.logger.error(message)
            response = GameMatcher.GameMatcherResponseAll(games: [], teamNameMatchErrors: [], error: e.localizedDescription)
        }
        return try await response.encodeResponse(for: req)
    }
    
    app.get("testLines") { req async throws -> Response in
        try await LineParser(appConfig).parse(req).encodeResponse(for: req)
    }
    
//    app.get("getLines", ":poolUserIEntryd") { req async throws -> Response in
//        print ("here")
//        guard let poolUserParam = req.parameters.get("poolUserEntryId"),
//            let poolUserId = Int(poolUserParam)
//        else {
//            throw Abort(.badRequest, reason: "invalid request vecotor unless poolUserId parameter is provided")
//        }
//        let lines = try await LineParser(appConfig).parseVI2022(req)
//        let week = try await currentWeek(req)
//        let gameMatcherResponse = try await GameMatcher().load(req, appConfig: appConfig, lines: lines, week: week)
//                                                         .exceptPickFor(req, user: poolUserId, week: week)
//        return try await gameMatcherResponse.encodeResponse(for: req)
//    }
    
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
