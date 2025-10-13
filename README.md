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

```
rent_app/                      # Project root
│
├── app/                       # 📱 FLUTTER APP SOURCE CODE
│   ├── lib/                  # Dart source code
│   │   ├── main.dart        # App entry point
│   │   ├── core/            # Core functionality
│   │   │   ├── database/   # Drift database
│   │   │   ├── enums/      # Enumerations
│   │   │   └── constants/  # Constants
│   │   ├── models/          # Data models (Drift-generated)
│   │   ├── repositories/    # Business logic layer
│   │   ├── services/        # Services layer
│   │   ├── screens/         # UI screens
│   │   │   ├── properties/ # Property management
│   │   │   ├── contracts/  # Contract management
│   │   │   ├── payments/   # Payment tracking
│   │   │   ├── reports/    # Financial reports
│   │   │   └── settings/   # Settings
│   │   ├── widgets/         # Reusable widgets
│   │   ├── providers/       # Riverpod providers
│   │   └── l10n/            # Localization (ARB files)
│   │
│   ├── test/                 # 🧪 Tests
│   │   ├── repositories/    # Repository tests
│   │   ├── services/        # Service tests
│   │   └── widgets/         # Widget tests
│   │
│   ├── ios/                  # 📱 iOS native code
│   │   ├── Runner/          # iOS app wrapper
│   │   └── Runner.xcodeproj/ # Xcode project
│   │
│   ├── pubspec.yaml          # Flutter dependencies
│   ├── l10n.yaml             # Localization config
│   └── analysis_options.yaml # Dart linter config
│
├── PRD.md                     # 📋 Product Requirements (Claude)
├── DESIGN_SPEC.md             # 🏗️  Technical Design (Claude)
├── PROGRESS.md                # 📈 Development Progress (Claude)
├── README.md                  # 📖 This file
│
└── .claude/                   # 🤖 Claude Code configuration
    ├── agents/                # Agent prompts
    └── settings.local.json    # Local settings
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

3. **Navigate to app directory**:
   ```bash
   cd app
   ```

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Generate Drift database code** (when database is implemented):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**:
   ```bash
   flutter run
   ```

### Running Tests

```bash
cd app
flutter test

# Run tests with coverage
flutter test --coverage
```

### Code Analysis

```bash
cd app
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

Add translations to ARB files in `app/lib/l10n/`:
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

## 📚 Documentation Files

| File | Purpose | Location | Generated By |
|------|---------|----------|--------------|
| **PRD.md** | Product Requirements Document | `/PRD.md` | Claude (product-manager) |
| **DESIGN_SPEC.md** | Technical Design (973 lines) | `/DESIGN_SPEC.md` | Claude (architect) |
| **PROGRESS.md** | Development Progress Tracker | `/PROGRESS.md` | Claude (engineer) |
| **README.md** | Project overview | `/README.md` | You & Claude |

## 🗂️ Key Source Code Locations

| Path | What's Inside | Navigate |
|------|---------------|----------|
| `app/` | **All Flutter app code** | `cd app` |
| `app/lib/` | All Dart source code | `cd app/lib` |
| `app/lib/main.dart` | App entry point | - |
| `app/lib/core/` | Database, enums, constants | - |
| `app/lib/repositories/` | Business logic (not yet implemented) | - |
| `app/lib/screens/` | UI screens (placeholders) | - |
| `app/lib/l10n/` | Localization (3 languages) | - |
| `app/test/` | Unit and widget tests | `cd app/test` |
| `app/ios/` | iOS native code | - |
| `app/pubspec.yaml` | Flutter dependencies | - |

## 🤝 Contributing

This is a personal project, but feedback is welcome via issues.

## 📄 License

MIT

---

**Current Status**: Phase 1 Week 1 Day 2 ✅ (Project Setup Complete)
**Next Steps**: Implement database tables and repositories (Days 3-7)
**Working Directory**: All Flutter commands should be run from `app/` folder
