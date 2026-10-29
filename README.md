# PMFinances

**PMFinances** is a modern, native iOS personal finance and expense tracking app built with pure SwiftUI. Designed with a sleek dark aesthetic, purple brand accents, and a privacy-first architecture, it provides an intuitive overview of your financial health without requiring third-party accounts or cloud servers.

---

## Key Features

- **Transaction Tracking**: Log, edit, and organize financial movements categorized as *Income* (Ingreso), *Expense* (Gasto), or *Investment* (Inversión).
- **KPI Metrics Dashboard**: Instant summary cards showing Net Balance, Total Income, Total Expenses, and Savings/Investment Rate.
- **Interactive Visualizations**: Dynamic charts powered by Apple's Swift Charts framework to visualize spending by category and cash flow trends over time.
- **Advanced Filtering & Search**:
  - Period filter (Monthly breakdown or full historical view).
  - Transaction type filters (All, Income, Expense, Investment).
  - Multi-selection category chips and real-time text search.
- **Category Customization**: Create, rename, customize, and delete expense/income categories with custom icons and color schemes.
- **Privacy-First & Local Storage**:
  - All records are saved in a clean, human-readable `finanzas.json` file.
  - **iCloud Drive Support**: Seamless synchronization across devices using user-selected iCloud Drive folders via Apple Security-Scoped Bookmarks.
  - No backend, no accounts, and no data tracking.
- **CSV Data Export**: Export complete transaction histories into CSV format at any time using the native iOS share sheet.

---

## Tech Stack & Architecture

- **Language & Frameworks**: Swift 5.0+, SwiftUI, Swift Charts, UniformTypeIdentifiers.
- **Design Pattern**: MVVM (Model-View-ViewModel) with strict separation between data persistence (`LocalStorageService`), business logic (`FinancialViewModel`), and modular SwiftUI views.
- **Design System**: Tailored pure-black palette (`ThemeColors.swift`) optimized for OLED displays with high-contrast typography and native iOS navigation components.
- **Compatibility**: iOS 17.0+ (Universal iPhone & iPad).

---

## Versioning Policy

This project follows semantic minor version increments (`MARKETING_VERSION = X.Y`). Before each commit containing functional changes or updates, the minor version number is bumped.
