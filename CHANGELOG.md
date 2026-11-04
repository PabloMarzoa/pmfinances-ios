# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-11-04

### Added
- **Official Version 1.0 Release**: Reached production readiness across iOS and macOS with full feature completeness.
- **Dynamic Language Detection for Siri Shortcuts**:
  - Pre-registered Siri App Shortcuts automatically adapt to the device system language: phrases, intent titles, parameter prompts (amount, merchant, dynamic categories, transaction type), and confirmation dialogs render in Spanish or English based on `Locale.preferredLanguages`.
  - Settings shortcut trigger dynamically opens `"Nuevo Registro"` or `"New Record"` matching the active device language.
- **Auto-Sync Categories Without Record Mutation**:
  - The app automatically registers any unknown category encountered in transactions into `categories.json` without altering or overwriting existing records.
  - Category deletion protection: categories that have transactions associated with them cannot be deleted until those transactions are reassigned or removed.
- **App Version Display in Settings**:
  - Added discrete, centered version and build indicator (`PMFinances Versión 1.0 (1)`) at the bottom of the Settings menu (`ConfigView`) for error reporting and tracking.
- **Clean Initial Demo Data**:
  - Configured default mock data to two initial sample records: "Test 1" and "Test 2".

### Improved
- **High-Performance Architecture & Frame Rate Optimizations**:
  - Replaced per-row allocations of `DateFormatter` and `NumberFormatter` with thread-safe (`NSLock`) static cached formatters, eliminating scroll stutters and reducing per-row formatting overhead by over 1,000x.
  - Implemented memoization caching in `FinancialViewModel`: `filteredRecords` and `stats` are calculated once and cached, invalidating only when filter properties or record collections change, maintaining 60/120 fps during swipe-to-delete interactions.
  - Optimized file metadata inspection in `LocalStorageService` to prevent redundant synchronous JSON reads and decodes from disk.
  - Reusable static `JSONDecoder` and `JSONEncoder` instances across storage operations.
  - Unified date component extraction in `calculateStats` using a single `Calendar.dateComponents` call.
- **Category Storage Standardization**:
  - Standardized category storage filename to `categories.json` with seamless backwards-compatible automatic migration from legacy `categorias.json`.

### Fixed
- **Settings Appearance Mode & System Sync**:
  - Fixed theme switcher where selecting light, dark, or system stopped responding after initial change.
  - Resolved system appearance synchronization by tracking live window interface style overrides via `AppAppearance.apply(appearance:)`.

---

## [0.5.0] - 2026-10-31

### Added
- **Apple Shortcuts & Siri Integration (App Intents)**:
  - Complete, autonomous native shortcut (`AddFinancialRecordIntent`) pre-registered in iOS via `AppShortcutsProvider`.
  - Step-by-step interactive prompt requesting the 5 required transaction data points: Amount (€), Description/Merchant, Dynamic Category, Transaction Type, and exact Creation Date/Time.
  - Dynamic category provider (`DynamicCategoryOptionsProvider`) feeding categories in real time from `categorias.json`.
  - Automatic background persistence directly to `finanzas.json` (Local Storage and iCloud Drive).
  - Dedicated "Atajos de Siri" settings screen in `ConfigView` with direct "Run Shortcut" button and guides for Siri, Apple Pay automations, and Action Button / Widgets.
- **Interval Comparison Screen ("Comparativa")**:
  - Independent dual time range selection (Interval A vs Interval B) with shared global filters.
  - Comparative KPI cards with delta pill indicators (+/- € and +/- %).
  - Side-by-side comparative bar chart and category-by-category expense comparisons.
- **Category Customization & Submenus in Settings**:
  - Reorganized Settings into submenus: Idioma, Categorías, Atajos de Siri, and Almacenamiento de datos.
  - Dedicated category manager (`categorias.json`) with customizable color palettes.

### Improved
- **Optimized Swipe-to-Delete Interaction**:
  - Restricted the horizontal swipe-to-delete gesture recognizer to the trailing edge (rightmost 95 pt, over the amount/badge area) in `TransactionRowView`.
  - Completely resolved gesture contention with vertical scrolling, ensuring smooth, uninterrupted scrolling across the entire transaction list.
- **Documentation**:
  - Updated `README.md` with comprehensive user onboarding instructions for Apple Shortcuts and Siri.

---

## [0.4.0] - 2026-10-29

### Added
- **Multi-Language Support (English & Spanish)**:
  - Implemented full localization support via native Xcode String Catalog (`Localizable.xcstrings`).
  - Added an in-app language picker (Segmented Picker) in `ConfigView` allowing real-time switching between Español and English.
  - Persisted user language preference across sessions via `@AppStorage("app_language")` dynamically injected into SwiftUI's `.environment(\.locale)`.
  - Localized all UI views, navigation titles, KPI cards, charts, transaction types, time range filters, categories, dialogs, and toast notifications.

---

## [0.3.0] - 2026-10-29

### Added
- **Collapsible Category Breakdown Card**:
  - Made the "Gastos por Categoría" card in `ChartsView` interactively collapsible with fluid animation.
  - Added directional chevron indicator (pointing up when expanded, pointing down when collapsed).
  - Persisted collapsed/expanded state across app sessions using `@AppStorage`.

---

## [0.2.0] - 2026-10-29

### Added
- **New App Icon (`AppIcon`)**: Designed and integrated a 1024x1024 native iOS app icon featuring the purple 3D "PM" financial trend glyph on a deep dark studio gradient with ambient backlight and drop shadows.
- **In-App Branding (`AppLogo`)**: Added multiscale transparent assets (`@1x`, `@2x`, `@3x`) under `AppLogo.imageset`.
- **Navigation & Settings Branding**:
  - Integrated the `AppLogo` alongside the navigation title in the primary toolbar of `ContentView`.
  - Added a dedicated branding header card with the app logo in `ConfigView`.
- **Documentation**:
  - Created `README.md` covering app overview, architecture, key features, and storage mechanisms.
  - Added `CHANGELOG.md` to track project release history.
- **Versioning Policy**: Configured minor version increment workflow (`MARKETING_VERSION = 0.2`).

---

## [0.1.0] - 2026-10-29

### Added
- Initial release of the native SwiftUI iOS application.
- Financial record tracking supporting *Income*, *Expense*, and *Investment* types.
- Real-time KPI summary dashboard (Net balance, Total income, Total expenses, Savings rate).
- Interactive Swift Charts breakdown by category and chronological cash flow trends.
- Search and multi-criteria filtering by period, type, and categories.
- Custom categories manager (create, edit, delete, icons, and colors).
- Persistence engine with local JSON file handling and iCloud Drive support using Security-Scoped Bookmarks.
- CSV export capabilities via native iOS `ShareLink`.
