# Design Specification - RentTracker Flutter App

## 1. Architecture Overview

### 1.1 Technology Stack
- **Platform**: Flutter 3.24+
- **Language**: Dart 3+
- **Target OS**: iOS 17+ (Android-ready for future)
- **Architecture Pattern**: Repository Pattern (simplified, testable)
- **Data Persistence**: Drift (SQLite) - Local-first
- **State Management**: Riverpod
- **Notification System**: Local Notifications (flutter_local_notifications)
- **PDF Generation**: pdf package
- **Localization**: intl + flutter_localizations (English, Simplified Chinese, Traditional Chinese)
- **Distribution**: Internal distribution / TestFlight

### 1.2 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  RentTracker Flutter App                    │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (Flutter Widgets)                      │
│  ├── Property Management Screens                           │
│  ├── Contract & Payment Screens                            │
│  ├── Financial Reports Screens                             │
│  └── Settings & Backup Screens                             │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer (Repositories)                       │
│  ├── PropertyRepository                                    │
│  ├── ContractRepository                                    │
│  ├── PaymentRepository                                     │
│  └── ExpenseRepository                                     │
├─────────────────────────────────────────────────────────────┤
│  Service Layer                                              │
│  ├── NotificationService                                   │
│  ├── PDFExportService                                      │
│  ├── BackupService                                         │
│  └── LocalizationService                                   │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Drift - SQLite)                               │
│  ├── Properties Table                                      │
│  ├── Tenants Table                                         │
│  ├── Contracts Table                                       │
│  ├── Payments Table                                        │
│  ├── PaymentSchedules Table                               │
│  └── Expenses Table                                        │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 Development Phases

**Phase 1 (MVP - 3 weeks)**: Local-only app
- Drift (SQLite) for local storage
- All core features working offline
- Single-device use

**Phase 2 (Cloud Sync - 2 weeks)**: Multi-device support
- Add Supabase (PostgreSQL) cloud database
- Implement sync service (Drift ↔ Supabase)
- User authentication
- Multi-device sync

---

## 2. Data Model Design

### 2.1 Drift Tables (Phase 1)

#### Properties Table
```dart
@DataClassName('Property')
class Properties extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get propertyType => text()(); // 'residential' or 'commercial'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Tenants Table
```dart
@DataClassName('Tenant')
class Tenants extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Contracts Table
```dart
@DataClassName('Contract')
class Contracts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get propertyId => integer().references(Properties, #id)();
  IntColumn get tenantId => integer().references(Tenants, #id)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  RealColumn get rentAmount => real()(); // Using double for Decimal
  TextColumn get paymentCycle => text()(); // 'monthly', 'bimonthly', 'quarterly', 'yearly'
  RealColumn get depositAmount => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Payments Table
```dart
@DataClassName('Payment')
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contractId => integer().references(Contracts, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get paidDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get paymentType => text()(); // 'rent', 'lateFee', 'deposit', 'depositReturn'
  TextColumn get paymentMethod => text()(); // 'bankTransfer', 'wechatPay', 'cash'
  BoolColumn get isPartial => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### PaymentSchedules Table
```dart
@DataClassName('PaymentSchedule')
class PaymentSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contractId => integer().references(Contracts, #id)();
  DateTimeColumn get dueDate => dateTime()();
  RealColumn get amount => real()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get paidDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Expenses Table
```dart
@DataClassName('Expense')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get propertyId => integer().references(Properties, #id)();
  RealColumn get amount => real()();
  TextColumn get category => text()(); // 'maintenance', 'repair', 'other'
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

### 2.2 Enumerations

```dart
enum PropertyType {
  residential('residential'),
  commercial('commercial');

  final String value;
  const PropertyType(this.value);
}

enum PaymentCycle {
  monthly('monthly', 1),
  bimonthly('bimonthly', 2),
  quarterly('quarterly', 3),
  yearly('yearly', 12);

  final String value;
  final int months;
  const PaymentCycle(this.value, this.months);
}

enum PaymentType {
  rent('rent'),
  lateFee('lateFee'),
  deposit('deposit'),
  depositReturn('depositReturn');

  final String value;
  const PaymentType(this.value);
}

enum PaymentMethod {
  bankTransfer('bankTransfer'),
  wechatPay('wechatPay'),
  cash('cash');

  final String value;
  const PaymentMethod(this.value);
}

enum ExpenseCategory {
  maintenance('maintenance'),
  repair('repair'),
  other('other');

  final String value;
  const ExpenseCategory(this.value);
}
```

---

## 3. Repository Layer Design

### 3.1 PropertyRepository

**Responsibilities:**
- CRUD operations for properties
- Get properties with active contracts
- Calculate vacancy rate

**Key Methods:**
```dart
class PropertyRepository {
  final AppDatabase db;

  Future<Property> addProperty(String name, String address, PropertyType type);
  Future<List<Property>> getAllProperties();
  Future<Property?> getPropertyById(int id);
  Future<void> updateProperty(Property property);
  Future<void> deleteProperty(int id);
  Future<List<PropertyWithContracts>> getPropertiesWithContracts();
  Future<double> calculateVacancyRate();
}
```

### 3.2 ContractRepository

**Responsibilities:**
- CRUD operations for contracts
- Generate payment schedules
- Handle contract activation/deactivation
- Track rent increases

**Key Methods:**
```dart
class ContractRepository {
  final AppDatabase db;
  final PaymentRepository paymentRepository;

  Future<Contract> createContract({
    required int propertyId,
    required int tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required double rentAmount,
    required PaymentCycle paymentCycle,
    required double depositAmount,
  });

  Future<List<Contract>> getAllContracts();
  Future<List<Contract>> getActiveContracts();
  Future<Contract?> getContractById(int id);
  Future<void> updateContract(Contract contract);
  Future<void> terminateContract(int id);
  Future<List<PaymentSchedule>> generatePaymentSchedules(Contract contract);
}
```

### 3.3 PaymentRepository

**Responsibilities:**
- CRUD operations for payments
- Track payment schedules
- Identify overdue payments
- Calculate late fees
- Handle partial payments

**Key Methods:**
```dart
class PaymentRepository {
  final AppDatabase db;

  Future<Payment> recordPayment({
    required int contractId,
    required double amount,
    required DateTime paidDate,
    required DateTime dueDate,
    required PaymentType type,
    required PaymentMethod method,
    bool isPartial = false,
    String? notes,
  });

  Future<List<Payment>> getAllPayments();
  Future<List<Payment>> getPaymentsByContract(int contractId);
  Future<List<PaymentSchedule>> getOverduePayments();
  Future<List<PaymentSchedule>> getUpcomingPayments({int days = 7});
  Future<void> markScheduleAsPaid(int scheduleId, Payment payment);
  Future<double> calculateLateFee(PaymentSchedule schedule);
  Future<double> calculateYearlyIncome(int year);
}
```

### 3.4 ExpenseRepository

**Responsibilities:**
- CRUD operations for expenses
- Track expenses by property
- Calculate yearly expenses

**Key Methods:**
```dart
class ExpenseRepository {
  final AppDatabase db;

  Future<Expense> addExpense({
    required int propertyId,
    required double amount,
    required ExpenseCategory category,
    required String description,
    required DateTime date,
  });

  Future<List<Expense>> getAllExpenses();
  Future<List<Expense>> getExpensesByProperty(int propertyId);
  Future<double> calculateYearlyExpenses(int year);
  Future<double> calculateProfitLoss(int year);
}
```

---

## 4. User Interface Design

### 4.1 Navigation Structure

```
main.dart (App Entry)
└── HomeScreen (Bottom Navigation Bar)
    ├── PropertiesScreen (Tab 1)
    │   ├── PropertiesListScreen
    │   ├── PropertyDetailScreen
    │   └── AddPropertyScreen
    ├── ContractsScreen (Tab 2)
    │   ├── ContractsListScreen
    │   ├── ContractDetailScreen
    │   └── AddContractScreen
    ├── PaymentsScreen (Tab 3 - Priority)
    │   ├── PaymentsDashboardScreen (Overdue payments)
    │   ├── AddPaymentScreen
    │   ├── PaymentHistoryScreen
    │   └── AddExpenseScreen
    ├── ReportsScreen (Tab 4)
    │   ├── YearlyReportScreen
    │   ├── ProfitLossScreen
    │   └── PDFExportScreen
    └── SettingsScreen (Tab 5)
        ├── NotificationSettingsScreen
        ├── BackupRestoreScreen
        ├── LanguageSettingsScreen
        └── AboutScreen
```

### 4.2 Key UI Components

#### PaymentsDashboardScreen (Priority View)
**Purpose**: Immediately show overdue/upcoming payments

**Features:**
- Red badges for overdue payments (past due date)
- Yellow badges for due soon (within 3 days)
- Property name, tenant name, amount, days overdue
- Quick "Mark Paid" button
- Tap to view payment details
- Pull-to-refresh

**Layout:**
- List with sticky headers (grouped by status: Overdue, Due Soon, Upcoming)
- Each item shows: Property → Tenant → Amount → Days
- Swipe actions: Mark Paid, View Details, Snooze

#### Money Input Widget
**Purpose**: Simple, user-friendly currency input

**Features:**
- Custom number pad with decimal support
- Currency symbol (¥) display
- Comma formatting (1,000.00)
- Quick amount buttons (100, 500, 1000, 5000)
- Real-time validation
- Clear/backspace buttons

#### Responsive Design
**Phone Layout:**
- Single column lists
- Full-screen modals for forms
- Bottom sheets for quick actions

**Tablet Layout:**
- Split-view navigation (list + detail)
- Sidebar navigation
- Popover modals

---

## 5. Service Layer Design

### 5.1 NotificationService

**Responsibilities:**
- Request notification permissions
- Schedule rent due reminders
- Schedule overdue alerts
- Handle notification actions

**Notification Schedule:**
```
Rent Due Reminders:
├── 3 days before due date (9:00 AM)
├── 1 day before due date (9:00 AM)
└── On due date (9:00 AM)

Overdue Alerts:
├── 1 day overdue (9:00 AM)
├── 7 days overdue (9:00 AM)
└── 30 days overdue (9:00 AM)

Contract Expiration:
├── 30 days before expiration
└── 7 days before expiration
```

**Methods:**
```dart
class NotificationService {
  Future<bool> requestPermission();
  Future<void> scheduleRentDueNotifications(PaymentSchedule schedule);
  Future<void> scheduleOverdueNotifications(PaymentSchedule schedule);
  Future<void> cancelNotification(String id);
  Future<void> handleNotificationTap(String payload);
}
```

### 5.2 PDFExportService

**Responsibilities:**
- Generate PDF reports
- Export payment history
- Create yearly summaries

**Methods:**
```dart
class PDFExportService {
  Future<Uint8List> generateYearlyReport(int year);
  Future<Uint8List> generateProfitLossReport(DateTime start, DateTime end);
  Future<Uint8List> generatePaymentHistory(int propertyId);
  Future<void> sharePDF(Uint8List pdfBytes, String filename);
}
```

### 5.3 BackupService

**Responsibilities:**
- Export database to file
- Import database from file
- Validate backup files

**Methods:**
```dart
class BackupService {
  Future<String> createBackup();
  Future<bool> restoreBackup(String path);
  Future<bool> validateBackup(String path);
}
```

---

## 6. Localization Design

### 6.1 Supported Languages
- **English** (en)
- **Simplified Chinese** (zh-Hans)
- **Traditional Chinese** (zh-Hant)

### 6.2 Implementation

**Using flutter_localizations + intl:**

```dart
// l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart

// lib/l10n/
├── app_en.arb (English)
├── app_zh_Hans.arb (Simplified Chinese)
└── app_zh_Hant.arb (Traditional Chinese)
```

### 6.3 Key Localization Considerations
- **Currency Formatting**: ¥ symbol, Chinese formatting (¥1,000 vs ¥1万)
- **Date Formatting**: Chinese date formats (2025年1月15日)
- **Payment Methods**: 银行转账 (Bank Transfer), 微信支付 (WeChat Pay)
- **Property Types**: 住宅 (Residential), 商业 (Commercial)
- **Number Formatting**: Support 万 (10,000) and 千 (1,000) in Chinese

---

## 7. Security & Data Protection

### 7.1 Data Security (Phase 1)
- **Local Encryption**: SQLite encryption using sqlcipher (Drift support)
- **Sensitive Data**: Encrypt tenant personal information
- **No Cloud Storage**: All data stored locally (Phase 1)
- **Backup Encryption**: Optional password-protected backups

### 7.2 Privacy Considerations
- **Minimal Data**: Only essential rental management data
- **No Analytics**: No third-party tracking
- **User Control**: Complete control over data export/import
- **Compliance**: Follow local privacy regulations

### 7.3 Phase 2 (Cloud Sync) Security
- **Supabase RLS**: Row-level security (users see only their data)
- **Authentication**: Supabase Auth (email/password)
- **HTTPS Only**: All cloud communication encrypted
- **Data Ownership**: User owns all data, can delete anytime

---

## 8. Performance Optimization

### 8.1 Database Optimization
- **Indexes**: Add indexes on frequently queried columns (propertyId, contractId, dueDate)
- **Batch Operations**: Use Drift batch inserts for payment schedules
- **Lazy Loading**: Load data on-demand for large lists
- **Pagination**: Implement pagination for payment history

### 8.2 UI Performance
- **ListView.builder**: Use for long lists (efficient memory)
- **Cached Images**: Cache property/tenant photos
- **Debouncing**: Debounce search inputs
- **Lazy Tabs**: Load tab content on-demand

---

## 9. Testing Strategy

### 9.1 Unit Testing (Priority for MVP)

**Test Repositories (Business Logic):**
```dart
// payment_repository_test.dart
test('should calculate late fee for overdue payment', () async {
  // Arrange
  final mockDb = MockDatabase();
  final repository = PaymentRepository(mockDb);
  final overdueSchedule = PaymentSchedule(
    dueDate: DateTime.now().subtract(Duration(days: 5)),
    amount: 1000,
  );

  // Act
  final lateFee = await repository.calculateLateFee(overdueSchedule);

  // Assert
  expect(lateFee, equals(50.0)); // 5% or fixed amount
});

test('should identify overdue payments', () async {
  final payments = await repository.getOverduePayments();
  expect(payments.length, greaterThan(0));
  expect(payments.first.dueDate.isBefore(DateTime.now()), isTrue);
});
```

**Test Services:**
```dart
// pdf_export_service_test.dart
test('should generate valid PDF bytes', () async {
  final service = PDFExportService();
  final pdfBytes = await service.generateYearlyReport(2025);

  expect(pdfBytes, isNotEmpty);
  expect(pdfBytes.first, equals(0x25)); // PDF magic number
});
```

**Test Enums and Models:**
```dart
test('PaymentCycle.monthly should have 1 month interval', () {
  expect(PaymentCycle.monthly.months, equals(1));
});
```

### 9.2 Widget Testing (Phase 2)

**Test UI Components:**
```dart
testWidgets('PaymentsDashboard shows overdue badge', (tester) async {
  await tester.pumpWidget(PaymentsDashboardScreen());
  expect(find.text('Overdue'), findsOneWidget);
  expect(find.byIcon(Icons.warning), findsWidgets);
});
```

### 9.3 Integration Testing (Optional)

**Test Full Workflows:**
- Add property → Create contract → Record payment
- Generate yearly report → Export PDF
- Schedule notification → Receive notification

### 9.4 Test Coverage Goals

**Phase 1 (MVP):**
- Repositories: 80%+ coverage
- Services: 70%+ coverage
- Models/Enums: 90%+ coverage
- **Total**: ~70% coverage

**Phase 2:**
- Add widget tests
- Add integration tests
- **Total**: ~85% coverage

---

## 10. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1

  # Database
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.3
  path: ^1.9.0

  # PDF Generation
  pdf: ^3.10.8
  printing: ^5.12.0

  # Notifications
  flutter_local_notifications: ^17.1.2
  timezone: ^0.9.3

  # Localization
  intl: ^0.19.0
  flutter_localizations:
    sdk: flutter

  # Utils
  uuid: ^4.4.0

dev_dependencies:
  # Code Generation
  drift_dev: ^2.18.0
  build_runner: ^2.4.9

  # Testing
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
```

---

## 11. File Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # App configuration (theme, localization)
│
├── core/
│   ├── database/
│   │   ├── app_database.dart    # Drift database class
│   │   └── app_database.g.dart  # Generated
│   ├── enums/
│   │   └── enums.dart           # All enumerations
│   └── constants/
│       └── constants.dart       # App constants
│
├── models/
│   ├── property.dart
│   ├── tenant.dart
│   ├── contract.dart
│   ├── payment.dart
│   ├── payment_schedule.dart
│   └── expense.dart
│
├── repositories/
│   ├── property_repository.dart
│   ├── contract_repository.dart
│   ├── payment_repository.dart
│   └── expense_repository.dart
│
├── services/
│   ├── notification_service.dart
│   ├── pdf_export_service.dart
│   └── backup_service.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── properties/
│   │   ├── properties_list_screen.dart
│   │   ├── property_detail_screen.dart
│   │   └── add_property_screen.dart
│   ├── contracts/
│   │   ├── contracts_list_screen.dart
│   │   ├── contract_detail_screen.dart
│   │   └── add_contract_screen.dart
│   ├── payments/
│   │   ├── payments_dashboard_screen.dart
│   │   ├── add_payment_screen.dart
│   │   └── payment_history_screen.dart
│   ├── reports/
│   │   ├── yearly_report_screen.dart
│   │   └── profit_loss_screen.dart
│   └── settings/
│       ├── settings_screen.dart
│       ├── notification_settings_screen.dart
│       └── backup_restore_screen.dart
│
├── widgets/
│   ├── money_input.dart
│   ├── property_card.dart
│   ├── payment_status_badge.dart
│   └── custom_app_bar.dart
│
├── providers/
│   └── providers.dart           # Riverpod providers
│
└── l10n/
    ├── app_en.arb
    ├── app_zh_Hans.arb
    └── app_zh_Hant.arb

test/
├── repositories/
│   ├── property_repository_test.dart
│   ├── contract_repository_test.dart
│   └── payment_repository_test.dart
├── services/
│   ├── notification_service_test.dart
│   └── pdf_export_service_test.dart
└── widgets/
    └── money_input_test.dart
```

---

## 12. Implementation Roadmap

### Phase 1: Local-Only MVP (3 Weeks)

#### Week 1: Foundation
**Days 1-2: Project Setup**
- ✅ Create Flutter project
- ✅ Add dependencies (Drift, Riverpod, pdf, notifications)
- ✅ Set up folder structure
- ✅ Configure localization (3 languages)
- ✅ Create app theme (dark/light mode)

**Days 3-5: Database & Models**
- ✅ Define Drift tables (6 tables)
- ✅ Create enumerations
- ✅ Generate Drift code
- ✅ Write database migrations
- ✅ Test database operations

**Days 6-7: Repositories (Part 1)**
- ✅ PropertyRepository (CRUD)
- ✅ ContractRepository (basic CRUD)
- ✅ Write unit tests for repositories

#### Week 2: Core Features
**Days 8-9: Property & Tenant Management**
- ✅ PropertiesListScreen (with search)
- ✅ AddPropertyScreen (form validation)
- ✅ PropertyDetailScreen
- ✅ Tenant management integrated with properties

**Days 10-11: Contract Management**
- ✅ ContractsListScreen
- ✅ AddContractScreen (complex form)
- ✅ Payment schedule generation
- ✅ Contract validation logic

**Days 12-14: Payment System (Priority)**
- ✅ PaymentRepository (with overdue logic)
- ✅ PaymentsDashboardScreen (overdue/upcoming)
- ✅ AddPaymentScreen (money input widget)
- ✅ Payment schedule tracking
- ✅ Late fee calculations

#### Week 3: Polish & Services
**Days 15-16: Notifications**
- ✅ NotificationService implementation
- ✅ Schedule rent due reminders
- ✅ Schedule overdue alerts
- ✅ Notification permission handling

**Days 17-18: Reports & PDF**
- ✅ YearlyReportScreen
- ✅ PDFExportService (yearly report)
- ✅ Profit/loss calculations
- ✅ Share PDF functionality

**Days 19-20: Settings & Backup**
- ✅ SettingsScreen
- ✅ BackupService (export/import database)
- ✅ Language selection
- ✅ Notification settings

**Day 21: Testing & Bug Fixes**
- ✅ Manual testing of all flows
- ✅ Fix critical bugs
- ✅ Performance optimization
- ✅ Prepare for TestFlight

### Phase 2: Cloud Sync (2 Weeks) - Future

#### Week 4: Supabase Integration
**Days 1-2: Setup**
- Set up Supabase project
- Create PostgreSQL tables (mirror Drift schema)
- Configure Row-Level Security (RLS)
- Set up authentication

**Days 3-5: Sync Service**
- Create SyncService
- Implement push changes (local → cloud)
- Implement pull changes (cloud → local)
- Conflict resolution (last-write-wins)

**Days 6-7: Authentication**
- Add login/signup screens
- Integrate Supabase Auth
- Handle session management
- Multi-user support

#### Week 5: Polish & Deploy
**Days 8-10: Testing**
- Test sync scenarios (offline → online)
- Test conflict resolution
- Test multi-device sync
- Fix sync bugs

**Days 11-12: Deployment**
- Prepare for App Store
- Create app screenshots
- Write App Store description
- Submit to TestFlight

**Days 13-14: Buffer**
- Final bug fixes
- Documentation
- User guide

---

## 13. Phase 2: Cloud Sync Architecture (Future)

### 13.1 Supabase Integration

**PostgreSQL Schema** (mirrors Drift):
```sql
CREATE TABLE properties (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  property_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row-Level Security
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own properties"
  ON properties FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own properties"
  ON properties FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

### 13.2 Sync Service

**Strategy**: Offline-first with periodic sync

**Sync Flow:**
1. User makes change → Save to Drift immediately
2. Mark record as "needs sync" (add `synced_at` column)
3. When online → SyncService detects internet
4. Push unsynced changes to Supabase
5. Pull changes from Supabase (modified after last sync)
6. Resolve conflicts (last-write-wins or custom logic)
7. Update local database

**Conflict Resolution:**
- Compare `updated_at` timestamps
- If cloud newer → Use cloud version
- If local newer → Push local version
- Log conflicts for review

### 13.3 Authentication

**Supabase Auth Features:**
- Email/password authentication
- Password reset
- Email verification
- Session management

**User Experience:**
- First launch → Create account or login
- Automatic session refresh
- Logout option in settings
- Multi-device sync after login

---

## 14. Success Metrics

### Phase 1 (MVP)
- ✅ App launches without crashes
- ✅ All CRUD operations work
- ✅ Overdue payments detected correctly
- ✅ Notifications scheduled successfully
- ✅ PDF exports valid
- ✅ Database backup/restore works
- ✅ Localization displays correctly (3 languages)
- ✅ 70%+ test coverage

### Phase 2 (Cloud Sync)
- ✅ Multi-device sync < 5 seconds
- ✅ Conflict resolution works
- ✅ Offline mode graceful degradation
- ✅ User authentication secure
- ✅ Data never lost during sync

---

## 15. Future Enhancements (Phase 3+)

### 15.1 Advanced Features
- **Photo Attachments**: Add photos to expenses and properties
- **Document Storage**: Store lease PDFs, receipts (Supabase Storage)
- **Advanced Analytics**: Charts and graphs (fl_chart package)
- **Tenant Portal**: Separate app for tenants to view contracts

### 15.2 Platform Expansion
- **Android**: Already Flutter-ready, just test and deploy
- **Web**: Flutter web for landlord dashboard
- **Desktop**: macOS/Windows desktop apps

### 15.3 Integrations
- **Bank Integration**: Link bank accounts for automatic payment tracking
- **Calendar Integration**: Sync payment due dates to device calendar
- **Email Reports**: Send monthly reports via email

---

This design specification provides a complete blueprint for implementing the RentTracker Flutter app with a pragmatic, phased approach optimized for solo development and fast MVP delivery.
