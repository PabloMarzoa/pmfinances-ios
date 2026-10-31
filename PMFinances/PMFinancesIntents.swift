import Foundation
import AppIntents

// MARK: - Transaction Type Intent Enum

public enum TransactionTypeIntentOption: String, AppEnum, Sendable {
    case gastoUnico = "gastoUnico"
    case gastoRecurrente = "gastoRecurrente"
    case ingreso = "ingreso"

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tipo de Movimiento"

    public static var caseDisplayRepresentations: [TransactionTypeIntentOption: DisplayRepresentation] = [
        .gastoUnico: "Gasto Único",
        .gastoRecurrente: "Gasto Recurrente",
        .ingreso: "Ingreso"
    ]

    public func toDomainType() -> TransactionType {
        switch self {
        case .gastoUnico: return .gastoUnico
        case .gastoRecurrente: return .gastoRecurrente
        case .ingreso: return .ingreso
        }
    }
}

// MARK: - Dynamic Category Options Provider

public struct DynamicCategoryOptionsProvider: DynamicOptionsProvider {
    public init() {}

    public func results() async throws -> [String] {
        let categories = (try? LocalStorageService.shared.fetchCategories()) ?? FinancialCategory.defaultCategories
        let names = categories.map { $0.name }.filter { !$0.isEmpty }
        return names.isEmpty ? ["Otros"] : names
    }
}

// MARK: - Add Financial Record Intent

public struct AddFinancialRecordIntent: AppIntent {
    public static var title: LocalizedStringResource = "Añadir Registro Financiero"
    public static var description = IntentDescription("Añade un nuevo movimiento a finanzas.json en PMFinances.")

    @Parameter(
        title: "Concepto",
        description: "Nombre o descripción del movimiento (ej. Supermercado, Amazon, Nómina)"
    )
    public var name: String

    @Parameter(
        title: "Importe (€)",
        description: "Cantidad en euros"
    )
    public var cantidad: Double

    @Parameter(
        title: "Categoría",
        description: "Categoría del movimiento alimentada desde PMFinances",
        optionsProvider: DynamicCategoryOptionsProvider()
    )
    public var categoria: String

    @Parameter(
        title: "Tipo",
        description: "Tipo de transacción (Gasto Único, Gasto Recurrente o Ingreso)",
        default: .gastoUnico
    )
    public var tipo: TransactionTypeIntentOption

    @Parameter(
        title: "Fecha",
        description: "Fecha y hora del movimiento",
        default: .now
    )
    public var fecha: Date

    public init() {}

    public static var parameterSummary: some ParameterSummary {
        Summary("Añadir \(\.$name) de \(\.$cantidad) € en \(\.$categoria)") {
            \.$tipo
            \.$fecha
        }
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "Movimiento sin concepto" : trimmedName
        let cleanCategory = categoria.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalCategory = cleanCategory.isEmpty ? "Otros" : cleanCategory

        _ = try LocalStorageService.shared.createRecord(
            name: finalName,
            cantidad: abs(cantidad),
            categoria: finalCategory,
            tipo: tipo.toDomainType(),
            fecha: fecha
        )

        let formattedAmount = String(format: "%.2f €", abs(cantidad))
        return .result(dialog: "Añadido a PMFinances: \(finalName) (\(formattedAmount)) en \(finalCategory).")
    }
}

// MARK: - Get Categories Intent

public struct GetCategoriesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Obtener Categorías de PMFinances"
    public static var description = IntentDescription("Devuelve la lista actual de categorías configuradas en PMFinances.")

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<[String]> & ProvidesDialog {
        let categories = (try? LocalStorageService.shared.fetchCategories()) ?? FinancialCategory.defaultCategories
        let names = categories.map { $0.name }
        return .result(
            value: names,
            dialog: "Tienes \(names.count) categorías configuradas en PMFinances: \(names.joined(separator: ", "))."
        )
    }
}

// MARK: - App Shortcuts Provider

public struct PMFinancesShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddFinancialRecordIntent(),
            phrases: [
                "Añadir gasto en \(.applicationName)",
                "Nuevo registro en \(.applicationName)",
                "Añadir movimiento a \(.applicationName)",
                "Registrar gasto con \(.applicationName)"
            ],
            shortTitle: "Añadir Registro",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: GetCategoriesIntent(),
            phrases: [
                "Categorías de \(.applicationName)",
                "Mostrar categorías en \(.applicationName)"
            ],
            shortTitle: "Categorías",
            systemImageName: "tag.fill"
        )
    }
}
