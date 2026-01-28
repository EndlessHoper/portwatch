//
//  PreferencesView.swift
//  PortWatch
//
//  Preferences panel
//

import SwiftUI

struct PreferencesView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preferences")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // General
                    SectionView("General") {
                        Toggle("Launch at login", isOn: $settings.launchAtLogin)
                            .onChange(of: settings.launchAtLogin) { _, newValue in
                                LoginItemManager.shared.setEnabled(newValue)
                            }
                    }
                    
                    // Refresh
                    SectionView("Refresh") {
                        Toggle("Auto-refresh", isOn: $settings.autoRefreshEnabled)
                        
                        HStack {
                            Text("Interval")
                            Spacer()
                            Text("\(Int(settings.refreshIntervalSeconds))s")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Stepper("", value: $settings.refreshIntervalSeconds, in: 2...60, step: 1)
                                .labelsHidden()
                        }
                        .disabled(!settings.autoRefreshEnabled)
                        .opacity(settings.autoRefreshEnabled ? 1 : 0.5)
                    }
                    
                    // Appearance
                    SectionView("Appearance") {
                        Text("Menu bar icon")
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 5), spacing: 8) {
                            ForEach(AppSettings.availableEmojis, id: \.self) { emoji in
                                Button {
                                    settings.headerEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 36, height: 36)
                                        .background(settings.headerEmoji == emoji ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Visibility
                    SectionView("Visibility") {
                        Toggle("Show system / directory", isOn: $settings.showSystemRootDirectory)
                        Toggle("Show PortWatch process", isOn: $settings.showPortWatchProcess)
                        
                        if !settings.ignoredProcessKeys.isEmpty {
                            Divider()
                            Text("Hidden processes")
                                .foregroundStyle(.secondary)
                            ForEach(Array(settings.ignoredProcessKeys).sorted(), id: \.self) { name in
                                HStack {
                                    Text(name)
                                    Spacer()
                                    Button("Unhide") {
                                        settings.ignoredProcessKeys.remove(name)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                    
                    // Resource Thresholds
                    SectionView("Resource Thresholds") {
                        Text("CPU (%)")
                            .foregroundStyle(.secondary)
                        ThresholdRow(label: "Medium", value: $settings.cpuMediumThreshold, range: 1...90)
                        ThresholdRow(label: "High", value: $settings.cpuHighThreshold, range: 5...100)
                        
                        Divider()
                        
                        Text("Memory (%)")
                            .foregroundStyle(.secondary)
                        ThresholdRow(label: "Medium", value: $settings.memoryMediumThreshold, range: 1...50)
                        ThresholdRow(label: "High", value: $settings.memoryHighThreshold, range: 5...80)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 340, height: 520)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ThresholdRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: 60, alignment: .leading)
            Slider(value: $value, in: range, step: 1)
            Text("\(Int(value))")
                .monospacedDigit()
                .frame(width: 28, alignment: .trailing)
        }
    }
}

#Preview {
    PreferencesView(settings: AppSettings())
}
