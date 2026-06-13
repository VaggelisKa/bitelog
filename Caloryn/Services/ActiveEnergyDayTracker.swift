import Foundation
@preconcurrency import HealthKit
import Observation

@MainActor
@Observable
final class ActiveEnergyDayTracker {
    private(set) var activeEnergyKcal: Double = 0
    private(set) var isLoading = false
    private(set) var message: String?

    @ObservationIgnored private var activeEnergyObserver: HKObserverQuery?
    private var selectedDate: Date = Date().startOfDay
    private var isEnabled = false

    func configure(date: Date, isEnabled: Bool) async {
        let normalizedDate = date.startOfDay
        let dateChanged = !Calendar.current.isDate(normalizedDate, inSameDayAs: selectedDate)
        let enabledChanged = self.isEnabled != isEnabled

        selectedDate = normalizedDate
        self.isEnabled = isEnabled

        guard isEnabled else {
            stopObserving()
            reset()
            return
        }

        let observerNeedsStart = activeEnergyObserver == nil
        startObservingIfNeeded()

        if dateChanged || enabledChanged || observerNeedsStart {
            await refresh()
        }
    }

    func refreshWhenActive() {
        guard isEnabled else { return }
        startObservingIfNeeded()

        Task {
            await refresh()
        }
    }

    func stopObserving() {
        guard activeEnergyObserver != nil else { return }
        HealthKitService.stop(activeEnergyObserver)
        activeEnergyObserver = nil
    }

    private func refresh() async {
        guard isEnabled else {
            reset()
            return
        }

        guard AppleHealthAdjustmentSettings.isHealthAvailable else {
            AppleHealthAdjustmentSettings.disable(message: AppleHealthAdjustmentSettings.unavailableMessage)
            isEnabled = false
            activeEnergyKcal = 0
            message = AppleHealthAdjustmentSettings.unavailableMessage
            stopObserving()
            return
        }

        isLoading = true
        message = nil
        defer {
            isLoading = false
        }

        do {
            let kcal = try await HealthKitService.activeEnergyBurnedKcal(for: selectedDate)
            if activeEnergyKcal != kcal {
                activeEnergyKcal = kcal
            }
            message = nil
        } catch {
            AppleHealthAdjustmentSettings.disable(message: error.localizedDescription)
            isEnabled = false
            activeEnergyKcal = 0
            message = error.localizedDescription
            stopObserving()
        }
    }

    private func reset() {
        activeEnergyKcal = 0
        isLoading = false
        message = nil
    }

    private func startObservingIfNeeded() {
        guard activeEnergyObserver == nil, AppleHealthAdjustmentSettings.isHealthAvailable else { return }

        activeEnergyObserver = HealthKitService.observeActiveEnergyChanges { [weak self] in
            guard let self else { return }

            Task {
                await self.refresh()
            }
        }
    }
}
