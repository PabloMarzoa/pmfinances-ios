import SwiftUI
import Charts

public struct ComparisonMonthItem: Identifiable, Hashable, Equatable, Sendable {
    public let id: String
    public let year: Int
    public let month: Int
    public let label: String
    public let shortLabel: String

    public init(id: String, year: Int, month: Int, label: String, shortLabel: String) {
        self.id = id
        self.year = year
        self.month = month
        self.label = label
        self.shortLabel = shortLabel
    }
}

public struct ComparisonView: View {
    @ObservedObject public var viewModel: FinancialViewModel

    @AppStorage("app_language") private var appLanguage: String = "es"

    // Interval A state
    @State private var rangeA: TimeRangeFilter? = .currentMonth
    @State private var selectedMonthsA: Set<String> = []
    @State private var customStartA: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var customEndA: Date = Date()

    // Interval B state
    @State private var rangeB: TimeRangeFilter? = .lastMonth
    @State private var selectedMonthsB: Set<String> = []
    @State private var customStartB: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndB: Date = Date()

    public init(viewModel: FinancialViewModel) {
        self.viewModel = viewModel
    }

    private var availableMonths: [ComparisonMonthItem] {
        let locale = Locale(identifier: appLanguage)
        let monthNameFormatter = DateFormatter()
        monthNameFormatter.locale = locale
        monthNameFormatter.dateFormat = "MMMM yyyy"

        let shortFormatter = DateFormatter()
        shortFormatter.locale = locale
        shortFormatter.dateFormat = "MMM yy"

        let calendar = Calendar.current
        let referenceDate = Date()
        var items: [ComparisonMonthItem] = []
        for offset in 0..<12 {
            guard let date = calendar.date(byAdding: .month, value: -offset, to: referenceDate) else { continue }
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let id = String(format: "%04d-%02d", year, month)
            let label = monthNameFormatter.string(from: date).capitalized
            let shortLabel = shortFormatter.string(from: date).capitalized
            items.append(ComparisonMonthItem(id: id, year: year, month: month, label: label, shortLabel: shortLabel))
        }
        return items
    }

    private var statsA: FinancialStats {
        if !selectedMonthsA.isEmpty {
            return viewModel.stats(forMonths: selectedMonthsA)
        } else if let range = rangeA {
            return viewModel.stats(for: range, customStart: customStartA, customEnd: customEndA)
        } else {
            return FinancialStats()
        }
    }

    private var statsB: FinancialStats {
        if !selectedMonthsB.isEmpty {
            return viewModel.stats(forMonths: selectedMonthsB)
        } else if let range = rangeB {
            return viewModel.stats(for: range, customStart: customStartB, customEnd: customEndB)
        } else {
            return FinancialStats()
        }
    }

    private func boxLabel(range: TimeRangeFilter?, selectedMonths: Set<String>) -> String {
        if !selectedMonths.isEmpty {
            let months = availableMonths.filter { selectedMonths.contains($0.id) }
            if months.count == 1 {
                return months[0].label
            } else if months.count == 2 {
                return "\(months[0].shortLabel), \(months[1].shortLabel)"
            } else {
                return "\(months.count) \(String(localized: "meses"))"
            }
        } else if let range = range {
            return range.title
        } else {
            return String(localized: "Seleccionar")
        }
    }

    private func intervalTitle(range: TimeRangeFilter?, selectedMonths: Set<String>) -> String {
        if !selectedMonths.isEmpty {
            let months = availableMonths.filter { selectedMonths.contains($0.id) }
            if months.count == 1 {
                return months[0].label
            } else if months.count <= 2 {
                return months.map { $0.shortLabel }.joined(separator: ", ")
            } else {
                return "\(months.count) \(String(localized: "meses"))"
            }
        } else if let range = range {
            return range.title
        } else {
            return String(localized: "Sin selección")
        }
    }

    private let colorA = Color(red: 0.15, green: 0.65, blue: 1.0) // Cyan/Blue
    private let colorB = Color(red: 0.75, green: 0.40, blue: 0.95) // Purple

    public var body: some View {
        let currentStatsA = statsA
        let currentStatsB = statsB

        VStack(spacing: 16) {
            // 1. Selector de Intervalos A y B
            intervalsSelectorCard()

            // 2. Tarjetas KPI Comparativas
            comparisonKPICards(statsA: currentStatsA, statsB: currentStatsB)

            // 3. Gráfico comparativo de Ingresos y Gastos
            comparisonBarChart(statsA: currentStatsA, statsB: currentStatsB)

            // 4. Comparativa detallada por Categoría
            categoryComparisonBreakdown(statsA: currentStatsA, statsB: currentStatsB)
        }
    }

    // MARK: - 1. Selector de Intervalos

    private func intervalsSelectorCard() -> some View {
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
                        let tempMonths = selectedMonthsA
                        let tempStart = customStartA
                        let tempEnd = customEndA

                        rangeA = rangeB
                        selectedMonthsA = selectedMonthsB
                        customStartA = customStartB
                        customEndA = customEndB

                        rangeB = tempRange
                        selectedMonthsB = tempMonths
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
                    selectedMonths: $selectedMonthsA,
                    customStart: $customStartA,
                    customEnd: $customEndA
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
                    selectedMonths: $selectedMonthsB,
                    customStart: $customStartB,
                    customEnd: $customEndB
                )
            }

            // Quick Presets
            HStack(spacing: 8) {
                Text("Preajustes:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                presetButton("Mes vs Anterior") {
                    rangeA = .currentMonth
                    selectedMonthsA.removeAll()
                    rangeB = .lastMonth
                    selectedMonthsB.removeAll()
                }

                presetButton("3M vs 6M") {
                    rangeA = .last3Months
                    selectedMonthsA.removeAll()
                    rangeB = .last6Months
                    selectedMonthsB.removeAll()
                }

                presetButton("Este Año vs Todo") {
                    rangeA = .currentYear
                    selectedMonthsA.removeAll()
                    rangeB = .all
                    selectedMonthsB.removeAll()
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
        .appCardShadow()
    }

    private func intervalBox(
        title: LocalizedStringKey,
        color: Color,
        selectedRange: Binding<TimeRangeFilter?>,
        selectedMonths: Binding<Set<String>>,
        customStart: Binding<Date>,
        customEnd: Binding<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
            }

            Menu {
                // Sección 1: Selección por Meses (Últimos 12 meses)
                Section {
                    ForEach(availableMonths) { item in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedRange.wrappedValue = nil
                                if selectedMonths.wrappedValue.contains(item.id) {
                                    selectedMonths.wrappedValue.remove(item.id)
                                    if selectedMonths.wrappedValue.isEmpty {
                                        selectedRange.wrappedValue = .currentMonth
                                    }
                                } else {
                                    selectedMonths.wrappedValue.insert(item.id)
                                }
                            }
                        } label: {
                            HStack {
                                Text(item.label)
                                if selectedMonths.wrappedValue.contains(item.id) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    if !selectedMonths.wrappedValue.isEmpty {
                        Button(role: .destructive) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMonths.wrappedValue.removeAll()
                                selectedRange.wrappedValue = .currentMonth
                            }
                        } label: {
                            Label("Limpiar selección de meses", systemImage: "xmark.circle")
                        }
                    }
                } header: {
                    Text("Últimos 12 Meses")
                }

                // Sección 2: Rangos Predefinidos
                Section {
                    ForEach(TimeRangeFilter.allCases) { range in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMonths.wrappedValue.removeAll()
                                selectedRange.wrappedValue = range
                            }
                        } label: {
                            HStack {
                                Text(range.localizedTitle)
                                if selectedRange.wrappedValue == range && selectedMonths.wrappedValue.isEmpty {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Rangos Predefinidos")
                }
            } label: {
                HStack {
                    Text(boxLabel(range: selectedRange.wrappedValue, selectedMonths: selectedMonths.wrappedValue))
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

            // Chips horizontales de meses seleccionados
            if !selectedMonths.wrappedValue.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(availableMonths.filter { selectedMonths.wrappedValue.contains($0.id) }) { item in
                            HStack(spacing: 3) {
                                Text(item.shortLabel)
                                    .font(.system(size: 10, weight: .semibold))

                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMonths.wrappedValue.remove(item.id)
                                        if selectedMonths.wrappedValue.isEmpty {
                                            selectedRange.wrappedValue = .currentMonth
                                        }
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(color.opacity(0.15))
                            .foregroundStyle(color)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(color.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.top, 2)
                }
            }

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

    private func presetButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
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

    private func comparisonKPICards(statsA: FinancialStats, statsB: FinancialStats) -> some View {
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
                    suffix: " \(String(localized: "movs"))",
                    isHigherBetter: nil
                )
            }
        }
    }

    private func comparativeRowCard(
        title: LocalizedStringKey,
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

                    Text("\(diff >= 0 ? "+" : "")\(String(format: isCurrency ? "%.2f €" : "%.1f", diff)) (\(diff >= 0 ? "+" : "")\("\(String(format: "%.1f", pctChange))%"))")
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
                        Text(intervalTitle(range: rangeA, selectedMonths: selectedMonthsA))
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
                        Text(intervalTitle(range: rangeB, selectedMonths: selectedMonthsB))
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
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
    }

    private func comparativeMetricCard(
        title: LocalizedStringKey,
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
                    Text("\(diff >= 0 ? "+" : "")\("\(String(format: "%.1f", pctChange))%")")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .foregroundStyle(isPositive ? Color.green : Color.red)
                        .clipShape(Capsule())
                }
            }

            let formattedValA = isCurrency ? String(format: "%.2f €", valA) : "\(String(format: "%.1f", valA))\(suffix)"
            let formattedValB = isCurrency ? String(format: "%.2f €", valB) : "\(String(format: "%.1f", valB))\(suffix)"
            let formattedDiff = isCurrency ? String(format: "%.2f €", diff) : "\(String(format: "%.1f", diff))\(suffix)"

            VStack(alignment: .leading, spacing: 6) {
                // Row A
                HStack {
                    Circle().fill(colorA).frame(width: 6, height: 6)
                    Text("A:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedValA)
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
                    Text(formattedValB)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                // Delta
                HStack {
                    Text("Dif:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(diff >= 0 ? "+" : "")\(formattedDiff)")
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
                .stroke(Color.appCardBorder, lineWidth: 1)
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

    private func comparisonBarChart(statsA: FinancialStats, statsB: FinancialStats) -> some View {
        let labelA = String(localized: "Intervalo A")
        let labelB = String(localized: "Intervalo B")
        let metricIncome = String(localized: "Ingresos")
        let metricExpenses = String(localized: "Gastos")
        let metricBalance = String(localized: "Balance")

        let items: [MetricBarItem] = [
            MetricBarItem(metric: metricIncome, interval: labelA, amount: statsA.totalIngresos, color: colorA),
            MetricBarItem(metric: metricIncome, interval: labelB, amount: statsB.totalIngresos, color: colorB),
            MetricBarItem(metric: metricExpenses, interval: labelA, amount: statsA.totalGastos, color: colorA),
            MetricBarItem(metric: metricExpenses, interval: labelB, amount: statsB.totalGastos, color: colorB),
            MetricBarItem(metric: metricBalance, interval: labelA, amount: max(statsA.balanceNeto, 0), color: colorA),
            MetricBarItem(metric: metricBalance, interval: labelB, amount: max(statsB.balanceNeto, 0), color: colorB)
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
                        HStack(spacing: 2) {
                            Text("A: ")
                                .font(.system(size: 10, weight: .bold))
                            Text(intervalTitle(range: rangeA, selectedMonths: selectedMonthsA))
                                .font(.system(size: 10))
                        }
                    }
                    .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Circle().fill(colorB).frame(width: 8, height: 8)
                        HStack(spacing: 2) {
                            Text("B: ")
                                .font(.system(size: 10, weight: .bold))
                            Text(intervalTitle(range: rangeB, selectedMonths: selectedMonthsB))
                                .font(.system(size: 10))
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Chart(items) { item in
                BarMark(
                    x: .value(String(localized: "Métrica"), item.metric),
                    y: .value(String(localized: "Importe"), item.amount)
                )
                .foregroundStyle(by: .value(String(localized: "Intervalo"), item.interval))
                .position(by: .value(String(localized: "Intervalo"), item.interval))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale([
                labelA: colorA,
                labelB: colorB
            ])
            .chartLegend(.hidden)
            .frame(height: 180)
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
        .appCardShadow()
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

    private func categoryComparisonItems(statsA: FinancialStats, statsB: FinancialStats) -> [CategoryComparisonItem] {
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

    private func categoryComparisonBreakdown(statsA: FinancialStats, statsB: FinancialStats) -> some View {
        let items = categoryComparisonItems(statsA: statsA, statsB: statsB)

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

                                Text(LocalizedStringKey(item.category))
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
                                    Text("\(diff >= 0 ? "+" : "")\(String(format: "%.2f €", diff)) (\(diff >= 0 ? "+" : "")\(String(format: "%.0f", pct))%)")
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
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
        .appCardShadow()
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
