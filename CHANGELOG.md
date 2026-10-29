# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
