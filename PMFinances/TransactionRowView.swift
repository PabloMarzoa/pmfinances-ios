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

                Text(record.tipo.localizedName)
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

// MARK: - Swipeable Transaction Row Container

public struct SwipeableTransactionRow: View {
    public let record: FinancialRecord
    @Binding public var activeSwipedId: String?
    public let onTap: () -> Void
    public let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var hasTriggeredHaptic: Bool = false
    @State private var isDeleting: Bool = false

    private let fullSwipeThreshold: CGFloat = -140

    public init(
        record: FinancialRecord,
        activeSwipedId: Binding<String?>,
        initialOffset: CGFloat = 0,
        onTap: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.record = record
        self._activeSwipedId = activeSwipedId
        self._offset = State(initialValue: initialOffset)
        self.onTap = onTap
        self.onDelete = onDelete
    }

    private var isPastFullSwipe: Bool {
        offset < fullSwipeThreshold
    }

    public var body: some View {
        cardContent
            .opacity(0)
            .accessibilityHidden(true)
            .overlay(alignment: .trailing) {
                // Indicador rojo con icono de basura al arrastrar hacia la izquierda
                if offset < 0 {
                    ZStack(alignment: .trailing) {
                        Color.red

                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(isPastFullSwipe ? 1.25 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPastFullSwipe)
                            .frame(width: 75)
                    }
                    .frame(width: max(0, -offset))
                    .frame(maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("Eliminar")
                }
            }
            .overlay {
                // Tarjeta interactiva en primer plano
                cardContent
                    .offset(x: offset)
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .onTapGesture {
                        if offset != 0 {
                            closeSwipe()
                        } else {
                            onTap()
                        }
                    }
                    .overlay(alignment: .trailing) {
                        // Zona de activación del deslizamiento (únicamente en el lado derecho de la fila)
                        // Esto permite hacer scroll vertical suave sin interferencias en el resto de la fila
                        Color.clear
                            .frame(width: 95)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if offset != 0 {
                                    closeSwipe()
                                } else {
                                    onTap()
                                }
                            }
                            .gesture(dragGesture)
                    }
                    .contextMenu {
                        Button {
                            onTap()
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            triggerDelete()
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
            }
            .onChange(of: activeSwipedId) { _, newId in
                if newId != record.id && offset != 0 {
                    closeSwipe()
                }
            }
    }

    private var cardContent: some View {
        TransactionRowView(record: record)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.appBorder, lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 15, coordinateSpace: .local)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }

                if activeSwipedId != record.id {
                    activeSwipedId = record.id
                }

                let newOffset = value.translation.width

                if newOffset <= 0 {
                    offset = newOffset
                } else {
                    offset = sqrt(newOffset) * 2
                }

                if offset < fullSwipeThreshold {
                    if !hasTriggeredHaptic {
                        triggerSelectionHaptic()
                        hasTriggeredHaptic = true
                    }
                } else {
                    hasTriggeredHaptic = false
                }
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    closeSwipe()
                    return
                }

                if offset < fullSwipeThreshold {
                    triggerDelete()
                } else {
                    // Si se suelta antes de alcanzar el umbral de borrado, vuelve a la derecha
                    closeSwipe()
                }
            }
    }

    private func closeSwipe() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            offset = 0
            if activeSwipedId == record.id {
                activeSwipedId = nil
            }
        }
    }

    private func triggerDelete() {
        guard !isDeleting else { return }
        isDeleting = true
        triggerWarningHaptic()

        withAnimation(.easeOut(duration: 0.22)) {
            offset = -500
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            onDelete()
        }
    }

    private func triggerSelectionHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    private func triggerWarningHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        #endif
    }
}

#Preview {
    VStack(spacing: 14) {
        // Estado normal
        SwipeableTransactionRow(
            record: FinancialRecord(
                id: "1",
                name: "Compra Mercadona",
                cantidad: 64.20,
                categoria: "Comida",
                fecha: Date(),
                tipo: .gastoUnico
            ),
            activeSwipedId: .constant(nil),
            onTap: {},
            onDelete: {}
        )

        // Estado deslizado mostrando el indicador rojo de papelera
        SwipeableTransactionRow(
            record: FinancialRecord(
                id: "2",
                name: "Suscripción Netflix",
                cantidad: 17.99,
                categoria: "Suscripciones",
                fecha: Date(),
                tipo: .gastoRecurrente
            ),
            activeSwipedId: .constant("2"),
            initialOffset: -90,
            onTap: {},
            onDelete: {}
        )
    }
    .padding(16)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
