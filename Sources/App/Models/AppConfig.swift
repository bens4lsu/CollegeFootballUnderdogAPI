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
    
    struct Smtp: Codable {
        var hostname: String
        var port: Int32
        var username: String
        var password: String
        var timeout: UInt
        var friendlyName: String
        var fromEmail: String
    }

    
    let linesUrl: String
    let listenOnPort: Int
    let dstOffset: String
    let stOffset: String
    let database: AppConfig.Database
    let smtp: AppConfig.Smtp
    
    var certificateVerification: CertificateVerification {
        if database.certificateVerificationString == "noHostnameVerification" {
            return .noHostnameVerification
        }
        else if database.certificateVerificationString == "fullVerification" {
            return .fullVerification
        }
        return .none
    }
    
    init() {
    
        do {
            let path = DirectoryConfiguration.detect().resourcesDirectory
            let url = URL(fileURLWithPath: path).appendingPathComponent("Config.json")
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(Self.self, from: data)
            
            self.linesUrl = decoded.linesUrl
            self.listenOnPort = decoded.listenOnPort
            self.dstOffset = decoded.dstOffset
            self.stOffset = decoded.stOffset
            self.database = decoded.database
            self.smtp = decoded.smtp
        }
        catch {
            print ("Could not initialize app from Config.json.  Initilizing with hard-coded default values. \n \(error)")
            exit(0)
        }
    }
}
