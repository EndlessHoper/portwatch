//
//  AppController.swift
//  PortWatch
//
//  Shared app state and background refresh
//

import Foundation
import Observation

@MainActor
final class AppController {
    static let shared = AppController()

    let settings: AppSettings
    let viewModel: ProcessViewModel

    private var refreshTask: Task<Void, Never>?

    private init() {
        let settings = AppSettings()
        self.settings = settings
        self.viewModel = ProcessViewModel(settings: settings)
    }

    func start() {
        viewModel.refresh()
        startAutoRefresh()
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()

        refreshTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                if self.settings.autoRefreshEnabled {
                    await self.viewModel.refreshNow()
                    MenuBarManager.shared.updateBadge(count: self.viewModel.totalProcessCount, emoji: self.settings.headerEmoji)
                    let seconds = max(1, self.settings.refreshIntervalSeconds)
                    try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                } else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
    }
}
