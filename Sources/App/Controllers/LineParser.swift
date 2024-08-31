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
    
//    private var dateFormatterDateOnly: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        return formatter
//    }
//    
//    private var dateFormatterDateTime: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd H:mm"
//        formatter.timeZone = TimeZone(abbreviation: "EST")
//        return formatter
//    }
//    
//    private var dateFormatterShortDateOnPage: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMM dd, yyyy"
//        return formatter
//    }
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    private var nextYear: Int {
        currentYear + 1
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
    
    
    func parse(_ req: Request) async throws -> [LineParser.OnlineSpread] {
        var logger = req.application.logger
        logger.logLevel = appConfig.loggerLogLevel
        let sourceData = try await dataFromSource(req)
        guard let doc = try? SwiftSoup.parse(sourceData) else {
            throw Abort (.internalServerError, reason: "Unable to parse document at \(appConfig.linesUrl)")
        }

        if logger.logLevel == .trace {
            if let html = try? doc.outerHtml() {
                logger.trace("\(html)")
            }
        }
        
        guard let elements = try? doc.select("table.sportsbook-table tr:nth-child(1), table.sportsbook-table tr.break-line"),
        //guard let elements = try? doc.select("table.sportsbook-table tr.break-line"),
              elements.count > 0
        else {
            throw Abort(.internalServerError, reason: "Did not find \"table.sportsbook-table tr:nth-child(2), table.sportsbook-table tr.break-line\" in document at \(appConfig.linesUrl)")
        }
        
        logger.debug("\(elements.count) elements")
                
        var lines = [OnlineSpread]()
        
        let gameInfoElementParse: (Element?) -> Element? = { e in
            //self.loggedDOMParse(element: e, pattern: nil, instance: 0, logger: logger)
            e
        }
        
        let dateParse: (Element) -> String? = { e in
            let datePart: String? = self.loggedDOMParse(element: e.parent()?.parent(), pattern: "div.sportsbook-table-header__title > span > span", instance: 0, logger: logger)
            let timePart: String? = self.loggedDOMParse(element: e, pattern: "span.event-cell__start-time", instance: 0, logger: logger)
                return "\(datePart ?? "nil") \(timePart ?? "nil")"
        }
        
        let awayParse: (Element) -> String? = { e in
            self.loggedDOMParse(element: e, pattern: "th.sportsbook-table__column-row:first-child div.event-cell__name-text", instance: 0, logger: logger)
        }
        
        let homeParse: (Element) -> String? = { e in
            try? self.loggedDOMParse(element: e.nextElementSibling(), pattern: "th.sportsbook-table__column-row:first-child div.event-cell__name-text", instance: 0, logger: logger)
        }
        
        let spreadTextParse: (Element) -> String? = { e in
            // looking for away team's number, negative or positive
            self.loggedDOMParse(element: e, pattern: "span.sportsbook-outcome-cell__line", instance: 0, logger: logger)
        }

        for i in 0..<(elements.count) {
            if let gameInfoElement = gameInfoElementParse(elements[i]),
               let stringDate = dateParse(gameInfoElement),
               let dateDate = try onlineDateToDate(stringDate, logger),
               let away = awayParse(gameInfoElement),
               let home = homeParse(gameInfoElement),
               let spreadText = spreadTextParse(gameInfoElement),
               let spreadValue = Double(spreadText)
            {
                logger.trace("\(stringDate) \(dateDate) \(away)  \(home)  \(spreadText)")
                lines.append(OnlineSpread(date: dateDate, awayTeamString: away, homeTeamString: home, spreadValue: spreadValue))
            }
        }
        logger.debug("\(lines.count) succesfully parsed.")
        return lines
    }
    

    private func onlineDateToDate(_ dt: String, _ logger: Logger) throws -> Date? {
        var dt = dt
        logger.trace ("Starting date conversion of \(dt)")
        
        let comps = dt.components(separatedBy: " ")
        guard let firstWord = comps.first,
              let lastWord = comps.last
        else {
            throw Abort(.internalServerError, reason: "Error converting date in the game data to an actual date.")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        
        dateFormatter.dateFormat = "EEE MMM dd'TH'"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        
        if firstWord == "Today" {
            dt = dateFormatter.string(from: Date()) + " " + lastWord
        }
        
        if firstWord == "Tomorrow" {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            dt = dateFormatter.string(from: tomorrow ?? Date()) + " " + lastWord
        }
        
            
        dateFormatter.dateFormat = "EEE MMM dd'TH' h:mma"
            
        var attemptedDate = dateFormatter.date(from:dt)
        if attemptedDate == nil {
            dateFormatter.dateFormat = "EEE MMM dd'ND' h:mma"
            attemptedDate = dateFormatter.date(from:dt)
        }
        if attemptedDate == nil {
            dateFormatter.dateFormat = "EEE MMM dd'ST' h:mma"
            attemptedDate = dateFormatter.date(from:dt)
        }
        
        guard let date = attemptedDate else {
            logger.error("Date conversion failed \(dt)")
            return nil
        }
        var dateComponets = calendar.dateComponents([.month, .day, .year, .hour, .minute, .timeZone], from: date)
        var theYear = currentYear
        if [1, 2].contains(dateComponets.month) {
            theYear = nextYear
        }
        dateComponets.year = theYear
        let finalDate = calendar.date(from: dateComponets)
        logger.trace("Date val: \(String(describing: finalDate)) --> \(dateComponets.debugDescription)")
        return finalDate
    }
    
    
//    private func onlineDateToDate(_ req: Request, _ dt: String) throws -> Date {
//        let comps = dt.components(separatedBy: " ")
//        guard let firstWord = comps.first else {
//            throw Abort(.internalServerError, reason: "Error converting date in the game data to an actual date.")
//        }
//
//        var date: Date
//        if weekdays.contains(firstWord) || firstWord == "Today" || firstWord == "Tomorrow" {
//            date = try dateFromWord(req, firstWord)
//        }
//        else {
//            var year = calendar.component(.year, from: Date())
//            if calendar.component(.month, from: Date()) == 1 {
//                year += 1
//            }
//
//            guard let dateFromPage = dateFormatterShortDateOnPage.date(from: comps[0] + " " + comps[1] + ", " + String(year)) else {
//                throw Abort (.internalServerError, reason: "Error converting \(comps[0] + " " + comps[1]) to date.")
//            }
//            date = dateFromPage
//        }
//
//        var time: String
//        guard comps.count == 4 || comps.count == 5 else {
//            throw Abort(.internalServerError, reason: "Could not parse time from \(String(describing: dt))")
//        }
//        if comps.count == 4 {
//            time = try timeTo24(hm: comps[1], ap: comps[2])
//        }
//        else  {
//            time = try timeTo24(hm: comps[2], ap: comps[3])
//        }
//
//
//        let datetimeString = dateFormatterDateOnly.string(from: date) + " " + time
//        //print ("\(datetimeString) \(dateFormatterDateTime.date(from: datetimeString))")
//        guard let finalDt = dateFormatterDateTime.date(from: datetimeString) else {
//            throw Abort(.internalServerError, reason: "Could not translate \"\(datetimeString)\" into a datetime")
//        }
//        return finalDt
//    }
    
    
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
    
    private func loggedDOMParse(element: Element?, pattern: String?, instance: Int, description: String? = nil, logger: Logger) -> Element? {
        
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
        guard div.count > instance else {
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
    
    private func loggedDOMParse(element: Element?, pattern: String?, instance: Int, description: String? = nil, logger: Logger) -> String? {
        let elem: Element? = loggedDOMParse(element: element, pattern: pattern, instance: instance, logger: logger)
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


