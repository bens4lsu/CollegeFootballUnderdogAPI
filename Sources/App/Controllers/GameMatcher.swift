//
//  File.swift
//  
//
//  Created by Ben Schultz on 8/22/22.
//

import Foundation
import Vapor
import Fluent
import FluentMySQLDriver

class GameMatcher {
    
    static var teamList = [Team]()
    
    struct GameMatcherResponse: Codable, Content {
        var gameId: Int
        var homeTeam: String
        var awayTeam: String
        var kickoff: String
        var spread: Double
        var whoFavored: String
        
        init(gameId: Int, homeTeam: String, awayTeam: String, kickoff: Date, spread: Double) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d  |  HH:mm"
            formatter.timeZone = TimeZone(abbreviation: timezoneString())
            
            self.gameId = gameId
            self.homeTeam = homeTeam
            self.awayTeam = awayTeam
            self.spread = abs(spread)
            self.whoFavored = spread < 0 ? "A" : "H"
            self.kickoff = formatter.string(from: kickoff) + " Central Time"
            
            func timezoneString() -> String {
                let tz = TimeZone.current
                if tz.isDaylightSavingTime() {
                    return "CDT"
                }
                return "CST"
            }
        }
    }
    
    
    struct GameMatcherResponseAll: Codable, Content {
        var games: [GameMatcherResponse]
        var teamNameMatchErrors: [String]
        var error: String?
        
        func exceptPickFor(_ req: Request, user: Int, week: Week) async throws -> GameMatcherResponseAll {
            let pickCollection = try await PickCollection().picksFor(req, weekId: week.id, poolUserEntryId: user)
            let filterGames = pickCollection.compactMap{ $0.gameId }
            let games = self.games.filter { !filterGames.contains($0.gameId) }
            return GameMatcherResponseAll (games: games, teamNameMatchErrors: self.teamNameMatchErrors)
        }
    }

    
    func load(_ req: Request, appConfig: AppConfig, lines: [LineParser.OnlineSpread], week: Week) async throws -> GameMatcherResponseAll {
        
        if Self.teamList.isEmpty {
            Self.teamList = try await Team.query(on: req.db).all()
        }
                        
        //let allTeamNames = teamList.map{$0.teamName}
        var findTeamErrors = [String]()
        var gamesThisWeek = [GameMatcherResponse]()
        for line in lines {
            let homeTeam = matchTeam(teamName: line.homeTeamString)
            let awayTeam = matchTeam(teamName: line.awayTeamString)
            if homeTeam == nil {
                findTeamErrors.append(line.homeTeamString)
            }
            if awayTeam == nil {
                findTeamErrors.append(line.awayTeamString)
            }
            
            if homeTeam != nil && awayTeam != nil && line.date > Date() {
                let game = try await findGameWith(req, homeTeam: homeTeam!, awayTeam: awayTeam!, weekId: week.id!)
                if game != nil {
                    let gmr = GameMatcherResponse(gameId: game!.id!, homeTeam: line.homeTeamString, awayTeam: line.awayTeamString, kickoff: line.date, spread: line.spreadValue)
                    gamesThisWeek.append(gmr)
                }
                else {  //create new agame
                    //print ("home: \(homeTeam!.teamName)   away: \(awayTeam!.teamName)")
                    let newGame = Game(week: week.id!, awayTeamId: awayTeam!.id!, homeTeamId: homeTeam!.id!, kickoff: line.date)
                    try await newGame.save(on: req.db)
                    let gmr = GameMatcherResponse(gameId: newGame.id!, homeTeam: line.homeTeamString, awayTeam: line.awayTeamString, kickoff: line.date, spread: line.spreadValue)
                    gamesThisWeek.append(gmr)
                }
            }
        }
        
        return GameMatcherResponseAll(games: gamesThisWeek, teamNameMatchErrors: findTeamErrors.sorted())
    }
    
    private func matchTeam(teamName searchName: String) -> Team? {
        return Self.teamList.filter { team in
            team.teamName == searchName
        }.first
    }
    
    private func findGameWith(_ req: Request, homeTeam: Team, awayTeam: Team, weekId: Int) async throws -> Game? {
        try await Game.query(on: req.db).filter(\.$homeTeamId == homeTeam.id!)
                                        .filter(\.$awayTeamId == awayTeam.id!)
                                        .filter(\.$week == weekId)
                                        .first()
    }
    
    

}
