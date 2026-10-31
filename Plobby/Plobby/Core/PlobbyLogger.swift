//
//  PlobbyLogger.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import Foundation
import OSLog

nonisolated enum LogLevel {
    
    /// - network: 네트워크 정보
    /// - debug: 디버깅
    /// - error: 오류
    
    case network
    case debug
    case error
    
    var category: String {
        switch self {
        case .network: "Network"
        case .debug: "Debug"
        case .error: "Error"
        }
    }
    
    var label: String {
        switch self {
        case .network: "🛜 Network"
        case .debug: "🐛 Debug"
        case .error: "❌ Error"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .network: .default
        case .debug: .debug
        case .error: .error
        }
    }
    
    var shouldShowInRelease: Bool {
        switch self {
        case .error: true
        default: false
        }
    }
}

nonisolated enum PlobbyLogger {
    
    private static let subsystem = Bundle.main.bundleIdentifier!
    
    private static func shouldShowLog(level: LogLevel) -> Bool {
        #if DEBUG
        true
        #else
        level.shouldShowInRelease
        #endif
    }
    
    private static func log(
        level: LogLevel,
        message: Any,
        file: String,
        function: String
    ) {
        guard shouldShowLog(level: level) else { return }
        
        let logger = Logger(subsystem: subsystem, category: level.category)
        let fileName = (file as NSString).lastPathComponent
        
        logger.log(
            level: level.osLogType,
            "[\(level.label)] [\(fileName) -> \(function)]: \(String(describing: message))"
        )
    }
    
    static func network(
        _ message: Any,
        file: String = #fileID,
        function: String = #function
    ) {
        log(
            level: .network,
            message: message,
            file: file,
            function: function
        )
    }
    
    static func debug(
        _ message: Any,
        file: String = #fileID,
        function: String = #function
    ) {
        log(
            level: .debug,
            message: message,
            file: file,
            function: function
        )
    }
    
    static func error(
        _ error: Error,
        file: String = #fileID,
        function: String = #function
    ) {
        log(
            level: .error,
            message: error.localizedDescription,
            file: file,
            function: function
        )
    }
}
