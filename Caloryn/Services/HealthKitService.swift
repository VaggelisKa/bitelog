import Foundation
@preconcurrency import HealthKit

enum HealthKitServiceError: LocalizedError {
    case unavailable
    case authorizationFailed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Apple Health is not available on this device."
        case .authorizationFailed:
            return "Apple Health permission was not completed."
        }
    }
}

@MainActor
enum HealthKitService {
    private static let store = HKHealthStore()
    private static let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

    static var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    static func requestActiveEnergyAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HealthKitServiceError.unavailable
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: [], read: [activeEnergyType]) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitServiceError.authorizationFailed)
                }
            }
        }
    }

    static func activeEnergyBurnedKcal(for date: Date, calendar: Calendar = .current) async throws -> Double {
        guard isHealthDataAvailable else {
            throw HealthKitServiceError.unavailable
        }

        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate, .strictEndDate])

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let quantity = statistics?.sumQuantity()
                let kcal = quantity?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: kcal)
            }

            store.execute(query)
        }
    }
}
