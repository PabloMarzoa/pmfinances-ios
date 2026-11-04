import Foundation
import AppIntents

// MARK: - Device Language Helper

public enum DeviceLanguage: Sendable {
    public static var isSpanish: Bool {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        return preferred.hasPrefix("es")
    }
}

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

    public var localizedTitle: String {
        if DeviceLanguage.isSpanish {
            switch self {
            case .gastoUnico: return "Gasto Único"
            case .gastoRecurrente: return "Gasto Recurrente"
            case .ingreso: return "Ingreso"
            }
        } else {
            switch self {
            case .gastoUnico: return "One-off Expense"
            case .gastoRecurrente: return "Recurring Expense"
            case .ingreso: return "Income"
            }
        }
    }

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
        let fallback = DeviceLanguage.isSpanish ? "Otros" : "Other"
        return names.isEmpty ? [fallback] : names
    }
}

// MARK: - Complete Add Financial Record Intent

public struct AddFinancialRecordIntent: AppIntent {
    public static var title: LocalizedStringResource = "Añadir Registro Financiero"
    public static var description = IntentDescription("Atajo completo para añadir un movimiento a finanzas.json solicitando importe, concepto, categoría, tipo y fecha actual.")

    @Parameter(
        title: "Importe (€)",
        description: "Cantidad en euros del movimiento"
    )
    public var cantidad: Double?

    @Parameter(
        title: "Concepto",
        description: "Nombre o descripción del movimiento"
    )
    public var name: String?

    @Parameter(
        title: "Categoría",
        description: "Categoría del movimiento alimentada desde las categorías de PMFinances",
        optionsProvider: DynamicCategoryOptionsProvider()
    )
    public var categoria: String?

    @Parameter(
        title: "Tipo de Movimiento",
        description: "Tipo de transacción (Gasto Único, Gasto Recurrente o Ingreso)"
    )
    public var tipo: TransactionTypeIntentOption?

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

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let isSpanish = DeviceLanguage.isSpanish

        // 1. Importe / Cantidad (solicitar si no se ha proporcionado)
        let resolvedAmount: Double
        if let c = cantidad, c > 0 {
            resolvedAmount = c
        } else {
            let prompt = isSpanish
                ? "Introduce el importe o cantidad en euros (€):"
                : "Enter the amount in euros (€):"
            resolvedAmount = try await $cantidad.requestValue(
                IntentDialog(stringLiteral: prompt)
            )
        }

        // 2. Concepto (solicitar si no se ha proporcionado)
        let resolvedName: String
        if let n = name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
            resolvedName = n
        } else {
            let prompt = isSpanish
                ? "Introduce el concepto o comercio:"
                : "Enter the description or merchant:"
            resolvedName = try await $name.requestValue(
                IntentDialog(stringLiteral: prompt)
            )
        }

        // 3. Categoría (alimentada en tiempo real de categories.json)
        let categories = (try? LocalStorageService.shared.fetchCategories()) ?? FinancialCategory.defaultCategories
        let categoryNames = categories.map { $0.name }.filter { !$0.isEmpty }
        let validCategories = categoryNames.isEmpty ? ["Amazon"] : categoryNames

        let resolvedCategory: String
        if let cat = categoria?.trimmingCharacters(in: .whitespacesAndNewlines), !cat.isEmpty {
            resolvedCategory = cat
        } else {
            let prompt = isSpanish ? "Selecciona una categoría:" : "Select a category:"
            resolvedCategory = try await $categoria.requestDisambiguation(
                among: validCategories,
                dialog: IntentDialog(stringLiteral: prompt)
            )
        }

        // 4. Tipo de movimiento (Gasto Único, Gasto Recurrente o Ingreso)
        let resolvedTipo: TransactionTypeIntentOption
        if let t = tipo {
            resolvedTipo = t
        } else {
            let prompt = isSpanish ? "Selecciona el tipo de movimiento:" : "Select transaction type:"
            resolvedTipo = try await $tipo.requestDisambiguation(
                among: TransactionTypeIntentOption.allCases,
                dialog: IntentDialog(stringLiteral: prompt)
            )
        }

        // 5. Fecha del momento en que se crea el registro
        let resolvedDate = fecha

        // Guardar directamente en finanzas.json
        _ = try LocalStorageService.shared.createRecord(
            name: resolvedName,
            cantidad: abs(resolvedAmount),
            categoria: resolvedCategory,
            tipo: resolvedTipo.toDomainType(),
            fecha: resolvedDate
        )

        let formattedAmount = String(format: "%.2f €", abs(resolvedAmount))
        let tipoName = resolvedTipo.localizedTitle
        let resultMsg = isSpanish
            ? "Añadido a PMFinances: \(resolvedName) (\(formattedAmount)) en \(resolvedCategory) como \(tipoName)."
            : "Added to PMFinances: \(resolvedName) (\(formattedAmount)) in \(resolvedCategory) as \(tipoName)."
        return .result(
            dialog: IntentDialog(stringLiteral: resultMsg)
        )
    }
}

// MARK: - Get Categories Intent

public struct GetCategoriesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Obtener Categorías de PMFinances"
    public static var description = IntentDescription("Devuelve la lista actual de categorías configuradas en PMFinances.")

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<[String]> & ProvidesDialog {
        let categories = (try? LocalStorageService.shared.fetchCategories()) ?? FinancialCategory.defaultCategories
        let names = categories.map { $0.name }
        let isSpanish = DeviceLanguage.isSpanish
        let dialogMsg = isSpanish
            ? "Tienes \(names.count) categorías configuradas en PMFinances: \(names.joined(separator: ", "))."
            : "You have \(names.count) categories configured in PMFinances: \(names.joined(separator: ", "))."
        return .result(
            value: names,
            dialog: IntentDialog(stringLiteral: dialogMsg)
        )
    }
}

// MARK: - App Shortcuts Provider

public struct PMFinancesShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        if DeviceLanguage.isSpanish {
            return [
                AppShortcut(
                    intent: AddFinancialRecordIntent(),
                    phrases: [
                        "Añadir gasto en \(.applicationName)",
                        "Nuevo registro en \(.applicationName)",
                        "Añadir movimiento a \(.applicationName)",
                        "Registrar gasto con \(.applicationName)",
                        "Crear gasto en \(.applicationName)"
                    ],
                    shortTitle: "Nuevo Registro",
                    systemImageName: "plus.circle.fill"
                ),
                AppShortcut(
                    intent: GetCategoriesIntent(),
                    phrases: [
                        "Categorías de \(.applicationName)",
                        "Mostrar categorías en \(.applicationName)"
                    ],
                    shortTitle: "Categorías",
                    systemImageName: "tag.fill"
                )
            ]
        } else {
            return [
                AppShortcut(
                    intent: AddFinancialRecordIntent(),
                    phrases: [
                        "Add expense in \(.applicationName)",
                        "New record in \(.applicationName)",
                        "Add transaction to \(.applicationName)",
                        "Record expense with \(.applicationName)",
                        "Create expense in \(.applicationName)"
                    ],
                    shortTitle: "New Record",
                    systemImageName: "plus.circle.fill"
                ),
                AppShortcut(
                    intent: GetCategoriesIntent(),
                    phrases: [
                        "Categories of \(.applicationName)",
                        "Show categories in \(.applicationName)"
                    ],
                    shortTitle: "Categories",
                    systemImageName: "tag.fill"
                )
            ]
        }
    }
}
