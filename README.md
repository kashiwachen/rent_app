# RentTracker

A Flutter iOS app for landlords to manage rental properties, tenants, contracts, payments, expenses, and financial reports with offline-first local storage.

## 🚀 Features

### Core Features (Phase 1 - MVP)
- **Property Management**: Track residential and commercial properties
- **Contract Management**: Flexible payment cycles (monthly, bimonthly, quarterly, yearly)
- **Payment Tracking**: Rent, late fees, deposits with partial payment support
- **Expense Management**: Track maintenance, repairs, and other property expenses
- **Payment Dashboard**: See overdue and upcoming payments at a glance
- **Local Notifications**: Rent due reminders and overdue alerts
- **Financial Reports**: Yearly income, profit/loss analysis, vacancy rates
- **PDF Export**: Generate and share financial reports
- **Backup/Restore**: Local database backup and restore
- **Multi-language**: English, Simplified Chinese, Traditional Chinese

### Future Features (Phase 2)
- Cloud sync via Supabase
- Multi-device support
- User authentication

## 📱 Tech Stack

- **Framework**: Flutter 3.35+ (Dart 3.9+)
- **Target**: iOS 17+
- **Architecture**: Repository Pattern
- **Database**: Drift (SQLite) - Offline-first
- **State Management**: Riverpod
- **Notifications**: flutter_local_notifications
- **PDF Generation**: pdf package + printing
- **Localization**: intl + flutter_localizations

## 📂 Project Structure

### App Source Code
```
lib/                        # 📱 APP SOURCE CODE
├── main.dart              # App entry point
├── core/                  # Core functionality
│   ├── database/         # Drift database configuration
│   ├── enums/            # App-wide enumerations
│   └── constants/        # App constants
├── models/               # Data models (Drift-generated)
├── repositories/         # Business logic layer
│   ├── property_repository.dart
│   ├── contract_repository.dart
│   ├── payment_repository.dart
│   └── expense_repository.dart
├── services/             # Services layer
│   ├── notification_service.dart
│   ├── pdf_export_service.dart
│   └── backup_service.dart
├── screens/              # UI screens
│   ├── properties/       # Property management screens
│   ├── contracts/        # Contract management screens
│   ├── payments/         # Payment tracking screens
│   ├── reports/          # Financial reports screens
│   └── settings/         # Settings screens
├── widgets/              # Reusable UI components
├── providers/            # Riverpod state providers
└── l10n/                 # Localization ARB files

test/                      # 🧪 TEST CODE
├── repositories/         # Repository unit tests
├── services/             # Service unit tests
└── widgets/              # Widget tests

ios/                       # 📱 iOS NATIVE CODE
├── Runner/               # iOS app configuration
└── Runner.xcodeproj/     # Xcode project

pubspec.yaml              # 📦 Flutter dependencies
l10n.yaml                 # 🌍 Localization config
analysis_options.yaml     # 📊 Dart linter config
```

### Documentation & Claude Files
```
PRD.md                    # 📋 Product Requirements (Claude)
DESIGN_SPEC.md            # 🏗️  Technical Design (Claude)
PROGRESS.md               # 📈 Development Progress (Claude)
README.md                 # 📖 This file

.claude/                  # 🤖 Claude Code configuration
├── agents/               # Agent prompts
└── settings.local.json   # Local settings

RentTracker_Swift_Backup/ # 🗄️  Old Swift project (archived)
```

## 🛠️ Requirements

- **Flutter SDK**: 3.24 or higher
- **Dart**: 3.0 or higher
- **iOS**: iOS 17+ for deployment
- **Development**: Xcode 15+ (for iOS builds)

## 🏁 Getting Started

### Installation

1. **Install Flutter** (if not already installed):
   ```bash
   brew install --cask flutter
   flutter doctor
   ```

2. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd rent_app
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Generate Drift database code** (when database is implemented):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**:
   ```bash
   flutter run
   ```

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Code Analysis

```bash
# Analyze code quality
flutter analyze

# Format code
dart format lib/ test/
```

## 📖 Development Guide

### Architecture

This app follows the **Repository Pattern**:
- **Repositories**: Handle business logic and data operations
- **Services**: Provide cross-cutting functionality (notifications, PDF, backup)
- **Providers**: Riverpod state management
- **Screens**: UI presentation layer

### Database

Using **Drift** (type-safe SQLite ORM):
- 6 tables: Properties, Tenants, Contracts, Payments, PaymentSchedules, Expenses
- Automatic code generation for type-safe queries
- Foreign key relationships enforced

### Testing Strategy

Following **TDD (Test-Driven Development)**:
- Write tests before implementation
- Target: 70%+ test coverage for MVP
- Focus on repository and service layers

### Localization

Add translations to ARB files in `lib/l10n/`:
- `app_en.arb` (English - template)
- `app_zh.arb` (Chinese - fallback)
- `app_zh_Hans.arb` (Simplified Chinese)
- `app_zh_Hant.arb` (Traditional Chinese)

Run `flutter pub get` after modifying ARB files to regenerate.

## 📋 Development Roadmap

### Phase 1: Local-Only MVP (3 Weeks)
- ✅ **Week 1 Days 1-2**: Project setup, dependencies, localization
- **Week 1 Days 3-7**: Database, models, repositories (Part 1)
- **Week 2**: Core features (Properties, Contracts, Payments UI)
- **Week 3**: Polish (Notifications, PDF, Backup, Testing)

### Phase 2: Cloud Sync (2 Weeks) - Future
- Supabase integration
- User authentication
- Multi-device sync
- Conflict resolution

See **PROGRESS.md** for detailed task breakdown.

## 📚 Key Documentation Files

| File | Purpose | Generated By |
|------|---------|--------------|
| **PRD.md** | Product Requirements Document | Claude (product-manager agent) |
| **DESIGN_SPEC.md** | Technical Design Specification (973 lines) | Claude (architect agent) |
| **PROGRESS.md** | Development Progress Tracker | Claude (engineer agent) |
| **README.md** | Project overview (this file) | You & Claude |

## 🗂️ Key Source Code Locations

| Path | What's Inside |
|------|---------------|
| `lib/` | **All Dart app code** |
| `lib/main.dart` | App entry point with Riverpod setup |
| `lib/core/` | Database, enums, constants |
| `lib/repositories/` | Business logic (not yet implemented) |
| `lib/screens/` | UI screens (placeholders) |
| `lib/l10n/` | Localization files (3 languages) |
| `test/` | Unit and widget tests |
| `ios/` | iOS native code and Xcode project |
| `pubspec.yaml` | Flutter dependencies |

## 🤝 Contributing

This is a personal project, but feedback is welcome via issues.

## 📄 License

MIT

---

**Current Status**: Phase 1 Week 1 Day 2 ✅ (Project Setup Complete)
**Next Steps**: Implement database tables and repositories (Days 3-7)
