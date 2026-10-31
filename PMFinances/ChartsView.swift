import SwiftUI
import Charts

public struct CategoryBreakdownView: View {
    public let stats: FinancialStats
    public let selectedCategories: Set<String>
    public let onCategoryTapped: (String) -> Void

    @AppStorage("pmfinances_category_card_collapsed") private var isCollapsed: Bool = false

    public init(stats: FinancialStats, selectedCategories: Set<String>, onCategoryTapped: @escaping (String) -> Void) {
        self.stats = stats
        self.selectedCategories = selectedCategories
        self.onCategoryTapped = onCategoryTapped
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: isCollapsed ? 0 : 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isCollapsed.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gastos por Categoría")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("Distribución de los gastos en el período")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Text("\(stats.categoryBreakdown.count) categorías")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appTertiaryFill)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1))

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isCollapsed ? 0 : 180))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                if stats.categoryBreakdown.isEmpty {
                    Text("No hay gastos registrados en este período.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    // Stacked Bar
                    GeometryReader { proxy in
                        HStack(spacing: 2) {
                            ForEach(stats.categoryBreakdown) { cat in
                                let width = max(proxy.size.width * CGFloat(cat.percentage / 100.0) - 2, 3)
                                cat.color
                                    .frame(width: width)
                                    .opacity(selectedCategories.isEmpty || selectedCategories.contains(cat.category) ? 1.0 : 0.3)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .frame(height: 14)

                    // Category List
                    VStack(spacing: 8) {
                        ForEach(stats.categoryBreakdown) { cat in
                            let isSelected = selectedCategories.contains(cat.category)

                            Button {
                                onCategoryTapped(cat.category)
                            } label: {
                                HStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(cat.color)
                                        .frame(width: 14, height: 14)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(cat.category)
                                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                                .foregroundStyle(isSelected ? Color.green : Color.primary)

                                            Text("(\(cat.count) movs)")
                                                .font(.system(size: 11))
                                                .foregroundStyle(.secondary)

                                            if isSelected {
                                                Text("Filtro")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .textCase(.uppercase)
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2)
                                                    .background(Color.green.opacity(0.15))
                                                    .foregroundStyle(.green)
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                            }
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(String(format: "%.2f €", cat.total))
                                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(.primary)

                                        Text(String(format: "%.1f%%", cat.percentage))
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.green.opacity(0.1) : Color.appSecondaryFill)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isSelected ? Color.green.opacity(0.6) : Color.appBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

public struct MonthlyEvolutionView: View {
    public let stats: FinancialStats

    public init(stats: FinancialStats) {
        self.stats = stats
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Evolución Mensual")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Comparativa Ingresos vs Gastos")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Ingresos").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text("Gastos").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
            }

            if stats.monthlyBreakdown.isEmpty {
                Text("No hay datos suficientes para calcular la evolución mensual.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                let maxAmount = max(stats.monthlyBreakdown.map { max($0.ingresos, $0.gastos) }.max() ?? 1.0, 1.0)

                VStack(spacing: 12) {
                    ForEach(stats.monthlyBreakdown) { month in
                        VStack(spacing: 8) {
                            HStack {
                                Text(month.label)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .textCase(.uppercase)

                                Spacer()

                                Text("Balance: \(month.balance >= 0 ? "+" : "")\(String(format: "%.2f €", month.balance))")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(month.balance >= 0 ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                                    .foregroundStyle(month.balance >= 0 ? Color.green : Color.red)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(month.balance >= 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            // Bars
                            VStack(spacing: 6) {
                                // Ingresos Bar
                                GeometryReader { proxy in
                                    HStack(spacing: 8) {
                                        Text("Ingresos:")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 50, alignment: .leading)

                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.appSystemFill)
                                                .frame(height: 7)

                                            let barWidth = proxy.size.width - 120
                                            let progress = min(CGFloat(month.ingresos / maxAmount), 1.0)
                                            Capsule()
                                                .fill(Color.green)
                                                .frame(width: max(barWidth * progress, 4), height: 7)
                                        }

                                        Text("+\(Int(month.ingresos))€")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.green)
                                            .frame(width: 55, alignment: .trailing)
                                    }
                                }
                                .frame(height: 14)

                                // Gastos Bar
                                GeometryReader { proxy in
                                    HStack(spacing: 8) {
                                        Text("Gastos:")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 50, alignment: .leading)

                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.appSystemFill)
                                                .frame(height: 7)

                                            let barWidth = proxy.size.width - 120
                                            let progress = min(CGFloat(month.gastos / maxAmount), 1.0)
                                            Capsule()
                                                .fill(Color.red)
                                                .frame(width: max(barWidth * progress, 4), height: 7)
                                        }

                                        Text("-\(Int(month.gastos))€")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.red)
                                            .frame(width: 55, alignment: .trailing)
                                    }
                                }
                                .frame(height: 14)
                            }
                        }
                        .padding(12)
                        .background(Color.appSecondaryFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

public struct CategoryPieChartView: View {
    public let stats: FinancialStats

    public init(stats: FinancialStats) {
        self.stats = stats
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gráfico de Gastos por Categoría")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Distribución porcentual en gráfico circular")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }

            if stats.categoryBreakdown.isEmpty {
                Text("No hay gastos registrados en este período.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 16) {
                    // Pie / Donut Chart (visualización clara y estática)
                    Chart(stats.categoryBreakdown) { cat in
                        SectorMark(
                            angle: .value("Gasto", cat.total),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(cat.color)
                    }
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            if let anchor = chartProxy.plotFrame {
                                let frame = geometry[anchor]
                                VStack(spacing: 2) {
                                    Text("Total Gastos")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.secondary)

                                    Text(String(format: "%.2f €", stats.totalGastos))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(width: frame.width * 0.5)
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                    .frame(height: 220)

                    // Leyenda informativa no interactiva
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                        ForEach(stats.categoryBreakdown) { cat in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(cat.color)
                                    .frame(width: 8, height: 8)

                                Text(cat.category)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Spacer()

                                Text(String(format: "%.1f%%", cat.percentage))
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.appSecondaryFill)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

public struct ChartsView: View {
    public let stats: FinancialStats
    public let selectedCategories: Set<String>
    public let onCategoryTapped: (String) -> Void

    public init(stats: FinancialStats, selectedCategories: Set<String>, onCategoryTapped: @escaping (String) -> Void) {
        self.stats = stats
        self.selectedCategories = selectedCategories
        self.onCategoryTapped = onCategoryTapped
    }

    public var body: some View {
        VStack(spacing: 16) {
            CategoryBreakdownView(
                stats: stats,
                selectedCategories: selectedCategories,
                onCategoryTapped: onCategoryTapped
            )

            MonthlyEvolutionView(stats: stats)

            CategoryPieChartView(stats: stats)
        }
    }
}

#Preview("CategoryPieChartView") {
    let stats: FinancialStats = {
        var s = FinancialStats()
        s.totalGastos = 1420.50
        s.categoryBreakdown = [
            CategorySummary(category: "Alimentación", total: 450.0, count: 12, percentage: 31.7, color: .orange),
            CategorySummary(category: "Vivienda", total: 600.0, count: 2, percentage: 42.2, color: .blue),
            CategorySummary(category: "Transporte", total: 180.50, count: 5, percentage: 12.7, color: .purple),
            CategorySummary(category: "Ocio", total: 190.0, count: 4, percentage: 13.4, color: .pink)
        ]
        return s
    }()

    return CategoryPieChartView(stats: stats)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
