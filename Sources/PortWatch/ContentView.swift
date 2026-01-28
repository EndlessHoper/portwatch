//
//  ContentView.swift
//  PortWatch
//
//  Main UI for the menu bar app
//

import SwiftUI

struct ContentView: View {
    @State private var settings: AppSettings
    @State private var viewModel: ProcessViewModel
    @State private var showingKillAllConfirmation = false
    @State private var showingLoginItemPrompt = false
    @State private var activeSheet: ActiveSheet?
    @State private var collapsedGroups: Set<String> = []
    
    init() {
        let controller = AppController.shared
        _settings = State(initialValue: controller.settings)
        _viewModel = State(initialValue: controller.viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            if let errorMessage = viewModel.errorMessage {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                Divider()
            } else {
                Divider()
            }
            
            // Sort controls
            sortControlsView
            
            Divider()
            
            // Process list
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else if viewModel.projectGroups.isEmpty {
                emptyStateView
            } else {
                processListView
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Kill All Processes?", isPresented: $showingKillAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Kill All", role: .destructive) {
                viewModel.killAllProcesses()
            }
        } message: {
            Text("This will terminate \(viewModel.totalProcessCount) processes. This action cannot be undone.")
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .preferences:
                PreferencesView(settings: settings)
            }
        }
        .onAppear {
            MenuBarManager.shared.updateBadge(count: viewModel.totalProcessCount, emoji: settings.headerEmoji)
            if !settings.hasAskedAboutLoginItem {
                showingLoginItemPrompt = true
            }
        }
        .onChange(of: settings.headerEmoji) { _, newEmoji in
            MenuBarManager.shared.updateBadge(count: viewModel.totalProcessCount, emoji: newEmoji)
        }
        .alert("Start at Login?", isPresented: $showingLoginItemPrompt) {
            Button("Yes") {
                LoginItemManager.shared.setEnabled(true)
                settings.launchAtLogin = true
                settings.hasAskedAboutLoginItem = true
            }
            Button("No", role: .cancel) {
                settings.hasAskedAboutLoginItem = true
            }
        } message: {
            Text("Would you like PortWatch to start automatically when you log in? You can change this later in Preferences.")
        }
        .onChange(of: viewModel.totalProcessCount) { _, newValue in
            MenuBarManager.shared.updateBadge(count: newValue, emoji: settings.headerEmoji)
        }
    }
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 4) {
                Text(settings.headerEmoji)
                    .font(.title2)
                Text("\(viewModel.totalProcessCount) Active Server\(viewModel.totalProcessCount == 1 ? "" : "s")")
                    .font(.headline)
            }
            
            Spacer()
            
            Button(action: { activeSheet = .preferences }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var sortControlsView: some View {
        HStack {
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: { viewModel.sortOption = option }) {
                        HStack {
                            Text(option.rawValue)
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Sort:")
                    Text(viewModel.sortOption.rawValue)
                        .frame(minWidth: 60, alignment: .leading)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            Spacer()
            
            Button(action: { viewModel.refresh() }) {
                Image(systemName: viewModel.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Active Servers")
                .font(.headline)
            Text("Your development environment is clean")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private var sortedGroups: [ProjectGroup] {
        viewModel.projectGroups.sorted { a, b in
            let aCollapsed = collapsedGroups.contains(a.directory)
            let bCollapsed = collapsedGroups.contains(b.directory)
            if aCollapsed != bCollapsed {
                return !aCollapsed
            }
            return a.directoryName < b.directoryName
        }
    }
    
    private var processListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sortedGroups) { group in
                    ProjectGroupView(
                        group: group,
                        settings: settings,
                        isCollapsed: collapsedGroups.contains(group.directory),
                        onToggleCollapse: {
                            if collapsedGroups.contains(group.directory) {
                                collapsedGroups.remove(group.directory)
                            } else {
                                collapsedGroups.insert(group.directory)
                            }
                        },
                        onKill: { pid in
                            viewModel.killProcess(pid: pid)
                        },
                        onIgnore: { process in
                            settings.toggleIgnore(process)
                        }
                    )
                }
            }
        }
    }
    
    private var footerView: some View {
        HStack {
            Button(role: .destructive) {
                showingKillAllConfirmation = true
            } label: {
                Text("Kill All")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .disabled(viewModel.totalProcessCount == 0)
            .buttonStyle(.borderedProminent)
            .tint(.red)
            
            Spacer()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct ProjectGroupView: View {
    let group: ProjectGroup
    let settings: AppSettings
    let isCollapsed: Bool
    let onToggleCollapse: () -> Void
    let onKill: (Int) -> Void
    let onIgnore: (ProcessInfo) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggleCollapse) {
                HStack {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(group.directoryName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(group.processes.count) process\(group.processes.count == 1 ? "" : "es")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 6)
            
            if !isCollapsed {
                ForEach(group.processes) { process in
                    ProcessRowView(process: process, settings: settings, onKill: onKill, onIgnore: onIgnore)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ProcessRowView: View {
    let process: ProcessInfo
    let settings: AppSettings
    let onKill: (Int) -> Void
    let onIgnore: (ProcessInfo) -> Void
    @State private var showingConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(resourceStatus(for: process).color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(process.displayName)
                        .font(.system(size: 12, weight: .medium))
                    
                    Text(":\(process.ports.map(String.init).joined(separator: ", "))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 8) {
                    Text("CPU: \(process.cpuUsage, format: .number.precision(.fractionLength(1)))%")
                    Text("MEM: \(process.memoryMB, format: .number.precision(.fractionLength(0)))MB")
                    if let startTime = process.startTime {
                        Text(formatUptime(startTime))
                    } else {
                        Text("Unknown")
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                onIgnore(process)
            } label: {
                Image(systemName: "eye.slash")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Hide this process")
            
            Button(role: .destructive) {
                showingConfirmation = true
            } label: {
                Text("Kill")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderless)
            .tint(.red)
        }
        .alert("Kill Process?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Kill", role: .destructive) {
                onKill(process.pid)
            }
        } message: {
            Text("Terminate \(process.displayName) (PID: \(process.pid))?")
        }
    }
    
    private func formatUptime(_ startDate: Date) -> String {
        let interval = max(0, Date().timeIntervalSince(startDate))

        if interval < 60 {
            return "<1m"
        }

        if interval < 3600 {
            let minutes = Int((interval / 60).rounded())
            return "\(minutes)m"
        }

        if interval < 86400 {
            let hours = Int((interval / 3600).rounded())
            return "\(max(1, hours))h"
        }

        let days = Int(interval / 86400)
        let remaining = interval - Double(days * 86400)
        var hours = Int((remaining / 3600).rounded())

        if hours == 24 {
            hours = 0
        }

        if hours == 0 {
            return "\(days)d"
        }

        return "\(days)d \(hours)h"
    }

    private func resourceStatus(for process: ProcessInfo) -> ResourceStatus {
        if process.cpuUsage >= settings.cpuHighThreshold || process.memoryPercent >= settings.memoryHighThreshold {
            return .high
        }
        if process.cpuUsage >= settings.cpuMediumThreshold || process.memoryPercent >= settings.memoryMediumThreshold {
            return .medium
        }
        return .low
    }
}

enum ActiveSheet: Identifiable {
    case preferences

    var id: String {
        switch self {
        case .preferences: return "preferences"
        }
    }
}

#Preview {
    ContentView()
}
