import SwiftUI

public struct KPICardsView: View {
    public let stats: FinancialStats

    public init(stats: FinancialStats) {
        self.stats = stats
    }

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: .infinity), spacing: 12)
    ]

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            // 1. Ingresos Totales
            cardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ingresos Totales")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Spacer()

                        Image(systemName: "arrow.down.left.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.green)
                    }

                    Text("+\(formatCurrency(stats.totalIngresos))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Período seleccionado")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }
            }

            // 2. Gastos Totales
            cardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Gastos Totales")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Spacer()

                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.red)
                    }

                    Text("-\(formatCurrency(stats.totalGastos))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 8) {
                        Text("Rec: \(Int(stats.totalGastoRecurrente))€")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("Único: \(Int(stats.totalGastoUnico))€")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 3. Balance Neto
            cardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Balance Neto")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Spacer()

                        Image(systemName: stats.balanceNeto >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(stats.balanceNeto >= 0 ? .teal : .red)
                    }

                    Text("\(stats.balanceNeto >= 0 ? "+" : "")\(formatCurrency(stats.balanceNeto))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(stats.balanceNeto >= 0 ? Color.teal : Color.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Diferencia neta ahorro")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            // 4. Tasa de Ahorro
            cardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tasa de Ahorro")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Spacer()

                        Image(systemName: "percent")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.purple)
                            .padding(4)
                            .background(Color.purple.opacity(0.15), in: Circle())
                    }

                    Text("\(String(format: "%.1f", stats.tasaAhorro))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Sobre ingresos del período")
                        .font(.system(size: 11))
                        .foregroundStyle(.purple)
                }
            }
        }
    }

    @ViewBuilder
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appCardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: abs(value))) ?? String(format: "%.2f €", abs(value))
    }
}
