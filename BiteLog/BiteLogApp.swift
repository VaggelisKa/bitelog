import SwiftUI
import SwiftData

@main
struct BiteLogApp: App {
    let sharedModelContainer: ModelContainer

    init() {
        let iCloudEnabled = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true
        let schema = Schema([
            UserProfile.self,
            FoodItem.self,
            FoodLogEntry.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: iCloudEnabled ? .automatic : .none
        )

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
