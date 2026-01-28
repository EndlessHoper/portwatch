//
//  ProcessInfo.swift
//  PortWatch
//
//  Data models for process information
//

import Foundation

struct ProcessInfo: Identifiable, Equatable {
    let id = UUID()
    let pid: Int
    let name: String
    let command: String
    let ports: [Int]
    let workingDirectory: String
    let framework: Framework
    let cpuUsage: Double      // percentage
    let memoryPercent: Double  // percentage
    let memoryMB: Double       // for display
    let startTime: Date?
    let startDescription: String?
    
    var displayName: String {
        if framework != .unknown {
            return "\(name) (\(framework.rawValue))"
        }
        return name
    }
    
    var directoryName: String {
        URL(fileURLWithPath: workingDirectory).lastPathComponent
    }
    
    var resourceStatus: ResourceStatus {
        .low
    }
}

enum Framework: String, CaseIterable {
    case vite = "Vite"
    case astro = "Astro"
    case nextjs = "Next.js"
    case webpack = "Webpack"
    case fastapi = "FastAPI"
    case flask = "Flask"
    case django = "Django"
    case spring = "Spring"
    case rails = "Rails"
    case llamaCpp = "llama.cpp"
    case docker = "Docker"
    case postgres = "Postgres"
    case redis = "Redis"
    case mongodb = "MongoDB"
    case unknown = "Unknown"
}

enum ResourceStatus {
    case high, medium, low
    
    var color: String {
        switch self {
        case .high: return "🔴"
        case .medium: return "🟡"
        case .low: return "🟢"
        }
    }
}

struct ProjectGroup: Identifiable {
    let id = UUID()
    let directory: String
    let directoryName: String
    let processes: [ProcessInfo]
}

enum SortOption: String, CaseIterable {
    case port = "Port"
    case name = "Name"
    case project = "Project"
    case usage = "Usage"
    case time = "Time"
}
