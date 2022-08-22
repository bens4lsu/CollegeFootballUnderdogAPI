//
//  File.swift
//  
//
//  Created by Ben Schultz on 8/21/22.
//

import Foundation
import SwiftSoup

extension Element {
    func firstChild() throws -> Element{
        guard self.children().count >= 1 else {
            throw LineParseError.expectedChildNotPresent
        }
        return self.children()[0]
    }
    
    func secondChild() throws -> Element{
        guard self.children().count >= 2 else {
            throw LineParseError.expectedChildNotPresent
        }
        return self.children()[1]
    }
}
