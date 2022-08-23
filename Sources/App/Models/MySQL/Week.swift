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

    
    typealias IDValue = Int
    
    static var schema = "DWeeks"
    
    @Field(key: "idPoolSubtypes")
    var idPoolSubtypes: Int
    
    @ID(custom: "idDWeeks")
    var id: Int?
    
    @Field(key: "WeekName")
    var weekName: String
    
    @Field(key: "WeekDateStart")
    var weekDateStart: Date
    
    @Field(key: "WeekDateEnd")
    var weekDateEnd: Date

    private enum CodingKeys: String, CodingKey {
        case id = "idDWeeks",
             idPoolSubtypes = "idPoolSubtypes",
            weekName = "WeekName",
            weekDateStart = "WeekDateStart",
            weekDateEnd = "WeekDateEnd"
    }
    
    required init() {
        
    }
    

}

