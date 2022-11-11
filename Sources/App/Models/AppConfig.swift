//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/13/21.
//

import Foundation
import Vapor
import NIOSSL

final class AppConfig: Codable {
    
    struct Database: Codable {
        let hostname: String
        let port: Int
        let username: String
        let password: String
        let database: String
        let certificateVerificationString: String
    }

    
    let linesUrl: String
    let listenOnPort: Int
    let database: AppConfig.Database
    let logLevel: String

    var certificateVerification: CertificateVerification {
        if database.certificateVerificationString == "noHostnameVerification" {
            return .noHostnameVerification
        }
        else if database.certificateVerificationString == "fullVerification" {
            return .fullVerification
        }
        return .none
    }
    
    var loggerLogLevel: Logger.Level {
        Logger.Level(rawValue: logLevel) ?? .error
    }

    init() {
    
        do {
            let path = DirectoryConfiguration.detect().resourcesDirectory
            let url = URL(fileURLWithPath: path).appendingPathComponent("Config.json")
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(Self.self, from: data)
            
            self.linesUrl = decoded.linesUrl
            self.listenOnPort = decoded.listenOnPort
            self.database = decoded.database
            self.logLevel = decoded.logLevel
        }
        catch {
            print ("Could not initialize app from Config.json.  Initilizing with hard-coded default values. \n \(error)")
            exit(0)
        }
    }
}
