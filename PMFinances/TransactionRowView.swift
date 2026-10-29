import SwiftUI

public struct TransactionRowView: View {
    public let record: FinancialRecord

    public init(record: FinancialRecord) {
        self.record = record
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Category Icon/Color Circle
            ZStack {
                Circle()
                    .fill(FinancialCategory.color(for: record.categoria).opacity(0.2))
                    .frame(width: 40, height: 40)

                Circle()
                    .fill(FinancialCategory.color(for: record.categoria))
                    .frame(width: 14, height: 14)
            }

            // Info Column
            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(record.categoria)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Text(record.fechaString)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Amount & Type Column
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(record.tipo == .ingreso ? "+" : "-")\(record.formattedAmount)")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(record.tipo == .ingreso ? Color.green : Color.primary)

                Text(record.tipo.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeBackground)
                    .foregroundStyle(badgeForeground)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
    }

    private var badgeBackground: Color {
        switch record.tipo {
        case .ingreso:
            return Color.green.opacity(0.15)
        case .gastoRecurrente:
            return Color.blue.opacity(0.15)
        case .gastoUnico:
            return Color.appTertiaryFill
        }
    }

    private var badgeForeground: Color {
        switch record.tipo {
        case .ingreso:
            return Color.green
        case .gastoRecurrente:
            return Color.blue
        case .gastoUnico:
            return Color.secondary
        }
    }
}
