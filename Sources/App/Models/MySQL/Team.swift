//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/14/21.
//

import Foundation
import Vapor
import Fluent
import FluentMySQLDriver

final class Team: Model, Content {
    typealias IDValue = Int
    
    static var schema = "DFootballTeams"
    
    @ID(custom: "idDFootballTeams")
    var id: Int?
    
    @Field(key: "TeamName")
    var teamName: String
    
    @Field(key: "TeamUrl")
    var teamUrl: String
    
    @Field(key: "FBSFlag")
    var fbsFlag: Bool

    private enum CodingKeys: String, CodingKey {
        case id = "idDFootballTeams",
             teamName = "TeamName",
             teamUrl = "TeamUrl",
             fbsFlag = "FBSFlag"
    }
    
    required init() {
        
    }
    

}
