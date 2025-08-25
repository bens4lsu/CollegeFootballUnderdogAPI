//
//  File.swift
//  CollegeFootballUnderdogAPI
//
//  Created by Ben Schultz on 8/24/25.
//

import Foundation
import Vapor
import Fluent
import FluentMySQLDriver

final class GameSavedSpread: Model, Content, @unchecked Sendable {
    typealias IDValue = Int
    
    static var schema = "DGamesSavedSpreads"
    
    @ID(custom: "idDGames")
    var id: Int?
    
    @Field(key: "Spread")
    var spread: Double
    
    @Field(key: "WhoFavored")
    var whoFavored: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "idDGames",
             spread = "Spread",
             whoFavored = "WhoFavored"
    }
    
    required init() {
        
    }
    
    init(id: Int, spread: Double, whoFavored: String) {
        self.id = id
        self.spread = spread
        self.whoFavored = whoFavored
    }
}
