//
//  Logger.swift
//
//
//  Created by James Kim on 05/12/2018.
//  Copyright © 2018 DKI. All rights reserved.
//

/**
 로그 출력을 enum으로 관리하여 출력하도록 하는 클래스. class func을 이용하여 별도 생성없이 이용함
 - 아래 참조사이트에서 참고하여 교정함
 https://medium.com/@sauvik_dolui/developing-a-tiny-logger-in-swift-7221751628e6
 
 edit: 23/07/10 ejkim :
 */
import Foundation
import os

class Logger {
    
    enum  enumLogEventType: String{
        case Error  = "‼️ " // 오류발생시 출력
        case Info   = "ℹ️ " // 정보형 출력
        case Trace  = "💬 " // 일반 trace 로그
        case Hot    = "🔥 " // 중요한 로그를 확인할때 이용
        
    }
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
        return formatter
    }()
    
    class func log(_ message: String, logType: enumLogEventType = .Trace,
                   fileName: String = #file,
                   line: Int = #line,
                   funcName: String = #function) {
        
        #if DEBUG
        print("\(dateFormatter.string(from: Date())) \(logType.rawValue)[\(sourceFileName(filePath: fileName))]:\(line) \(funcName) -> \(message)")
        #endif
    }
    
    /// 디바이스 콘솔로그에서 출력 가능한 로그
    class func systemLog(_ message: String, logType: enumLogEventType = .Trace,
                         fileName: String = #file,
                         line: Int = #line,
                         funcName: String = #function) {

        os_log(logType.toOSLogType, "%@ %@[%@]:%@ %@ ->", dateFormatter.string(from: Date()), logType.rawValue, sourceFileName(filePath: fileName), line, funcName, message)
    }
    
    private class func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    
}

extension Logger.enumLogEventType {
    var toOSLogType: OSLogType {
        switch self {
        case .Error:
            return OSLogType.fault
        case .Info:
            return OSLogType.info
        case .Trace:
            return OSLogType.default
        case .Hot:
            return OSLogType.error
        }
    }
}
