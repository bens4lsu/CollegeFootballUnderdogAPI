//
//  File 2.swift
//  
//
//  Created by Ben Schultz on 11/14/21.
//

import Foundation
import Vapor


enum SpreadError: Error {
    case numberNotFactorOfPoint5
}

struct SpreadValue: Content {
    private var whole: Int
    private var hook: Bool
    
    var points: Double {
        return Double(whole) + (hook ? 0.5 : 0.0)
    }
    
    init(_ val: Double) throws {
        guard (val * 10.0).truncatingRemainder(dividingBy: 5.0) == 0 else {
            throw SpreadError.numberNotFactorOfPoint5
        }
        self.whole = Int(floor(val))
        self.hook = Int((val * 10.0).truncatingRemainder(dividingBy: 10.0)) == 5
    }
}

enum Spread: Content {
    case homeTeamFavored(SpreadValue)
    case awayTeamFavored(SpreadValue)
    case pick
    
    var points: Double {
        switch self {
        case .homeTeamFavored(let sv):
            return sv.points
        case .awayTeamFavored(let sv):
            return sv.points
        case .pick:
            return 0
        }
    }
}


