# Caloryn

Caloryn is a native iOS calorie and macro tracking app built with SwiftUI and SwiftData. It focuses on fast daily logging, profile-based calorie targets, Open Food Facts search, barcode lookup, and lightweight history/export flows.

## Stack

- SwiftUI for the app UI and navigation
- SwiftData for local persistence
- CloudKit-backed SwiftData sync when iCloud sync is enabled
- Open Food Facts for product search, nutrition data, and barcode lookup
- Xcode project-based setup with no external package dependencies

## Features

- Onboarding flow for profile setup, activity level, and macro ratio selection
- Automatic BMR, TDEE, calorie target, and macro target calculation
- Day-based food logging with breakfast, lunch, dinner, and multiple snack groups
- Food search and barcode scanning backed by Open Food Facts
- Custom foods stored locally in SwiftData
- Daily calorie ring, macro progress, optional Nutri-Score summary, and history view
- CSV export of logged food entries
- Theme preference and optional iCloud sync toggle

## Project Structure

```text
Caloryn/
  Models/        SwiftData models and domain types
  Services/      Nutrition logic, food search, CSV export
  Views/         Onboarding, today, history, food log, settings
  Theme/         App theme, glass styles, appearance helpers
  Extensions/    Date and formatting helpers
  Assets.xcassets/
Caloryn.xcodeproj/
```

## Data Model

The app persists three main SwiftData models:

- `UserProfile`: user demographics, activity level, calorie target, and macro targets
- `FoodItem`: reusable food definitions, including barcode, serving info, and nutrition per 100g
- `FoodLogEntry`: logged portions for a specific date and meal slot, with nutrition values denormalized at write time

## How It Works

- App entry starts in [`Caloryn/CalorynApp.swift`](/Users/vaggelis_kara/coding-projects/bitelog/Caloryn/CalorynApp.swift), where the SwiftData `ModelContainer` is configured.
- On first launch, users complete onboarding; afterwards the app opens into the main tab flow in [`Caloryn/ContentView.swift`](/Users/vaggelis_kara/coding-projects/bitelog/Caloryn/ContentView.swift).
- Daily logging lives in [`Caloryn/Views/Today/TodayView.swift`](/Users/vaggelis_kara/coding-projects/bitelog/Caloryn/Views/Today/TodayView.swift).
- Food lookup is handled by [`Caloryn/Services/FoodSearchService.swift`](/Users/vaggelis_kara/coding-projects/bitelog/Caloryn/Services/FoodSearchService.swift), which queries Open Food Facts search and barcode endpoints.
- Goal calculation is centralized in [`Caloryn/Services/NutritionCalculator.swift`](/Users/vaggelis_kara/coding-projects/bitelog/Caloryn/Services/NutritionCalculator.swift).

## Running The App

1. Open [`Caloryn.xcodeproj`](/Users/vaggelis_kara/coding-projects/bitelog/Caloryn.xcodeproj/project.pbxproj) in Xcode.
2. Select the `Caloryn` scheme.
3. Run on an iOS Simulator or device.

Current project settings in the checked-in Xcode project:

- iOS deployment target: `26.0`
- Swift version: `5.0`
- Bundle identifier: `www.caloryn`

## Notes

- The app uses network calls to Open Food Facts, so search and barcode lookup require connectivity.
- SwiftData sync is configured to use CloudKit when the `iCloudSyncEnabled` preference is on.
- CSV export writes a temporary file and presents the native iOS share sheet.
