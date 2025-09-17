# RentTracker iOS App

A SwiftUI + MVVM iOS app to track rental properties, tenants, contracts, payments (including partial payments and late fees), expenses (maintenance), and yearly profit/loss with offline-first Core Data storage.

## Features
- Contract tracking with flexible cycles: monthly, bi-monthly, quarterly, yearly
- Tenant info (name, contact) and deposit tracking
- Income: rent, late fee, deposit; Expenses: maintenance
- Partial payments and variable rent increases
- Overdue/Upcoming payment dashboard with local notifications
- Yearly income and profit/loss overview; vacancy rate
- PDF export (scaffolded in design; implementation planned)
- Offline-first (Core Data) with backup/restore
- iPhone and iPad support; English, Simplified & Traditional Chinese

## Tech Stack
- SwiftUI UI + MVVM architecture
- Core Data (SQLite) for persistence
- Local Notifications (UserNotifications)
- PDFKit (planned)

## Project Structure
```
RentTracker.xcodeproj
RentTracker/
  ├── RentTrackerApp.swift
  ├── ContentView.swift
  ├── Models/
  │   ├── Enums.swift
  │   └── CoreData/
  │       ├── Property+*
  │       ├── Tenant+*
  │       ├── Contract+*
  │       ├── Payment+*
  │       ├── PaymentSchedule+*
  │       └── Expense+*
  ├── Services/
  │   ├── PersistenceController.swift
  │   ├── CoreDataService.swift
  │   └── NotificationService.swift
  ├── ViewModels/
  │   ├── PropertyViewModel.swift
  │   ├── ContractViewModel.swift
  │   └── PaymentViewModel.swift
  └── Views/
      ├── Payments/
      ├── Properties/
      ├── Contracts/
      ├── Reports/
      ├── Settings/
      └── Forms/
```

## Requirements
- Xcode 15+
- iOS 15+ (deployment target in project settings)

## Getting Started
1. Open `RentTracker.xcodeproj` in Xcode
2. Select a simulator (iPhone or iPad) and run
3. On first launch, allow notification permission to get rent reminders

## Development
- Architecture: MVVM
- Persistence: `PersistenceController` + `CoreDataService`
- Notifications: `NotificationService`
- Add sample data in `PersistenceController.preview` for SwiftUI previews

## Localization
- Languages: English (`Base`), Simplified Chinese (`zh-Hans`), Traditional Chinese (`zh-Hant`)
- Use `NSLocalizedString` keys from code; string files to be added during localization pass

## Backups
- Create/restore backups via Settings → Data Management
- Backups copy the SQLite store; keep files secure

## Roadmap
- PDF export: yearly reports and property reports via PDFKit
- Advanced analytics and charts
- iCloud sync (optional future)

## License
MIT
