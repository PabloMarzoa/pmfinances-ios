import SwiftUI

public struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject public var viewModel: FinancialViewModel

    @State private var searchText: String = ""
    @State private var categoryToEdit: CategoryItem? = nil
    @State private var isCreatingNew: Bool = false
    @State private var categoryToDelete: CategoryItem? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var showResetConfirmation: Bool = false

    public init(viewModel: FinancialViewModel) {
        self.viewModel = viewModel
    }

    private var filteredCategories: [CategoryItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return viewModel.categories
        }
        return viewModel.categories.filter { $0.name.lowercased().contains(query) }
    }

    private var deleteAlertMessage: LocalizedStringKey {
        guard let item = categoryToDelete else { return "" }
        let count = viewModel.recordCount(for: item.name)
        if count > 0 {
            return "Hay \(count) transacciones registradas con la categoría '\(item.name)'. Si la eliminas, esas transacciones se moverán a 'Otros'."
        } else {
            return "¿Seguro que deseas eliminar la categoría '\(item.name)'?"
        }
    }

    public var body: some View {
        NavigationStack {
            List {
                headerSection
                categoriesListSection
                resetSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .searchable(text: $searchText, prompt: "Buscar categoría...")
            .navigationTitle("Gestionar Categorías")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    CircularDismissButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreatingNew = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .tint(.green)
                    .accessibilityLabel("Añadir Categoría")
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    CircularDismissButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isCreatingNew = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .tint(.green)
                    .accessibilityLabel("Añadir Categoría")
                }
                #endif
            }
            .sheet(isPresented: $isCreatingNew) {
                newCategoryModal
            }
            .sheet(item: $categoryToEdit) { item in
                editCategoryModal(item: item)
            }
            .alert("Eliminar Categoría", isPresented: $showDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    if let item = categoryToDelete {
                        executeDelete(item)
                    }
                }
            } message: {
                Text(deleteAlertMessage)
            }
            .alert("Restablecer Categorías", isPresented: $showResetConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Restablecer", role: .destructive) {
                    executeReset()
                }
            } message: {
                Text("Se restaurará la lista de categorías original. ¿Deseas continuar?")
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 520)
        #endif
        .preferredColorScheme(.dark)
    }

    private var newCategoryModal: some View {
        CategoryEditorModal(
            title: "Nueva Categoría",
            initialName: "",
            initialHex: "#10B981"
        ) { name, hex in
            Task {
                await viewModel.addCategory(name: name, hexColor: hex)
            }
        }
    }

    private func editCategoryModal(item: CategoryItem) -> some View {
        CategoryEditorModal(
            title: "Editar Categoría",
            initialName: item.name,
            initialHex: item.hexColor
        ) { newName, newHex in
            Task {
                await viewModel.updateCategory(original: item, newName: newName, newHexColor: newHex)
            }
        }
    }

    private func executeDelete(_ item: CategoryItem) {
        Task {
            await viewModel.deleteCategory(item)
        }
    }

    private func executeReset() {
        Task {
            await viewModel.resetCategoriesToDefault()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Total de Categorías")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.categories.count) configuradas")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    isCreatingNew = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("Añadir")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.appCardBackground)
        }
    }

    @ViewBuilder
    private var categoriesListSection: some View {
        Section(header: Text("Tus Categorías").foregroundStyle(.secondary)) {
            if filteredCategories.isEmpty {
                Text(searchText.isEmpty ? "No hay categorías configuradas" : "No se encontró ninguna categoría con '\(searchText)'")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.appCardBackground)
            } else {
                ForEach(filteredCategories) { item in
                    categoryRow(for: item)
                        .listRowBackground(Color.appCardBackground)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                prepareDelete(item)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }

                            Button {
                                categoryToEdit = item
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Restablecer Categorías Iniciales")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .listRowBackground(Color.appCardBackground)
        } footer: {
            Text("Al restablecer, volverás a la lista de 22 categorías estándar sugeridas por la aplicación.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func categoryRow(for item: CategoryItem) -> some View {
        let count = viewModel.recordCount(for: item.name)

        return HStack(spacing: 12) {
            Circle()
                .fill(item.color)
                .frame(width: 14, height: 14)
                .shadow(color: item.color.opacity(0.4), radius: 3, x: 0, y: 1)

            Text(item.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.appSecondaryFill)
                    .clipShape(Capsule())
            }

            // Edit button
            Button {
                categoryToEdit = item
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(6)
            }
            .buttonStyle(.plain)

            // Delete button
            Button {
                prepareDelete(item)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private func prepareDelete(_ item: CategoryItem) {
        categoryToDelete = item
        showDeleteConfirmation = true
    }
}

// MARK: - Color Preset Button

private struct ColorPresetButton: View {
    let hex: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        let col = Color(hex: hex)
        Button(action: onSelect) {
            ZStack {
                Circle()
                    .fill(col)
                    .frame(width: 36, height: 36)

                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(width: 36, height: 36)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Editor Modal

private struct CategoryEditorModal: View {
    @Environment(\.dismiss) private var dismiss

    let title: LocalizedStringKey
    let initialName: String
    let initialHex: String
    let onSave: (String, String) -> Void

    @State private var name: String = ""
    @State private var selectedColor: Color = .green
    @State private var selectedHex: String = "#10B981"

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let presetHexColors: [String] = [
        "#10B981", "#059669", "#06B6D4", "#0284C7",
        "#3B82F6", "#6366F1", "#8B5CF6", "#A855F7",
        "#EC4899", "#E11D48", "#EF4444", "#DC2626",
        "#F97316", "#EA580C", "#F59E0B", "#D97706",
        "#14B8A6", "#64748B"
    ]

    private let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    init(title: LocalizedStringKey, initialName: String, initialHex: String, onSave: @escaping (String, String) -> Void) {
        self.title = title
        self.initialName = initialName
        self.initialHex = initialHex
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    previewSection
                    nameFieldSection
                    colorSelectionSection
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    CircularDismissButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    CircularSaveButton(isEnabled: isNameValid) {
                        saveCategory()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    CircularDismissButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    CircularSaveButton(isEnabled: isNameValid) {
                        saveCategory()
                    }
                }
                #endif
            }
            .onAppear {
                name = initialName
                selectedHex = initialHex
                selectedColor = Color(hex: initialHex)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveCategory() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onSave(trimmed, selectedHex)
            dismiss()
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("VISTA PREVIA")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 10, height: 10)

                Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nombre categoría" : name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selectedColor.opacity(0.18))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(selectedColor.opacity(0.4), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var nameFieldSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nombre de la Categoría")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("ej. Restaurantes, Farmacia, Viajes...", text: $name)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Color")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .onChange(of: selectedColor) { _, newColor in
                        selectedHex = newColor.toHex()
                    }
            }

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(presetHexColors, id: \.self) { hex in
                    ColorPresetButton(
                        hex: hex,
                        isSelected: selectedHex.uppercased() == hex.uppercased()
                    ) {
                        selectedHex = hex
                        selectedColor = Color(hex: hex)
                    }
                }
            }
            .padding(14)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    CategoryManagementView(viewModel: FinancialViewModel())
}
