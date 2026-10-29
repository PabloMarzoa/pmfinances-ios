import SwiftUI

public struct CreateRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject public var viewModel: FinancialViewModel

    @State private var name: String = ""
    @State private var amountString: String = ""
    @State private var tipo: TransactionType = .gastoUnico
    @State private var categoria: String = "Comida"
    @State private var fecha: Date = Date()
    @State private var isSaving: Bool = false

    public init(viewModel: FinancialViewModel) {
        self.viewModel = viewModel
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

                        TextField("ej. Compra Mercadona", text: $name)
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
                                Text(t.rawValue).tag(t)
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

                    // Botón Guardar
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Guardar Movimiento")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(isValid ? Color.green : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid || isSaving)
                    .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Nuevo Movimiento")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                    .fontWeight(.bold)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, idealWidth: 460, minHeight: 480)
        #endif
        .preferredColorScheme(.dark)
    }

    private func save() {
        guard isValid else { return }
        isSaving = true
        let clean = amountString.replacingOccurrences(of: ",", with: ".")
        let amount = Double(clean) ?? 0

        Task {
            await viewModel.createRecord(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                cantidad: amount,
                categoria: categoria,
                tipo: tipo,
                fecha: fecha
            )
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    CreateRecordView(viewModel: FinancialViewModel())
}
