//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/13/21.
//

import Foundation
import Vapor

class EspnLines {
    var lines: [Line]

    init(_ req: Request, _ appConfig: AppConfig) async throws {        
        let espnURL = URI(stringLiteral: appConfig.espnLinesUrl)
        let espnResponse = try await req.client.get(espnURL).get()
        
        self.lines = []
    }
    
    func value(_ req: Request) async throws -> Response {
        return try await lines.encodeResponse(for: req)
    }
}
