//
//  ProcessViewModel.swift
//  PortWatch
//
//  View model for managing process state
//

import SwiftUI
import Observation

@MainActor
@Observable
class ProcessViewModel {
    var processes: [ProcessInfo] = []
    var isLoading = false
    var sortOption: SortOption = .port
    var errorMessage: String?

    let settings: AppSettings
    
    private var refreshTask: Task<Void, Never>?
    
    init(settings: AppSettings) {
        self.settings = settings
    }

    var totalProcessCount: Int {
        visibleProcesses.count
    }
    
    var projectGroups: [ProjectGroup] {
        let sorted = sortedProcesses
        let grouped = Dictionary(grouping: sorted) { $0.workingDirectory }
        
        return grouped.map { directory, processes in
            ProjectGroup(
                directory: directory,
                directoryName: URL(fileURLWithPath: directory).lastPathComponent,
                processes: processes
            )
        }.sorted { $0.directoryName < $1.directoryName }
    }
    
    private var sortedProcesses: [ProcessInfo] {
        let filtered = visibleProcesses

        switch sortOption {
        case .port:
            return filtered.sorted {
                let port0 = $0.ports.first ?? 0
                let port1 = $1.ports.first ?? 0
                return port0 < port1
            }
        case .name:
            return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .project:
            return filtered.sorted { $0.workingDirectory < $1.workingDirectory }
        case .usage:
            return filtered.sorted {
                let usage0 = $0.cpuUsage + $0.memoryPercent
                let usage1 = $1.cpuUsage + $1.memoryPercent
                return usage0 > usage1
            }
        case .time:
            return filtered.sorted {
                guard let time0 = $0.startTime, let time1 = $1.startTime else {
                    return $0.startTime != nil
                }
                return time0 < time1
            }
        }
    }

    private var visibleProcesses: [ProcessInfo] {
        processes.filter { process in
            if !settings.showPortWatchProcess && isPortWatchProcess(process) {
                return false
            }
            if !settings.showSystemRootDirectory && process.workingDirectory == "/" {
                return false
            }
            if settings.isIgnored(process) {
                return false
            }
            return true
        }
    }
    
    func refresh() {
        refreshTask?.cancel()

        refreshTask = Task {
            await refreshNow()
        }
    }

    func refreshNow() async {
        if isLoading {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            processes = try await ProcessScanner.shared.scan()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func killProcess(pid: Int) {
        Task {
            do {
                try await ProcessManager.shared.killProcess(pid: pid)
                // Remove from list
                processes.removeAll { $0.pid == pid }
            } catch {
                errorMessage = "Failed to kill process: \(error.localizedDescription)"
            }
        }
    }
    
    func killAllProcesses() {
        Task {
            let pids = visibleProcesses.map { $0.pid }
            let results = await ProcessManager.shared.killProcesses(pids: pids)
            
            // Remove successful kills from list
            let successfulPids = results.filter { $0.success }.map { $0.pid }
            processes.removeAll { successfulPids.contains($0.pid) }
            
            // Show errors if any
            let errors = results.filter { !$0.success }
            if !errors.isEmpty {
                errorMessage = "Failed to kill \(errors.count) process(es)"
            }
        }
    }

    private func isPortWatchProcess(_ process: ProcessInfo) -> Bool {
        if process.name == "PortWatch" {
            return true
        }
        return process.command.localizedCaseInsensitiveContains("PortWatch")
    }
}

@MainActor
@Observable
class AppSettings {
    var showSystemRootDirectory = false
    var showPortWatchProcess = false
    var cpuMediumThreshold = 10.0
    var cpuHighThreshold = 50.0
    var memoryMediumThreshold = 15.0  // percentage
    var memoryHighThreshold = 25.0   // percentage
    var autoRefreshEnabled = true
    var refreshIntervalSeconds = 5.0
    var headerEmoji = "⚓"
    var hasAskedAboutLoginItem = false
    var launchAtLogin = false
    var ignoredProcessKeys: Set<String> = []
    
    static let availableEmojis = ["⚓", "🚢", "⛵", "🔥", "🚀", "⚡", "🎯", "📡", "🔌", "🌐"]
    
    func isIgnored(_ process: ProcessInfo) -> Bool {
        ignoredProcessKeys.contains(ignoreKey(for: process))
    }
    
    func toggleIgnore(_ process: ProcessInfo) {
        let key = ignoreKey(for: process)
        if ignoredProcessKeys.contains(key) {
            ignoredProcessKeys.remove(key)
        } else {
            ignoredProcessKeys.insert(key)
        }
    }
    
    func ignoreKey(for process: ProcessInfo) -> String {
        let port = process.ports.first.map { ":\($0)" } ?? ""
        if process.framework != .unknown {
            return "\(process.name) (\(process.framework.rawValue))\(port)"
        }
        return "\(process.name)\(port)"
    }
}
