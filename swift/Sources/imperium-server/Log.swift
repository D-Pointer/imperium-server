
import Foundation

class Log {

    private static let log = Log()

    //
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        return formatter
    }()

    public static func debug(_ message: String, file: String=#file, function: String=#function) {
        Log.log.doLog(message: message, level: "debug", file: file, function: function)
    }

    public static func info(_ message: String, file: String=#file, function: String=#function) {
        Log.log.doLog(message: message, level: "info ", file: file, function: function)
    }

    public static func warn(_ message: String, file: String=#file, function: String=#function) {
        Log.log.doLog(message: message, level: "warn ", file: file, function: function)
    }

    public static func error(_ message: String, file: String=#file, function: String=#function) {
        Log.log.doLog(message: message, level: "error", file: file, function: function)
    }

    private init() {

    }

    private func doLog(message: String, level: String, file: String, function: String) {
        let date = dateFormatter.string(from: Date())
        var lastFile = String(file.split(separator: "/").last ?? "invalid")
        if let pointPos = lastFile.index(of: ".") {
            lastFile = String(lastFile[lastFile.startIndex..<pointPos])
        }

        var cleanFunction = function
        if let parenPos = function.index(of: "(") {
            cleanFunction = String(function[function.startIndex..<parenPos])
        }

        print( "\(date) \(level) \(lastFile).\(cleanFunction): \(message)" )
    }
}

