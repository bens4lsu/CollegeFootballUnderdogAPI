//
//  File.swift
//  
//
//  Created by Ben Schultz on 10/9/22.
//

import Foundation
import Vapor
import Fluent
import FluentMySQLDriver

final class FlattenedPick: Model, Content {
    typealias IDValue = Int
    
    static var schema = "vwAllPicks"
    
    @ID(custom: "idDPicks")
    var id: Int?
    
    @Field(key: "idPoolUsers")
    var poolUserId: Int
    
    @Field(key: "idPoolUserEntries")
    var poolUserEntryId: Int
    
    @Field(key: "idDWeeks")
    var weekId: Int
    
    @Field(key: "idDGames")
    var gameId: Int
    
    @Field(key: "idPools")
    var poolId: Int
    
    @Field(key: "IdPoolSubtypes")
    var awayTeamScore: Int
    
    @Field(key: "WeekName")
    var weekName: String
    
    @Field(key: "PoolSubtypeDescription")
    var poolSubtypeDescription: String
    
    @Field(key: "idDFootballTeamsFav")
    var favoredTeamId: String
    
    @Field(key: "idDFootballTeamsDog")
    var underdogTeamId: String
    
    @Field(key: "Favorite")
    var favoredTeam: String
    
    @Field(key: "Underdog")
    var underdogTeam: String
    
    @Field(key: "Spread")
    var spread: Float
    
    @Field(key: "ScoreHome")
    var scoreHome: Int?
    
    @Field(key: "ScoreAway")
    var scoreAway: Int?
    
    @Field(key: "Kickoff")
    var kickoff: Date
    
    @Field(key: "Name")
    var name: String
    
    @Field(key: "AwayTeam")
    var awayTeam: String
    
    @Field(key: "HomeTeam")
    var homeTeam: String
    
    @Field(key: "TeamPicked")
    var teamPicked: String
    
    @Field(key: "PointsEarned")
    var pointsEarned: Float
    
    @Field(key: "Winners")
    var winner: Bool
    
    @Field(key: "IsBonusPick")
    var bonusPick: Bool
    
    
    //    private enum CodingKeys: String, CodingKey {
    //        case id = "idDPicks",
    //             teamName = "TeamName",
    //             teamUrl = "TeamUrl",
    //             fbsFlag = "FBSFlag"
    //    }
    
    required init() {
        
    }
}
