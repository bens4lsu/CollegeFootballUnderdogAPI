//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/14/21.
//

import Foundation
import Vapor

final class Line: Content {
    var id: Int
    var homeTeam: Team
    var awayTeam: Team
    var kickoff: Date
    var spread: Spread
    
    init(id: Int, homeTeam: Team, awayTeam: Team, kickoff: Date, spread: Spread) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.kickoff = kickoff
        self.spread = spread
    }
}
