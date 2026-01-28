//
//  ProcessManager.swift
//  PortWatch
//
//  Handles process termination
//

import Foundation

actor ProcessManager {
    static let shared = ProcessManager()
    
    private init() {}
    
    func killProcess(pid: Int) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/kill")
        process.arguments = ["-9", String(pid)]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let status = process.terminationStatus
        if status != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ProcessError.killFailed(error)
        }
    }
    
    func killProcesses(pids: [Int]) async -> [(pid: Int, success: Bool, error: String?)] {
        var results: [(pid: Int, success: Bool, error: String?)] = []
        
        for pid in pids {
            do {
                try await killProcess(pid: pid)
                results.append((pid, true, nil))
            } catch {
                results.append((pid, false, error.localizedDescription))
            }
        }
        
        return results
    }
}

enum ProcessError: Error, LocalizedError {
    case killFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .killFailed(let message):
            return "Failed to kill process: \(message)"
        }
    }
}
