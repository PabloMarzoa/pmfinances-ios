import SwiftUI
import Combine

@MainActor
public class FinancialViewModel: ObservableObject {
    @Published public var allRecords: [FinancialRecord] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    // Sheets & Dialogs
    @Published public var showConfigModal: Bool = false
    @Published public var showCreateModal: Bool = false
    @Published public var selectedRecordForEdit: FinancialRecord? = nil
    @Published public var showSuccessToast: Bool = false
    @Published public var toastMessage: String = ""

    // Filters
    @Published public var timeRange: TimeRangeFilter = .currentMonth
    @Published public var selectedCategories: Set<String> = []
    @Published public var selectedType: String = "all" // "all", "Ingreso", "Gasto recurrente", "Gasto único"
    @Published public var searchQuery: String = ""
    @Published public var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published public var customEndDate: Date = Date()
    @Published public var minAmount: Double? = nil
    @Published public var maxAmount: Double? = nil

    // Categories
    @Published public var categories: [CategoryItem] = []

    public var categoryNames: [String] {
        categories.map(\.name).sorted()
    }

    public func recordCount(for categoryName: String) -> Int {
        allRecords.filter { $0.categoria == categoryName }.count
    }

    private let storageService = LocalStorageService.shared

    public init() {
        Task {
            await loadData()
        }
    }

    // MARK: - Storage Status

    public var isCustomFolderConfigured: Bool {
        storageService.isCustomFolderConfigured
    }

    public var isICloudStorage: Bool {
        storageService.isICloudStorage
    }

    public var currentFolderDisplayName: String {
        storageService.currentFolderDisplayName
    }

    public var metadata: FileStorageMetadata {
        storageService.getMetadata()
    }

    public var statusBadgeTitle: String {
        if isICloudStorage {
            return "iCloud"
        } else if isCustomFolderConfigured {
            return currentFolderDisplayName
        } else {
            return "Local"
        }
    }

    public var statusBadgeColor: Color {
        if isICloudStorage {
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        } else if isCustomFolderConfigured {
            return Color.green
        } else {
            return Color.orange
        }
    }

    public func selectStorageFolder(url: URL) async {
        do {
            try storageService.saveFolderURL(url)
            await loadData()
            showToast("Carpeta configurada correctamente")
        } catch {
            showToast("Error al configurar carpeta: \(error.localizedDescription)")
        }
    }

    public func resetToDefaultFolder() async {
        storageService.resetToDefaultFolder()
        await loadData()
        showToast("Restablecido a carpeta por defecto")
    }

    public func loadDemoData() async {
        do {
            try storageService.loadDemoData()
            await loadData()
            showToast("Datos de demo cargados en finanzas.json")
        } catch {
            showToast("Error al cargar demo: \(error.localizedDescription)")
        }
    }

    // MARK: - Data Loading

    public func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try storageService.fetchRecords()
            self.allRecords = fetched.sorted(by: { $0.fecha > $1.fecha })
            self.categories = (try? storageService.fetchCategories()) ?? FinancialCategory.defaultCategories
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            if self.allRecords.isEmpty {
                self.allRecords = MockData.generateMockRecords()
            }
            self.categories = (try? storageService.fetchCategories()) ?? FinancialCategory.defaultCategories
        }
    }

    // MARK: - CRUD Actions

    public func createRecord(name: String, cantidad: Double, categoria: String, tipo: TransactionType, fecha: Date) async {
        do {
            let saved = try storageService.createRecord(name: name, cantidad: cantidad, categoria: categoria, tipo: tipo, fecha: fecha)
            allRecords.insert(saved, at: 0)
            allRecords.sort(by: { $0.fecha > $1.fecha })
            showToast("Movimiento guardado en finanzas.json")
        } catch {
            showToast("Error al guardar: \(error.localizedDescription)")
        }
    }

    public func updateRecord(_ updated: FinancialRecord) async {
        guard let index = allRecords.firstIndex(where: { $0.id == updated.id }) else { return }
        let original = allRecords[index]
        allRecords[index] = updated
        allRecords.sort(by: { $0.fecha > $1.fecha })
        selectedRecordForEdit = nil

        do {
            try storageService.updateRecord(updated)
            showToast("Movimiento actualizado")
        } catch {
            allRecords[index] = original
            showToast("Error al actualizar: \(error.localizedDescription)")
        }
    }

    public func deleteRecord(id: String) async {
        guard let index = allRecords.firstIndex(where: { $0.id == id }) else { return }
        let original = allRecords[index]
        withAnimation(.easeInOut(duration: 0.25)) {
            _ = allRecords.remove(at: index)
        }
        selectedRecordForEdit = nil

        do {
            try storageService.deleteRecord(id: id)
            showToast("Movimiento eliminado")
        } catch {
            allRecords.insert(original, at: index)
            showToast("Error al eliminar: \(error.localizedDescription)")
        }
    }

    private func showToast(_ msg: String) {
        toastMessage = msg
        showSuccessToast = true
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if toastMessage == msg {
                showSuccessToast = false
            }
        }
    }

    // MARK: - Category Management

    public func addCategory(name: String, hexColor: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if categories.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            showToast("Ya existe una categoría con ese nombre")
            return
        }

        var updatedList = categories
        let newItem = CategoryItem(name: trimmed, hexColor: hexColor)
        updatedList.append(newItem)
        updatedList.sort(by: { $0.name.lowercased() < $1.name.lowercased() })

        do {
            try storageService.saveCategories(updatedList)
            self.categories = updatedList
            showToast("Categoría añadida: \(trimmed)")
        } catch {
            showToast("Error al guardar categoría: \(error.localizedDescription)")
        }
    }

    public func updateCategory(original: CategoryItem, newName: String, newHexColor: String) async {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.caseInsensitiveCompare(original.name) != .orderedSame &&
           categories.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            showToast("Ya existe otra categoría con el nombre '\(trimmed)'")
            return
        }

        var updatedList = categories
        if let idx = updatedList.firstIndex(where: { $0.name == original.name }) {
            updatedList[idx] = CategoryItem(name: trimmed, hexColor: newHexColor)
            updatedList.sort(by: { $0.name.lowercased() < $1.name.lowercased() })
        }

        do {
            try storageService.saveCategories(updatedList)
            self.categories = updatedList

            // If category name was renamed, update all records with that category
            if trimmed != original.name {
                var recordsChanged = false
                var updatedRecords = allRecords
                for i in 0..<updatedRecords.count {
                    if updatedRecords[i].categoria == original.name {
                        updatedRecords[i].categoria = trimmed
                        recordsChanged = true
                    }
                }
                if recordsChanged {
                    try storageService.saveAllRecords(updatedRecords)
                    self.allRecords = updatedRecords
                }
            }

            showToast("Categoría actualizada")
        } catch {
            showToast("Error al actualizar: \(error.localizedDescription)")
        }
    }

    public func deleteCategory(_ category: CategoryItem) async {
        var updatedList = categories
        updatedList.removeAll(where: { $0.name == category.name })

        do {
            try storageService.saveCategories(updatedList)
            self.categories = updatedList

            // Reassign existing records with this deleted category to "Otros"
            var recordsChanged = false
            var updatedRecords = allRecords
            for i in 0..<updatedRecords.count {
                if updatedRecords[i].categoria == category.name {
                    updatedRecords[i].categoria = "Otros"
                    recordsChanged = true
                }
            }
            if recordsChanged {
                try storageService.saveAllRecords(updatedRecords)
                self.allRecords = updatedRecords
            }

            showToast("Categoría eliminada")
        } catch {
            showToast("Error al eliminar categoría: \(error.localizedDescription)")
        }
    }

    public func resetCategoriesToDefault() async {
        let defaults = FinancialCategory.defaultCategories
        do {
            try storageService.saveCategories(defaults)
            self.categories = defaults
            showToast("Categorías restablecidas")
        } catch {
            showToast("Error al restablecer categorías: \(error.localizedDescription)")
        }
    }

    // MARK: - Filter Helpers

    public func isCategorySelected(_ category: String) -> Bool {
        selectedCategories.contains(category)
    }

    public func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    public func clearSelectedCategories() {
        selectedCategories.removeAll()
    }

    public func setAmountPreset(min: Double?, max: Double?) {
        minAmount = min
        maxAmount = max
    }

    public func clearAmountFilter() {
        minAmount = nil
        maxAmount = nil
    }

    public var hasAmountFilter: Bool {
        minAmount != nil || maxAmount != nil
    }

    public var amountFilterLabel: String {
        if let min = minAmount, let max = maxAmount {
            return "\(Int(min))€ - \(Int(max))€"
        }
        if let min = minAmount {
            return "≥ \(Int(min))€"
        }
        if let max = maxAmount {
            return "≤ \(Int(max))€"
        }
        return "Cualquier importe"
    }

    public var hasActiveFilters: Bool {
        timeRange != .currentMonth || hasActiveCommonFilters
    }

    public var hasActiveCommonFilters: Bool {
        !selectedCategories.isEmpty ||
        selectedType != "all" ||
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        hasAmountFilter
    }

    public func clearFilters() {
        timeRange = .currentMonth
        clearCommonFilters()
    }

    public func clearCommonFilters() {
        selectedCategories.removeAll()
        selectedType = "all"
        searchQuery = ""
        clearAmountFilter()
    }

    // MARK: - Filtered Records

    public var filteredRecords: [FinancialRecord] {
        filteredRecords(for: timeRange, customStart: customStartDate, customEnd: customEndDate)
    }

    public func filteredRecords(
        for range: TimeRangeFilter,
        customStart: Date? = nil,
        customEnd: Date? = nil
    ) -> [FinancialRecord] {
        let calendar = Calendar.current
        let now = Date()

        return allRecords.filter { record in
            // 1. Time range filter
            if !matchesTimeRange(range, date: record.fecha, calendar: calendar, now: now, customStart: customStart, customEnd: customEnd) {
                return false
            }

            // 2. Common Category filter
            if !selectedCategories.isEmpty && !selectedCategories.contains(record.categoria) {
                return false
            }

            // 3. Common Type filter
            if selectedType != "all" && record.tipo.rawValue != selectedType {
                return false
            }

            // 4. Common Amount filter
            if let min = minAmount, record.cantidad < min {
                return false
            }
            if let max = maxAmount, record.cantidad > max {
                return false
            }

            // 5. Common Search query
            let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                let matchName = record.name.lowercased().contains(query)
                let matchCat = record.categoria.lowercased().contains(query)
                if !matchName && !matchCat {
                    return false
                }
            }

            return true
        }
    }

    public func matchesTimeRange(
        _ range: TimeRangeFilter,
        date: Date,
        calendar: Calendar = .current,
        now: Date = Date(),
        customStart: Date? = nil,
        customEnd: Date? = nil
    ) -> Bool {
        switch range {
        case .currentMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month) &&
                   calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .lastMonth:
            guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
            return calendar.isDate(date, equalTo: lastMonthDate, toGranularity: .month) &&
                   calendar.isDate(date, equalTo: lastMonthDate, toGranularity: .year)
        case .last3Months:
            guard let startDate = calendar.date(byAdding: .month, value: -3, to: now) else { return false }
            return date >= startDate && date <= now
        case .last6Months:
            guard let startDate = calendar.date(byAdding: .month, value: -6, to: now) else { return false }
            return date >= startDate && date <= now
        case .last12Months:
            guard let startDate = calendar.date(byAdding: .month, value: -12, to: now) else { return false }
            return date >= startDate && date <= now
        case .currentYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .all:
            return true
        case .custom:
            let start = calendar.startOfDay(for: customStart ?? customStartDate)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: customEnd ?? customEndDate) ?? (customEnd ?? customEndDate)
            return date >= start && date <= end
        }
    }

    // MARK: - Stats Calculation

    public var stats: FinancialStats {
        calculateStats(for: filteredRecords)
    }

    public func stats(
        for range: TimeRangeFilter,
        customStart: Date? = nil,
        customEnd: Date? = nil
    ) -> FinancialStats {
        let recs = filteredRecords(for: range, customStart: customStart, customEnd: customEnd)
        return calculateStats(for: recs)
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "MMM yy"
        return formatter
    }()

    public func calculateStats(for records: [FinancialRecord]) -> FinancialStats {
        var s = FinancialStats()
        s.recordCount = records.count

        var expenseByCat: [String: (total: Double, count: Int)] = [:]
        var monthlyMap: [String: (label: String, ingresos: Double, gastos: Double, date: Date)] = [:]

        let calendar = Calendar.current
        let monthFormatter = Self.monthFormatter

        for r in records {
            if r.tipo == .ingreso {
                s.totalIngresos += r.cantidad
            } else {
                s.totalGastos += r.cantidad
                if r.tipo == .gastoRecurrente {
                    s.totalGastoRecurrente += r.cantidad
                } else {
                    s.totalGastoUnico += r.cantidad
                }

                var current = expenseByCat[r.categoria] ?? (total: 0, count: 0)
                current.total += r.cantidad
                current.count += 1
                expenseByCat[r.categoria] = current
            }

            let year = calendar.component(.year, from: r.fecha)
            let month = calendar.component(.month, from: r.fecha)
            let key = String(format: "%04d-%02d", year, month)

            var monthData = monthlyMap[key] ?? (
                label: monthFormatter.string(from: r.fecha).capitalized,
                ingresos: 0,
                gastos: 0,
                date: r.fecha
            )

            if r.tipo == .ingreso {
                monthData.ingresos += r.cantidad
            } else {
                monthData.gastos += r.cantidad
            }
            monthlyMap[key] = monthData
        }

        s.balanceNeto = s.totalIngresos - s.totalGastos
        if s.totalIngresos > 0 {
            let rate = (s.balanceNeto / s.totalIngresos) * 100.0
            s.tasaAhorro = (rate * 10).rounded() / 10
        } else {
            s.tasaAhorro = 0
        }

        // Category breakdown
        s.categoryBreakdown = expenseByCat.map { (cat, val) in
            let pct = s.totalGastos > 0 ? (val.total / s.totalGastos) * 100.0 : 0
            return CategorySummary(
                category: cat,
                total: val.total,
                count: val.count,
                percentage: (pct * 10).rounded() / 10,
                color: FinancialCategory.color(for: cat)
            )
        }.sorted(by: { $0.total > $1.total } )

        // Monthly breakdown sorted chronologically
        s.monthlyBreakdown = monthlyMap.sorted(by: { $0.key < $1.key }).map { (key, val) in
            MonthlyBreakdown(
                monthKey: key,
                label: val.label,
                ingresos: val.ingresos,
                gastos: val.gastos
            )
        }

        return s
    }

    // MARK: - CSV Export

    public func generateCsvContent() -> String {
        let currentStats = stats
        let list = filteredRecords

        func escapeCsv(_ val: Any) -> String {
            let str = String(describing: val).replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(str)\""
        }

        var lines: [String] = []

        lines.append("RESUMEN DE BALANCES")
        lines.append("Métrica,Valor (€ / %)")
        lines.append("\(escapeCsv("Total Ingresos")),\(escapeCsv(String(format: "%.2f", currentStats.totalIngresos)))")
        lines.append("\(escapeCsv("Total Gastos")),\(escapeCsv(String(format: "%.2f", currentStats.totalGastos)))")
        lines.append("\(escapeCsv("Gasto Recurrente")),\(escapeCsv(String(format: "%.2f", currentStats.totalGastoRecurrente)))")
        lines.append("\(escapeCsv("Gasto Único")),\(escapeCsv(String(format: "%.2f", currentStats.totalGastoUnico)))")
        lines.append("\(escapeCsv("Balance Neto")),\(escapeCsv(String(format: "%.2f", currentStats.balanceNeto)))")
        lines.append("\(escapeCsv("Tasa de Ahorro (%)")),\(escapeCsv(String(format: "%.1f", currentStats.tasaAhorro)))")
        lines.append("\(escapeCsv("Total Movimientos")),\(escapeCsv(currentStats.recordCount))")
        lines.append("")

        lines.append("REGISTRO DE MOVIMIENTOS")
        lines.append("Fecha,Concepto,Categoría,Tipo,Importe (€)")

        for record in list {
            lines.append([
                escapeCsv(record.fechaString),
                escapeCsv(record.name),
                escapeCsv(record.categoria),
                escapeCsv(record.tipo.rawValue),
                escapeCsv(String(format: "%.2f", record.cantidad))
            ].joined(separator: ","))
        }

        return "\u{FEFF}" + lines.joined(separator: "\r\n")
    }
}
