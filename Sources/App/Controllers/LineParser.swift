//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/13/21.
//

import Foundation
import Vapor
import SwiftSoup

enum LineParseError: Error {
    case expectedChildNotPresent
}


class LineParser {
    
    struct OnlineSpread: Codable, Content {
        var date: Date
        var awayTeamString: String
        var homeTeamString: String
        var spreadValue: Double
    }
    
    private let appConfig: AppConfig
    private let weekdays = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    private let calendar = Calendar(identifier: .gregorian)
    
    private var dateFormatterDateOnly: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    private var dateFormatterDateTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd H:mm Z"
        return formatter
    }
    
    private var dateFormatterShortDateOnPage: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }

    init(_ appConfig: AppConfig) async throws {
        self.appConfig = appConfig
    }
    
    private func dataFromSource(_ req: Request) async throws -> String {
        let uri = URI(string: appConfig.linesUrl)
        let headers = HTTPHeaders([("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0")])
        let response = try await req.client.get(uri, headers: headers).get()
        
        guard var body = response.body,
              let returnString = body.readString(length: body.readableBytes)
        else {
            throw Abort (.internalServerError, reason: "Unable to read response from \(appConfig.linesUrl)")
        }
        return returnString
    }
    
    
    func parseVI2022(_ req: Request) async throws -> [LineParser.OnlineSpread] {
        let sourceData = try await dataFromSource(req)
        guard let doc = try? SwiftSoup.parse(sourceData) else {
            throw Abort (.internalServerError, reason: "Unable to parse document at \(appConfig.linesUrl)")
        }

        guard let elements = try? doc.select("div.odds-slider-all") else {
            throw Abort(.internalServerError, reason: "Did not find \"div.elements\" in document at \(appConfig.linesUrl)")
        }
        
        var lines = [OnlineSpread]()
        // don't sart at 0.  Line 0 is just headings.
        for i in 1..<elements.count {
            let gameInfoElement = try elements[i].firstChild()
            let date = try gameInfoElement.firstChild().ownText()
            let away = try gameInfoElement.secondChild().firstChild().firstChild().firstChild().select("span").text()
            let home = try gameInfoElement.secondChild().firstChild().secondChild().firstChild().select("span").text()
            let spreadText = try elements[i].select(".odds-box")[1].firstChild().text()
            let spreadValue = Double(spreadText)
            let countDateParts = date.components(separatedBy: " ").count
            print ("\(date)  \(away)  \(home)  \(spreadText)")
            if spreadValue != nil && date != "Live" && date != "Final" && countDateParts > 2 {
                try lines.append(OnlineSpread(date: onlineDateToDate(req, date), awayTeamString: away, homeTeamString: home, spreadValue: spreadValue!))
            }
        }
        return lines
    }
    
    private func onlineDateToDate(_ req: Request, _ dt: String) throws -> Date {
        let comps = dt.components(separatedBy: " ")
        guard let firstWord = comps.first else {
            throw Abort(.internalServerError, reason: "Error converting date in the game data to an actual date.")
        }
        
        var date: Date
        if weekdays.contains(firstWord) || firstWord == "Today" || firstWord == "Tomorrow" {
            date = try dateFromWord(req, firstWord)
        }
        else {
            var year = calendar.component(.year, from: Date())
            if calendar.component(.month, from: Date()) == 1 {
                year += 1
            }
            
            guard let dateFromPage = dateFormatterShortDateOnPage.date(from: comps[0] + " " + comps[1] + ", " + String(year)) else {
                throw Abort (.internalServerError, reason: "Error converting \(comps[0] + " " + comps[1]) to date.")
            }
            date = dateFromPage
        }
        
        var time: String
        guard comps.count == 4 || comps.count == 5 else {
            throw Abort(.internalServerError, reason: "Could not parse time from \(String(describing: dt))")
        }
        if comps.count == 4 {
            time = try timeTo24(hm: comps[1], ap: comps[2])
        }
        else  {
            time = try timeTo24(hm: comps[2], ap: comps[3])
        }
        
    
        let datetimeString = dateFormatterDateOnly.string(from: date) + " " + time + " " + timezoneString()
        //print ("\(datetimeString) \(dateFormatterDateTime.date(from: datetimeString))")
        guard let finalDt = dateFormatterDateTime.date(from: datetimeString) else {
            throw Abort(.internalServerError, reason: "Could not translate \"\(datetimeString)\" into a datetime")
        }
        return finalDt
    }
    
    
    private func dateFromWord(_ req: Request, _ targetDay: String) throws -> Date {
        if targetDay == "Today" {
            return Date()
        }
        else if targetDay == "Tomorrow" {
	    return Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        }
        
        let weekDayIndexToday = calendar.component(.weekday, from: Date())
        guard let weekDayIndexTarget = weekdays.firstIndex(of: targetDay) else {
            throw Abort (.internalServerError, reason: "Date of \(targetDay) can not be parsed.")
        }
        var daysInFuture = weekDayIndexTarget - weekDayIndexToday
        if daysInFuture <= 0 {
            daysInFuture += 7
        }
        return Calendar.current.date(byAdding: .day, value: daysInFuture, to: Date())!
    }
    
    private func timeTo24 (hm: String, ap: String) throws -> String {
        // had to do this because the DateFormatter named dateFormatterDateTime will not work with AM/PM
        
        let hmParts = hm.components(separatedBy: ":")
        guard hmParts.count == 2 else {
            throw Abort(.internalServerError, reason: "Error parsing \(hm) into hour and minute pieces.")
        }
        var hour = Int(hmParts[0]) ?? 0
        if ap == "PM" && hour != 12 {
            hour += 12
        }
        return String(hour) + ":" + hmParts[1]
    }
    
    private func timezoneString() -> String {
        let tz = TimeZone.current
        if tz.isDaylightSavingTime() {
            return appConfig.dstOffset
        }
        return appConfig.stOffset
    }
    
    
}

