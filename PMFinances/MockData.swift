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

        return [
            FinancialRecord(
                id: "mock_1",
                name: "Test 1",
                cantidad: 50.0,
                categoria: "Amazon",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 1),
                tipo: .gastoUnico
            ),
            FinancialRecord(
                id: "mock_2",
                name: "Test 2",
                cantidad: 20.0,
                categoria: "Apple",
                fecha: makeDate(year: currentYear, month: currentMonth, day: 2),
                tipo: .gastoRecurrente
            )
        ]
    }
}
