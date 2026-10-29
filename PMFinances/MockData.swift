import Foundation

public struct MockData: Sendable {
    nonisolated public static func generateMockRecords() -> [FinancialRecord] {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        func makeDate(year: Int, month: Int, day: Int) -> Date {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            components.hour = 12
            return calendar.date(from: components) ?? now
        }

        let prevMonth = currentMonth == 1 ? 12 : currentMonth - 1
        let prevYear = currentMonth == 1 ? currentYear - 1 : currentYear

        let twoMonthsAgoMonth = prevMonth == 1 ? 12 : prevMonth - 1
        let twoMonthsAgoYear = prevMonth == 1 ? prevYear - 1 : prevYear

        return [
            FinancialRecord(
                id: "mock_1",
                name: "Nómina Empresa",
                cantidad: 2450.0,
                categoria: "Nómina",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 1),
                tipo: .ingreso
            ),
            FinancialRecord(
                id: "mock_2",
                name: "Alquiler Piso",
                cantidad: 750.0,
                categoria: "Piso",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 2),
                tipo: .gastoRecurrente
            ),
            FinancialRecord(
                id: "mock_3",
                name: "Compra Mercadona",
                cantidad: 86.45,
                categoria: "Comida",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 5),
                tipo: .gastoUnico
            ),
            FinancialRecord(
                id: "mock_4",
                name: "Suscripción Netflix & Disney",
                cantidad: 22.98,
                categoria: "Netflix",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 10),
                tipo: .gastoRecurrente
            ),
            FinancialRecord(
                id: "mock_5",
                name: "Gasolina Repsol",
                cantidad: 65.20,
                categoria: "Gasolina",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 12),
                tipo: .gastoUnico
            ),
            FinancialRecord(
                id: "mock_6",
                name: "Seguro Médico Sanitas",
                cantidad: 54.00,
                categoria: "Sanitas",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 15),
                tipo: .gastoRecurrente
            ),
            FinancialRecord(
                id: "mock_7",
                name: "Cena Restaurante con Amigos",
                cantidad: 48.50,
                categoria: "Ocio",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 18),
                tipo: .gastoUnico
            ),
            FinancialRecord(
                id: "mock_8",
                name: "Pedido Amazon",
                cantidad: 39.99,
                categoria: "Amazon",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 20),
                tipo: .gastoUnico
            ),
            FinancialRecord(
                id: "mock_9",
                name: "Almacenamiento iCloud",
                cantidad: 2.99,
                categoria: "iCloud",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 22),
                tipo: .gastoRecurrente
            ),
            FinancialRecord(
                id: "mock_10",
                name: "Factura Móvil Fibra y Teléfono",
                cantidad: 42.00,
                categoria: "Teléfono",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 24),
                tipo: .gastoRecurrente
            ),
            FinancialRecord(
                id: "mock_11",
                name: "Nómina Mes Anterior",
                cantidad: 2450.0,
                categoria: "Nómina",
                fecha: makeDate(year: prevYear, month: prevMonth, day: 1),
                tipo: .ingreso
            ),
            FinancialRecord(
                id: "mock_12",
                name: "Alquiler Piso Mes Anterior",
                cantidad: 750.0,
                categoria: "Piso",
                fecha: makeDate(year: prevYear, month: prevMonth, day: 2),
                tipo: .gastoRecurrente
            ),
            FinancialRecord(
                id: "mock_13",
                name: "Revisión y Taller Coche",
                cantidad: 210.0,
                categoria: "Coche",
                fecha: makeDate(year: prevYear, month: prevMonth, day: 14),
                tipo: .gastoUnico
            ),
            FinancialRecord(
                id: "mock_14",
                name: "Seguro Coche Anual",
                cantidad: 320.0,
                categoria: "Seguro coche",
                fecha: makeDate(year: twoMonthsAgoYear, month: twoMonthsAgoMonth, day: 8),
                tipo: .gastoRecurrente
            )
        ]
    }
}
