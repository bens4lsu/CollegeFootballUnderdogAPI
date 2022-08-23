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

final class Game: Model, Content {
    typealias IDValue = Int
    
    static var schema = "DGames2"
    
    @ID(custom: "idDGames")
    var id: Int?
    
    @Field(key: "idDWeeks")
    var week: Int
    
    @Field(key: "idDFootballTeamsAway")
    var awayTeamId: Int
    
    @Field(key: "idDFootballTeamsHome")
    var homeTeamId: Int
    
    @Field(key: "Kickoff")
    var kickoff: Date
    
    @Field(key: "ScoreHome")
    var homeTeamScore: Int?
    
    @Field(key: "ScoreAway")
    var awayTeamScore: Int?

    private enum CodingKeys: String, CodingKey {
        case id = "idDFootballTeams",
             teamName = "TeamName",
             teamUrl = "TeamUrl",
             fbsFlag = "FBSFlag"
    }
    
    required init() {
        
    }
    
    init(week: Int, awayTeamId: Int, homeTeamId: Int, kickoff: Date) {
        self.week = week
        self.awayTeamId = awayTeamId
        self.homeTeamId = homeTeamId
        self.kickoff = kickoff
    }
}

