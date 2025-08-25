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

final class PoolMessage: Model, Content, @unchecked Sendable {
    typealias IDValue = Int
    
    static var schema = "PoolMessages"
    
    @ID(custom: "idPoolMessages")
    var id: Int?
    
    @Field(key: "idPools")
    var poolId: Int
    
    @Field(key: "ParentIDPoolMessages")
    var parentPoolMessageId: Int
    
    @Field(key: "Message")
    var message: String
    
    @Field(key: "EnteredById")
    var enteredBy: Int
    
    @Field(key: "EntryTime")
    var entryTime: Date
    
    @Field(key: "EmailComplete")
    var emailComplete: Bool

//    private enum CodingKeys: String, CodingKey {
//        case id = "idDFootballTeams",
//             teamName = "TeamName",
//             teamUrl = "TeamUrl",
//             fbsFlag = "FBSFlag"
//    }
    
    required init() {
        
    }
    
    init(poolId: Int, parentPoolMessageId: Int, message: String, enteredBy: Int) {
        self.poolId = poolId
        self.parentPoolMessageId = parentPoolMessageId
        self.message = message
        self.enteredBy = enteredBy
        self.entryTime = Date()
        self.emailComplete = false
    }
}
