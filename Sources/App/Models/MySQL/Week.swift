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

final class Week: Model, Content {
    var id: Int?
    
    typealias IDValue = Int
    
    static var schema = "DWeeks"
    
    @Field(key: "idPoolSubtypes")
    var idPoolSubtypes: Int
    
    @ID(key: "idDWeeks")
    var idDWeeks: Int?
    
    @Field(key: "WeekName")
    var weekName: String
    
    @Field(key: "WeekDateStart")
    var weekDateStart: Date
    
    @Field(key: "WeekDateEnd")
    var weekDateEnd: Date

//    private enum CodingKeys: String, CodingKey {
//        case id = "idDFootballTeams",
//             teamName = "TeamName",
//             teamUrl = "TeamUrl",
//             fbsFlag = "FBSFlag"
//    }
    
    required init() {
        
    }
    

}

