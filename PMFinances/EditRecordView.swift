import SwiftUI

public struct EditRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject public var viewModel: FinancialViewModel
    public let initialRecord: FinancialRecord

    @State private var name: String = ""
    @State private var amountString: String = ""
    @State private var tipo: TransactionType = .gastoUnico
    @State private var categoria: String = "Otros"
    @State private var fecha: Date = Date()
    @State private var isSaving: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    public init(viewModel: FinancialViewModel, record: FinancialRecord) {
        self.viewModel = viewModel
        self.initialRecord = record
        _name = State(initialValue: record.name)
        _amountString = State(initialValue: String(format: "%.2f", record.cantidad))
        _tipo = State(initialValue: record.tipo)
        _categoria = State(initialValue: record.categoria)
        _fecha = State(initialValue: record.fecha)
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let clean = amountString.replacingOccurrences(of: ",", with: ".")
        guard let num = Double(clean), num > 0 else { return false }
        return true
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Campo 1: Concepto
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Concepto")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        TextField("Concepto", text: $name)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.appCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                            .autocorrectionDisabled()
                    }

                    // Campo 2: Importe
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Importe")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            #if os(iOS)
                            TextField("0,00", text: $amountString)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                            #else
                            TextField("0,00", text: $amountString)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                            #endif

                            Text("€")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }

                    // Campo 3: Tipo de Movimiento
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tipo de Movimiento")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Picker("", selection: $tipo) {
                            ForEach(TransactionType.allCases) { t in
                                Text(t.localizedName).tag(t)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    // Campo 4: Categoría
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Categoría")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Menu {
                            ForEach(viewModel.categoryNames, id: \.self) { cat in
                                Button {
                                    categoria = cat
                                } label: {
                                    HStack {
                                        Text(cat)
                                        if categoria == cat {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(FinancialCategory.color(for: categoria))
                                    .frame(width: 12, height: 12)

                                Text(categoria)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.appCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Campo 5: Fecha
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fecha")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack {
                            DatePicker("", selection: $fecha, displayedComponents: .date)
                                .labelsHidden()
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }

                    // Botón Eliminar Movimiento
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Eliminar Movimiento", systemImage: "trash")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Editar Movimiento")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    CircularDismissButton()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    CircularSaveButton(isSaving: isSaving, isEnabled: isValid) {
                        save()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    CircularDismissButton()
                }

                ToolbarItem(placement: .confirmationAction) {
                    CircularSaveButton(isSaving: isSaving, isEnabled: isValid) {
                        save()
                    }
                }
                #endif
            }
            .confirmationDialog(
                "¿Eliminar este movimiento?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar Movimiento", role: .destructive) {
                    delete()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción eliminará \"\(name)\" permanentemente.")
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, idealWidth: 460, minHeight: 520)
        #endif
        .preferredColorScheme(.dark)
    }

    private func save() {
        guard isValid else { return }
        isSaving = true
        let clean = amountString.replacingOccurrences(of: ",", with: ".")
        let amount = Double(clean) ?? 0

        var updated = initialRecord
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.cantidad = amount
        updated.categoria = categoria
        updated.tipo = tipo
        updated.fecha = fecha

        Task {
            await viewModel.updateRecord(updated)
            isSaving = false
            dismiss()
        }
    }

    private func delete() {
        Task {
            await viewModel.deleteRecord(id: initialRecord.id)
            dismiss()
        }
    }
}

#Preview {
    EditRecordView(
        viewModel: FinancialViewModel(),
        record: FinancialRecord(
            id: UUID().uuidString,
            name: "Compra Supermercado",
            cantidad: 45.50,
            categoria: "Comida",
            fecha: Date(),
            tipo: .gastoUnico
        )
    )
}
