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

class PickCollection {
    
    func picksFor(_ req: Request, weekId: Int? = nil, poolUserId: Int? = nil, poolId: Int? = nil) async throws -> [FlattenedPick] {
        
        var picks = FlattenedPick.query(on: req.db)
        
        if let weekId = weekId {
            picks = picks.filter(\.$weekId == weekId)
        }
        
        if let poolUserId = poolUserId {
            picks = picks.filter(\.$poolUserId == poolUserId)
        }
        
        if let poolId = poolId {
            picks = picks.filter(\.$poolId == poolId)
        }
        
        return try await picks.all()
    }
}
