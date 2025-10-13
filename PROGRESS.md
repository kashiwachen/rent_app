# RentTracker Development Progress

## Phase 1: Local-Only MVP (3 Weeks)

**Start Date**: 2025-10-13
**Target Completion**: 2025-11-03
**Architecture**: Repository Pattern + Drift (SQLite) + Riverpod
**Testing**: TDD Mandatory (80%+ coverage)

---

## Week 1: Foundation (Days 1-7)

### ✅ Days 1-2: Project Setup
- [ ] **Task 1.1**: Check Flutter SDK installation and version (3.24+)
- [ ] **Task 1.2**: Create Flutter project with iOS platform
- [ ] **Task 1.3**: Add all dependencies to pubspec.yaml (Section 10)
  - flutter_riverpod ^2.5.1
  - drift ^2.18.0 + sqlite3_flutter_libs ^0.5.0
  - pdf ^3.10.8 + printing ^5.12.0
  - flutter_local_notifications ^17.1.2
  - intl ^0.19.0
  - Dev dependencies (drift_dev, build_runner, mockito)
- [ ] **Task 1.4**: Create folder structure (Section 11)
  - core/ (database, enums, constants)
  - models/
  - repositories/
  - services/
  - screens/ (properties, contracts, payments, reports, settings)
  - widgets/
  - providers/
  - l10n/
- [ ] **Task 1.5**: Configure localization (l10n.yaml + ARB files)
  - app_en.arb (English)
  - app_zh_Hans.arb (Simplified Chinese)
  - app_zh_Hant.arb (Traditional Chinese)
- [ ] **Task 1.6**: Create app theme (lib/app.dart)
  - Light mode theme
  - Dark mode theme
  - Material 3 design
- [ ] **Task 1.7**: Run initial build to verify setup

### 🔄 Days 3-5: Database & Models
- [ ] **Task 2.1**: Define enumerations (lib/core/enums/enums.dart)
  - PropertyType (residential, commercial)
  - PaymentCycle (monthly, bimonthly, quarterly, yearly)
  - PaymentType (rent, lateFee, deposit, depositReturn)
  - PaymentMethod (bankTransfer, wechatPay, cash)
  - ExpenseCategory (maintenance, repair, other)
- [ ] **Task 2.2**: Write unit tests for enumerations (BEFORE implementation)
  - Test enum values and properties
  - Test coverage ≥90%
- [ ] **Task 2.3**: Define Drift tables (lib/core/database/app_database.dart)
  - Properties table
  - Tenants table
  - Contracts table
  - Payments table
  - PaymentSchedules table
  - Expenses table
- [ ] **Task 2.4**: Create AppDatabase class with Drift
  - Configure database connection
  - Add schema version
  - Set up database path
- [ ] **Task 2.5**: Run code generation (build_runner)
  - `dart run build_runner build --delete-conflicting-outputs`
- [ ] **Task 2.6**: Write database integration tests
  - Test table creation
  - Test basic CRUD operations
  - Test foreign key relationships
- [ ] **Task 2.7**: Create migration scripts (if needed)

### 🔄 Days 6-7: Repositories (Part 1)
- [ ] **Task 3.1**: Write unit tests for PropertyRepository (TDD - RED)
  - Test addProperty()
  - Test getAllProperties()
  - Test getPropertyById()
  - Test updateProperty()
  - Test deleteProperty()
  - Test getPropertiesWithContracts()
  - Test calculateVacancyRate()
- [ ] **Task 3.2**: Implement PropertyRepository (TDD - GREEN)
  - Implement all methods to pass tests
  - Handle edge cases (null checks, empty lists)
- [ ] **Task 3.3**: Refactor PropertyRepository (TDD - REFACTOR)
  - Clean up code
  - Optimize queries
- [ ] **Task 3.4**: Write unit tests for ContractRepository (TDD - RED)
  - Test createContract()
  - Test getAllContracts()
  - Test getActiveContracts()
  - Test getContractById()
  - Test updateContract()
  - Test terminateContract()
  - Test generatePaymentSchedules()
- [ ] **Task 3.5**: Implement ContractRepository (TDD - GREEN)
  - Implement CRUD operations
  - Implement payment schedule generation logic
- [ ] **Task 3.6**: Refactor ContractRepository (TDD - REFACTOR)
- [ ] **Task 3.7**: **MANDATORY**: Run code-reviewer on all repository code
- [ ] **Task 3.8**: Verify test coverage ≥80% for repositories

---

## Week 2: Core Features (Days 8-14)

### 🔄 Days 8-9: Property & Tenant Management UI
- [ ] **Task 4.1**: Write widget tests for PropertiesListScreen (TDD - RED)
  - Test empty state
  - Test list rendering
  - Test search functionality
  - Test navigation to detail screen
- [ ] **Task 4.2**: Implement PropertiesListScreen (TDD - GREEN)
  - ListView with search bar
  - Property cards
  - Pull-to-refresh
  - Empty state UI
- [ ] **Task 4.3**: Write widget tests for AddPropertyScreen (TDD - RED)
  - Test form validation
  - Test property type selection
  - Test save button
- [ ] **Task 4.4**: Implement AddPropertyScreen (TDD - GREEN)
  - Form with validation
  - Property type dropdown
  - Save to database
- [ ] **Task 4.5**: Write widget tests for PropertyDetailScreen (TDD - RED)
  - Test property display
  - Test contract list
  - Test edit/delete actions
- [ ] **Task 4.6**: Implement PropertyDetailScreen (TDD - GREEN)
  - Property details display
  - Associated contracts list
  - Edit/delete actions
- [ ] **Task 4.7**: Integrate Tenant management
  - Add tenant form (inline with property)
  - Tenant selection dropdown
- [ ] **Task 4.8**: **MANDATORY**: Run code-reviewer on UI code
- [ ] **Task 4.9**: Manual testing of property flows

### 🔄 Days 10-11: Contract Management UI
- [ ] **Task 5.1**: Write widget tests for ContractsListScreen (TDD - RED)
  - Test active/inactive contract filtering
  - Test contract card display
  - Test navigation
- [ ] **Task 5.2**: Implement ContractsListScreen (TDD - GREEN)
  - List of contracts (active/expired)
  - Filter by status
  - Contract cards with key info
- [ ] **Task 5.3**: Write widget tests for AddContractScreen (TDD - RED)
  - Test complex form validation
  - Test property/tenant selection
  - Test payment cycle selection
  - Test date range validation
- [ ] **Task 5.4**: Implement AddContractScreen (TDD - GREEN)
  - Multi-step form
  - Property/tenant dropdowns
  - Payment cycle selection
  - Date pickers (start/end date)
  - Rent amount input
  - Deposit amount input
- [ ] **Task 5.5**: Implement payment schedule generation
  - Generate schedules based on payment cycle
  - Save to PaymentSchedules table
- [ ] **Task 5.6**: Write widget tests for ContractDetailScreen (TDD - RED)
  - Test contract info display
  - Test payment schedule display
  - Test terminate contract action
- [ ] **Task 5.7**: Implement ContractDetailScreen (TDD - GREEN)
  - Contract details display
  - Payment schedule timeline
  - Terminate contract button
- [ ] **Task 5.8**: **MANDATORY**: Run code-reviewer on contract UI
- [ ] **Task 5.9**: Manual testing of contract flows

### 🔄 Days 12-14: Payment System (Priority)
- [ ] **Task 6.1**: Write unit tests for PaymentRepository (TDD - RED)
  - Test recordPayment()
  - Test getAllPayments()
  - Test getPaymentsByContract()
  - Test getOverduePayments()
  - Test getUpcomingPayments()
  - Test calculateLateFee()
  - Test calculateYearlyIncome()
  - Test markScheduleAsPaid()
- [ ] **Task 6.2**: Implement PaymentRepository (TDD - GREEN)
  - Implement all payment methods
  - Implement overdue detection logic
  - Implement late fee calculation (5% or fixed)
- [ ] **Task 6.3**: Write unit tests for ExpenseRepository (TDD - RED)
  - Test addExpense()
  - Test getAllExpenses()
  - Test getExpensesByProperty()
  - Test calculateYearlyExpenses()
  - Test calculateProfitLoss()
- [ ] **Task 6.4**: Implement ExpenseRepository (TDD - GREEN)
- [ ] **Task 6.5**: Refactor PaymentRepository and ExpenseRepository (TDD - REFACTOR)
- [ ] **Task 6.6**: Write widget tests for PaymentsDashboardScreen (TDD - RED)
  - Test overdue payments section
  - Test upcoming payments section
  - Test "Mark Paid" action
  - Test status badges (red/yellow)
- [ ] **Task 6.7**: Implement PaymentsDashboardScreen (TDD - GREEN)
  - Priority view with overdue/upcoming payments
  - Red badges for overdue (past due date)
  - Yellow badges for due soon (within 3 days)
  - Quick "Mark Paid" button
  - Sticky section headers (Overdue, Due Soon, Upcoming)
- [ ] **Task 6.8**: Write widget tests for MoneyInput widget (TDD - RED)
  - Test custom number pad
  - Test decimal input
  - Test quick amount buttons
  - Test validation
- [ ] **Task 6.9**: Implement MoneyInput widget (TDD - GREEN)
  - Custom number pad (0-9, decimal, clear)
  - Currency symbol (¥) display
  - Comma formatting (1,000.00)
  - Quick amount buttons (100, 500, 1000, 5000)
- [ ] **Task 6.10**: Write widget tests for AddPaymentScreen (TDD - RED)
  - Test payment form validation
  - Test payment type/method selection
  - Test partial payment checkbox
- [ ] **Task 6.11**: Implement AddPaymentScreen (TDD - GREEN)
  - Payment form with MoneyInput
  - Payment type/method dropdowns
  - Partial payment option
  - Notes field
- [ ] **Task 6.12**: Implement AddExpenseScreen
  - Expense form
  - Category dropdown
  - Date picker
- [ ] **Task 6.13**: **MANDATORY**: Run code-reviewer on payment system
- [ ] **Task 6.14**: Manual testing of payment flows
- [ ] **Task 6.15**: Verify test coverage ≥80% for payment system

---

## Week 3: Polish & Services (Days 15-21)

### 🔄 Days 15-16: Notifications
- [ ] **Task 7.1**: Write unit tests for NotificationService (TDD - RED)
  - Test requestPermission()
  - Test scheduleRentDueNotifications()
  - Test scheduleOverdueNotifications()
  - Test cancelNotification()
  - Test handleNotificationTap()
- [ ] **Task 7.2**: Implement NotificationService (TDD - GREEN)
  - Request notification permissions (iOS)
  - Schedule rent due reminders (3 days, 1 day, on due date)
  - Schedule overdue alerts (1 day, 7 days, 30 days)
  - Schedule contract expiration alerts (30 days, 7 days)
- [ ] **Task 7.3**: Configure iOS notification entitlements
  - Update Info.plist
  - Configure notification capabilities
- [ ] **Task 7.4**: Integrate NotificationService with payment schedules
  - Auto-schedule notifications on contract creation
  - Cancel notifications on payment completion
- [ ] **Task 7.5**: Test notifications on iOS simulator/device
  - Test foreground notifications
  - Test background notifications
  - Test notification actions
- [ ] **Task 7.6**: **MANDATORY**: Run code-reviewer on NotificationService

### 🔄 Days 17-18: Reports & PDF Export
- [ ] **Task 8.1**: Write unit tests for PDFExportService (TDD - RED)
  - Test generateYearlyReport()
  - Test generateProfitLossReport()
  - Test generatePaymentHistory()
  - Test PDF validity (magic number check)
- [ ] **Task 8.2**: Implement PDFExportService (TDD - GREEN)
  - Generate yearly income/expense report
  - Generate profit/loss report
  - Generate payment history PDF
  - Add Chinese localization to PDFs
- [ ] **Task 8.3**: Write widget tests for YearlyReportScreen (TDD - RED)
  - Test year selection
  - Test report display
  - Test export button
- [ ] **Task 8.4**: Implement YearlyReportScreen (TDD - GREEN)
  - Year picker
  - Income/expense summary
  - Export to PDF button
  - Share functionality (iOS share sheet)
- [ ] **Task 8.5**: Implement ProfitLossScreen
  - Date range picker
  - Profit/loss calculation
  - Export to PDF
- [ ] **Task 8.6**: Test PDF generation on iOS device
  - Test PDF rendering
  - Test sharing via iOS share sheet
- [ ] **Task 8.7**: **MANDATORY**: Run code-reviewer on PDF service

### 🔄 Days 19-20: Settings & Backup
- [ ] **Task 9.1**: Write unit tests for BackupService (TDD - RED)
  - Test createBackup()
  - Test restoreBackup()
  - Test validateBackup()
- [ ] **Task 9.2**: Implement BackupService (TDD - GREEN)
  - Export database to JSON file
  - Import database from JSON file
  - Validate backup file structure
- [ ] **Task 9.3**: Implement SettingsScreen
  - Language selection (3 languages)
  - Notification settings toggle
  - Backup/restore section
  - About section (version info)
- [ ] **Task 9.4**: Implement BackupRestoreScreen
  - Create backup button
  - Restore backup button (file picker)
  - Share backup file (iOS share sheet)
- [ ] **Task 9.5**: Implement NotificationSettingsScreen
  - Enable/disable notifications toggle
  - Reminder timing preferences
- [ ] **Task 9.6**: Implement language switching
  - Update app locale on language change
  - Persist language preference
- [ ] **Task 9.7**: Test backup/restore flow
  - Test backup creation
  - Test backup restoration
  - Test data integrity after restore
- [ ] **Task 9.8**: **MANDATORY**: Run code-reviewer on settings & backup

### 🔄 Day 21: Testing & Bug Fixes
- [ ] **Task 10.1**: Run full test suite
  - Unit tests (repositories, services)
  - Widget tests (UI components)
  - Verify ≥80% test coverage
- [ ] **Task 10.2**: Manual end-to-end testing
  - Test property creation → contract → payment flow
  - Test overdue payment detection
  - Test notifications (schedule & receive)
  - Test PDF export
  - Test backup/restore
  - Test localization (all 3 languages)
- [ ] **Task 10.3**: Performance testing
  - Test with 50+ properties
  - Test with 100+ payments
  - Test database query performance
  - Optimize slow queries
- [ ] **Task 10.4**: Fix critical bugs identified in testing
- [ ] **Task 10.5**: UI polish
  - Fix visual inconsistencies
  - Improve loading states
  - Add error handling UI
- [ ] **Task 10.6**: Prepare for TestFlight
  - Configure iOS build settings
  - Create app icon
  - Update version number (1.0.0-beta)
  - Create build for TestFlight
- [ ] **Task 10.7**: **MANDATORY**: Final code review of entire codebase
- [ ] **Task 10.8**: Update README with setup instructions
- [ ] **Task 10.9**: Create release notes for beta testers

---

## Phase 1 Completion Checklist

### Functional Requirements
- [ ] ✅ All CRUD operations work (Properties, Tenants, Contracts, Payments, Expenses)
- [ ] ✅ Overdue payments detected and displayed correctly
- [ ] ✅ Notifications scheduled and delivered (iOS)
- [ ] ✅ PDF exports generate valid files
- [ ] ✅ Backup/restore preserves data integrity
- [ ] ✅ Localization works for 3 languages (EN, ZH-Hans, ZH-Hant)
- [ ] ✅ App handles offline-only usage (no network required)

### Quality Requirements
- [ ] ✅ Test coverage ≥80% (repositories + services)
- [ ] ✅ No critical bugs in manual testing
- [ ] ✅ App launches without crashes
- [ ] ✅ Performance acceptable with 100+ records
- [ ] ✅ UI responsive on iPhone (iOS 17+)
- [ ] ✅ Code reviewed by code-reviewer agent

### Distribution Requirements
- [ ] ✅ TestFlight build created
- [ ] ✅ App icon and metadata ready
- [ ] ✅ Release notes written

---

## Phase 2: Cloud Sync (Future - 2 Weeks)

### Week 4: Supabase Integration
- [ ] Set up Supabase project
- [ ] Create PostgreSQL tables (mirror Drift schema)
- [ ] Configure Row-Level Security (RLS)
- [ ] Implement SyncService (local ↔ cloud)
- [ ] Implement authentication (Supabase Auth)

### Week 5: Polish & Deploy
- [ ] Test multi-device sync
- [ ] Test conflict resolution
- [ ] Fix sync bugs
- [ ] App Store submission
- [ ] User documentation

---

## Notes

**TDD Discipline (MANDATORY):**
- 🔴 RED: Write failing tests first
- ✅ GREEN: Implement minimal code to pass
- 🔄 REFACTOR: Clean up with tests passing
- Never commit untested code

**Code Review:**
- Invoke `code-reviewer` after every code change
- Address all findings before moving to next task
- No task is complete without code review

**Git Commit Strategy:**
- Commit after each task completion
- Use conventional commits (feat:, fix:, test:, refactor:)
- Example: `feat: implement PropertyRepository with unit tests`

**Daily Workflow:**
1. Pick next pending task
2. Write tests (TDD - RED)
3. Implement code (TDD - GREEN)
4. Refactor (TDD - REFACTOR)
5. Run code-reviewer
6. Commit changes
7. Update progress checkboxes

---

**Last Updated**: 2025-10-13
**Current Phase**: Week 1 - Foundation
**Next Milestone**: Days 1-2 Project Setup
