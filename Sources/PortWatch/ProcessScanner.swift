//
//  ProcessScanner.swift
//  PortWatch
//
//  Scans for listening processes using lsof and ps
//

import Foundation

actor ProcessScanner {
    static let shared = ProcessScanner()
    
    private init() {}
    
    func scan() async throws -> [ProcessInfo] {
        // Step 1: Get all listening TCP processes (system-wide)
        let lsofOutput = try await runCommand(
            "/usr/sbin/lsof",
            arguments: ["-iTCP", "-sTCP:LISTEN", "-P", "-n"]
        )
        
        // Parse lsof output to get PID -> ports mapping
        var pidToPorts: [Int: Set<Int>] = [:]
        var pidToName: [Int: String] = [:]
        
        for line in lsofOutput.components(separatedBy: .newlines) {
            let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard components.count >= 9 else { continue }
            
            // lsof format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
            guard let pid = Int(components[1]) else { continue }
            let name = components[0]
            
            // Extract port from tokens (e.g., "*:8080" or "127.0.0.1:5173")
            if let port = extractPort(from: components) {
                pidToPorts[pid, default: []].insert(port)
            }
            
            pidToName[pid] = name
        }
        
        // Step 2: Get detailed info for each PID
        var processes: [ProcessInfo] = []
        
        for pid in pidToPorts.keys {
            guard let ports = pidToPorts[pid],
                  let name = pidToName[pid] else { continue }
            
            // Get working directory
            let workingDir = try? await getWorkingDirectory(pid: pid)
            
            // Get command and resource usage
            let details = try? await getProcessDetails(pid: pid)
            
            let processInfo = ProcessInfo(
                pid: pid,
                name: name,
                command: details?.command ?? name,
                ports: Array(ports).sorted(),
                workingDirectory: workingDir ?? "Unknown",
                framework: FrameworkDetector.detect(from: details?.command ?? ""),
                cpuUsage: details?.cpu ?? 0,
                memoryPercent: details?.memPercent ?? 0,
                memoryMB: details?.memMB ?? 0,
                startTime: details?.startTime,
                startDescription: details?.startDescription
            )
            
            processes.append(processInfo)
        }
        
        return processes
    }
    
    private func getWorkingDirectory(pid: Int) async throws -> String? {
        let output = try await runCommand("/usr/sbin/lsof", arguments: ["-p", String(pid)])
        
        for line in output.components(separatedBy: .newlines) {
            if line.contains("cwd") {
                let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                // Find the path (usually after "DIR" or similar)
                if let pathIndex = components.firstIndex(where: { $0.hasPrefix("/") }) {
                    return components[pathIndex]
                }
            }
        }
        
        // Fallback to ps
        let psOutput = try await runCommand("/bin/ps", arguments: ["-o", "cwd=", "-p", String(pid)])
        let trimmed = psOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "/" {
            return nil
        }
        return trimmed
    }
    
    private func getProcessDetails(pid: Int) async throws -> (command: String, cpu: Double, memPercent: Double, memMB: Double, startTime: Date?, startDescription: String?)? {
        // Get command, CPU, memory %, RSS, and start time
        let output = try await runCommand("/bin/ps", arguments: [
            "-o", "command=,%cpu=,%mem=,rss=,start=",
            "-p", String(pid)
        ])
        
        let components = output.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard components.count >= 5 else { return nil }
        
        // Parse from the end since command can have spaces
        let startStr = components[components.count - 1]
        let rssStr = components[components.count - 2]
        let memStr = components[components.count - 3]
        let cpuStr = components[components.count - 4]
        let command = components[0..<components.count - 4].joined(separator: " ")
        
        guard let cpu = Double(cpuStr),
              let memPercent = Double(memStr),
              let rssKB = Int(rssStr) else {
            return nil
        }
        
        let memoryMB = Double(rssKB) / 1024
        
        // Parse start time
        let startTime = parseStartTime(startStr)
        let startDescription = startTime == nil ? startStr : nil
        
        return (command, cpu, memPercent, memoryMB, startTime, startDescription)
    }
    
    private func extractPort(from components: [String]) -> Int? {
        // Handle formats like "*:8080", "127.0.0.1:5173", "[::]:3000", "localhost:8000"
        for token in components.reversed() {
            if let port = extractPort(fromToken: token) {
                return port
            }
        }
        return nil
    }
    
    private func extractPort(fromToken token: String) -> Int? {
        guard let colonIndex = token.lastIndex(of: ":") else { return nil }
        let portString = String(token[token.index(after: colonIndex)...]).trimmingCharacters(in: CharacterSet(charactersIn: ")"))
        guard let port = Int(portString) else { return nil }
        return port
    }
    
    private func parseStartTime(_ startStr: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let todayTime = formatter.date(from: startStr) {
            // Combine with today's date
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.year, .month, .day], from: now)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: todayTime)
            
            var combined = DateComponents()
            combined.year = components.year
            combined.month = components.month
            combined.day = components.day
            combined.hour = timeComponents.hour
            combined.minute = timeComponents.minute
            
            return calendar.date(from: combined)
        }
        
        // Try date format
        formatter.dateFormat = "MMM dd"
        return formatter.date(from: startStr)
    }
    
    private func runCommand(_ path: String, arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""
        
        guard process.terminationStatus == 0 else {
            throw ScannerError.commandFailed(stderr.isEmpty ? stdout : stderr)
        }
        
        return stdout
    }

}

enum ScannerError: Error {
    case noUser
    case decodingFailed
    case commandFailed(String)
}
