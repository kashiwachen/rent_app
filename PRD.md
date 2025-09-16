# Product Requirements Document (PRD) - Rental Property Management iOS App

## 1. Product Overview
**Product Name**: RentTracker iOS App  
**Target User**: Property owners/landlords managing multiple rental properties  
**Core Value**: Simplified income/expense tracking with flexible contract management  

## 2. Core Features & User Stories

### 2.1 Contract Management
- **As a landlord**, I want to create rental contracts with flexible payment schedules (monthly, bi-monthly, quarterly, yearly)
- **As a landlord**, I want to view complete contract history for each property
- **As a landlord**, I want to handle rent increases over time within existing contracts
- **As a landlord**, I want to track partial payments when tenants can't pay full amount

### 2.2 Tenant Information
- **As a landlord**, I want to record basic tenant information (name, contact details)
- **As a landlord**, I want to associate one tenant per property
- **As a landlord**, I want to track security deposits (collection and return)

### 2.3 Financial Tracking
**Income Tracking:**
- Regular rent payments
- Late fees
- Security deposits

**Expense Tracking:**
- Maintenance and repair costs
- Simple expense entry interface

**Payment Methods:**
- Bank transfer tracking
- WeChat Pay tracking
- Manual entry system (no payment integration)

### 2.4 Reporting & Analytics
- **As a landlord**, I want to see yearly income overview
- **As a landlord**, I want to calculate profit/loss across all properties
- **As a landlord**, I want to track vacancy rates
- **As a landlord**, I want to export reports as PDF

### 2.5 User Interface
- **As a landlord**, I want a simple money input interface
- **As a landlord**, I want to quickly identify properties with missing payments
- **As a landlord**, I want rent due notifications
- **As a landlord**, I want offline functionality

## 3. Technical Requirements

### 3.1 Platform
- iOS native application
- Offline-first functionality
- Local data storage with backup capabilities

### 3.2 Data Management
- Local SQLite database
- PDF export functionality
- Data backup/restore features
- No cloud sync required (Phase 1)

## 4. MVP Scope & Priorities

### Phase 1 (MVP) - High Priority
1. ✅ Property and tenant basic information management
2. ✅ Contract creation with flexible payment schedules
3. ✅ Income tracking (rent, late fees, deposits)
4. ✅ Expense tracking (maintenance)
5. ✅ Payment status overview
6. ✅ Rent due notifications

### Phase 2 - Medium Priority
1. Contract history viewing
2. Yearly income reports
3. Profit/loss calculations
4. PDF export functionality

### Phase 3 - Future Enhancements
1. Vacancy rate analytics
2. Advanced reporting features
3. Cloud sync capabilities

## 5. Success Metrics
- Reduced time for income/expense recording
- Clear visibility of payment status across properties
- Accurate yearly financial reporting
- User satisfaction with simple, intuitive interface
