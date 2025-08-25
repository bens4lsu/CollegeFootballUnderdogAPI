//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/14/21.
//

import Foundation
import Vapor


enum LineFavorite: Character, Codable {
    case h = "H", a = "A"
}

final class Line: Content, @unchecked Sendable {

    var homeTeam: Team
    var awayTeam: Team
    var kickoff: Date
    var spread: Spread
    var favorite: LineFavorite
    var gameId: Int?
    
    var description: String {
        """
        Home Team: \(homeTeam.teamName)
        Away Team: \(awayTeam.teamName)
        Kickoff: \(kickoff)
        Spread: \(spread)
        Favorite: \(favorite)
        ID: \(gameId?.description ?? "")
        
        """
    }
    
    init(homeTeam: Team, awayTeam: Team, kickoff: Date, spread: Spread, favorite: LineFavorite) {
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.kickoff = kickoff
        self.favorite = favorite
        self.spread = spread
    }
}
