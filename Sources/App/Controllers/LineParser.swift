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
        formatter.dateFormat = "yyyy-MM-dd H:mm"
        formatter.timeZone = TimeZone(abbreviation: "EST")
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
        var logger = req.application.logger
        logger.logLevel = appConfig.loggerLogLevel
        let sourceData = try await dataFromSource(req)
        guard let doc = try? SwiftSoup.parse(sourceData) else {
            throw Abort (.internalServerError, reason: "Unable to parse document at \(appConfig.linesUrl)")
        }

        guard let elements = try? doc.select("div.odds-slider-all"),
              elements.count > 0
        else {
            throw Abort(.internalServerError, reason: "Did not find \"div.odds-slider-all\" in document at \(appConfig.linesUrl)")
        }
        
        var lines = [OnlineSpread]()
        // don't sart at 0.  Line 0 is just headings.
        
        let gameInfoElementParse: (Element?) -> Element? = { e in
            self.loggedDOMParse(element: e, pattern: nil, logger: logger, instance: 0)
        }
        
        let dateParse: (Element) -> String? = { e in
            self.loggedDOMParse(element: e, pattern: ".py-2", logger: logger, instance: 0)
        }
        
        let awayParse: (Element) -> String? = { e in
            self.loggedDOMParse(element: e, pattern: ".my-auto", logger: logger, instance: 0)
        }
        
        let homeParse: (Element) -> String? = { e in
            self.loggedDOMParse(element: e, pattern: ".my-auto", logger: logger, instance: 1)
        }
        
        let spreadTextParse: (Element) -> String? = { e in
            let elem: Element? = self.loggedDOMParse(element: e, pattern: ".odds-box", logger: logger, instance: 1)
            
            return self.loggedDOMParse(element: elem, pattern: ".pt-2", logger: logger, instance: 0)
        }
        
        
        for i in 1..<elements.count {
            if let gameInfoElement = gameInfoElementParse(elements[i]),
               let date = dateParse(gameInfoElement),
               let away = awayParse(gameInfoElement),
               let home = homeParse(gameInfoElement),
               let spreadText = spreadTextParse(gameInfoElement),
               let spreadValue = Double(spreadText)
            {
                let countDateParts = date.components(separatedBy: " ").count
                logger.debug("\(date)  \(away)  \(home)  \(spreadText)")
                if date != "Live" && date != "Final" && countDateParts > 2 {
                    try lines.append(OnlineSpread(date: onlineDateToDate(req, date), awayTeamString: away, homeTeamString: home, spreadValue: spreadValue))
                }
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
        
    
        let datetimeString = dateFormatterDateOnly.string(from: date) + " " + time
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
    
    private func loggedDOMParse(element: Element?, pattern: String?, description: String? = nil, logger: Logger, instance: Int) -> Element? {
        
        var elems : Elements?
        if let pattern {
            elems = try? element?.select(pattern)
        }
        else if element != nil {
            var array = [Element]()
            array.append(element!)
            elems = Elements(array)
        }
            
        guard let div = elems else {
            logger.trace("\(description ?? "") parse error -- \(pattern ?? "<<no pattern>>") not found")
            return nil
        }
        guard div.count > 0 else {
            logger.trace("\(description ?? "") parse error -- \(pattern ?? "<<no pattern>>") not found (with count \(div.count)")
            return nil
        }
        if div.count < instance + 1 {
            logger.trace("\(description ?? "") parse error -- < \(instance) instances of \(pattern ?? "<<no pattern>>") found.")
            return nil
        }
        logger.trace("\(description ?? "") parse successful")
        return div[instance]
    }
    
    private func loggedDOMParse(element: Element?, pattern: String, description: String? = nil, logger: Logger, instance: Int) -> String? {
        let elem: Element? = loggedDOMParse(element: element, pattern: pattern, logger: logger, instance: instance)
        let str = try? elem?.text()
        let logEntry = str == nil ? "\(description ?? "") text not found" : "\(description ?? ""): \(str!)"
        logger.trace(Logger.Message(stringLiteral: logEntry))
        return str
    }
}

//extension Element {
//    func firstChild() throws -> Element {
//        guard self.children().count >= 1 else {
//            throw LineParseError.expectedChildNotPresent
//        }
//        return self.children()[0]
//    }
//    
//    func secondChild() throws -> Element{
//        guard self.children().count >= 2 else {
//            throw LineParseError.expectedChildNotPresent
//        }
//        return self.children()[1]
//    }
//}


