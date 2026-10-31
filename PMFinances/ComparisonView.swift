import SwiftUI
import Charts

public struct ComparisonView: View {
    @ObservedObject public var viewModel: FinancialViewModel

    // Interval A state
    @State private var rangeA: TimeRangeFilter = .currentMonth
    @State private var customStartA: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var customEndA: Date = Date()

    // Interval B state
    @State private var rangeB: TimeRangeFilter = .lastMonth
    @State private var customStartB: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndB: Date = Date()

    public init(viewModel: FinancialViewModel) {
        self.viewModel = viewModel
    }

    private var statsA: FinancialStats {
        viewModel.stats(for: rangeA, customStart: customStartA, customEnd: customEndA)
    }

    private var statsB: FinancialStats {
        viewModel.stats(for: rangeB, customStart: customStartB, customEnd: customEndB)
    }

    private let colorA = Color(red: 0.15, green: 0.65, blue: 1.0) // Cyan/Blue
    private let colorB = Color(red: 0.75, green: 0.40, blue: 0.95) // Purple

    public var body: some View {
        VStack(spacing: 16) {
            // 1. Selector de Intervalos A y B
            intervalsSelectorCard

            // 2. Filtros comunes (Categorías, Tipo, Importe, Buscador)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Text("Filtros comunes para ambos intervalos")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                FiltersBarView(viewModel: viewModel, showTimeRange: false)
            }

            // 3. Tarjetas KPI Comparativas
            comparisonKPICards

            // 4. Gráfico comparativo de Ingresos y Gastos
            comparisonBarChart

            // 5. Comparativa detallada por Categoría
            categoryComparisonBreakdown
        }
    }

    // MARK: - 1. Selector de Intervalos

    private var intervalsSelectorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Comparativa de Intervalos")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Selecciona dos períodos temporales para comparar")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Botón para intercambiar intervalos
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        let tempRange = rangeA
                        let tempStart = customStartA
                        let tempEnd = customEndA
                        rangeA = rangeB
                        customStartA = customStartB
                        customEndA = customEndB
                        rangeB = tempRange
                        customStartB = tempStart
                        customEndB = tempEnd
                    }
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.appSecondaryFill)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.appBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Intercambiar intervalos")
            }

            // Dual Interval Columns
            HStack(spacing: 12) {
                // Intervalo A
                intervalBox(
                    title: "Intervalo A",
                    color: colorA,
                    selectedRange: $rangeA,
                    customStart: $customStartA,
                    customEnd: $customEndA,
                    recordCount: statsA.recordCount
                )

                // Divider / VS badge
                VStack {
                    Text("VS")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.appTertiaryFill)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1))
                }

                // Intervalo B
                intervalBox(
                    title: "Intervalo B",
                    color: colorB,
                    selectedRange: $rangeB,
                    customStart: $customStartB,
                    customEnd: $customEndB,
                    recordCount: statsB.recordCount
                )
            }

            // Quick Presets
            HStack(spacing: 8) {
                Text("Preajustes:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                presetButton("Mes vs Anterior") {
                    rangeA = .currentMonth
                    rangeB = .lastMonth
                }

                presetButton("3M vs 6M") {
                    rangeA = .last3Months
                    rangeB = .last6Months
                }

                presetButton("Este Año vs Todo") {
                    rangeA = .currentYear
                    rangeB = .all
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
    }

    private func intervalBox(
        title: String,
        color: Color,
        selectedRange: Binding<TimeRangeFilter>,
        customStart: Binding<Date>,
        customEnd: Binding<Date>,
        recordCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)

                Spacer()

                Text("\(recordCount) movs")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Menu {
                ForEach(TimeRangeFilter.allCases) { range in
                    Button {
                        selectedRange.wrappedValue = range
                    } label: {
                        HStack {
                            Text(range.localizedTitle)
                            if selectedRange.wrappedValue == range {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedRange.wrappedValue.localizedTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.appSecondaryFill)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if selectedRange.wrappedValue == .custom {
                VStack(spacing: 4) {
                    DatePicker("Desde", selection: customStart, displayedComponents: .date)
                        .labelsHidden()
                        .font(.system(size: 10))

                    DatePicker("Hasta", selection: customEnd, displayedComponents: .date)
                        .labelsHidden()
                        .font(.system(size: 10))
                }
                .padding(6)
                .background(Color.appSecondaryFill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }

    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.appSecondaryFill)
                .foregroundStyle(.primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Tarjetas KPI Comparativas

    private var comparisonKPICards: some View {
        VStack(spacing: 10) {
            // Balance Neto
            comparativeRowCard(
                title: "Balance Neto",
                icon: "scale.3d",
                valA: statsA.balanceNeto,
                valB: statsB.balanceNeto,
                isCurrency: true,
                isHigherBetter: true
            )

            // Ingresos vs Gastos
            HStack(spacing: 10) {
                comparativeMetricCard(
                    title: "Ingresos",
                    icon: "arrow.down.left",
                    iconColor: .green,
                    valA: statsA.totalIngresos,
                    valB: statsB.totalIngresos,
                    isCurrency: true,
                    isHigherBetter: true
                )

                comparativeMetricCard(
                    title: "Gastos",
                    icon: "arrow.up.right",
                    iconColor: .red,
                    valA: statsA.totalGastos,
                    valB: statsB.totalGastos,
                    isCurrency: true,
                    isHigherBetter: false // Gastar menos es mejor
                )
            }

            // Tasa de Ahorro y Movimientos
            HStack(spacing: 10) {
                comparativeMetricCard(
                    title: "Tasa de Ahorro",
                    icon: "percent",
                    iconColor: .blue,
                    valA: statsA.tasaAhorro,
                    valB: statsB.tasaAhorro,
                    isCurrency: false,
                    suffix: "%",
                    isHigherBetter: true
                )

                comparativeMetricCard(
                    title: "Movimientos",
                    icon: "list.bullet.rectangle",
                    iconColor: .purple,
                    valA: Double(statsA.recordCount),
                    valB: Double(statsB.recordCount),
                    isCurrency: false,
                    suffix: " movs",
                    isHigherBetter: nil
                )
            }
        }
    }

    private func comparativeRowCard(
        title: String,
        icon: String,
        valA: Double,
        valB: Double,
        isCurrency: Bool,
        isHigherBetter: Bool
    ) -> some View {
        let diff = valA - valB
        let pctChange = valB != 0 ? ((valA - valB) / abs(valB)) * 100.0 : (valA > 0 ? 100.0 : 0.0)
        let isPositive = isHigherBetter ? diff >= 0 : diff <= 0

        return VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.green)

                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Delta badge
                HStack(spacing: 3) {
                    Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))

                    Text("\(diff >= 0 ? "+" : "")\(String(format: isCurrency ? "%.2f €" : "%.1f", diff)) (\(diff >= 0 ? "+" : "")\(String(format: "%.1f%%", pctChange)))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .foregroundStyle(isPositive ? Color.green : Color.red)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isPositive ? Color.green.opacity(0.4) : Color.red.opacity(0.4), lineWidth: 1)
                )
            }

            HStack(spacing: 16) {
                // Intervalo A
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Circle().fill(colorA).frame(width: 6, height: 6)
                        Text(rangeA.localizedTitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Text(String(format: isCurrency ? "%.2f €" : "%.0f", valA))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(valA >= 0 ? Color.primary : Color.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 32)
                    .background(Color.appBorder)

                // Intervalo B
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Circle().fill(colorB).frame(width: 6, height: 6)
                        Text(rangeB.localizedTitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Text(String(format: isCurrency ? "%.2f €" : "%.0f", valB))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(valB >= 0 ? Color.primary : Color.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }

    private func comparativeMetricCard(
        title: String,
        icon: String,
        iconColor: Color,
        valA: Double,
        valB: Double,
        isCurrency: Bool,
        suffix: String = "",
        isHigherBetter: Bool?
    ) -> some View {
        let diff = valA - valB
        let pctChange = valB != 0 ? ((valA - valB) / abs(valB)) * 100.0 : (valA > 0 ? 100.0 : 0.0)

        let isPositive: Bool? = {
            guard let isHigherBetter = isHigherBetter else { return nil }
            return isHigherBetter ? diff >= 0 : diff <= 0
        }()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if let isPositive = isPositive {
                    Text("\(diff >= 0 ? "+" : "")\(String(format: "%.1f%%", pctChange))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .foregroundStyle(isPositive ? Color.green : Color.red)
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                // Row A
                HStack {
                    Circle().fill(colorA).frame(width: 6, height: 6)
                    Text("A:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: isCurrency ? "%.2f €" : "%.1f\(suffix)", valA))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                // Row B
                HStack {
                    Circle().fill(colorB).frame(width: 6, height: 6)
                    Text("B:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: isCurrency ? "%.2f €" : "%.1f\(suffix)", valB))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                // Delta
                HStack {
                    Text("Dif:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(diff >= 0 ? "+" : "")\(String(format: isCurrency ? "%.2f €" : "%.1f\(suffix)", diff))")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(isPositive == nil ? Color.secondary : (isPositive! ? Color.green : Color.red))
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }

    // MARK: - 4. Gráfico Comparativo

    private struct MetricBarItem: Identifiable {
        let id = UUID()
        let metric: String
        let interval: String
        let amount: Double
        let color: Color
    }

    private var comparisonBarChart: some View {
        let items: [MetricBarItem] = [
            MetricBarItem(metric: "Ingresos", interval: "Intervalo A", amount: statsA.totalIngresos, color: colorA),
            MetricBarItem(metric: "Ingresos", interval: "Intervalo B", amount: statsB.totalIngresos, color: colorB),
            MetricBarItem(metric: "Gastos", interval: "Intervalo A", amount: statsA.totalGastos, color: colorA),
            MetricBarItem(metric: "Gastos", interval: "Intervalo B", amount: statsB.totalGastos, color: colorB),
            MetricBarItem(metric: "Balance", interval: "Intervalo A", amount: max(statsA.balanceNeto, 0), color: colorA),
            MetricBarItem(metric: "Balance", interval: "Intervalo B", amount: max(statsB.balanceNeto, 0), color: colorB)
        ]

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Comparativa Visual")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Ingresos, Gastos y Balance lado a lado")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle().fill(colorA).frame(width: 8, height: 8)
                        Text("A: \(rangeA.title)").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(colorB).frame(width: 8, height: 8)
                        Text("B: \(rangeB.title)").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }
            }

            Chart(items) { item in
                BarMark(
                    x: .value("Métrica", item.metric),
                    y: .value("Importe", item.amount)
                )
                .foregroundStyle(by: .value("Intervalo", item.interval))
                .position(by: .value("Intervalo", item.interval))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale([
                "Intervalo A": colorA,
                "Intervalo B": colorB
            ])
            .chartLegend(.hidden)
            .frame(height: 180)
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
    }

    // MARK: - 5. Comparativa por Categoría

    private struct CategoryComparisonItem: Identifiable {
        var id: String { category }
        let category: String
        let color: Color
        let amountA: Double
        let amountB: Double
        var diff: Double { amountA - amountB }
        var maxAmount: Double { max(amountA, amountB) }
    }

    private var categoryComparisonItems: [CategoryComparisonItem] {
        var mapA: [String: Double] = [:]
        for c in statsA.categoryBreakdown {
            mapA[c.category] = c.total
        }

        var mapB: [String: Double] = [:]
        for c in statsB.categoryBreakdown {
            mapB[c.category] = c.total
        }

        var allCatNames = Set(mapA.keys).union(mapB.keys)

        // If categories are filtered, only include those matching selectedCategories
        if !viewModel.selectedCategories.isEmpty {
            allCatNames = allCatNames.intersection(viewModel.selectedCategories)
        }

        return allCatNames.map { cat in
            CategoryComparisonItem(
                category: cat,
                color: FinancialCategory.color(for: cat),
                amountA: mapA[cat] ?? 0,
                amountB: mapB[cat] ?? 0
            )
        }.sorted { max($0.amountA, $0.amountB) > max($1.amountA, $1.amountB) }
    }

    private var categoryComparisonBreakdown: some View {
        let items = categoryComparisonItems

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gastos por Categoría")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Comparación del gasto en cada categoría")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(items.count) categorías")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appTertiaryFill)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1))
            }

            if items.isEmpty {
                Text("No hay gastos para comparar en las categorías seleccionadas.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                let maxOverall = max(items.map { $0.maxAmount }.max() ?? 1.0, 1.0)

                VStack(spacing: 10) {
                    ForEach(items) { item in
                        VStack(spacing: 6) {
                            HStack {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)

                                Text(item.category)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)

                                Spacer()

                                // Difference badge
                                let diff = item.diff
                                let pct = item.amountB > 0 ? (diff / item.amountB) * 100.0 : (item.amountA > 0 ? 100.0 : 0.0)
                                let isLessExpense = diff <= 0

                                HStack(spacing: 3) {
                                    Image(systemName: diff <= 0 ? "arrow.down" : "arrow.up")
                                        .font(.system(size: 9, weight: .bold))
                                    Text("\(diff >= 0 ? "+" : "")\(String(format: "%.2f €", diff)) (\(diff >= 0 ? "+" : "")\(String(format: "%.0f%%", pct)))")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(isLessExpense ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                                .foregroundStyle(isLessExpense ? Color.green : Color.red)
                                .clipShape(Capsule())
                            }

                            // Dual comparative bars
                            VStack(spacing: 4) {
                                // Interval A bar
                                GeometryReader { proxy in
                                    HStack(spacing: 6) {
                                        Text("A:")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(colorA)
                                            .frame(width: 16, alignment: .leading)

                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.appSystemFill)
                                                .frame(height: 6)

                                            let barWidth = proxy.size.width - 90
                                            let progress = min(CGFloat(item.amountA / maxOverall), 1.0)
                                            Capsule()
                                                .fill(colorA)
                                                .frame(width: max(barWidth * progress, 3), height: 6)
                                        }

                                        Text(String(format: "%.2f €", item.amountA))
                                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(.primary)
                                            .frame(width: 65, alignment: .trailing)
                                    }
                                }
                                .frame(height: 12)

                                // Interval B bar
                                GeometryReader { proxy in
                                    HStack(spacing: 6) {
                                        Text("B:")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(colorB)
                                            .frame(width: 16, alignment: .leading)

                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.appSystemFill)
                                                .frame(height: 6)

                                            let barWidth = proxy.size.width - 90
                                            let progress = min(CGFloat(item.amountB / maxOverall), 1.0)
                                            Capsule()
                                                .fill(colorB)
                                                .frame(width: max(barWidth * progress, 3), height: 6)
                                        }

                                        Text(String(format: "%.2f €", item.amountB))
                                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(.primary)
                                            .frame(width: 65, alignment: .trailing)
                                    }
                                }
                                .frame(height: 12)
                            }
                        }
                        .padding(10)
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
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    ScrollView {
        ComparisonView(viewModel: FinancialViewModel())
            .padding()
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
