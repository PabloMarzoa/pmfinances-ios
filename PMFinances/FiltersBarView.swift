import SwiftUI

/// Layout horizontal adaptable que salta de línea automáticamente cuando los elementos no entran.
public struct FlowLayout: Layout {
    public var spacing: CGFloat

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxAvailableWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxAvailableWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: maxAvailableWidth, height: currentY + lineHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

public struct FiltersBarView: View {
    @ObservedObject public var viewModel: FinancialViewModel
    public var showTimeRange: Bool = true

    public init(viewModel: FinancialViewModel, showTimeRange: Bool = true) {
        self.viewModel = viewModel
        self.showTimeRange = showTimeRange
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Search Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))

                TextField("Buscar movimiento...", text: $viewModel.searchQuery)
                    .font(.system(size: 13))

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.appSecondaryFill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.appBorder, lineWidth: 1)
            )

            // Filter Chips Flow Layout (wraps to next line when chips don't fit)
            FlowLayout(spacing: 8) {
                if showTimeRange {
                    // Time Range Menu
                    Menu {
                        ForEach(TimeRangeFilter.allCases) { range in
                            Button {
                                viewModel.timeRange = range
                            } label: {
                                HStack {
                                    Text(range.localizedTitle)
                                    if viewModel.timeRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text(viewModel.timeRange.localizedTitle)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(viewModel.timeRange != .currentMonth ? Color.green.opacity(0.18) : Color.appSecondaryFill)
                        .foregroundStyle(viewModel.timeRange != .currentMonth ? Color.green : Color.primary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(viewModel.timeRange != .currentMonth ? Color.green.opacity(0.6) : Color.appBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Category Filter Menu
                Menu {
                    if !viewModel.selectedCategories.isEmpty {
                        Button(role: .destructive) {
                            viewModel.clearSelectedCategories()
                        } label: {
                            Label("Limpiar categorías", systemImage: "xmark")
                        }
                        Divider()
                    }

                    ForEach(viewModel.categoryNames, id: \.self) { cat in
                        Button {
                            viewModel.toggleCategory(cat)
                        } label: {
                            HStack {
                                Text(cat)
                                if viewModel.isCategorySelected(cat) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(viewModel.selectedCategories.isEmpty ? Color.gray : Color.green)
                            .frame(width: 6, height: 6)

                        categoryButtonLabelView
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(!viewModel.selectedCategories.isEmpty ? Color.green.opacity(0.18) : Color.appSecondaryFill)
                    .foregroundStyle(!viewModel.selectedCategories.isEmpty ? Color.green : Color.primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(!viewModel.selectedCategories.isEmpty ? Color.green.opacity(0.6) : Color.appBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Type Filter Menu
                Menu {
                    Button {
                        viewModel.selectedType = "all"
                    } label: {
                        HStack {
                            Text("Todos los tipos")
                            if viewModel.selectedType == "all" { Image(systemName: "checkmark") }
                        }
                    }

                    ForEach(TransactionType.allCases) { type in
                        Button {
                            viewModel.selectedType = type.rawValue
                        } label: {
                            HStack {
                                Text(type.localizedName)
                                if viewModel.selectedType == type.rawValue { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        typeButtonLabelView
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(viewModel.selectedType != "all" ? Color.green.opacity(0.18) : Color.appSecondaryFill)
                    .foregroundStyle(viewModel.selectedType != "all" ? Color.green : Color.primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(viewModel.selectedType != "all" ? Color.green.opacity(0.6) : Color.appBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Amount Interval Menu
                Menu {
                    if viewModel.hasAmountFilter {
                        Button(role: .destructive) {
                            viewModel.clearAmountFilter()
                        } label: {
                            Label("Limpiar importe", systemImage: "xmark")
                        }
                        Divider()
                    }

                    Button("Hasta 50 €") {
                        viewModel.setAmountPreset(min: nil, max: 50)
                    }
                    Button("50 € - 200 €") {
                        viewModel.setAmountPreset(min: 50, max: 200)
                    }
                    Button("200 € - 500 €") {
                        viewModel.setAmountPreset(min: 200, max: 500)
                    }
                    Button("Más de 500 €") {
                        viewModel.setAmountPreset(min: 500, max: nil)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(viewModel.hasAmountFilter ? viewModel.amountFilterLabel : "Importe")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(viewModel.hasAmountFilter ? Color.green.opacity(0.18) : Color.appSecondaryFill)
                    .foregroundStyle(viewModel.hasAmountFilter ? Color.green : Color.primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(viewModel.hasAmountFilter ? Color.green.opacity(0.6) : Color.appBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Clear Filters Button
                let hasFilters = showTimeRange ? viewModel.hasActiveFilters : viewModel.hasActiveCommonFilters
                if hasFilters {
                    Button {
                        if showTimeRange {
                            viewModel.clearFilters()
                        } else {
                            viewModel.clearCommonFilters()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Borrar filtros")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom Date Range Row
            if showTimeRange && viewModel.timeRange == .custom {
                HStack(spacing: 12) {
                    DatePicker("Desde", selection: $viewModel.customStartDate, displayedComponents: .date)
                        .labelsHidden()
                        .font(.system(size: 12))

                    Text("→")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))

                    DatePicker("Hasta", selection: $viewModel.customEndDate, displayedComponents: .date)
                        .labelsHidden()
                        .font(.system(size: 12))
                }
                .padding(8)
                .background(Color.appSecondaryFill)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
        }
        .padding(14)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private var categoryButtonLabelView: some View {
        if viewModel.selectedCategories.isEmpty {
            Text("Categorías")
        } else if viewModel.selectedCategories.count == 1, let first = viewModel.selectedCategories.first {
            Text(first)
        } else {
            Text("\(viewModel.selectedCategories.count) categorías")
        }
    }

    @ViewBuilder
    private var typeButtonLabelView: some View {
        if viewModel.selectedType == "all" {
            Text("Todos los tipos")
        } else if let type = TransactionType(rawValue: viewModel.selectedType) {
            Text(type.localizedName)
        } else {
            Text(viewModel.selectedType)
        }
    }
}

#Preview {
    FiltersBarView(viewModel: FinancialViewModel())
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
