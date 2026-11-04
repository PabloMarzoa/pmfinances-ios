import SwiftUI

public enum TransactionType: String, CaseIterable, Codable, Identifiable, Sendable {
    case gastoUnico = "Gasto único"
    case gastoRecurrente = "Gasto recurrente"
    case ingreso = "Ingreso"

    public var id: String { rawValue }

    public var isExpense: Bool {
        self != .ingreso
    }

    public var localizedName: LocalizedStringKey {
        switch self {
        case .gastoUnico: return "Gasto único"
        case .gastoRecurrente: return "Gasto recurrente"
        case .ingreso: return "Ingreso"
        }
    }
}

public struct CategoryItem: Identifiable, Hashable, Codable, Sendable {
    public var id: String { name }
    public var name: String
    public var hexColor: String

    public var color: Color {
        Color(hex: hexColor)
    }

    nonisolated public init(name: String, hexColor: String) {
        self.name = name
        self.hexColor = hexColor
    }

    @MainActor
    public init(name: String, color: Color) {
        self.name = name
        self.hexColor = color.toHex()
    }
}

public final class CategoryRegistry: @unchecked Sendable {
    public static let shared = CategoryRegistry()
    private let lock = NSLock()
    private var colorMap: [String: Color] = [:]

    private init() {
        for item in FinancialCategory.defaultCategories {
            colorMap[item.name] = item.color
        }
    }

    public func register(categories: [CategoryItem]) {
        lock.lock()
        defer { lock.unlock() }
        for cat in categories {
            colorMap[cat.name] = cat.color
        }
    }

    public func reset(to categories: [CategoryItem]) {
        lock.lock()
        defer { lock.unlock() }
        colorMap.removeAll()
        for cat in categories {
            colorMap[cat.name] = cat.color
        }
    }

    public func remove(categoryName: String) {
        lock.lock()
        defer { lock.unlock() }
        colorMap.removeValue(forKey: categoryName)
    }

    public func color(for category: String) -> Color {
        lock.lock()
        defer { lock.unlock() }
        return colorMap[category] ?? Color(hex: "#64748B")
    }

    public func allCategories() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(colorMap.keys).sorted()
    }
}

public struct FinancialCategory: Sendable {
    nonisolated public static let defaultCategories: [CategoryItem] = [
        CategoryItem(name: "Amazon", hexColor: "#F59E0B"),
        CategoryItem(name: "Apple", hexColor: "#A855F7"),
        CategoryItem(name: "Care", hexColor: "#EC4899"),
        CategoryItem(name: "Disney", hexColor: "#06B6D4"),
        CategoryItem(name: "Google", hexColor: "#EF4444"),
        CategoryItem(name: "Netflix", hexColor: "#E11D48"),
        CategoryItem(name: "iCloud", hexColor: "#6366F1"),
        CategoryItem(name: "Skyshowtime", hexColor: "#A855F7"),
        CategoryItem(name: "YouTube", hexColor: "#DC2626")
    ]

    public static var standardCategories: [String] {
        CategoryRegistry.shared.allCategories()
    }

    nonisolated public static let paletteHexColors: [String] = [
        "#10B981", "#059669", "#06B6D4", "#0284C7",
        "#3B82F6", "#6366F1", "#8B5CF6", "#A855F7",
        "#EC4899", "#E11D48", "#EF4444", "#DC2626",
        "#F97316", "#EA580C", "#F59E0B", "#D97706",
        "#14B8A6", "#64748B"
    ]

    nonisolated private static let knownCategoryHexColors: [String: String] = [
        "amazon": "#F59E0B",
        "apple": "#A855F7",
        "care": "#EC4899",
        "coche": "#3B82F6",
        "comida": "#10B981",
        "disney": "#06B6D4",
        "efectivo": "#14B8A6",
        "gasolina": "#F97316",
        "google": "#EF4444",
        "netflix": "#E11D48",
        "nómina": "#10B981",
        "nomina": "#10B981",
        "icloud": "#6366F1",
        "ocio": "#8B5CF6",
        "otros": "#64748B",
        "other": "#64748B",
        "piso": "#0284C7",
        "préstamo personal": "#D97706",
        "prestamo personal": "#D97706",
        "sanitas": "#059669",
        "seguro coche": "#EA580C",
        "skyshowtime": "#A855F7",
        "teléfono": "#38BDF8",
        "telefono": "#38BDF8",
        "télegram": "#0EA5E9",
        "telegram": "#0EA5E9",
        "youtube": "#DC2626"
    ]

    nonisolated public static func defaultColorHex(for categoryName: String) -> String {
        let key = categoryName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let known = knownCategoryHexColors[key] {
            return known
        }
        let hash = abs(key.utf8.reduce(5381) { (($0 << 5) &+ $0) &+ Int($1) })
        return paletteHexColors[hash % paletteHexColors.count]
    }

    public static func register(categories: [CategoryItem]) {
        CategoryRegistry.shared.register(categories: categories)
    }

    public static func color(for category: String) -> Color {
        CategoryRegistry.shared.color(for: category)
    }
}

public struct FinancialRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var cantidad: Double
    public var categoria: String
    public var fecha: Date
    public var tipo: TransactionType

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d/M/yyyy"
        return formatter
    }()

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let formatterLock = NSLock()

    public var fechaString: String {
        Self.formatterLock.lock()
        defer { Self.formatterLock.unlock() }
        return Self.dateFormatter.string(from: fecha)
    }

    public var formattedAmount: String {
        Self.formatterLock.lock()
        defer { Self.formatterLock.unlock() }
        return Self.currencyFormatter.string(from: NSNumber(value: cantidad)) ?? String(format: "%.2f €", cantidad)
    }

    nonisolated public init(id: String = UUID().uuidString, name: String, cantidad: Double, categoria: String, fecha: Date, tipo: TransactionType) {
        self.id = id
        self.name = name
        self.cantidad = abs(cantidad)
        self.categoria = categoria
        self.fecha = fecha
        self.tipo = tipo
    }
}

public enum TimeRangeFilter: String, CaseIterable, Identifiable, Sendable {
    case currentMonth = "current_month"
    case lastMonth = "last_month"
    case last3Months = "last_3_months"
    case last6Months = "last_6_months"
    case last12Months = "last_12_months"
    case currentYear = "current_year"
    case all = "all"
    case custom = "custom"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .currentMonth: return "Este mes"
        case .lastMonth: return "Mes pasado"
        case .last3Months: return "Últimos 3 meses"
        case .last6Months: return "Últimos 6 meses"
        case .last12Months: return "Últimos 12 meses"
        case .currentYear: return "Año actual"
        case .all: return "Todo el histórico"
        case .custom: return "Personalizado"
        }
    }

    public var localizedTitle: LocalizedStringKey {
        switch self {
        case .currentMonth: return "Este mes"
        case .lastMonth: return "Mes pasado"
        case .last3Months: return "Últimos 3 meses"
        case .last6Months: return "Últimos 6 meses"
        case .last12Months: return "Últimos 12 meses"
        case .currentYear: return "Año actual"
        case .all: return "Todo el histórico"
        case .custom: return "Personalizado"
        }
    }
}

public struct CategorySummary: Identifiable, Equatable, Sendable {
    public var id: String { category }
    public let category: String
    public let total: Double
    public let count: Int
    public let percentage: Double
    public let color: Color

    nonisolated public init(category: String, total: Double, count: Int, percentage: Double, color: Color) {
        self.category = category
        self.total = total
        self.count = count
        self.percentage = percentage
        self.color = color
    }
}

public struct MonthlyBreakdown: Identifiable, Equatable, Sendable {
    public var id: String { monthKey }
    public let monthKey: String
    public let label: String
    public let ingresos: Double
    public let gastos: Double
    public var balance: Double {
        ingresos - gastos
    }

    nonisolated public init(monthKey: String, label: String, ingresos: Double, gastos: Double) {
        self.monthKey = monthKey
        self.label = label
        self.ingresos = ingresos
        self.gastos = gastos
    }
}

public struct FinancialStats: Equatable, Sendable {
    public var totalIngresos: Double = 0
    public var totalGastos: Double = 0
    public var totalGastoRecurrente: Double = 0
    public var totalGastoUnico: Double = 0
    public var balanceNeto: Double = 0
    public var tasaAhorro: Double = 0
    public var recordCount: Int = 0
    public var categoryBreakdown: [CategorySummary] = []
    public var monthlyBreakdown: [MonthlyBreakdown] = []

    nonisolated public init() {}
}
