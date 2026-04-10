import Foundation
import os
import SwiftUI

private let buddiLogger = os.Logger(subsystem: "com.splab.buddi", category: "App")

enum LogCategory: String {
    case lifecycle = "lifecycle"
    case memory = "memory"
    case performance = "performance"
    case ui = "ui"
    case network = "network"
    case error = "error"
    case warning = "warning"
    case success = "success"
    case debug = "debug"
}

struct Logger {
    static func log(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        switch category {
        case .error:
            buddiLogger.error("[\(fileName, privacy: .public):\(line, privacy: .public)] \(function, privacy: .public) - \(message, privacy: .private)")
        case .warning:
            buddiLogger.warning("[\(fileName, privacy: .public):\(line, privacy: .public)] \(function, privacy: .public) - \(message, privacy: .private)")
        default:
            buddiLogger.debug("[\(fileName, privacy: .public):\(line, privacy: .public)] \(function, privacy: .public) - \(message, privacy: .private)")
        }
    }
    
    static func trackMemory(
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            log(String(format: "Memory used: %.2f MB", usedMB),
                category: .memory,
                file: file,
                function: function,
                line: line)
        }
    }
}

extension View {
    func trackLifecycle(_ identifier: String) -> some View {
        self.modifier(ViewLifecycleTracker(identifier: identifier))
    }
}

struct ViewLifecycleTracker: ViewModifier {
    let identifier: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                Logger.log("\(identifier) appeared", category: .lifecycle)
                Logger.trackMemory()
            }
            .onDisappear {
                Logger.log("\(identifier) disappeared", category: .lifecycle)
                Logger.trackMemory()
            }
    }
} 