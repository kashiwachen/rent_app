# Design Specification - RentTracker iOS App

## 1. Architecture Overview

### 1.1 Technology Stack
- **UI Framework**: SwiftUI (iOS 15+)
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Data Persistence**: Core Data with SQLite backend
- **Notification System**: Local Notifications + Push Notifications
- **PDF Generation**: PDFKit
- **Platform Support**: Universal (iPhone + iPad)
- **Localization**: English, Simplified Chinese, Traditional Chinese
- **Distribution**: Internal/Enterprise distribution

### 1.2 System Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    RentTracker iOS App                      │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI Views)                        │
│  ├── Property Management Views                             │
│  ├── Contract & Payment Views                              │
│  ├── Financial Reports Views                               │
│  └── Settings & Backup Views                               │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer (ViewModels - MVVM)                  │
│  ├── PropertyViewModel                                     │
│  ├── ContractViewModel                                     │
│  ├── PaymentViewModel                                      │
│  ├── ReportViewModel                                       │
│  └── NotificationViewModel                                 │
├─────────────────────────────────────────────────────────────┤
│  Service Layer                                              │
│  ├── CoreDataService                                       │
│  ├── NotificationService                                   │
│  ├── PDFExportService                                      │
│  ├── BackupService                                         │
│  └── LocalizationService                                   │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Core Data)                                    │
│  ├── Property Entity                                       │
│  ├── Tenant Entity                                         │
│  ├── Contract Entity                                       │
│  ├── Payment Entity                                        │
│  └── Expense Entity                                        │
└─────────────────────────────────────────────────────────────┘
```

## 2. Data Model Design

### 2.1 Core Data Entities

#### Property Entity
```swift
@Entity Property {
    @Attribute var id: UUID
    @Attribute var name: String
    @Attribute var address: String
    @Attribute var propertyType: PropertyType // Enum: residential, commercial
    @Attribute var createdAt: Date
    @Relationship var contracts: [Contract]
    @Relationship var expenses: [Expense]
}
```

#### Tenant Entity
```swift
@Entity Tenant {
    @Attribute var id: UUID
    @Attribute var name: String
    @Attribute var phone: String
    @Attribute var email: String?
    @Attribute var createdAt: Date
    @Relationship var contracts: [Contract]
}
```

#### Contract Entity
```swift
@Entity Contract {
    @Attribute var id: UUID
    @Attribute var startDate: Date
    @Attribute var endDate: Date
    @Attribute var rentAmount: Decimal
    @Attribute var paymentCycle: PaymentCycle // Enum: monthly, bimonthly, quarterly, yearly
    @Attribute var depositAmount: Decimal
    @Attribute var isActive: Bool
    @Attribute var createdAt: Date
    @Relationship var property: Property
    @Relationship var tenant: Tenant
    @Relationship var payments: [Payment]
    @Relationship var paymentSchedules: [PaymentSchedule]
}
```

#### Payment Entity
```swift
@Entity Payment {
    @Attribute var id: UUID
    @Attribute var amount: Decimal
    @Attribute var paidDate: Date
    @Attribute var dueDate: Date
    @Attribute var paymentType: PaymentType // Enum: rent, lateFee, deposit, depositReturn
    @Attribute var paymentMethod: PaymentMethod // Enum: bankTransfer, wechatPay, cash
    @Attribute var isPartial: Bool
    @Attribute var notes: String?
    @Relationship var contract: Contract
}
```

#### Expense Entity
```swift
@Entity Expense {
    @Attribute var id: UUID
    @Attribute var amount: Decimal
    @Attribute var category: ExpenseCategory // Enum: maintenance, repair, other
    @Attribute var description: String
    @Attribute var date: Date
    @Relationship var property: Property
}
```

#### PaymentSchedule Entity
```swift
@Entity PaymentSchedule {
    @Attribute var id: UUID
    @Attribute var dueDate: Date
    @Attribute var amount: Decimal
    @Attribute var isPaid: Bool
    @Attribute var paidDate: Date?
    @Relationship var contract: Contract
}
```

### 2.2 Enumerations
```swift
enum PropertyType: String, CaseIterable {
    case residential = "residential"
    case commercial = "commercial"
}

enum PaymentCycle: String, CaseIterable {
    case monthly = "monthly"
    case bimonthly = "bimonthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
}

enum PaymentType: String, CaseIterable {
    case rent = "rent"
    case lateFee = "lateFee"
    case deposit = "deposit"
    case depositReturn = "depositReturn"
}

enum PaymentMethod: String, CaseIterable {
    case bankTransfer = "bankTransfer"
    case wechatPay = "wechatPay"
    case cash = "cash"
}

enum ExpenseCategory: String, CaseIterable {
    case maintenance = "maintenance"
    case repair = "repair"
    case other = "other"
}
```

## 3. User Interface Design

### 3.1 Navigation Structure
```
RentTrackerApp (Main App)
├── ContentView (Root Navigation)
    ├── TabView
        ├── PropertiesTab
        │   ├── PropertiesListView
        │   ├── PropertyDetailView
        │   └── AddPropertyView
        ├── ContractsTab
        │   ├── ContractsListView
        │   ├── ContractDetailView
        │   ├── AddContractView
        │   └── ContractHistoryView
        ├── PaymentsTab
        │   ├── PaymentsDashboardView (Overdue Payments)
        │   ├── AddPaymentView
        │   ├── PaymentHistoryView
        │   └── AddExpenseView
        ├── ReportsTab
        │   ├── YearlyReportView
        │   ├── ProfitLossView
        │   ├── VacancyRateView
        │   └── PDFExportView
        └── SettingsTab
            ├── NotificationSettingsView
            ├── BackupRestoreView
            ├── LanguageSettingsView
            └── AboutView
```

### 3.2 Key UI Components

#### PaymentsDashboardView (Priority View)
- **Purpose**: Immediately show properties with missing/overdue payments
- **Layout**: List of overdue payments with property names, amounts, days overdue
- **Actions**: Quick "Mark Paid" button, navigation to payment details
- **Visual Indicators**: Red badges for overdue, yellow for due soon

#### Simple Money Input Interface
- **Component**: Custom NumPad with decimal support
- **Features**: Currency symbol (¥), comma formatting, quick amount buttons
- **Validation**: Real-time validation, error states
- **Accessibility**: VoiceOver support, large touch targets

#### Universal Design (iPhone/iPad)
- **iPhone**: Single-column navigation, full-screen modals
- **iPad**: Split-view navigation, popover modals, sidebar navigation
- **Responsive**: Adaptive layouts using SwiftUI's size classes

## 4. Service Layer Design

### 4.1 CoreDataService
```swift
class CoreDataService: ObservableObject {
    lazy var persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext
    
    func save()
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T]
    func delete(_ object: NSManagedObject)
    func createBackup() -> URL?
    func restoreFromBackup(_ url: URL) -> Bool
}
```

### 4.2 NotificationService
```swift
class NotificationService: ObservableObject {
    func requestPermission()
    func scheduleRentDueNotification(for contract: Contract)
    func scheduleOverdueNotification(for payment: PaymentSchedule)
    func cancelNotification(for id: String)
    func handleNotificationResponse(_ response: UNNotificationResponse)
}
```

### 4.3 PDFExportService
```swift
class PDFExportService {
    func generateYearlyReport(year: Int) -> PDFDocument
    func generateProfitLossReport(startDate: Date, endDate: Date) -> PDFDocument
    func generatePaymentHistory(for property: Property) -> PDFDocument
    func exportToPDF(_ document: PDFDocument) -> URL?
}
```

### 4.4 BackupService
```swift
class BackupService {
    func createBackup() -> BackupResult
    func restoreBackup(from url: URL) -> RestoreResult
    func validateBackup(_ url: URL) -> Bool
    func getBackupMetadata(_ url: URL) -> BackupMetadata?
}
```

## 5. Notification System Design

### 5.1 Local Notifications Strategy
```
NotificationService
├── Rent Due Reminders
│   ├── 3 days before due date
│   ├── 1 day before due date
│   └── On due date
├── Overdue Payment Alerts
│   ├── 1 day overdue
│   ├── 7 days overdue
│   └── 30 days overdue
└── Contract Expiration Warnings
    ├── 30 days before expiration
    └── 7 days before expiration
```

### 5.2 Notification Categories & Actions
```swift
// Rent Due Category
UNNotificationCategory(
    identifier: "RENT_DUE",
    actions: [
        UNNotificationAction(identifier: "MARK_PAID", title: "Mark Paid"),
        UNNotificationAction(identifier: "REMIND_LATER", title: "Remind Later")
    ]
)

// Overdue Category
UNNotificationCategory(
    identifier: "OVERDUE",
    actions: [
        UNNotificationAction(identifier: "MARK_PAID", title: "Mark Paid"),
        UNNotificationAction(identifier: "CONTACT_TENANT", title: "Contact Tenant")
    ]
)
```

## 6. Localization Design

### 6.1 Supported Languages
- **Base**: English (en)
- **Simplified Chinese**: zh-Hans
- **Traditional Chinese**: zh-Hant

### 6.2 Localization Structure
```
Resources/
├── Base.lproj/
│   ├── Localizable.strings
│   └── InfoPlist.strings
├── zh-Hans.lproj/
│   ├── Localizable.strings
│   └── InfoPlist.strings
└── zh-Hant.lproj/
    ├── Localizable.strings
    └── InfoPlist.strings
```

### 6.3 Key Localization Considerations
- **Currency Formatting**: ¥ symbol, Chinese number formatting (万, 千)
- **Date Formatting**: Chinese calendar context support
- **Payment Methods**: 微信支付 (WeChat Pay), 银行转账 (Bank Transfer)
- **Property Types**: 住宅 (Residential), 商业 (Commercial)
- **Font Support**: SF Pro with Chinese character support

## 7. Security & Data Protection

### 7.1 Data Security
- **Core Data Encryption**: SQLite database encryption using FileProtection
- **Sensitive Data**: Encrypt tenant personal information
- **Backup Security**: Encrypted backup files with user-defined passwords
- **Local Storage**: All data stored locally, no cloud transmission

### 7.2 Privacy Considerations
- **Minimal Data Collection**: Only essential rental management data
- **No Analytics**: No third-party analytics or tracking
- **User Control**: Complete control over data export/import
- **Compliance**: Follow local privacy regulations for tenant data

## 8. Performance Optimization

### 8.1 Core Data Optimization
- **Lazy Loading**: Use NSFetchedResultsController for large datasets
- **Batch Operations**: Batch inserts/updates for better performance
- **Memory Management**: Proper context management and memory cleanup
- **Indexing**: Strategic Core Data indexes for frequently queried fields

### 8.2 UI Performance
- **Lazy Views**: Use LazyVStack/LazyHStack for large lists
- **Image Optimization**: Efficient image loading and caching
- **Animation Performance**: Optimize SwiftUI animations
- **Memory Usage**: Monitor and optimize memory usage for iPad

## 9. Testing Strategy

### 9.1 Unit Testing
- **ViewModels**: Test all business logic in ViewModels
- **Services**: Test Core Data operations, PDF generation, notifications
- **Data Models**: Test Core Data entity relationships and validations
- **Utilities**: Test calculation functions, date formatting, currency handling

### 9.2 UI Testing
- **Navigation**: Test tab navigation and view transitions
- **Forms**: Test data entry forms and validation
- **Notifications**: Test notification handling and actions
- **Accessibility**: Test VoiceOver support and accessibility features

## 10. Deployment Strategy

### 10.1 Internal Distribution
- **Apple Developer Enterprise Program**: For internal distribution
- **Ad Hoc Distribution**: For testing and limited distribution
- **TestFlight**: For beta testing with stakeholders
- **Configuration**: Development, staging, and production configurations

### 10.2 Build Configuration
- **Development**: Debug builds with extensive logging
- **Staging**: Release builds with limited logging for testing
- **Production**: Optimized release builds for distribution
- **Code Signing**: Proper certificates and provisioning profiles

## 11. Future Enhancements (Phase 2+)

### 11.1 Cloud Sync
- **iCloud Integration**: Sync data across user's devices
- **Conflict Resolution**: Handle data conflicts between devices
- **Backup to Cloud**: Automatic iCloud backup option

### 11.2 Advanced Features
- **Photo Attachments**: Add photos to expenses and property records
- **Document Storage**: Store lease documents and receipts
- **Advanced Analytics**: More detailed financial analytics and trends
- **Integration**: Bank account integration for automatic payment tracking

### 11.3 Platform Expansion
- **macOS Version**: Native macOS app using Mac Catalyst
- **Apple Watch**: Quick payment recording and notifications
- **Widgets**: iOS home screen widgets for payment status

---

## Implementation Priority

### Phase 1 (MVP) - 8-10 weeks
1. **Week 1-2**: Core Data setup, basic entities, data service layer
2. **Week 3-4**: SwiftUI navigation structure, basic CRUD operations
3. **Week 5-6**: Payment tracking, simple money input, overdue payment dashboard
4. **Week 7-8**: Local notifications, basic reporting
5. **Week 9-10**: Chinese localization, testing, bug fixes

### Phase 2 - 4-6 weeks
1. **Week 11-12**: Advanced reporting, PDF export
2. **Week 13-14**: Backup/restore functionality
3. **Week 15-16**: iPad optimization, accessibility improvements

This design specification provides a comprehensive blueprint for implementing the RentTracker iOS app with all required features, proper architecture, and scalability considerations.
