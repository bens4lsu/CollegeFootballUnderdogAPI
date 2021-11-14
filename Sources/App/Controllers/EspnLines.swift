//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/13/21.
//

import Foundation
import Vapor

class EspnLines {
    var appConfig: AppConfig
    var lines: [Line]

    init(_ req: Request, _ appConfig: AppConfig) async throws {
        self.appConfig = appConfig
        
        let espnURL = URI(path: appConfig.espnLinesUrl)
        let espnResponse = try await req.client.get(espnURL)
        
        self.lines = []
    }
    
    func value(_ req: Request) async throws -> Response {
        return try await lines.encodeResponse(for: req)
    }
}
