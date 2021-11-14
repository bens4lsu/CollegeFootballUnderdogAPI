//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/13/21.
//

import Foundation
import Vapor

final class AppConfig: Codable {
    var espnLinesUrl: String
    
    init() {
    
        do {
            let path = DirectoryConfiguration.detect().resourcesDirectory
            let url = URL(fileURLWithPath: path).appendingPathComponent("Config.json")
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(Self.self, from: data)
            
            self.espnLinesUrl = decoded.espnLinesUrl
        }
        catch {
            print ("Could not initialize app from Config.json.  Initilizing with hard-coded default values. \n \(error)")
            exit(0)
        }
    }
}
